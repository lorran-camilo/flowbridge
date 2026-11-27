# Rascunho 02 — Ambiente local e aprendizados da Fase 1

**Status:** aguardando revisão e aprovação do proprietário; não publicado.
**Escopo:** entregas 1.4 e 1.5 da Fase 1.
**Imagem:** `../assets/flowbridge-phase-1-local-environment.png` (exportação para revisão/publicação) e `../assets/flowbridge-phase-1-local-environment.svg` (fonte vetorial editável). O diagrama mostra o shell Angular e os containers com health checks; não representa integração da aplicação.

## Texto sugerido

Hoje avancei na base do FlowBridge, meu projeto de estudo sobre integração e automação de pedidos.

Deixei o shell inicial do painel Angular com dependências travadas no `package-lock.json`, teste estrutural com Vitest e build de produção. Também subi o ambiente local com Docker Compose: PostgreSQL, RabbitMQ e Keycloak.

Os três containers ficaram saudáveis, e executei uma verificação real das permissões do PostgreSQL: a credencial de migration pode criar estruturas; as credenciais de execução da API e do worker não podem criar tabelas. A descoberta OIDC do realm vazio do Keycloak também respondeu com o issuer configurado.

Uma distinção que estou aprendendo a fazer: um container `healthy` passou pelo health check dele. Isso não prova que a API esteja conectada a esse serviço. Ainda não ligamos API e worker ao banco, broker ou provedor de identidade; o login e a validação de tokens também continuam para etapas futuras.

Estudei ainda a diferença entre OIDC e Keycloak: OIDC é o padrão de identidade; Keycloak é um servidor que implementa esse padrão. A API usará access tokens para autorizar chamadas, depois de validar as permissões no backend.

Estou usando IA como apoio didático e técnico. As decisões, a revisão e a responsabilidade por compreender e validar o projeto continuam comigo.

O que você costuma verificar primeiro ao iniciar dependências locais: saúde do serviço, permissões ou uma integração ponta a ponta?

#Java #SpringBoot #Angular #DockerCompose #PostgreSQL #RabbitMQ #Keycloak #AprendizadoContínuo

## Descrição alternativa da imagem

Diagrama em azul-marinho: o shell Angular inicial aparece separado de um grupo Docker Compose com PostgreSQL, RabbitMQ e Keycloak, cada um identificado como container com health check saudável. Uma faixa ressalta que saúde dos containers não comprova integração da API.

## Nota editorial e limites

- `npm ci`, teste Vitest, build Angular e verificações do Compose foram executados nas entregas correspondentes; os detalhes e resultados estão no PR #4 e no roadmap.
- O Postgres grants check usou os containers reais e concluiu com sucesso. A discovery confirmou o issuer do realm vazio; não houve login, emissão/validação de token pela API nem configuração de cliente.
- A API e o worker existem como shells, mas ainda não foram conectados às dependências desta publicação.
- O hostname canônico ainda exige uma entrada local no arquivo `hosts` do Windows para acesso pelo próprio nome fora da rede Docker.
- A imagem é um diagrama de estado da Fase 1, não uma captura da aplicação. O rascunho precisa da revisão e aprovação do proprietário antes de qualquer publicação; não foi publicado.
