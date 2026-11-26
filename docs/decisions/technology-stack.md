# ADR-005 — versões aprovadas do stack FlowBridge

- **Status:** Accepted
- **Data:** 2026-11-01
- **Decisora:** proprietária do FlowBridge

## Contexto

A versão inicial do guia contém um baseline que precisava ser revisto antes do desenvolvimento. A Fase 0 comparou compatibilidade, suporte e risco de adoção. A proprietária aprovou Java 21 LTS, Spring Boot 4.1.x, Angular 22, Node.js 24 LTS, PostgreSQL 18, RabbitMQ 4.4 e Keycloak 26.8.x. Esta revisão fixa patches disponíveis em 26/11/2026 e registra as ressalvas; a atualização para Spring Boot 4.1.3 mantém a linha aprovada.

## Decisão

| Tecnologia | Versão escolhida | Uso no FlowBridge | Compatibilidade e orientação |
|---|---|---|---|
| Java | Eclipse Temurin 21.0.13+9 | Runtime da CI e versão-alvo da API e do worker. | Spring Boot 4.1 suporta Java 17 ou superior até Java 27. A propriedade compiler release gera bytecode Java 21. |
| Spring Boot | 4.1.3 | Framework da API e do worker. | Patch mais recente consultado na linha 4.1; usar o BOM pai para centralizar gestão de dependências. Spring Boot 4.2.0 também está disponível, mas não foi adotado nesta atualização de patch. |
| Maven | Wrapper 3.10.2, compartilhado na raiz; Wrapper Plugin 3.3.4. | Build reproduzível da API e do worker. | `./mvnw --batch-mode verify` executa o reactor; `./mvnw --batch-mode -f backend/pom.xml verify` e o comando equivalente para worker validam cada módulo. |
| Angular | 22.3.0 | SPA do dashboard. | Fixar Angular CLI na mesma versão quando o frontend for inicializado. |
| Node.js | 24.22.3 LTS | Runtime de build e testes do frontend. | Exato no arquivo `.nvmrc`; está dentro da faixa aceita por Angular 22 (`^24.15.0`). |
| TypeScript | 6.0.3 | Linguagem do frontend. | Patch corrente da linha aceita por Angular 22 (`>=6.0.0 <6.1.0`). |
| PostgreSQL | 18.7 | Banco relacional transacional. | Patch estável corrente consultado; fixar a imagem e atualizar com revisão. |
| RabbitMQ | 4.4.1 | Broker de eventos e filas. | Patch estável corrente consultado; usar imagem `rabbitmq:4.4.1-management` e validar Spring AMQP na implementação. |
| Keycloak | 26.8.2 | Provedor de identidade e emissão de tokens. | Patch estável corrente consultado; fixar a imagem e revisar notas de segurança antes de atualizações. |

O workflow de CI usa Eclipse Temurin 21.0.13+9 e Node conforme `.nvmrc`, executa nos runners `ubuntu-24.04` e fixa as GitHub Actions por SHA. Os jobs só compilam e testam módulos quando seus manifests existem.

## Justificativa

Java 21 é uma versão LTS e continua dentro da faixa suportada por Spring Boot 4.1.3. A propriedade `maven.compiler.release` limita o bytecode ao runtime 21, inclusive quando a build local roda sobre um JDK mais novo.

Angular 22.3.0 aceita Node 24 (`^24.15.0`) e TypeScript 6.0 (`>=6.0.0 <6.1.0`). Node 24.22.3 e TypeScript 6.0.3 satisfazem a matriz. O job de frontend usa `ng test` pelo script npm, com `--no-watch --no-progress` para encerrar em CI, e `npm run build`; os testes reais serão definidos junto com o dashboard.

O Maven Wrapper compartilhado na raiz oferece uma única versão de Maven para API e worker. A opção `-f` seleciona explicitamente cada POM, evitando que o worker dependa de um wrapper localizado dentro do backend. Esta decisão substitui a localização ilustrativa `backend/mvnw` na árvore do guia principal; muda apenas a localização da ferramenta de build, não a arquitetura de execução dos módulos.

## Alternativas consideradas

- **Java 25:** também está dentro da faixa suportada pelo Spring Boot 4.1.3 e está instalado no ambiente local, mas não foi adotado como runtime-alvo porque Java 21 é a LTS escolhida e a CI já usa essa versão.
- **Spring Boot 4.2.0:** minor mais recente disponível na data desta revisão. Foi mantido fora desta mudança para preservar a linha 4.1 aprovada; reavaliar quando as dependências reais forem testadas. Spring Boot 3.5.x continua sendo alternativa apenas se uma dependência essencial não funcionar na linha 4.x.
- **Wrappers Maven independentes:** um wrapper por módulo isolaria cada build, mas duplicaria configuração e atualização de versão. Foi escolhido um wrapper comum na raiz com POM explícito.
- **`ubuntu-latest`:** acompanha a imagem Linux mais recente do GitHub e reduz manutenção, mas pode mudar sem alteração do workflow. Foi escolhido `ubuntu-24.04` para tornar o ambiente do CI mais previsível; a imagem continua recebendo atualizações do GitHub.

## Riscos e validação

1. Spring Boot 4.1.3 é uma major recente e a linha 4.2 já está disponível. Validar starters, Spring Security, Spring AMQP, Flyway, Testcontainers e OpenAPI antes de expandir o esqueleto.
2. Validar a imagem `rabbitmq:4.4.1-management` e a integração de testes antes de implementar mensageria.
3. Patches de PostgreSQL, RabbitMQ e Keycloak mudam. Revalidar as tags exatas antes de atualizar a configuração local.
4. O workflow pode validar somente os módulos presentes. Build e testes reais do backend, worker e frontend permanecerão pendentes até que cada módulo exista.
5. Maven Wrapper 3.3.4 usa uma distribuição Maven fixada. A distribuição oficial do Maven 3.10.2 deve ser obtida pelo wrapper; a instalação local de Maven não substitui essa verificação.

Na entrega 1.2 da Fase 1, o build Maven validou Spring Boot 4.1.3 como parent e Java 21 como alvo de bytecode. Na entrega 1.4, o workspace Angular CLI 22.3.0, Node 24 e TypeScript 6.0.3 foram usados no build e testes locais; a CI seleciona o Node exato do `.nvmrc` (24.22.3). O ambiente local ainda usa Node 24.16.0, que está dentro da faixa aceita pela matriz do Angular 22. PostgreSQL 18.7, RabbitMQ 4.4.1 e Keycloak 26.8.2 ficam fixados para Compose na entrega 1.5.

## Referências oficiais

- [Spring Boot 4.1 system requirements](https://docs.spring.io/spring-boot/4.1/system-requirements.html) — Java 17 a 27, Maven 3.6.3 ou superior.
- [Requisitos do Spring Boot 4.1.3](https://docs.spring.io/spring-boot/4.1/system-requirements.html) — requisitos da linha escolhida e versão estável 4.2.0 mais recente.
- [Oracle Java SE support roadmap](https://www.oracle.com/java/technologies/java-se-support-roadmap.html) — ciclo de suporte LTS do Java 21.
- [Eclipse Temurin 21.0.13+9](https://github.com/adoptium/temurin21-binaries/releases) — build de CI fixado.
- [Maven Wrapper](https://maven.apache.org/wrapper/) — wrapper para builds Maven reproduzíveis.
- [GitHub setup-java version syntax](https://github.com/actions/setup-java/blob/main/README.md#supported-version-syntax) — aceita patch fixo `21.0.13+9`.
- [Angular compatibility matrix](https://angular.dev/reference/versions) — Node.js e TypeScript aceitos por Angular 22.
- [TypeScript 6.0 release notes](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html).
- [Angular 22 releases](https://angular.dev/reference/releases) — janela de suporte e cronograma de minors.
- [Node.js 24.22.3 LTS](https://nodejs.org/en/blog/release/v24.22.3).
- [Angular unit testing](https://angular.dev/guide/testing) — Vitest padrão e modo de execução única em CI.
- [PostgreSQL versioning policy](https://www.postgresql.org/support/versioning/) — suporte às versões principais.
- [RabbitMQ release information](https://www.rabbitmq.com/release-information) — versões e janelas de suporte.
- [Keycloak releases](https://www.keycloak.org/downloads) — versões mantidas e downloads oficiais.
- [Keycloak 26.8.2](https://www.keycloak.org/2026/11/keycloak-2682-released).
- [Apache Maven 3.10.2](https://maven.apache.org/download.cgi) e [Maven Wrapper 3.3.4](https://maven.apache.org/tools/wrapper/).
