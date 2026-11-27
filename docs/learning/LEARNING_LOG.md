# FlowBridge — registro de aprendizado

Use este documento para registrar aprendizados do proprietário, não apenas tópicos explicados por um agente. Cada entrada deve distinguir exposição ao conceito, estudo/prática e compreensão confirmada. Acrescente exemplos, perguntas que ainda restam e onde o conceito aparece no código quando houver implementação.

## Estados de aprendizado

- **Apresentado:** o conceito foi explicado ou documentado; não presume compreensão.
- **Em estudo:** o proprietário está lendo, praticando ou perguntando sobre ele.
- **Compreendido (confirmado):** o proprietário consegue explicá-lo com palavras próprias ou aplicá-lo em exercício/código revisado.
- **A revisar:** identificada dúvida ou lacuna após uso prático.

## Registro inicial — 2026-11-01

O planejamento e as decisões revisadas apresentaram os conceitos abaixo. O proprietário ainda não confirmou quais compreendeu; por isso nenhum tópico consta como aprendido. A aplicação não foi implementada, então não há prática em código para registrar.

| Fase | Conceitos/tópicos | Relação com o FlowBridge | Estado |
|---|---|---|---|
| Fase 0 — planejamento | Monólito modular e worker; API e contratos; OAuth 2.0/OIDC; persistência e idempotência; Outbox; RabbitMQ, retry e DLQ; dependências de etapas/reprocessamento; privilégios PostgreSQL; compatibilidade de versões. | Foram descritos nos documentos de arquitetura para apoiar revisão e estudo antes da implementação. | **Apresentado / a validar.** Nenhum foi marcado como compreendido sem confirmação do proprietário. |

## Sessão de revisão das entregas 1.2 a 1.5 — 2026-11-26

Este registro preserva as respostas dadas durante as revisões e as correções do tutor. “Compreendido (confirmado)” significa que a resposta escrita demonstrou o conceito naquele ponto; não substitui prática futura nem revisão do código.

### Contexto do projeto e método de estudo

**Confirmações do proprietário:** a identidade visual e o plano do projeto já estavam definidos; o FlowBridge é um projeto de estudo; o tutor deve explicar detalhadamente os conceitos e o andamento.

**Registro:** estas confirmações definem o método de trabalho, não são critérios técnicos de implementação. Cada entrega deve ligar os conceitos aos arquivos, explicar o que os comandos verificam e distinguir o que já foi implementado do que continua planejado. As decisões de arquitetura da Fase 0 permanecem nos documentos de requisitos e ADRs.

**Estado:** objetivo educacional e preferência por explicações detalhadas — **Confirmados pelo proprietário**.

### Entrega 1.2 — Maven, módulos e operações de build

**Resposta do proprietário:** “O POM raiz funciona como agregador e pai para não repetir versões nos módulos, e permite compilar de forma independente ou conjunta.”

**Correção e complemento:** a resposta está correta em seus pontos centrais. O POM raiz pode exercer dois papéis: agregar os módulos do reactor Maven e centralizar configuração herdada, como versões de dependências em `dependencyManagement` e versões de plugins. Um módulo pode ser selecionado sozinho ou compilado junto com os demais pelo reactor. O Maven Wrapper (`mvnw.cmd` no Windows e `./mvnw` em Unix) seleciona a versão Maven registrada pelo projeto.

As operações mais comuns são etapas diferentes do ciclo de vida Maven:

| Operação | O que faz | O que não garante sozinha |
|---|---|---|
| `clean` | Apaga saídas geradas anteriormente, normalmente `target/`. | Não compila nem testa. |
| `compile` | Compila o código principal do módulo. | Não executa os testes nem necessariamente cria o JAR final. |
| `test` | Compila testes e executa os testes configurados. | Não é uma prova de integração com serviços externos se os testes não os iniciarem. |
| `package` | Executa as etapas anteriores do ciclo e empacota o artefato, como um JAR. | Não significa que o JAR foi iniciado ou que as dependências externas foram integradas. |
| `verify` | Executa as etapas anteriores e as verificações configuradas até a fase `verify`. | Só verifica o que os plugins e testes do projeto realmente configuram. |

`mvnw.cmd --batch-mode verify` no POM raiz pede ao Maven para validar os módulos incluídos e executar o ciclo até `verify`. Rodar o mesmo comando dentro de um módulo ou selecionar um módulo permite trabalhar de forma mais localizada. “Build” é o processo de executar essas etapas; não é uma única operação com um único significado.

**Estado:** propósito de POM pai/agregador e compilação por módulo ou reactor — **Compreendido (confirmado)** pela explicação escrita. Diferenças entre fases Maven — **Apresentado / a revisar com prática**.

### Entrega 1.3 — Spring Boot, testes offline e execução do JAR

**Respostas do proprietário:**

1. “Define o inicio da aplicação spring.”
2. “A funcionalidade da API em ambiente ‘Offline’, sem iniciar nenhum ambiente, ja o JAR serviu para testar via HTTP, com uma porta real.”
3. O build e os testes confirmam que a API funciona, mas não que as dependências estão funcionando.

**Correção e complemento:** a classe com `main` chama o mecanismo de inicialização do Spring Boot e cria o contexto da aplicação: configurações, objetos gerenciados pelo Spring e, quando iniciado como servidor web, o servidor HTTP embutido. Um teste de contexto ou teste web com MockMvc pode exercitar a aplicação sem abrir uma porta de rede real; “offline” aqui significa sem iniciar um servidor HTTP real, não que a aplicação inteira é testada sem suas bibliotecas ou configurações. Executar o JAR inicia um processo separado com servidor HTTP e permite enviar uma requisição pela porta configurada.

Uma resposta `UP` no `/actuator/health` confirma o que aquele health check examina. Na entrega 1.3, esse era o health básico da aplicação; não havia ainda dependências configuradas nele. Mesmo um processo que inicia e responde HTTP não prova, por si só, integração com PostgreSQL, RabbitMQ ou Keycloak.

**Estado:** diferença entre teste sem servidor HTTP real e JAR iniciado numa porta — **Compreendido (confirmado)** pela resposta. O alcance de cada health check e a integração com dependências — **Apresentado / a revisar durante a integração**.

### Entrega 1.4 — npm, Vitest e build Angular

**Respostas do proprietário:**

1. `npm ci` instala as dependências necessárias usando as versões registradas em `package-lock.json`.
2. O Vitest verifica se o componente foi criado; o build verifica se compilou corretamente.
3. Perguntou se iniciar um JAR e testar via HTTP é o próximo teste.

**Correção e complemento:** a resposta sobre `npm ci` está correta: ele instala a árvore travada no lockfile e falha se esta não corresponder ao `package.json`. O teste Vitest do shell não deve ser entendido como um detector genérico de existência; ele monta/renderiza o componente e verifica as condições afirmadas nas expectativas do teste, como conteúdo visível. O build Angular compila e empacota a aplicação e detecta problemas de compilação, templates e tipos; não demonstra sozinho que o comportamento mostrado ao usuário está correto. Por isso build e teste respondem a perguntas diferentes.

Iniciar um JAR testa o backend como processo HTTP independente. Não testa, por si só, a integração do frontend Angular com a API. Para isso, o frontend precisa fazer uma chamada HTTP à API e deve haver um teste que observe essa interação.

**Estado:** `npm ci` — **Compreendido (confirmado)**. Diferença entre expectativas de teste e compilação — **A revisar**, pois “verificar se foi criado” é incompleto: é preciso explicar o que a expectativa do teste realmente comprova. JAR isolado versus integração frontend/API — **Apresentado / a revisar quando a chamada HTTP for implementada**.

### Entrega 1.5 — migrations, health checks, OIDC e Keycloak

**Respostas do proprietário:**

1. “Pois a criação de tabelas não deve ser feita por API, e sim ser feita por fora.”
2. “Não comprova, só comprova se a API está saudável, mas não uma integração.”
3. O proprietário pediu explicação sobre o hostname/issuer canônico.

**Correção e complemento:** a primeira resposta está correta com uma precisão: a API em execução usa uma conta de banco de runtime, sem permissão para criar estruturas. Uma ferramenta ou etapa controlada aplica as migrations usando a conta `flowbridge_migrator`. Assim, “por fora” significa fora das credenciais normais da API; migrations continuam sendo código versionado e reproduzível do projeto.

Na segunda resposta, houve uma confusão entre a saúde da API e a saúde das dependências. O estado `healthy` observado na entrega 1.5 veio dos health checks dos containers PostgreSQL, RabbitMQ e Keycloak. Ele diz que cada container respondeu ao seu teste configurado. Não prova que a API esteja saudável ou integrada. A integração exige evidência adicional, como conectar com as credenciais de runtime e executar uma operação real entre aplicação e serviço.

#### O que são OAuth 2.0, OIDC e Keycloak?

- **OAuth 2.0** é um protocolo de autorização delegada: define como um cliente obtém uma credencial de acesso para chamar uma API com permissões limitadas. OAuth 2.0 sozinho não padroniza um login de usuário para que o aplicativo saiba quem entrou.
- **OpenID Connect (OIDC)** é uma camada de identidade e autenticação construída sobre OAuth 2.0. Ela padroniza como o cliente confirma quem se autenticou e como recebe informações de identidade. Uma evidência importante é o **ID token**. O OIDC também define discovery para o cliente encontrar os endereços e chaves publicados pelo provedor.
- **Keycloak** é um produto que pode atuar como provedor de identidade e servidor de autorização: mantém realms, usuários, clientes, credenciais, roles e configurações; autentica e emite tokens conforme os protocolos. Keycloak é a ferramenta; OIDC e OAuth 2.0 são protocolos que ela implementa.

Uma analogia: OIDC é o idioma padronizado usado entre o aplicativo e o serviço de identidade; Keycloak é um dos servidores que sabe falar esse idioma. A API é outro participante: ela recebe access tokens e decide no servidor se são válidos e se autorizam aquela operação.

#### Tokens sem misturar suas funções

- O **ID token** informa ao cliente OIDC sobre o resultado da autenticação e a identidade do usuário. Ele é destinado ao cliente que iniciou o login.
- O **access token** é a credencial apresentada a uma API para pedir acesso a recursos. A API deve validar o token, incluindo assinatura, emissor (`iss`), validade temporal e público (`aud`) conforme a arquitetura.
- Um token pode ter formato JWT, mas JWT é um formato de token/claims; dizer “é JWT” não prova que emissor, validade, público e permissões sejam os esperados.

Portanto, Angular não autoriza sozinho uma operação escondendo um botão. A API é quem valida o access token e aplica autorização no servidor. O ID token não deve ser enviado no lugar do access token para proteger endpoints da API.

#### Fluxos planejados no FlowBridge

Para o **login humano no painel Angular**, o ADR-002 escolhe Authorization Code com PKCE: o navegador é redirecionado ao Keycloak; após autenticação, retorna um código temporário; o cliente troca esse código por tokens usando também o verificador temporário (PKCE), que reduz o risco de alguém que interceptou o código conseguir trocá-lo. O painel usa o access token para chamar a API, e a API valida o token e as permissões. O client Angular é público e não guarda um segredo fixo que possa ser extraído do navegador.

Para uma **integração de sistema para sistema**, o fluxo planejado é OAuth 2.0 Client Credentials: o cliente de máquina autentica-se como aplicação e recebe access token sem login de pessoa. Esse token representa o cliente de integração, não um usuário humano. A API aplica os scopes e o isolamento por `client_id` definidos no ADR-002.

O **worker não usa OIDC** no desenho aprovado: recebe eventos pelo RabbitMQ autenticado e usa suas próprias credenciais de menor privilégio no PostgreSQL. Ele não representa usuário nem precisa validar token do navegador.

#### Por que o issuer/hostname precisa ser consistente?

O issuer é a identidade do provedor que emitiu o token. No FlowBridge local, o valor aprovado é `http://keycloak.flowbridge.test:8080/realms/flowbridge`. O discovery publica esse issuer e tokens emitidos pelo realm carregam o mesmo emissor em `iss`. A API compara o emissor recebido com o que foi configurado; endereço diferente pode fazer a validação falhar, mesmo que ambos apontem para o mesmo container.

O mesmo nome também precisa ser alcançável por cada participante: o arquivo `hosts` do Windows aponta o nome para `127.0.0.1`, enquanto o alias Docker aponta o nome ao container Keycloak. Usar o nome interno `keycloak` como issuer criaria uma identidade distinta e não seria o hostname aprovado para navegador e API. A resolução Docker foi testada; a edição do `hosts` do Windows continua pendente por exigir permissão administrativa.

#### O que foi verificado e o que não foi

Na entrega 1.5, o realm vazio `flowbridge` iniciou e publicou discovery pelo endpoint `.well-known/openid-configuration`; a resposta apresentou o issuer esperado. Isso verifica disponibilidade e metadados do realm. Ainda não foram configurados clientes Angular ou de integração, login de usuário, emissão de tokens para esses clientes nem validação de token pela API. Esses comportamentos ficam para a fase de identidade. O ambiente atual usa modo de desenvolvimento e HTTP local, não configuração de produção.

**Estado das respostas:** separação entre API e migrations — **Compreendido (confirmado)** no princípio; aplicação de migrations será praticada depois. Diferença entre health de container, health de API e integração — **A revisar**. OAuth 2.0/OIDC/Keycloak, tokens, PKCE e issuer — **Apresentado nesta sessão; ainda não confirmado pelo proprietário**.

**Referências do projeto e fontes oficiais:** [ADR-002 — identidade e autorização](../decisions/ADR-002-identity-and-authorization.md), [ambiente local](../../infra/README.md), [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html), [OpenID Connect Discovery 1.0](https://openid.net/specs/openid-connect-discovery-1_0.html), [guia oficial de administração do Keycloak](https://www.keycloak.org/docs/latest/server_admin/) e [OAuth 2.0 Security Best Current Practice, RFC 9700](https://www.rfc-editor.org/rfc/rfc9700.html).

## Próximos registros

Para cada conceito, adicionar:

- **Data e fase:**
- **Conceito:**
- **Problema que resolve:**
- **Explicação em palavras do proprietário:**
- **Exemplo aplicado ou exercício:**
- **Arquivo/método/teste relacionado (se implementado):**
- **Dúvidas e limites que ainda restam:**
- **Estado:** apresentado / em estudo / compreendido (confirmado) / a revisar.
