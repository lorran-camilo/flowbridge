# FlowBridge — Order Integration & Automation Platform

Plataforma demonstrativa de integração e automação de pedidos. A API recebe pedidos e os persiste; um worker independente executa processamento assíncrono e simula integrações de frete e faturamento. O painel permitirá acompanhar o estado, investigar falhas e solicitar reprocessamento autorizado.

> **Estado:** planejamento da Fase 0. A aplicação ainda não foi implementada e este README ainda não contém um quick start executável.

## Objetivos de aprendizado

Praticar Java/Spring Boot, Angular, OAuth 2.0/OpenID Connect, PostgreSQL, RabbitMQ, TDD, idempotência, Outbox, retry/DLQ e observabilidade em um sistema de escopo educacional.

## Escopo da primeira versão

- Pedidos por API REST, validação e idempotência.
- Persistência relacional e histórico do processamento.
- Comunicação assíncrona com worker via RabbitMQ.
- Integrações de frete/faturamento simuladas.
- Login humano e cliente máquina a máquina via Keycloak.
- Painel Angular para consulta operacional.

Pagamentos, emissão fiscal, integrações comerciais reais, dados pessoais reais, Kubernetes, vários microsserviços, Kafka obrigatório e SLA produtivo estão fora do escopo inicial. Consulte a especificação antes de assumir funcionalidade.

## Arquitetura e decisões

- [Visão geral e fluxo](docs/architecture/overview.md)
- [Requisitos e ambiguidades](docs/architecture/requirements.md)
- [Modelo de domínio](docs/architecture/domain-model.md)
- [Modelo de dados](docs/architecture/data-model.md)
- [Contratos REST](docs/architecture/api-contracts.md)
- [Contratos de eventos](docs/architecture/event-contracts.md)
- [Plano de desenvolvimento](docs/architecture/development-roadmap.md)
- [Decisões técnicas e versões](docs/decisions/technology-stack.md)
- [ADRs](docs/decisions/)
- [Especificação funcional e técnica principal](FLOWBRIDGE_GUIA_DE_DESENVOLVIMENTO_CLAUDE_CODE_REENVIO.md)

As decisões e contratos desta Fase 0 são propostas até a revisão do proprietário. A especificação principal define o escopo funcional/técnico. O `AGENTS.md` define como o Codex deve trabalhar.

## Stack proposta

JDK 25 LTS, Spring Boot 4.1.x, Maven Wrapper 3.10.x, PostgreSQL 18.x, RabbitMQ 4.4.x, Keycloak 26.8.x, Angular 22.x, Node.js 24 LTS e TypeScript 6.0.x. Confira [technology-stack.md](docs/decisions/technology-stack.md) para alternativas, riscos, fontes oficiais e status de aprovação.

## Execução e testes

Ainda não existem comandos de execução ou testes para este projeto. Eles serão documentados quando a Fase 1 criar o ambiente e forem validados em fases posteriores. Não use esta seção como instrução operacional.

## Limites conhecidos

- Ambiente e aplicação ainda não criados.
- Alguns campos do pedido, ownership de consultas, política de retry/retention e hostname local do issuer aguardam decisão.
- Garantia pretendida é entrega pelo menos uma vez com efeitos idempotentes; não se promete exactly-once.
- Nenhuma integração comercial é real.
