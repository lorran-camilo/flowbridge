# ADR-005 — versões aprovadas do stack FlowBridge

- **Status:** Accepted
- **Data:** 2026-11-01
- **Decisora:** proprietária do FlowBridge

## Contexto

A versão inicial do guia contém um baseline que precisava ser revisto antes do desenvolvimento. A Fase 0 comparou compatibilidade, suporte e risco de adoção. A proprietária aprovou Java 21 LTS, Spring Boot 4.1.2, Angular 22, Node.js 24 LTS, PostgreSQL 18, RabbitMQ 4.4 e Keycloak 26.8.x. Este ADR registra essas escolhas; não inicia a Fase 1.

## Decisão

| Tecnologia | Versão escolhida | Uso no FlowBridge | Compatibilidade e orientação |
|---|---|---|---|
| Java | 21 LTS | Runtime e linguagem da API e do worker. | Spring Boot 4.1.2 requer Java 17 ou superior e aceita até Java 27; Java 21 está dentro dessa faixa. |
| Spring Boot | 4.1.2 | Framework da API e do worker. | Requer Spring Framework 7.0.10 ou superior; validar starters e bibliotecas usadas na Fase 1. |
| Maven | Wrapper 3.10.0, compartilhado na raiz do repositório. | Build reproduzível da API e do worker. | Executar `./mvnw --batch-mode -f backend/pom.xml verify` e `./mvnw --batch-mode -f worker/pom.xml verify`. O wrapper não fica dentro do backend, para o worker não depender do diretório de outro módulo. |
| Angular | 22.x | SPA do dashboard. | Manter Angular CLI na mesma major e usar a configuração de teste padrão do CLI, salvo decisão posterior. |
| Node.js | 24 LTS | Runtime de build e testes do frontend. | Angular 22 aceita Node 24 a partir de `24.15.0`; usar a linha 24 LTS. |
| TypeScript | 6.0.x | Linguagem do frontend. | A faixa aceita por Angular 22 é `>=6.0.0 <6.1.0`. |
| PostgreSQL | 18.x | Banco relacional transacional. | Fixar o patch da imagem na configuração da Fase 1 e atualizar com revisão. |
| RabbitMQ | 4.4.x | Broker de eventos e filas. | Fixar o patch da imagem na configuração da Fase 1 e validar integração com Spring AMQP. |
| Keycloak | 26.8.x | Provedor de identidade e emissão de tokens. | Fixar o patch da imagem na configuração da Fase 1 e revisar notas de segurança antes de atualizações. |

O workflow de CI usa Java 21 e Node 24, executa nos runners `ubuntu-24.04` e fixa as GitHub Actions por SHA. Os jobs só compilam e testam módulos quando seus manifests existem.

## Justificativa

Java 21 é uma versão LTS consolidada e reduz a exposição a mudanças recentes da plataforma. A escolha continua compatível com Spring Boot 4.1.2, que aceita Java 17 a 27. Isso permite adotar o Boot escolhido sem elevar o runtime do projeto para Java 25.

Angular 22 aceita Node 24 (`^24.15.0`) e TypeScript 6.0 (`>=6.0.0 <6.1.0`). O job de frontend usa o comando `ng test` por meio do script npm, com `--no-watch --no-progress` para encerrar em CI, e `npm run build` para o build configurado pelo Angular CLI. O runner padrão de Angular 22 usa Vitest; os testes reais serão definidos junto com o dashboard, sem testes fictícios nesta etapa.

O Maven Wrapper compartilhado na raiz oferece uma única versão de Maven para API e worker. A opção `-f` seleciona explicitamente cada POM, evitando que o worker dependa de um wrapper localizado dentro do backend. Esta decisão substitui a localização ilustrativa `backend/mvnw` na árvore do guia principal; muda apenas a localização da ferramenta de build, não a arquitetura de execução dos módulos.

## Alternativas consideradas

- **Java 25:** também está dentro da faixa suportada pelo Spring Boot 4.1.2, mas exigiria um runtime mais recente sem benefício necessário para este projeto de aprendizado. Poderá ser reconsiderado em ADR futuro.
- **Spring Boot 3.5.x:** alternativa se uma dependência essencial não for compatível com a linha 4.1. A troca exige evidência de incompatibilidade e aprovação registrada; não deve ocorrer silenciosamente.
- **Wrappers Maven independentes:** um wrapper por módulo isolaria cada build, mas duplicaria configuração e atualização de versão. Foi escolhido um wrapper comum na raiz com POM explícito.
- **`ubuntu-latest`:** acompanha a imagem Linux mais recente do GitHub e reduz manutenção, mas pode mudar sem alteração do workflow. Foi escolhido `ubuntu-24.04` para tornar o ambiente do CI mais previsível; a imagem continua recebendo atualizações do GitHub.

## Riscos e validação

1. Spring Boot 4.1.2 é uma major recente. Na Fase 1, validar starters, Spring Security, Spring AMQP, Flyway, Testcontainers e ferramentas de documentação OpenAPI antes de expandir o esqueleto.
2. A linha RabbitMQ 4.4 é recente. Validar a imagem, o plugin de management e a integração de testes na versão patch escolhida.
3. Patches de PostgreSQL, RabbitMQ e Keycloak mudam. Revalidar e registrar tags exatas antes da configuração de infraestrutura.
4. O workflow pode validar somente os módulos presentes. Build e testes reais do backend, worker e frontend permanecerão pendentes até que cada módulo exista.
5. O Maven Wrapper compartilhado deverá ser gerado e versionado na raiz do repositório na etapa aprovada de estruturação dos builds. Este ADR não cria o wrapper nem os módulos.

Na Fase 1, a validação incluirá uma aplicação mínima com Java 21 e Spring Boot 4.1.2, build com o wrapper raiz, compatibilidade de Angular CLI 22 com Node 24 e TypeScript 6.0, e execução dos serviços com os patches de banco, broker e identidade aprovados. Nenhuma dessas verificações de aplicação foi executada nesta revisão documental.

## Referências oficiais

- [Spring Boot 4.1 system requirements](https://docs.spring.io/spring-boot/system-requirements.html) — Java 17 a 27, Maven 3.6.3 ou superior.
- [Oracle Java SE support roadmap](https://www.oracle.com/java/technologies/java-se-support-roadmap.html) — ciclo de suporte LTS do Java 21.
- [Maven Wrapper](https://maven.apache.org/wrapper/) — wrapper para builds Maven reproduzíveis.
- [Angular compatibility matrix](https://angular.dev/reference/versions) — Node.js e TypeScript aceitos por Angular 22.
- [Angular unit testing](https://angular.dev/guide/testing) — Vitest padrão e modo de execução única em CI.
- [PostgreSQL versioning policy](https://www.postgresql.org/support/versioning/) — suporte às versões principais.
- [RabbitMQ release information](https://www.rabbitmq.com/release-information) — versões e janelas de suporte.
- [Keycloak releases](https://www.keycloak.org/downloads) — versões mantidas e downloads oficiais.
