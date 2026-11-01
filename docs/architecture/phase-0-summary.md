# FlowBridge — resumo da Fase 0

**Estado:** planejamento documental consolidado; aceite final da Fase 0 aguarda revisão do proprietário. Nenhuma implementação da aplicação foi iniciada.

## O que foi planejado

Uma plataforma demonstrativa de integração e automação de pedidos: Angular para o painel, API Spring Boot como monólito modular, PostgreSQL como fonte de verdade, Outbox Publisher para RabbitMQ e worker separado para processamento assíncrono de frete/faturamento simulados. Keycloak autentica pessoas e clients máquina. O projeto é local e educacional; integrações reais, pagamentos, emissão fiscal e dados pessoais reais ficam fora do escopo.

## Decisões arquiteturais aprovadas

- **Idempotência:** chave por `client_id`, retida por 24 horas; repetição dentro da janela devolve a resposta original; payload diferente conflita; expiração não apaga pedido/histórico.
- **Retry:** uma execução inicial e até três retries em 5, 30 e 120 segundos; jitter fora do escopo inicial; erros permanentes/exaustão são terminais e vão para DLQ.
- **Reprocessamento:** exige motivo, autorização humana, nova geração e evento. Grafo acíclico/versionado tem nós `FREIGHT` e `BILLING`; arestas serão declaradas e testadas antes de implementar o workflow, pois a especificação não define dependência entre elas. Refaz etapa falha e descendentes; preserva etapa bem-sucedida só se estado, versão/regra, hash das entradas e pré-requisitos ainda forem válidos, registrando `REUSED` com referência à etapa de origem.
- **Dados de frete:** zona de origem, zona de destino e peso total em gramas; sem endereços. Cotação é simulada e determinística.
- **Isolamento:** todo pedido máquina pertence a um `client_id`; todas as operações, inclusive busca individual por UUID e subrecursos, filtram por esse escopo. Client não pode reprocessar.
- **Keycloak:** hostname/issuer local canônico `http://keycloak.flowbridge.test:8080/realms/flowbridge`, resolvido no host para `127.0.0.1` e como alias na rede Docker. Navegador e API precisam observar o mesmo issuer; o worker não valida tokens OIDC.
- **PostgreSQL:** base compartilhada, credenciais de API e worker distintas e grants mínimos por responsabilidade; usuário de migrations único e separado, sem DDL/superuser nos processos runtime.
- **Consistência:** API grava pedido, itens, idempotência e evento Outbox numa transação PostgreSQL. Após commit, o Outbox Publisher independente consulta a tabela Outbox, publica no broker e atualiza o estado após confirmação; a API não chama o publisher. Entrega continua pelo menos uma vez, com duplicatas tratadas por idempotência.

## Tecnologias selecionadas

Java 21 LTS; Spring Boot 4.1.2; Angular 22; Node.js 24 LTS; TypeScript 6.0.x; PostgreSQL 18.x; RabbitMQ 4.4.x; Keycloak 26.8.x; Maven Wrapper compartilhado na raiz, com POM escolhido explicitamente por `-f`. O ADR-005 contém matriz e referências. Fixação de patches e prova de compatibilidade executável ficam para Fase 1.

## Documentos consolidados

- Especificação principal preservada como fonte funcional/técnica.
- Arquitetura: overview, requirements, domain model, data model, API contracts, event contracts, roadmap e este resumo.
- Decisões: ADR-001 (arquitetura/acesso DB), ADR-002 (identidade/isolamento), ADR-003 (Outbox/retry/DLQ/reprocessamento), ADR-004 (modelo/idempotência/frete) e ADR-005 (stack).
- README principal com estado real, escopo e tecnologias.
- Documentação de comunicação LinkedIn, plano editorial, template, diretrizes visuais, post kickoff e arte SVG/PNG.
- Registro de progresso e registro de aprendizado, sem presumir conceitos aprendidos pelo proprietário.
- AGENTS.md e workflow CI preservam convenções de trabalho, branches, revisões, actions pinadas por SHA e permissões mínimas.

## Versionamento e CI

Repositório público: [github.com/lorran-camilo/flowbridge](https://github.com/lorran-camilo/flowbridge). O fluxo inclui `main`, branches de tarefa, Conventional Commits e revisão via Pull Request. O workflow existente está estruturalmente preparado e executa jobs condicionados à presença de módulos/manifests. A alteração documental está na branch `docs/phase-0-finalization`; ainda não foi commitada, enviada ou submetida a PR.

## Ainda não implementado

- API, worker, módulos Java, Angular, componentes de UI e regras de domínio executáveis.
- Migrations, entidades/repositories, usuários/grants PostgreSQL e configuração de credenciais.
- Realm/client/scopes Keycloak, DNS local, Docker Compose, RabbitMQ exchanges/queues, Outbox Publisher e adaptadores.
- Testes unitários, integração e E2E da aplicação. Nenhum resultado de teste de aplicação pode ser declarado nesta fase.
- Deploy, publicação no LinkedIn e qualquer integração comercial real.

## Validações documentais realizadas

- `git diff --check`: sem erros de whitespace no diff (avisos de conversão de LF para CRLF do Git no Windows não alteram o conteúdo).
- Links Markdown relativos: todos os destinos locais foram encontrados.
- SVG: XML válido, `viewBox` 1200 × 627 e todos os rótulos essenciais presentes.
- PNG: exportado a partir do SVG com Chrome headless, 1200 × 627, assinatura PNG válida e conferido visualmente para legibilidade/composição.
- Testes/build da aplicação: não executados; os módulos não existem.

## Critérios para considerar a Fase 0 concluída

1. O proprietário revisa a documentação, o SVG/PNG, o post e as decisões aceitas.
2. Os contratos e ADRs permanecem consistentes entre pedido/Outbox, `client_id`, hostname/issuer, grants do banco e reprocessamento por dependências.
3. O roadmap conserva portões humanos e não autoriza implementação automaticamente.
4. O README e o post distinguem planejamento de implementação e não alegam testes de aplicação.
5. A arte vetorial passa validação XML e o PNG, se gerado, é conferido visualmente para dimensão/legibilidade.

A Fase 1 só pode começar após o proprietário aceitar esses critérios explicitamente.
