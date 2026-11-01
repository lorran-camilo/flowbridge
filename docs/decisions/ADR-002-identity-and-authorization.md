# ADR-002 — Keycloak, OIDC para pessoas e OAuth Client Credentials para integrações

- **Status:** proposta, aguardando aprovação.
- **Data:** 2026-11-01

## Contexto

O painel precisa login de pessoa; cliente externo precisa autenticar-se sem usuário interativo. Misturar identidade (login) com autorização (permissão) ou tratar a SPA como autoridade deixa endpoints vulneráveis.

## Decisão proposta

- Keycloak como Authorization Server/Identity Provider local.
- Angular como cliente público OIDC: Authorization Code + PKCE.
- Cliente de integração confidencial: OAuth 2.0 Client Credentials.
- Spring Boot API como OAuth2 Resource Server; valida assinatura, issuer `iss`, timestamps (`exp`/`nbf`) e audience `aud` explícita para API.
- API mapeia claims para authorities de forma explícita e protege cada endpoint no servidor.
- Roles de pessoas `ADMIN`, `OPERATOR`, `VIEWER` não são concedidas automaticamente ao client de máquina. Para cliente, usar scopes como `orders:write` e `orders:read` (nomes propostos).
- SPA não armazena access/refresh token em `localStorage`; proposta inicial mantém access token em memória usando biblioteca OIDC mantida e documenta reautenticação/reload.
- Client secret só existe em configuração local ignorada pelo Git; `.env.example` usa valores falsos.

## Como funciona

OIDC adiciona login e identidade sobre OAuth 2.0. Authorization Code + PKCE redireciona o navegador ao Keycloak; o verifier/challenge protege a troca de código em cliente público sem segredo. O access token é a credencial da API. ID token descreve autenticação do usuário ao cliente OIDC e não substitui access token da API. Em Client Credentials, processo servidor obtém access token como client, sem representar pessoa.

A API valida token localmente usando chave pública/JWKS publicada pelo issuer; não deve aceitar token porque a UI disse que usuário é admin. Spring Resource Server valida issuer, assinatura e timestamps por padrão configurado e permite validar audience explicitamente.

## Motivo e alternativas

- Keycloak evita implementar armazenamento de senha, login, emissão e assinatura JWT.
- OIDC atende login de usuário; Client Credentials atende máquina a máquina sem simular usuário.
- Alternativas: IdP gerenciado (custo/conta externa fora do escopo), sessão/BFF (altera arquitetura da SPA) ou auth própria (rejeitada por segurança e escopo).

## Consequências, riscos e limites

- Um token JWT assinado não é automaticamente válido para esta API: issuer, audience, expiração, assinatura e permissões precisam validar.
- Formato de roles do Keycloak depende de client/realm configuration; mapeamento deve ser testado, não presumido.
- A URL `iss` precisa ser alcançável e idêntica do ponto de vista do navegador e API/containers; hostname split local pode quebrar discovery/JWKS.
- Armazenamento de tokens no navegador tem risco XSS; memória reduz persistência local, mas reload exige login/token novo conforme biblioteca.
- CORS, redirect URIs e origins locais devem ser estritos. Guards Angular melhoram UX, não segurança.
- Confirmar se o client externo pode ler pedidos e qual ownership/tenant limita suas consultas.

## Como testar

Sem token, token expirado/assinado errado/issuer errado/audience errada: `401`; token válido sem permissão: `403`; pessoa com role apropriada e client com scope apropriado são aceitos; client token nunca ganha role de pessoa; testes de integração validam configuração real do realm. Verificar logs e capturas por segredo/token.

## Aprovação pendente

Confirmar nomes de scopes, roles, hostname/issuer de desenvolvimento, armazenamento de token da SPA e se integração poderá consultar/criar com ownership restrito.

## Referências

- [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html)
- [OAuth 2.0 Security Best Current Practice (RFC 9700)](https://www.rfc-editor.org/rfc/rfc9700.html)
- [Spring Security Resource Server JWT](https://docs.spring.io/spring-security/reference/servlet/oauth2/resource-server/jwt.html)
- [Keycloak Server Administration Guide](https://www.keycloak.org/docs/latest/server_admin/)
