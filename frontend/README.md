# FlowBridge frontend

Aplicação Angular do painel operacional. Nesta etapa existe apenas o shell inicial; autenticação, telas de pedidos e integração com a API ainda não foram implementadas.

## Requisitos

- Node.js 24.22.3, conforme o arquivo `.nvmrc` na raiz.
- npm 11.19.1, incluído na distribuição Node fixada.

## Comandos

Execute dentro desta pasta:

```bash
npm ci
npm test -- --no-watch --no-progress
npm run build
```

`npm ci` instala exatamente as versões registradas em `package-lock.json`. Os testes usam Vitest e jsdom para verificar o shell sem abrir um navegador.
