# ADR-003 — RabbitMQ, Outbox, redelivery, retry e DLQ

- **Status:** Accepted
- **Data:** 2026-11-01

## Contexto

A API deve confirmar o pedido e a intenção de processamento no PostgreSQL. O Outbox Publisher independente lê a intenção após commit e solicita entrega pelo RabbitMQ. Duas escritas independentes permitiriam perder evento ou publicar pedido que sofreu rollback; ACK, Outbox ou DLQ não garantem efeito exatamente uma vez.

## Decisão

1. API grava `Order` e `OutboxEvent` na mesma transação PostgreSQL; somente depois do commit o Outbox Publisher independente consulta/reivindica o evento pendente e publica no RabbitMQ.
2. O publicador recuperável manda mensagem persistente e exige publisher confirm/roteamento válido antes de marcar a linha da Outbox `PUBLISHED`.
3. O worker não é chamado diretamente pela API; consome da fila e persiste resultados antes do ACK.
4. Claim da Outbox é atômico: selecionar linha elegível com lock/skip-locked e gravar `PUBLISHING`, `locked_by`, `claim_token` e lease na mesma transação curta. Publisher que falha deixa lease recuperável; após expiração, outra instância pode reivindicar a linha. Atualização final só vale para o token do claim vigente.
5. Se publicador cair depois do confirm e antes de marcar estado, pode publicar duplicata após expirar o lease. Envelope republicado mantém `eventId`, agregado e geração; worker usa inbox/constraint e chaves idempotentes para deduplicar.
6. Fila principal durable/quorum para pedido; ACK manual somente após estado/tentativa persistidos. Limite de entrega configurado explicitamente.
7. Falha transitória usa filas de atraso de 5s, 30s e 120s, com uma execução inicial e até três retries (quatro execuções totais). Jitter está fora do escopo inicial. Falha permanente/exaustão marca pedido `FAILED` e rejeita sem requeue para DLQ.
8. Reprocessamento manual exige motivo, cria auditoria, nova geração e novo `eventId`; tentativas antigas são preservadas. Retoma a etapa que falhou e as etapas dependentes que precisem ser refeitas, preservando etapas anteriores ainda válidas.
9. DLQ durable/quorum, acessível para inspeção operacional; não apagar nem reprocessar automaticamente sem trilha.

Parâmetros e policy para dead lettering precisam ser verificados contra RabbitMQ 4.4. Para quorum queue, at-least-once dead-lettering requer configuração específica, incluindo política/overflow; custo e duplicatas continuam possíveis. Não depender de default de `delivery-limit`.

## Como funcionam os conceitos

- **Outbox:** tabela local armazena o compromisso de publicar na mesma transação do pedido; o processo Outbox Publisher consulta a tabela após commit e envia depois. A API não invoca o publisher. Fecha a lacuna de perda, mas não é transação distribuída.
- **Publisher confirm:** broker confirma que aceitou publicação; não significa que o worker já processou.
- **ACK:** consumidor informa que pode remover a entrega. ACK antes de persistir pode perder trabalho; ACK depois de persistir pode permitir duplicidade se cair na janela intermediária.
- **Retry/backoff:** repete falha transitória com atraso para evitar loop agressivo e pressão imediata. Erro permanente não deve repetir.
- **DLQ:** separa mensagem terminal para diagnóstico; não é recuperação automática nem estado de negócio por si só.
- **Idempotência:** dedupe pelo event ID/generation e chave estável de cada efeito simulado permite receber mensagem de novo sem faturar duas vezes.
- **Validação de mensagem:** autenticação RabbitMQ controla acesso ao broker, não confiabilidade do payload. O worker valida exchange/routing key, tipo/versão, identificadores e consistência AMQP/envelope antes de processar.

## Alternativas

- Banco e broker distribuídos com 2PC: complexidade/indisponibilidade e não apropriado aqui.
- `requeue=true` imediato: simples, mas gera loop quente sem backoff/limite.
- Debezium/CDC: resolve publicação lendo WAL, mas adiciona infraestrutura; fora de escopo inicial.
- Polling Outbox com um publisher único: simples para início, mas não escala horizontalmente sem claim/lease.
- Retry só no broker versus tabela de retry no banco: filas TTL são ensináveis e usam RabbitMQ nativo; um scheduler/Outbox de retry facilita estado auditável mas aumenta escopo. Começar com filas de atraso; reavaliar se teste de falha provar lacuna de recuperação.

## Consequências e limites

- Garantia declarada: publicação/entrega pelo menos uma vez nos limites configurados e efeitos de negócio idempotentes; nunca “exactly once”.
- Mensagem pode duplicar; banco e DLQ podem divergir momentaneamente; monitorar contagens e estado.
- Publisher precisa impedir dois processos reivindicarem o mesmo evento ao mesmo tempo.
- Worker pode completar freight antes de falhar billing; reprocessamento deve não duplicar etapa concluída e atualizar status global deterministicamente.
- Retenção/expurgo de Outbox publicada, tentativas, timeline e DLQ ainda não tem janela operacional aprovada; isso é separado da retenção de chave idempotente de 24 horas.

## Como testar

Testcontainers RabbitMQ valida exchanges, bindings, durable queues, TTL/DLX, publisher confirms, roteamento e ACK. Simular crash em cada fronteira: antes do publish, depois do confirm, durante integration call, depois da gravação e antes do ACK. Verificar Outbox recuperada, duplicata deduplicada, limite/backoff respeitado, falha terminal em DLQ e histórico preservado.

Os testes de Outbox devem executar publishers concorrentes contra as mesmas pendências, provar claim atômico e retomar o claim após expirar o lease do publisher interrompido. Injetar crash depois do publisher confirm e antes de marcar `PUBLISHED`; a republicação conserva o mesmo `eventId` e não repete efeitos no worker. Testes de contrato do consumidor rejeitam origem inesperada, routing key/type/version incoerentes, IDs inválidos e payload com `orderId` divergente de `aggregateId`.

### Dependências entre etapas e reprocessamento

As etapas serão identificadas por IDs estáveis (`FREIGHT`, `BILLING`) e relacionadas por um grafo acíclico explícito, versionado junto ao fluxo do worker. Uma aresta só existe se o contrato da etapa declarar que ela depende do resultado de outra; ordem textual/de execução não cria dependência por si só. A especificação não define se faturamento depende do resultado do frete, portanto essa aresta (ou a independência entre etapas) será fixada ao desenhar o caso de uso da Fase 6 antes de implementar o workflow. O worker persiste por etapa estado, versão da regra e hash das entradas relevantes. No reprocessamento, começa na etapa que falhou e inclui todos os seus descendentes no grafo. Conserva o resultado de uma etapa concluída somente se seu estado for sucesso, a versão/regra e o hash de entradas continuarem iguais e nenhuma dependência tiver sido invalidada. A nova geração registra a etapa como `REUSED` com referência à linha de origem, sem criar uma execução de integração fictícia. Alteração de entrada/regra ou falha em pré-requisito invalida os descendentes. Chaves idempotentes estáveis por pedido/etapa/efeito evitam duplicar efeitos em redelivery. Alteração manual de dados do pedido não faz parte do contrato inicial.

O grafo é configuração explícita e testada, não ordem incidental do código. O aceite da Fase 6 precisa registrar as arestas aprovadas e testar cada uma, incluindo um cenário com etapas independentes se esse for o contrato escolhido. Mudanças futuras de etapas ou dependências exigem revisão do grafo e testes de invalidação.

## Aprovação

RabbitMQ 4.4, uma execução inicial + até três retries de 5/30/120 segundos sem jitter e reprocessamento com motivo obrigatório foram aprovados. O reprocessamento refaz a etapa falha e descendentes dependentes invalidados, preservando resultados válidos por estado/versão/hash. Tipo de fila, TTL/DLX, retenção da DLQ e proteção da janela republicação/ACK serão fixados e testados na Fase 6; este ADR não autoriza infraestrutura agora.

## Referências

- [RabbitMQ release information](https://www.rabbitmq.com/release-information)
- [Quorum queues](https://www.rabbitmq.com/docs/quorum-queues)
- [Dead lettering](https://www.rabbitmq.com/docs/dlx)
- [Publisher confirms](https://www.rabbitmq.com/docs/confirms)
