# FlowBridge — requisitos e critérios de qualidade

**Estado:** requisitos base revisados; decisões complementares aprovadas na Fase 0. Implementação ainda não iniciada.
**Fonte de escopo:** guia principal do projeto. Sugestões e lacunas não são requisitos aprovados.

## Como ler este documento

- **Base**: explícito no guia principal.
- **Aprovado na Fase 0**: decisão que complementa a especificação e foi aprovada pelo proprietário.
- **Aberto**: questão não necessária para iniciar o escopo acordado ou que ainda exige decisão.

Este rótulo evita transformar detalhes de implementação em requisito silencioso.

## Objetivo e limites

O FlowBridge demonstra integração e automação de pedidos, tratamento assíncrono de falhas e observabilidade. O escopo inicial é educacional e local. Frete e faturamento são simulados. Pagamentos reais, emissão fiscal, integrações comerciais, dados reais, Kubernetes, muitos microsserviços, Kafka obrigatório, WebSockets obrigatórios, SLA produtivo e cloud pago estão fora do escopo.

## Requisitos funcionais

| ID | Requisito | Origem/estado | Evidência de aceite |
|---|---|---|---|
| FR-01 | Uma pessoa autentica-se no painel por Keycloak com OIDC. | Base | Login e logout reproduzíveis no ambiente local; token não exposto em logs. |
| FR-02 | Um cliente máquina a máquina obtém access token por Client Credentials e chama API. | Base | Chamada autorizada por client e permissões explicitamente configuradas. |
| FR-03 | API recebe pedido, valida campos e devolve erros consistentes. | Base | Pedido inválido não é persistido; respostas documentadas em OpenAPI. |
| FR-04 | API evita duplicidade quando uma chamada é repetida com a mesma chave e payload. | Base | Testes de primeira chamada, repetição equivalente e concorrência. |
| FR-05 | Reutilizar chave com payload materialmente diferente retorna conflito. | Base | `409 Conflict` documentado e testado. |
| FR-06 | Pedido e itens são persistidos no PostgreSQL com migrations reproduzíveis. | Base | Banco vazio criado pelas migrations; testes de integração. |
| FR-07 | API grava pedido, itens, registro de idempotência e evento de submissão na mesma transação PostgreSQL. | Base (Outbox na arquitetura) | Teste prova rollback conjunto; evento pendente recuperável após commit. |
| FR-08 | Outbox Publisher independente consulta eventos pendentes após commit e os envia ao RabbitMQ; API não chama publisher nem publica diretamente. | Base | Teste com broker real valida leitura/claim da Outbox, exchange, binding, persistência e confirmação. |
| FR-09 | Worker independente consome evento, executa frete e faturamento simulados e atualiza estado. | Base | API e worker iniciáveis separadamente; rastreio por pedido/correlation ID. |
| FR-10 | Sistema preserva estado, tentativas, execuções e timeline. | Base | Consulta apresenta passos e falhas sem apagar histórico. |
| FR-11 | Falha transitória é tentada novamente de forma limitada; falha permanente termina em DLQ/estado FAILED. | Base; política numérica aprovada na Fase 0 | Testes de transiente, permanente, limite e entrega à DLQ. |
| FR-12 | Usuário autorizado consulta pedidos e solicita reprocessamento auditável. | Base | Sem permissão recebe 403; ação grava auditoria e reprocessa sem excluir tentativas antigas. |
| FR-13 | API lista pedidos com paginação/filtros e oferece detalhe, timeline, integrações e resumo do dashboard. | Base | Contratos descritos em `api-contracts.md`. |
| FR-14 | Cliente que clona o repositório segue README e inicia fluxo demonstrável localmente. | Base (critério de sucesso final) | Clone limpo, ambiente e roteiro de demonstração reproduzíveis. |
| FR-15 | Cliente máquina só pode criar, repetir, listar e consultar pedidos pertencentes ao próprio `client_id`. | Decisão aprovada na Fase 0 | Testes autorizados e negados incluindo consulta individual por UUID conhecido. |
| FR-16 | Usuário autorizado solicita reprocessamento com motivo obrigatório; o sistema refaz a etapa falha e descendentes inválidos, preservando resultados válidos e histórico. | Base + decisão aprovada na Fase 0 | Teste de dependências, auditoria, geração nova e efeitos idempotentes. |
| FR-17 | Cliente máquina só acessa pedidos e subrecursos do próprio `client_id`; UUID inexistente e fora do escopo retornam resposta indistinguível `404`. | Decisão aprovada na Fase 0 | Testes com UUID de outro client e UUID inexistente confirmam mesmo status e corpo público. |

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
| NFR-12a | Retenção da chave de idempotência por 24 horas, delimitada por `client_id`; expiração não remove pedido ou histórico. | Decisão aprovada na Fase 0 | Testes de expiração/reutilização atômica; não classificar como decisão aberta. |
| NFR-12b | Retenção/expurgo de Outbox publicada, tentativas, timeline e DLQ. | Aberto para política operacional; distinto da retenção de idempotência | Definir e testar antes de uso produtivo; no escopo local, documentar limites e evitar expurgo silencioso. |
| NFR-13 | API e worker acessam PostgreSQL compartilhado por credenciais distintas e grants mínimos; migrations têm único usuário responsável. | Decisão aprovada na Fase 0 | Testes com credenciais reais de aplicação validam permissões permitidas e negadas. |

## Papéis e capacidades aprovadas como baseline

O guia define os papéis de usuário e clientes máquina. Não misturar os dois tipos de principal:

| Principal | Permissões aprovadas como baseline |
|---|---|
| Pessoa `ADMIN` | leitura operacional e ações de administração/reprocessamento. |
| Pessoa `OPERATOR` | leitura e solicitação auditável de reprocessamento. |
| Pessoa `VIEWER` | leitura somente. |
| Cliente máquina | scopes `orders:write`, `orders:read`; sem role administrativa de pessoa. Todo acesso é filtrado por `client_id`, inclusive `GET /orders/{id}` e subrecursos. |

O mapeamento entre client scopes/roles do Keycloak e authorities Spring deve ser explícito e testado; claim `client_id` é a fronteira de isolamento dos pedidos de integração.

## Decisões resolvidas e questões remanescentes

| Tema | O que falta / tensão | Recomendação para revisão |
|---|---|---|
| Idempotência | Retenção de 24 horas por `client_id`; após expiração a chave pode ser reutilizada, sem apagar pedido/histórico. | Aprovado; decisão fechada. Implementar expiração atômica/reutilização e documentar prazo para clientes. |
| Retry | Uma execução inicial + até três retries a 5/30/120 segundos, sem jitter inicial. | Aprovado; validar filas TTL/DLX e janelas de falha na Fase 6. |
| Reprocessamento | Exige motivo, nova geração/evento; refaz etapa falha e descendentes inválidos conforme grafo acíclico versionado, preservando resultados válidos. | Aprovado; estado, versão/regra, hash de entradas e invalidação de dependências serão cobertos em testes. |
| Frete | Zonas sintéticas de origem/destino e peso total em gramas; sem endereço real. | Aprovado; o valor será apenas resultado determinístico do simulador. |
| Isolamento | Pedidos de integração são escopados por `client_id` em todas as operações, incluindo busca por UUID. | Aprovado; teste negativo de acesso entre clientes é critério de aceite. |
| Keycloak local | `keycloak.flowbridge.test`, issuer `http://keycloak.flowbridge.test:8080/realms/flowbridge`, resolução no host e rede Docker. | Aprovado; validar discovery/JWKS para navegador e API. Worker não valida tokens OIDC no baseline. |
| PostgreSQL compartilhado | Credenciais runtime distintas; grants mínimos; usuário dedicado de migration. | Aprovado; mapear SQL grants e provar acessos permitidos/negados na Fase 1. |
| `externalReference` | Continua opcional, sem unicidade global ou por cliente aprovada. | Qualquer regra adicional requer decisão explícita. |
| Retenção operacional | Retenção de Outbox publicada, tentativas, timeline e DLQ; janela exata de expurgo ainda indefinida. | Necessária antes de produção; distinta da retenção idempotente aprovada de 24h. Não bloqueia o escopo local enquanto limites forem documentados. |
| Integrações e disponibilidade | Integrações são simuladas; não há SLA, alta disponibilidade, backup produtivo ou metas numéricas de carga. | Permanecem fora do escopo inicial; não inventar garantias. |

## Fora de escopo e controle de sugestões

Ficam fora do escopo inicial: plataforma completa de multi-tenancy/provisionamento, endereço de entrega persistido, autenticação BFF, CDC/Debezium, scheduler externo, tracing distribuído, SLA produtivo, integrações comerciais reais, pagamentos e emissão fiscal. A retenção de 24 horas aplica-se somente à chave de idempotência; políticas de expurgo de Outbox, tentativas, timeline e DLQ são decisões operacionais separadas, ainda pendentes para uso produtivo.
