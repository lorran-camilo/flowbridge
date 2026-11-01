# FlowBridge — contratos de eventos RabbitMQ

**Estado:** contratos e política de retry aprovados na Fase 0; infraestrutura não criada.
**Objetivo:** comunicação assíncrona durável entre Outbox Publisher e worker, mantendo os eventos pequenos e sem dados sensíveis. A API não chama o publisher e não publica diretamente no RabbitMQ.

## Envelope versionado

O mesmo envelope se aplica às versões de eventos. Campos padrão:

| Campo | Tipo | Significado |
|---|---|---|
| `eventId` | UUID | Identidade estável da ocorrência. Duplicatas de transporte preservam este ID; um reprocessamento cria novo event ID. |
| `eventType` | string | Nome semântico, por exemplo `OrderSubmitted`. |
| `eventVersion` | inteiro positivo | Versão incompatível do schema de payload. |
| `occurredAt` | timestamp UTC | Hora em que a solicitação foi gravada. |
| `correlationId` | UUID/texto limitado | Liga logs e requisições relacionadas. |
| `aggregateId` | UUID | ID do pedido relacionado. |
| `processingGeneration` | inteiro positivo | Geração do workflow; começa em 1 e aumenta em reprocessamento autorizado. |
| `payload` | objeto JSON | Dados mínimos do evento. |

### `OrderSubmitted.v1`

```json
{
  "eventId": "8ca5fead-3e7f-4a4c-9353-b028a6f0b2d2",
  "eventType": "OrderSubmitted",
  "eventVersion": 1,
  "occurredAt": "2026-11-01T12:00:00Z",
  "correlationId": "2a035347-84ed-4ebf-ae19-68a801fb383c",
  "aggregateId": "440f14b7-a55b-4935-9719-0dd71ef67140",
  "processingGeneration": 1,
  "payload": { "orderId": "440f14b7-a55b-4935-9719-0dd71ef67140" }
}
```

O worker busca o pedido e os itens no PostgreSQL compartilhado pelo `orderId`, incluindo zonas de frete e peso. Não enviar pedido completo no broker: reduz dados replicados e exige que banco e worker respeitem compatibilidade de schema. O ownership por `client_id` é aplicado na API; o worker processa somente IDs de eventos internos já persistidos e não expõe leitura a clients. O worker não valida tokens OIDC: RabbitMQ autentica a conexão de consumo; o worker valida o envelope e usa inbox/deduplicação e credencial PostgreSQL de privilégio mínimo.

### Confiança e validação no worker

Autenticação da conexão RabbitMQ controla quais processos podem conectar e quais filas/exchanges podem acessar; **não prova que o conteúdo de cada mensagem é confiável ou íntegro**. O worker trata corpo, headers e propriedades AMQP como entrada não confiável. ACLs do broker restringem usuários produtores às exchanges aprovadas e o consumidor às filas necessárias, mas não substituem validação da mensagem nem constituem assinatura criptográfica por evento.

Antes de iniciar processamento, o worker valida:

- origem observada (`exchange`) dentro da allowlist configurada, inicialmente `flowbridge.events`, e `routing_key` compatível com o tipo/versão aceitos (`orders.submitted.v1` ou `orders.reprocessing.requested.v1`); mensagens de retry devem voltar pela exchange e routing key configuradas, não por uma origem arbitrária;
- `eventType` e `eventVersion` em allowlist explícita de schemas suportados; versão desconhecida, zero ou negativa não é interpretada como versão corrente;
- `message_id == eventId`, `type == eventType + ".v" + eventVersion` e `correlation_id == correlationId` após normalização de formato;
- `eventId` e `aggregateId` em formato UUID; `correlationId` em formato UUID ou texto limitado conforme o contrato HTTP; `processingGeneration` inteiro positivo;
- `payload.orderId == aggregateId`, existência do pedido no PostgreSQL e coerência entre geração/evento e estado persistido antes de executar etapas;
- limites de tamanho/profundidade do corpo JSON e presença/tipo dos campos obrigatórios, sem aceitar campos de controle que alterem autorização ou ownership.

Mensagem malformada, de exchange/routing key inesperada ou com identificadores inconsistentes não executa efeitos de negócio. É classificada como inválida/poison, registrada sem conteúdo sensível e encaminhada à quarentena/DLQ conforme a topologia final, sem requeue ilimitado. A implementação deve definir essa rota ao fechar a política de poison message na Fase 6.

Para evento repetido, uma inbox única por `(consumer_name, event_id, generation)` impede novo efeito: evento já `COMPLETED` pode ser ACKado sem repetir etapas; estado incompleto é retomado com idempotência por etapa/efeito e só recebe ACK depois da conclusão persistida. A constraint do banco é a proteção final sob consumo concorrente.

### `OrderReprocessingRequested.v1`

Usado para reprocessamento autorizado. Possui o mesmo envelope e `payload.orderId`, `processingGeneration` incrementada e `eventId` novo. O ator/motivo fica na tabela de auditoria; a mensagem pode carregar somente referência à requisição auditada se necessária para rastreamento, sem duplicar texto livre.

### Evolução

- Mudança aditiva compatível pode ficar na mesma versão se consumidores ignorarem campos desconhecidos e o schema permitir.
- Remover/renomear campo, mudar tipo/semântica ou tornar campo obrigatório requer `eventVersion` nova, routing key nova e período de migração documentado.
- `eventType`, `eventVersion`, routing key e header AMQP `type`/`message_id` devem concordar; validar ao consumir.
- JSON é a serialização proposta. Schema registry está fora de escopo inicial; versionar exemplos/JSON Schema no repositório é sugestão para implementação.

## Topologia proposta

```mermaid
flowchart LR
  API[API: pedido + Outbox na mesma transação] --> PG[(PostgreSQL)]
  P[Outbox Publisher independente] -->|consulta/reivindica PENDING após commit| PG
  P -->|topic: orders.submitted.v1 / orders.reprocessing.requested.v1| E{{flowbridge.events}}
  P -->|marca PUBLISHED após confirm| PG
  E --> Q[[flowbridge.orders.process.v1\nquorum, durable]]
  W[Worker] --> Q
  W -->|transient: publish + confirm, retryAttempt incrementado| RE{{flowbridge.retry}}
  RE --> R1[[flowbridge.orders.retry.5s\nTTL 5s]]
  RE --> R2[[flowbridge.orders.retry.30s\nTTL 30s]]
  RE --> R3[[flowbridge.orders.retry.120s\nTTL 120s]]
  R1 -->|DLX após TTL| E
  R2 -->|DLX após TTL| E
  R3 -->|DLX após TTL| E
  Q -->|permanent/exhausted; reject sem requeue| DE{{flowbridge.dlx}}
  DE --> DQ[[flowbridge.orders.dlq.v1\nquorum, durable]]
```

### Exchanges, filas e routing keys

| Nome proposto | Tipo/durabilidade | Routing/binding | Propósito |
|---|---|---|---|
| `flowbridge.events` | topic, durable | `orders.submitted.v1`, `orders.reprocessing.requested.v1` | Exchange de eventos do domínio. |
| `flowbridge.orders.process.v1` | quorum, durable | Bind às duas routing keys acima | Fila principal do worker. |
| `flowbridge.retry` | direct, durable | `orders.retry.5s`, `.30s`, `.120s` | Recebe republicações atrasadas após falha transitória. |
| `flowbridge.orders.retry.5s` / `.30s` / `.120s` | quorum durable, message TTL proposto 5s/30s/120s | dead-letter exchange `flowbridge.events`, routing key original | Aguarda antes de retornar ao trabalho. |
| `flowbridge.dlx` | direct, durable | `orders.failed.v1` | Exchange de dead lettering terminal. |
| `flowbridge.orders.dlq.v1` | quorum, durable | binding `orders.failed.v1` | Mensagens que esgotaram retry ou não podem ser processadas; investigação manual/auditável. |

Topologia/nome de fila são baseline de desenho a confirmar tecnicamente na Fase 6. Configurar filas/exchanges por policy declarativa versionada; não depender de criação manual em painel. Evitar `requeue=true` imediato como política de retry.

### Propriedades AMQP

- mensagem persistente (`deliveryMode=2`) e filas duráveis;
- `message_id = eventId`, `correlation_id = correlationId`, `type = eventType + ".v" + eventVersion`, content type JSON;
- headers `processing-generation` e `retry-attempt` (inteiro). `retry-attempt=0` na primeira entrega;
- publisher confirms habilitados e retorno de mensagem não roteada tratado como falha, não como sucesso;
- consumer ACK manual após efeitos persistidos; prefetch explícito para limitar trabalho em voo;
- queue delivery limit explícito mesmo que RabbitMQ tenha default, pois configuração default pode variar entre versão/topologia;
- exchange de origem, routing key, propriedades AMQP e envelope precisam passar pelos checks de allowlist e consistência acima; autenticação do broker não substitui esses checks;
- proposal de quorum + at-least-once dead-lettering exige verificar policy/overflow aceitos pela versão. RabbitMQ documenta trade-offs: pode reter mensagens, aumentar uso de recursos e ainda exigir deduplicação.

## Retry, falhas e DLQ

1. O worker classifica erro como transitório ou permanente; classificação é explícita e testável.
2. Em falha transitória, registra `ProcessingAttempt` e o código de erro. Após a execução inicial, permite até três retries com intervalos de 5, 30 e 120 segundos; `retry-attempt=0` é a execução inicial, `1..3` são retries. Não usar jitter no escopo inicial. Republica para fila de atraso correspondente, aguarda publisher confirm e só então ACKa a entrega atual.
3. Se a publicação da cópia de retry não for confirmada, não ACKar a original; proteger contra loop agressivo com contagem de delivery/restart e alarmes. Melhor robustez futura pode persistir intenção de retry no Outbox, mas isso eleva escopo; decidir antes se cenário exigir.
4. Após a terceira tentativa de retry (quatro execuções totais), marcar pedido `FAILED`, registrar timeline e rejeitar sem requeue para DLX/DLQ.
5. Erro permanente segue para DLQ sem repetir automaticamente; pedido fica `FAILED` com código de falha não sensível.
6. Falha no processo antes de ACK provoca redelivery. `eventId` e `processingGeneration` mantêm idempotência; uma tentativa em estado incompleto pode ser retomada sem repetir integração já concluída.
7. Operação humana investiga DLQ. Reprocessamento pelo endpoint exige motivo, cria registro de auditoria e evento/generation novos; não apagar a mensagem ou histórico original silenciosamente. O worker começa pela etapa falha e inclui descendentes no grafo explícito e versionado. Só preserva resultado concluído se versão da regra, hash das entradas e pré-requisitos forem válidos; invalidar uma etapa invalida descendentes. Os nós iniciais são `FREIGHT` e `BILLING`; arestas serão explicitamente decididas e testadas na Fase 6 porque a especificação não fixa relação entre eles.

**Aprovado:** uma execução inicial e até três retries nos intervalos 5/30/120s; jitter fora do escopo inicial; reprocessamento com motivo obrigatório e cálculo de etapas por dependências versionadas. TTL/DLX concreto, política de poison message, retenção da DLQ e se a intenção de retry precisa também ser persistida em Outbox serão verificados na Fase 6. RabbitMQ não oferece `exactly-once`; a garantia é processamento pelo menos uma vez com efeitos idempotentes.

## Como testar

- contrato JSON e campos obrigatórios inválidos/versões desconhecidas;
- publisher confirma mensagem persistente roteada e detecta mensagem sem binding;
- publisher concorrente não reivindica a mesma Outbox; publisher interrompido tem claim recuperado quando o lease vence;
- crash depois do publisher confirm e antes do update PostgreSQL causa republicação com `eventId` igual, deduplicada pela inbox sem repetir efeitos;
- worker rejeita exchange/routing key inesperada, versão não suportada, propriedades AMQP divergentes, UUID inválido e `payload.orderId` divergente de `aggregateId` antes de executar efeitos;
- consumer muda status e ACK somente após commit;
- queda antes de integração, após integração e antes do ACK;
- duplicate delivery não duplica cobrança/faturamento simulado;
- reprocessamento de grafo declarado preserva etapa de sucesso com versão/entradas/pré-requisitos válidos; invalidar resultado de etapa faz seus descendentes serem refeitos;
- transiente passa pelas filas de atraso e respeita limite;
- permanente/esgotada chega à DLQ, preservando estado/timeline;
- indisponibilidade de fila de retry não perde silenciosamente a mensagem;
- teste de contrato demonstra que evento antigo não é reinterpretado como versão nova.

RabbitMQ real via Testcontainers é necessário para declarar exchange, TTL, DLX, confirmações e ACK validados. Mocks servem só para classificação de erro e regra pura de retry.

## Fontes

- [RabbitMQ releases](https://www.rabbitmq.com/release-information)
- [Quorum queues e delivery limit](https://www.rabbitmq.com/docs/quorum-queues)
- [Dead-letter exchanges](https://www.rabbitmq.com/docs/dlx)
- [Publisher confirms](https://www.rabbitmq.com/docs/confirms)
- [Message TTL](https://www.rabbitmq.com/docs/ttl)
