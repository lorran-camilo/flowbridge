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

## Entradas futuras

Adicionar uma seção por marco usando [PHASE_UPDATE_TEMPLATE.md](PHASE_UPDATE_TEMPLATE.md). Consultar código, testes efetivamente executados e Git; propor post somente quando houver aprendizado ou resultado demonstrável. Todo texto permanece rascunho até aprovação explícita.
