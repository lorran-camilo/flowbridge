# ADR-003 — RabbitMQ, Outbox, redelivery, retry e DLQ

- **Status:** proposta, aguardando aprovação de topologia e parâmetros.
- **Data:** 2026-11-01

## Contexto

A API deve confirmar pedido no PostgreSQL e solicitar processamento em RabbitMQ. Duas escritas independentes permitem perder evento ou publicar pedido que sofreu rollback. A entrega do broker pode repetir; ACK, Outbox ou DLQ não garantem efeito exatamente uma vez.

## Decisão proposta

1. Introduzir primeiro fluxo simples API → RabbitMQ → worker (Fase 5), conforme ordem do guia, deixando documentada a janela de dupla escrita.
2. Na Fase 6, gravar `Order` e `OutboxEvent` na mesma transação PostgreSQL.
3. Publicador recuperável manda mensagem persistente e exige publisher confirm/roteamento válido antes de marcar Outbox `PUBLISHED`.
4. Se publicador cair depois do confirm e antes de marcar estado, pode publicar duplicata. Envelope carrega `eventId` estável e worker usa inbox/constraint idempotente.
5. Fila principal durable/quorum para pedido; ACK manual somente após estado/tentativa persistidos. Limite de entrega configurado explicitamente.
6. Falha transitória usa filas de atraso (proposta 5s, 30s, 120s) e no máximo três redeliveries (quatro execuções totais). Falha permanente/exaustão marca pedido `FAILED` e rejeita sem requeue para DLQ.
7. Reprocessamento manual cria auditoria, nova geração e novo `eventId`; tentativas antigas são preservadas.
8. DLQ durable/quorum, acessível para inspeção operacional; não apagar nem reprocessar automaticamente sem trilha.

Parâmetros e policy para dead lettering precisam ser verificados contra RabbitMQ 4.4. Para quorum queue, at-least-once dead-lettering requer configuração específica, incluindo política/overflow; custo e duplicatas continuam possíveis. Não depender de default de `delivery-limit`.

## Como funcionam os conceitos

- **Outbox:** tabela local armazena o compromisso de publicar na mesma transação do pedido; publisher faz envio depois. Fecha a lacuna de perda, mas não é transação distribuída.
- **Publisher confirm:** broker confirma que aceitou publicação; não significa que o worker já processou.
- **ACK:** consumidor informa que pode remover a entrega. ACK antes de persistir pode perder trabalho; ACK depois de persistir pode permitir duplicidade se cair na janela intermediária.
- **Retry/backoff:** repete falha transitória com atraso para evitar loop agressivo e pressão imediata. Erro permanente não deve repetir.
- **DLQ:** separa mensagem terminal para diagnóstico; não é recuperação automática nem estado de negócio por si só.
- **Idempotência:** dedupe pelo event ID/generation e chave estável de cada efeito simulado permite receber mensagem de novo sem faturar duas vezes.

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
- Política de TTL/retention para Outbox publicada, tentativas e DLQ ainda precisa decisão.

## Como testar

Testcontainers RabbitMQ valida exchanges, bindings, durable queues, TTL/DLX, publisher confirms, roteamento e ACK. Simular crash em cada fronteira: antes do publish, depois do confirm, durante integration call, depois da gravação e antes do ACK. Verificar Outbox recuperada, duplicata deduplicada, limite/backoff respeitado, falha terminal em DLQ e histórico preservado.

## Aprovação pendente

Confirmar RabbitMQ 4.4, tipo quorum, delays/contagem, estratégia de retry por fila TTL, retenção e se retry precisa também de Outbox para eliminar lacunas entre republicar e ACK.

## Referências

- [RabbitMQ release information](https://www.rabbitmq.com/release-information)
- [Quorum queues](https://www.rabbitmq.com/docs/quorum-queues)
- [Dead lettering](https://www.rabbitmq.com/docs/dlx)
- [Publisher confirms](https://www.rabbitmq.com/docs/confirms)
