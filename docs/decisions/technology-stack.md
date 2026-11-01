# ADR-005 — baseline atual de versões para o FlowBridge

- **Status:** proposta para aprovação; versões verificadas em 2026-11-01.
- **Contexto:** a tabela de stack no guia é baseline datada e orienta rechecagem oficial, não um pin imutável. Fase 0 precisa propor linhas ainda mantidas e compatíveis.

## Decisão proposta

| Tecnologia | Linha recomendada | Função no FlowBridge | Por que / validação |
|---|---|---|
| Java | 25 LTS | Runtime e linguagem do backend/worker. | LTS atual na roadmap Oracle; Boot 4.1 aceita Java 25. |
| Spring Boot | 4.1.2 estável, linha 4.1.x | Framework da API e do worker; configura servidor HTTP, dependências, segurança e mensageria. | Atual estável consultado; Java 17–27, Spring Framework 7.0.10+, Maven 3.6.3+. |
| Maven | Wrapper 3.10.0 | Resolve dependências e compila/testa backend com versão reprodutível. | Apache lista 3.10.0 como atual/recomendado; Maven 4 permanece RC. |
| PostgreSQL | 18.6 | Banco relacional transacional e fonte de verdade. | Major atual suportado; policy informa suporte até 14 nov. 2030. Não usar PostgreSQL 19 RC. |
| RabbitMQ | 4.4.0 e patches 4.4.x | Broker que encaminha e retém eventos até worker consumir. | Lançado 20 out. 2026, comunidade até 31 jul. 2027; testar plugin Spring AMQP e Testcontainers por ser linha recém-lançada. |
| Keycloak | 26.8.1 e patches 26.8.x | Provedor de identidade/OAuth que autentica e emite tokens. | Patch oficial de 13 out. 2026; fixar imagem exata e revisar notas de segurança ao atualizar. |
| Angular | 22.x | Framework da SPA do painel. | Página oficial mostra 22 em active support; baseline de Angular CLI na mesma major. |
| Node.js | 24.22.2 LTS | Runtime/ferramenta de build do frontend Angular. | Active LTS; compatível com faixa Angular 22 `^24.15.0`. |
| TypeScript | 6.0.x dentro de `>=6.0.0 <6.1.0` | Linguagem tipada usada pelo frontend. | Matriz oficial Angular 22; não escolher fora da faixa. |

Fixar patch tags, Maven wrapper distribution, Java toolchain e arquivos de versão Node. Registrar versões de bibliotecas efetivamente usadas no build na Fase 1; não copiar a lista de dependências do guia sem necessidade.

## Problema e motivo

Baseline antiga pode perder suporte durante o projeto. Escolher versões mantidas e documentadas dá atualizações de segurança e compatibilidade clara. JDK 25 é LTS; Spring Boot 4.1.2 suporta sua faixa. Angular 22 e Node 24 satisfazem matriz oficial. PostgreSQL 18 está em janela longa. Keycloak 26.8.1 recebe patch atual. RabbitMQ 4.4 tem suporte comunitário atual, embora seja lançamento muito novo.

## Alternativas

- **Mais conservadora:** Java 21 + Spring Boot 3.5.16 + Angular 21 + Node 24 + PostgreSQL 18 + RabbitMQ 4.3.6 + Keycloak 26.8.1. Boot 3.5 é mantido e suporta Java 25; Angular 21 está em LTS. RabbitMQ 4.3 só tem suporte comunitário até jan. 2027, tornando-se curta para projeto prolongado.
- **Baseline recomendada:** Java 25, Boot 4.1, Angular 22, PostgreSQL 18, RabbitMQ 4.4, Keycloak 26.8. Mais atual e com melhor janela, mas aumenta risco de quebra em ecossistema e precisa spike de compatibilidade.
- **Maven 3.9.16:** opção se plugin não suportar 3.10.0; Maven 4 não é GA, não escolher para reprodutibilidade inicial.
- **PostgreSQL 17.11:** mantido até nov. 2029; alternativa se alguma integração não funcionar com PG18.

## Riscos e condições de adoção

1. Boot 4.1 é major com mudanças em Spring Framework 7, APIs e starters. `springdoc-openapi`, Flyway, Testcontainers, Spring AMQP e testes precisam demonstrar suporte real antes de gerar esqueleto. Se dependência essencial não tiver release compatível, voltar para Boot 3.5.16 é decisão técnica justificada, documentada em ADR atualizado — não falha de projeto.
2. Angular 22/TypeScript 6 é recente; validar biblioteca OIDC, ferramenta de teste e Playwright. Não forçar dependência sem compatibilidade oficial.
3. RabbitMQ 4.4.0 é recém-lançado; a compatibilidade de protocolo AMQP pode funcionar enquanto plugins, management image e integração de testes ainda precisam confirmação.
4. Tags Docker precisam ser exatas (ex. `4.4.0-management` se tag oficial existir); verificar nome/tag e digest na data da Fase 1. Não assumir sufixo.
5. Patches mudam; revalidar no início da fase e antes de lançamento. Versão atual não é política de atualização automática.

## Como validar

Antes de criar esqueleto, fazer uma spike curta sem regra de negócio: compilar app mínimo com Boot + Java; resolver plugins Maven; construir Angular CLI com Node/TS; iniciar imagens fixadas; confirmar migrations/Testcontainers e documentação OIDC. Registrar comandos e resultado. A spike pertence à Fase 1 somente após aprovação deste ADR.

## Referências oficiais consultadas

- [Spring Boot estável e releases](https://docs.spring.io/spring-boot/) · [4.1 system requirements](https://docs.spring.io/spring-boot/system-requirements.html) · [3.5 system requirements](https://docs.spring.io/spring-boot/3.5/system-requirements.html)
- [Oracle Java SE support roadmap](https://www.oracle.com/java/technologies/java-se-support-roadmap.html)
- [Maven releases history](https://maven.apache.org/docs/history.html) · [Maven 3.10 download](https://maven.apache.org/download.cgi)
- [Angular compatibility matrix](https://angular.dev/reference/versions) · [release/support status](https://angular.dev/reference/releases)
- [Node.js release schedule](https://nodejs.org/en/about/previous-releases)
- [PostgreSQL versioning](https://www.postgresql.org/support/versioning/) · [release notes](https://www.postgresql.org/docs/current/release.html)
- [RabbitMQ release information](https://www.rabbitmq.com/release-information)
- [Keycloak 26.8.1 release](https://www.keycloak.org/2026/10/keycloak-2681-released)
