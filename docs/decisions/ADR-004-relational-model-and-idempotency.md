# ADR-004 — PostgreSQL, modelo de pedido e idempotência persistente

- **Status:** proposta, aguardando confirmação de payload e retenção.
- **Data:** 2026-11-01

## Contexto

Pedidos, histórico e trabalho pendente precisam sobreviver a restart. Um `if` em memória não impede duas requisições simultâneas de usar a mesma chave. O modelo também deve preservar falhas/reprocessamentos sem sobrescrever evidência.

## Decisão proposta

- PostgreSQL relacional como fonte de verdade; Flyway controla schema incremental.
- Separar pedido, itens, idempotency record, Outbox, tentativa de processamento, execução de integração, inbox de eventos e auditoria/timeline.
- Dinheiro como decimal exato; validação positiva e transições como regras de domínio e constraints relevantes.
- `Idempotency-Key` limitada por `client_scope`, constraint única `(client_scope, idempotency_key)`, hash de payload canônico e vínculo ao pedido/resposta original.
- Repetição equivalente recupera resposta anterior; mesma chave com payload materialmente diferente retorna `409`.
- Transação única para pedido, itens, idempotency record e Outbox.
- Sem endpoint DELETE no primeiro contrato (proposta), para não apagar histórico e vínculos.
- Retenção sugerida de chaves: 24h, pendente de aprovação; manter histórico append-only durante retenção acordada.

## Por que e como funciona

Relacional/SQL permite constraints, índices e transações explícitas sobre dados ligados. A unique constraint é a árbitra final em concorrência: se dois pedidos tentarem inserir a mesma chave, só uma transação vence; a outra lê o registro persistido e devolve replay/conflito. Hash exige canonicalização: propriedades fora de ordem no JSON não devem mudar resultado, mas alterações reais do pedido devem.

Flyway versiona migrations como mudanças reproduzíveis; `ddl-auto=update` não será usado como substituto de migration porque esconderia a evolução do banco e não prova criação em banco vazio.

## Alternativas

- Idempotência em memória: perde dados no restart e falha em múltiplas instâncias; rejeitada.
- Redis para idempotência: baixa latência, mas outra dependência e dual write sem coordenação com pedido; sem benefício necessário nesta escala.
- Guardar somente chave na tabela Order: mistura lifecycle da ordem com retenção/replay de API; possível para escopo simples, porém registro separado explicita resposta e expurgo.
- JSONB para todo o pedido: flexível, mas enfraquece constraints/consultas relacionais; usar apenas payload de evento/safe details.

## Consequências e limites

- A chave expira após período decidido; chamada repetida depois da expiração pode criar novo pedido. Clientes devem conhecer o prazo.
- Hash e response snapshot precisam de versão/canonicalização definida.
- Não existe isolamento por tenant especificado. `client_scope` deduplica, mas não autoriza automaticamente leitura do pedido.
- Simulação de frete não tem campos suficientes definidos; modelo não deve persistir PII até justificar.
- Volume/índices devem ser medidos; não indexar toda coluna.

## Como testar

PostgreSQL real: migration de zero, constraints de dados, rollback conjunto, mesma chave com conteúdo igual/diferente, requests concorrentes, persistência após restart e limpeza por expiração. Testar cálculo de subtotal/total com decimais e garantir valor total de linha/order coerente.

## Aprovação pendente

Confirmar escopo do client (`client_id` ou identidade de pessoa), retenção de 24h, campo `externalReference`, política de exclusão e requisitos mínimos de dados para frete.
