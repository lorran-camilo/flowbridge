# FlowBridge — requisitos e critérios de qualidade

**Estado:** proposta da Fase 0, aguardando revisão.  
**Fonte de escopo:** guia principal do projeto. Sugestões e lacunas não são requisitos aprovados.

## Como ler este documento

- **Base**: explícito no guia principal.
- **Proposta**: decisão operacional recomendada nesta Fase 0, ainda sujeita à revisão.
- **Aberto**: a especificação não oferece informação suficiente para fixar o comportamento.

Este rótulo evita transformar detalhes de implementação em requisito silencioso.

## Objetivo e limites

O FlowBridge demonstra integração e automação de pedidos, tratamento assíncrono de falhas e observabilidade. O escopo inicial é educacional e local. Frete e faturamento são simulados. Pagamentos reais, emissão fiscal, integrações comerciais, dados reais, Kubernetes, muitos microsserviços, Kafka obrigatório, WebSockets obrigatórios, SLA produtivo e cloud pago estão fora do escopo.

## Requisitos funcionais

| ID | Requisito | Base / proposta | Evidência de aceite |
|---|---|---|---|
| FR-01 | Uma pessoa autentica-se no painel por Keycloak com OIDC. | Base | Login e logout reproduzíveis no ambiente local; token não exposto em logs. |
| FR-02 | Um cliente máquina a máquina obtém access token por Client Credentials e chama API. | Base | Chamada autorizada por client e permissões explicitamente configuradas. |
| FR-03 | API recebe pedido, valida campos e devolve erros consistentes. | Base | Pedido inválido não é persistido; respostas documentadas em OpenAPI. |
| FR-04 | API evita duplicidade quando uma chamada é repetida com a mesma chave e payload. | Base | Testes de primeira chamada, repetição equivalente e concorrência. |
| FR-05 | Reutilizar chave com payload materialmente diferente retorna conflito. | Base | `409 Conflict` documentado e testado. |
| FR-06 | Pedido e itens são persistidos no PostgreSQL com migrations reproduzíveis. | Base | Banco vazio criado pelas migrations; testes de integração. |
| FR-07 | Evento de submissão é registrado na mesma transação do pedido. | Base (Outbox na arquitetura) | Teste prova rollback conjunto; evento pendente recuperável. |
| FR-08 | Publicador envia eventos pendentes ao RabbitMQ. | Base | Teste com broker real valida exchange, binding, persistência e confirmação. |
| FR-09 | Worker independente consome evento, executa frete e faturamento simulados e atualiza estado. | Base | API e worker iniciáveis separadamente; rastreio por pedido/correlation ID. |
| FR-10 | Sistema preserva estado, tentativas, execuções e timeline. | Base | Consulta apresenta passos e falhas sem apagar histórico. |
| FR-11 | Falha transitória é tentada novamente de forma limitada; falha permanente termina em DLQ/estado FAILED. | Base; política numérica proposta | Testes de transiente, permanente, limite e entrega à DLQ. |
| FR-12 | Usuário autorizado consulta pedidos e solicita reprocessamento auditável. | Base | Sem permissão recebe 403; ação grava auditoria e reprocessa sem excluir tentativas antigas. |
| FR-13 | API lista pedidos com paginação/filtros e oferece detalhe, timeline, integrações e resumo do dashboard. | Base | Contratos descritos em `api-contracts.md`. |
| FR-14 | Cliente que clona o repositório segue README e inicia fluxo demonstrável localmente. | Base (critério de sucesso final) | Clone limpo, ambiente e roteiro de demonstração reproduzíveis. |

## Requisitos não funcionais

| ID | Requisito | Base / proposta | Como verificar |
|---|---|---|---|
| NFR-01 | Projeto é educacional, incremental, orientado por TDD e explicado ao proprietário. | Base | Ciclos RED/GREEN/REFACTOR demonstrados para regras importantes; revisão humana por fase. |
| NFR-02 | Segurança no backend, validação de token e autorização por endpoint. | Base | Testes 401/403/permitido; claims `iss`, assinatura, `exp`/`nbf` e audience da API explicitamente validada. |
| NFR-03 | Nenhum segredo real ou dado pessoal real entra no repositório, logs ou screenshots. | Base | Revisão de configuração, logs e artefatos; dados sintéticos. |
| NFR-04 | Versões e imagens fixadas; sem Docker `latest`. | Base | Inventário de versões no ADR de stack; verificação de imagens e lockfiles. |
| NFR-05 | Build reproduzível via Maven Wrapper e versões de Node/Angular compatíveis. | Base | Build a partir de clone limpo com versões documentadas. |
| NFR-06 | Integrações de banco e mensageria são demonstradas com serviços reais em testes apropriados. | Base | Testcontainers para PostgreSQL/RabbitMQ; mocks apenas para isolamento. |
| NFR-07 | Mensagens e efeitos de negócio toleram redelivery; não alegar exactly-once. | Base | Testes de duplicata e documentação das garantias reais. |
| NFR-08 | Erros não vazam stack trace e logs não expõem tokens/segredos. | Base | Testes/inspeção de resposta HTTP e logs de cenários de falha. |
| NFR-09 | Operações podem ser rastreadas por order ID e correlation ID. | Base | Correlation ID presente nos logs e timeline de ponta a ponta. |
| NFR-10 | Acessibilidade básica e estados claros de carregamento, erro, vazio e sucesso na UI. | Base | Testes da UI e revisão manual de teclado, labels e contraste. |
| NFR-11 | Desempenho e disponibilidade. | Aberto | Guia não define metas numéricas, carga-alvo, SLA ou ambiente produtivo; não inventar SLO. |
| NFR-12 | Retenção/expurgo de idempotência, outbox, timeline e DLQ. | Aberto | Definir política antes de produção; baseline educacional requer decisão sobre retenção. |

## Papéis e capacidades propostas

O guia sugere `ADMIN`, `OPERATOR`, `VIEWER` e `INTEGRATION_CLIENT`. A proposta é não usar um único conceito para dois tipos de principal:

| Principal | Permissões propostas |
|---|---|
| Pessoa `ADMIN` | leitura operacional e ações de administração/reprocessamento. |
| Pessoa `OPERATOR` | leitura e solicitação auditável de reprocessamento. |
| Pessoa `VIEWER` | leitura somente. |
| Cliente máquina | scopes `orders:write`, `orders:read`; sem role administrativa de pessoa. |

Os nomes finais dos scopes e o mapeamento entre realm/client roles do Keycloak e authorities Spring são propostas. Aprovar antes de espalhá-los por endpoints.

## Ambiguidades e inconsistências a resolver

| Tema | O que falta / tensão | Recomendação para revisão |
|---|---|---|
| Campos do pedido | A lista de campos não indica endereço, destino, peso ou outros dados necessários ao cálculo de frete. | Especificar um conjunto sintético mínimo para o adaptador, ou confirmar que frete é calculado apenas com SKU/quantidade. Não inferir PII. |
| `externalReference` | Não está definido se é opcional, único por tenant/client ou apenas informativo. | Tornar opcional na primeira versão e perguntar se deve ser único por cliente. |
| Criação síncrona/assíncrona | Pedido é persistido na requisição, mas processamento termina depois. O código HTTP inicial não foi fixado. | Recomendar `201 Created` porque Order já existe e possui `Location`; estado `RECEIVED` informa que processamento segue assíncrono. |
| GET listagem de pedidos | O guia não declara permissão por cliente para quais pedidos de integração pode ler. | Definir escopo/ownership e filtro por cliente antes de habilitar leitura ampla. |
| Reprocessamento | Falta definir motivo obrigatório, reprocessar pedido todo ou etapa específica e idempotência da solicitação. | Propor reprocessar fluxo inteiro com nova geração, motivo obrigatório e auditoria; confirmar. |
| Número/tempo de retry | “Limitado” não define contagem, backoff ou jitter. | Propor 3 redeliveries (4 tentativas totais) com atraso 5s, 30s, 2m, configurável. Confirmar números. |
| Retry e histórico | Tentativa pode significar entrega, fluxo completo ou execução individual de frete/faturamento. | Separar `ProcessingAttempt` do `IntegrationExecution` e manter contador de entrega no cabeçalho. |
| RabbitMQ redelivery e DLQ | DLQ do broker e estado `FAILED` no banco podem ficar divergentes em falhas entre gravação e ACK. | Gravar falha/estado antes de rejeitar; manter reconciliação/observação e idempotência; testar janelas de queda. |
| Banco compartilhado | API e worker escrevem no mesmo banco, mas não se definem dono de esquema nem privilégios. | Manter um PostgreSQL conforme o escopo, documentar dono de tabela e migrador único. |
| Autenticação local | Hostname canônico do issuer ainda não foi escolhido. Containers e navegador resolvem nomes diferentes. | Decidir URL local única e testar discovery/JWKS tanto no navegador quanto da API. |
| Frontend OIDC | Armazenamento e recuperação de sessão em SPA têm trade-offs; evitar localStorage está especificado, mas estratégia exata não. | Preferir memória para tokens; documentar necessidade de login novamente ao recarregar, salvo solução segura aprovada. |
| `422` vs `400` | O guia lista ambos sem regra. | Recomendar `400` para JSON/campos inválidos e `409` para chave idempotente conflitante; manter `422` fora do contrato inicial. |
| Stack do documento | Java 21, Spring Boot 3.5, Angular 21 e PostgreSQL 17 são baseline datada, não decisão obrigatória. | Atualizar recomendações por fontes oficiais no [ADR-005](../decisions/technology-stack.md); obter aprovação dos riscos de versões major atuais. |
| Observabilidade | Logs/correlation IDs são exigidos; tracing completo é opcional e métricas não têm objetivos. | Começar com logs estruturados e métricas básicas; sem SLA ou tracing distribuído obrigatório. |
| Requisitos de disponibilidade | Não há definição de produção, alta disponibilidade ou backup. | Manter fora do primeiro escopo; declarar limitações no README. |

## Fora de escopo e controle de sugestões

Não são requisitos aprovados: multi-tenant completo, endereço de entrega persistido, autenticação BFF, CDC/Debezium, scheduler externo, tracing distribuído, SLA, retenção específica, auditoria com motivo obrigatório, retry numérico específico. Algumas aparecem como propostas técnicas porque decisões precisam ser tomadas; ficam pendentes de aprovação quando indicado.
