# FlowBridge — Order Integration & Automation Platform

FlowBridge é um projeto pessoal de aprendizado e portfólio para explorar integração e automação de pedidos. O sistema **pretende** receber pedidos por uma API REST, persistir pedido e evento Outbox na mesma transação e processar o trabalho assincronamente por RabbitMQ e um worker. As etapas planejadas simulam frete e faturamento; não são integrações comerciais reais.

> **Estado atual: planejamento da Fase 0 concluído em documentação; implementação da aplicação ainda não iniciada.** Existem especificação, documentação arquitetural, ADRs aceitos e uma estrutura inicial de CI. Ainda não existem API, worker, dashboard ou infraestrutura local executável. Os jobs de build/teste de aplicação só poderão rodar quando os módulos e manifests forem criados em fases futuras.

## Objetivo e escopo planejado

O projeto pretende demonstrar pedidos, API REST, processamento assíncrono, recuperação de falhas e observabilidade em um ambiente educacional local. O escopo inclui autenticação humana OIDC e clientes máquina a máquina, isolamento de pedidos por `client_id`, processamento com histórico, idempotência, Outbox, retry/DLQ e um dashboard operacional.

Frete e faturamento serão simulados com dados sintéticos. Pagamentos reais, emissão fiscal, integrações comerciais, endereços/dados pessoais reais, Kubernetes, vários microsserviços, Kafka obrigatório, SLA produtivo e cloud pago estão fora do escopo inicial.

## Arquitetura planejada

- Angular como SPA de operações.
- API Spring Boot organizada como monólito modular.
- PostgreSQL como fonte de verdade. A API e o worker compartilharão a base com credenciais e grants mínimos distintos; um usuário de migração será o único responsável pelo schema.
- A API grava pedido, itens, chave de idempotência e evento Outbox na mesma transação. Após o commit, um Outbox Publisher independente consulta a tabela Outbox, publica no RabbitMQ e registra a confirmação; a API não chama o publisher diretamente.
- Worker Spring Boot separado consumirá eventos, processará as etapas `FREIGHT` e `BILLING` conforme um grafo explícito a definir antes da implementação, e registrará tentativas/resultados.
- Keycloak emitirá tokens OAuth 2.0/OIDC para pessoas e clients. O hostname local canônico planejado é `keycloak.flowbridge.test`; navegador e API usarão o mesmo issuer. O worker não valida tokens OIDC: consome mensagens pela conexão RabbitMQ autenticada e aplica controles de mensagem, deduplicação e permissões próprias no PostgreSQL.

Pedidos de clientes máquina serão isolados por `client_id` em todas as operações, inclusive consultas por UUID. A chave de idempotência vale por 24 horas por cliente. Falhas transitórias terão uma execução inicial e até três retries com atrasos de 5, 30 e 120 segundos, sem jitter no escopo inicial. Reprocessamento humano exige motivo e refaz a etapa falha e descendentes invalidados, preservando resultados anteriores ainda válidos. A relação de dependência entre as etapas `FREIGHT` e `BILLING` será explicitamente definida antes da implementação do workflow; não é inferida pela ordem de apresentação.

## Tecnologias selecionadas

- Java 21 LTS e Spring Boot 4.1.2 para API e worker.
- Angular 22, Node.js 24 LTS e TypeScript 6.0.x para frontend.
- PostgreSQL 18.x, RabbitMQ 4.4.x e Keycloak 26.8.x.
- Maven Wrapper compartilhado na raiz, usando `-f` para selecionar explicitamente os POMs de backend e worker quando esses módulos existirem.

Versões e justificativas estão em [ADR-005 — stack](docs/decisions/technology-stack.md). Imagens, patches e dependências concretas ainda não foram instalados ou validados em ambiente de aplicação.

## Fase 0 e documentação

A Fase 0 organizou requisitos, arquitetura, modelo relacional, contratos REST/eventos, dependências do processamento, decisões técnicas e roadmap. As recomendações pendentes foram analisadas e as sete decisões foram aprovadas pelo proprietário. O [resumo da Fase 0](docs/architecture/phase-0-summary.md) registra decisões, limites e itens ainda não implementados.

- [Visão geral da arquitetura](docs/architecture/overview.md)
- [Requisitos e critérios de qualidade](docs/architecture/requirements.md)
- [Modelo de domínio](docs/architecture/domain-model.md)
- [Modelo de dados](docs/architecture/data-model.md)
- [Contratos REST](docs/architecture/api-contracts.md)
- [Contratos RabbitMQ](docs/architecture/event-contracts.md)
- [Roadmap incremental](docs/architecture/development-roadmap.md)
- [ADRs](docs/decisions/)
- [Especificação funcional e técnica principal](FLOWBRIDGE_GUIA_DE_DESENVOLVIMENTO_CLAUDE_CODE_REENVIO.md)

## Versionamento e CI

O projeto está em um repositório público no GitHub: [lorran-camilo/flowbridge](https://github.com/lorran-camilo/flowbridge). As regras de trabalho definem branch `main` estável, branches de tarefa, Conventional Commits e revisão por Pull Request. A branch principal e os merges dependem de revisão/aprovação humana conforme a configuração do repositório.

O workflow inicial de GitHub Actions está preparado para mudanças em Pull Requests e na branch principal, com ações pinadas por SHA, permissões mínimas e jobs condicionados à existência dos módulos/manifests. Enquanto a aplicação não existir, **nenhum build ou teste de aplicação é declarado como executado ou aprovado**. A estrutura preparada não equivale a integração contínua de código de aplicação validada.

## Execução e testes

Não há comandos de execução ou testes da aplicação neste estado. Não foram implementados módulos Java, componentes Angular, migrations, serviços de infraestrutura ou integrações. As verificações da documentação e do diagrama serão informadas no resumo da Fase 0; não devem ser confundidas com testes de software.

## Aprendizado e uso de IA

O projeto será conduzido pelo proprietário, que é responsável por estudar, revisar, testar, validar e compreender as soluções. Agentes de IA serão usados como apoio didático e técnico para aprender conceitos, comparar alternativas, analisar problemas e revisar implementações. O [registro de aprendizado](docs/learning/LEARNING_LOG.md) distingue conceitos apresentados de conhecimento confirmado pelo proprietário.

## Comunicação

Materiais e rascunhos para divulgação estão em [docs/communication/linkedin](docs/communication/linkedin/README.md). O post de kickoff e sua imagem são conceitos de lançamento: não representam funcionalidades implementadas nem foram publicados.
