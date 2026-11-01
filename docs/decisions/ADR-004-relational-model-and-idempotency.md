# ADR-004 — PostgreSQL, modelo de pedido e idempotência persistente

- **Status:** Accepted
- **Data:** 2026-11-01

## Contexto

Pedidos, histórico e trabalho pendente precisam sobreviver a restart. Um `if` em memória não impede duas requisições simultâneas de usar a mesma chave. O modelo também deve preservar falhas/reprocessamentos sem sobrescrever evidência.

## Decisão

- PostgreSQL relacional como fonte de verdade; Flyway controla schema incremental.
- Separar pedido, itens, idempotency record, Outbox, tentativa de processamento, execução de integração, inbox de eventos e auditoria/timeline.
- Dinheiro como decimal exato; validação positiva e transições como regras de domínio e constraints relevantes.
- `Idempotency-Key` delimitada por `client_id`, constraint única `(client_id, idempotency_key)`, hash de payload canônico e vínculo ao pedido/resposta original.
- Repetição equivalente recupera resposta anterior; mesma chave com payload materialmente diferente retorna `409`.
- Transação única para pedido, itens, idempotency record e Outbox.
- Sem endpoint DELETE no primeiro contrato, para não apagar histórico e vínculos.
- Retenção de chaves: 24 horas desde a primeira criação confirmada. Depois da expiração, a chave pode ser reutilizada e uma nova solicitação pode criar novo pedido. Expirar a chave não apaga pedido nem histórico.
- Pedido contém zona de origem, zona de destino e peso total em gramas para o cálculo determinístico de frete simulado; endereços e dados pessoais reais não fazem parte do modelo.
- API é dona de pedido, itens, chave de idempotência e Outbox; worker é dono dos registros de execução/inbox/tentativas. Migrations usam usuário dedicado; API e worker têm usuários distintos e grants runtime mínimos (detalhados no ADR-001).

## Por que e como funciona

Relacional/SQL permite constraints, índices e transações explícitas sobre dados ligados. A unique constraint é a árbitra final em concorrência: se dois pedidos tentarem inserir a mesma chave, só uma transação vence; a outra lê o registro persistido e devolve replay/conflito. Hash exige canonicalização: propriedades fora de ordem no JSON não devem mudar resultado, mas alterações reais do pedido devem.

Flyway versiona migrations como mudanças reproduzíveis; `ddl-auto=update` não será usado como substituto de migration porque esconderia a evolução do banco e não prova criação em banco vazio.

## Alternativas

- Idempotência em memória: perde dados no restart e falha em múltiplas instâncias; rejeitada.
- Redis para idempotência: baixa latência, mas outra dependência e dual write sem coordenação com pedido; sem benefício necessário nesta escala.
- Guardar somente chave na tabela Order: mistura lifecycle da ordem com retenção/replay de API; possível para escopo simples, porém registro separado explicita resposta e expurgo.
- JSONB para todo o pedido: flexível, mas enfraquece constraints/consultas relacionais; usar apenas payload de evento/safe details.

## Consequências e limites

- A chave expira após 24 horas; chamada repetida depois da expiração pode criar novo pedido. Clientes devem conhecer o prazo.
- Hash e response snapshot precisam de versão/canonicalização definida.
- `client_id` é a fronteira de isolamento aprovada. Leituras individuais e coleções filtram por esse valor; chave de idempotência sozinha não é autorização.
- Peso e zonas são entradas sintéticas do simulador, não dados confiáveis de cotação comercial. Endereço/PII ficam fora do escopo.
- Volume/índices devem ser medidos; não indexar toda coluna.

## Como testar

PostgreSQL real: migration de zero, constraints de dados, rollback conjunto, mesma chave com conteúdo igual/diferente, requests concorrentes, persistência após restart e limpeza por expiração. Testar cálculo de subtotal/total com decimais e garantir valor total de linha/order coerente.

## Aprovação

Foram aprovados retenção idempotente de 24 horas por `client_id`, campos sintéticos de frete (zonas de origem/destino e peso total em gramas) e isolamento de pedidos por `client_id`. `externalReference` permanece opcional e sem unicidade global nesta versão; qualquer unicidade adicional exige decisão explícita. Não há exclusão de pedidos no contrato inicial.
