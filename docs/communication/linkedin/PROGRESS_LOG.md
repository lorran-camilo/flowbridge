# Registro de progresso — comunicação do FlowBridge

Este registro reúne fatos que podem embasar futuras publicações. Não substitui critérios de aceite. Estados, testes e aprendizados precisam de evidência; conceitos só são registrados como compreendidos após confirmação do proprietário.

## 2026-11-01 — Fase 0: planejamento e preparação de portfólio

- **Estado:** documentos e materiais atualizados; decisões aprovadas pelo proprietário. A validação final da Fase 0 depende da revisão humana deste conjunto.
- **Escopo:** requisitos, arquitetura, modelo de dados, contratos REST/eventos, ADRs, roadmap, README, fluxo de Git/CI e material inicial para LinkedIn.
- **Decisões aprovadas:** retenção de idempotência de 24 horas por `client_id`; uma execução inicial e até três retries a 5/30/120 segundos, sem jitter; reprocessamento com motivo e por dependências; dados sintéticos de frete; isolamento integral por `client_id`; hostname/issuer local `keycloak.flowbridge.test`; PostgreSQL compartilhado com credenciais separadas, grants mínimos e usuário migrator único.
- **Estado da aplicação:** nenhuma funcionalidade foi implementada. Não há API, worker, dashboard, migrations, configuração executável de infraestrutura ou testes de aplicação nesta etapa.
- **CI e versionamento:** repositório público `lorran-camilo/flowbridge`; CI inicial configurada com jobs condicionais para módulos ainda ausentes. Jobs de build/teste de aplicação não foram executados para módulos inexistentes. Esta atualização está na branch `docs/phase-0-finalization`; alterações ainda não foram commitadas nem enviadas em PR.
- **Verificações desta atualização:** SVG parseado como XML válido; `viewBox` 1200 × 627; textos essenciais presentes; PNG exportado e inspecionado visualmente na mesma dimensão; links relativos dos Markdown conferidos; `git diff --check` sem erros. Nenhuma dessas verificações é teste da aplicação.
- **Aprendizados do proprietário:** não inferidos. A documentação apresenta conceitos; nenhum deles foi marcado como aprendido/compreendido sem confirmação.
- **Desafios de implementação:** nenhum, pois a aplicação ainda não começou.
- **Decisões compartilháveis:** consistência transacional entre pedido e Outbox; ownership por client; seleção de etapas de reprocessamento via dependências explícitas; mesma identidade de issuer em host e containers.
- **Rascunho:** `posts/01-project-kickoff.md`, contém link do repositório e declara claramente que o desenvolvimento da aplicação ainda não começou. Aguarda revisão e aprovação; não foi publicado.
- **Visual:** `assets/flowbridge-kickoff.svg` e PNG associado são materiais conceituais. Representam arquitetura planejada, com pedido + Outbox na mesma transação e publicação posterior pelo Outbox Publisher; não demonstram sistema executável.

## 2026-11-26 — Fase 1: shell frontend e dependências locais

- **Estado:** entregas 1.4 e 1.5 implementadas nesta branch; aguardam revisão/validação humana conforme o roadmap.
- **Shell Angular (1.4):** `npm ci`, `npm test -- --no-watch --no-progress` e `npm run build` foram executados; o teste estrutural passou. O painel segue sem login, telas de pedidos e chamada à API.
- **Infra local (1.5):** Docker Compose iniciou PostgreSQL 18.7, RabbitMQ 4.4.1 e Keycloak 26.8.2 com health checks saudáveis. `postgres-grants-check` confirmou que migrator cria estruturas de teste e que API/worker não podem criar tabelas. Alias Docker do Keycloak e discovery do realm vazio foram verificados; a discovery publicou o issuer canônico.
- **Limites:** API e worker não foram ligados às dependências nesta entrega. Clientes OIDC, login, tokens e validação de token pela API não foram configurados. A entrada do hostname canônico no `hosts` do Windows continua pendente por exigir permissão administrativa.
- **Aprendizado registrado:** as respostas do proprietário sobre Maven, Spring Boot, npm/Vitest, health checks, migrations, OIDC e Keycloak estão em [LEARNING_LOG.md](../../learning/LEARNING_LOG.md). O papel de `sub` e `aud` segue como exercício de revisão.
- **Rascunho:** [02 — Ambiente local e aprendizados da Fase 1](posts/02-local-environment-and-learning.md), texto e SVG/PNG criados para revisão; não publicado.
- **Verificações documentais:** SVG validado como XML, com `title`, `desc` e `viewBox` 1200 × 627; PNG exportado em 1200 × 627 e inspecionado visualmente; `git diff --check` executado antes do commit. Testes de aplicação não se aplicam às alterações de documentação desta entrada.

## Entradas futuras

Adicionar uma seção por marco usando [PHASE_UPDATE_TEMPLATE.md](PHASE_UPDATE_TEMPLATE.md). Consultar código, testes efetivamente executados e Git; propor post somente quando houver aprendizado ou resultado demonstrável. Todo texto permanece rascunho até aprovação explícita.
