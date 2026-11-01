# FlowBridge — contratos REST propostos

**Estado:** proposta da Fase 0, aguardando aprovação.  
**Base URL local proposta:** `http://localhost:8080/api/v1`.  
**Formato:** JSON UTF-8; documentação OpenAPI acompanha o contrato implementado.

## Convenções

- Recursos ficam sob `/api/v1`. Versão na URI torna mudanças incompatíveis explícitas.
- Datas em RFC 3339/ISO 8601 UTC; IDs UUID; valores monetários decimais representados como JSON number e validados no servidor. Evitar floating point na lógica Java/SQL.
- Pedido criado usa `201 Created`: a entidade existe e pode ser consultada mesmo que o processamento siga assíncrono. `Location: /api/v1/orders/{id}` identifica o recurso. O corpo indica `RECEIVED`, não conclusão.
- `POST /orders` exige `Idempotency-Key` (proposta). Escopo da chave é o cliente autenticado. Mesma chave e mesmo payload retorna o resultado original; payload diferente retorna `409`.
- `X-Correlation-Id` é aceito se válido ou gerado pela API. Resposta retorna o ID para rastreamento. Não aceitar valores arbitrariamente longos.
- Paginação proposta: `page` começando em 0, `size` default 20 e máximo 100, ordenação whitelist (default `createdAt,desc`).
- Erros seguem Problem Details (RFC 9457) com `type`, `title`, `status`, `detail`, `instance`, `code`, `correlationId`; `errors[]` opcional contém campo/código/mensagem segura. Nunca incluir stack trace.

## DTOs

### `CreateOrderRequest`

```json
{
  "externalReference": "ERP-12345",
  "currency": "USD",
  "items": [
    { "sku": "SKU-001", "description": "Item sintético", "quantity": 2, "unitPrice": 19.95 }
  ]
}
```

- `externalReference`: opcional até decisão de negócio; seu escopo e unicidade estão abertos.
- `currency`: requerido; 3 letras maiúsculas (ISO 4217 proposta).
- `items`: pelo menos um; cada `sku` não vazio, `quantity > 0`, `unitPrice >= 0`, limite de tamanho/quantidade a fixar.
- `total` não é enviado/confiado ao cliente: API calcula a soma dos itens.
- Endereço/destino/peso não aparecem no guia. Não adicioná-los silenciosamente; confirmar como a simulação de frete obtém dados.

### `OrderResponse`

```json
{
  "id": "uuid",
  "externalReference": "ERP-12345",
  "status": "RECEIVED",
  "currency": "USD",
  "total": 39.90,
  "items": [
    { "id": "uuid", "lineNumber": 1, "sku": "SKU-001", "description": "Item sintético", "quantity": 2, "unitPrice": 19.95, "lineTotal": 39.90 }
  ],
  "createdAt": "2026-11-01T12:00:00Z",
  "updatedAt": "2026-11-01T12:00:00Z",
  "processingGeneration": 1,
  "correlationId": "uuid"
}
```

`items` pode ser omitido na listagem e incluído no detalhe; decidir no OpenAPI se haverá DTO de resumo separado. Respostas nunca expõem entidades JPA.

### `PageResponse<T>`

```json
{ "content": [], "page": 0, "size": 20, "totalElements": 0, "totalPages": 0, "sort": "createdAt,desc" }
```

### `TimelineEntry`, `IntegrationExecution` e `DashboardSummary`

- Timeline: `id`, `occurredAt`, `category`, `status`, `summary`, `correlationId`, `safeDetails` allowlisted.
- Execution: `id`, `orderId`, `integrationType`, `status`, `attemptNumber`, `externalReference` simulada opcional, `durationMs`, `errorCode`, `startedAt`, `finishedAt`.
- Dashboard: contadores por estado e janela consultada; não hardcode. Definir janela/filtros na implementação e validar agregações no banco.

### `ReprocessOrderRequest`

```json
{ "reason": "Falha simulada corrigida para demonstração" }
```

`reason` obrigatório é proposta, não requisito fechado. Uma geração nova é criada; histórico antigo é preservado. Reprocessar o fluxo inteiro é proposta preferida, pendente de aprovação.

## Endpoints

| Método e caminho | Parâmetros/headers/body | Sucesso | Erros principais | Acesso proposto |
|---|---|---|---|---|
| `POST /orders` | Bearer; `Idempotency-Key`; `X-Correlation-Id` opcional; `CreateOrderRequest` | `201`, `Location`, `OrderResponse` | `400` JSON/validação/header; `401`; `403`; `409` chave reutilizada diferente ou referência duplicada se aprovada; `413` limite de payload; `503` banco indisponível | client `orders:write`; usuário apenas se uso humano de criação for aprovado |
| `GET /orders` | `page`, `size`, `sort`; filtros `status`, `externalReference`, `createdFrom`, `createdTo` | `200 PageResponse<OrderSummary>` | `400` filtro/paginação inválidos; `401`; `403` | usuário `VIEWER`/`OPERATOR`/`ADMIN` com leitura; cliente com `orders:read` somente dentro do seu ownership (regra ainda aberta) |
| `GET /orders/{id}` | path UUID | `200 OrderResponse` | `400` UUID inválido; `401`; `403`; `404` | leitura autorizada no escopo do principal |
| `GET /orders/{id}/timeline` | path UUID; paginação se histórico crescer | `200 PageResponse<TimelineEntry>` | `400`; `401`; `403`; `404` | leitura autorizada |
| `POST /orders/{id}/reprocess` | Bearer; `X-Correlation-Id`; `ReprocessOrderRequest` | `202 Accepted`, `Location` para pedido/tentativa e `ReprocessResponse` | `400`; `401`; `403`; `404`; `409` estado não `FAILED`/reprocessamento já em andamento; `503` se gravação não persistir | pessoa `OPERATOR`/`ADMIN`; client proibido por padrão |
| `GET /integrations` | paginação/filtros de tipo/status se necessários | `200 PageResponse<IntegrationSummary>` | `400`; `401`; `403` | leitura operacional |
| `GET /integrations/{id}/executions` | path UUID, paginação | `200 PageResponse<IntegrationExecution>` | `400`; `401`; `403`; `404` | leitura operacional |
| `GET /dashboard/summary` | janela `from`/`to` opcional proposta | `200 DashboardSummary` | `400`; `401`; `403` | usuário com leitura operacional |

`GET /integrations/{id}/executions` não define entidade de integração configurável na especificação. Confirmar se `{id}` é tipo/recurso ou se o endpoint deve ser por `integrationType`; proposta alternativa de rota mais explícita: `GET /integrations/{integrationType}/executions`.

`GET /health` e endpoints de health/metrics são operacionais, não contratos de negócio; serão definidos na Fase 1/8 com exposição restrita conforme o caso.

## Erros e semântica

| Status | Uso proposto | Exemplo |
|---|---|---|
| `400 Bad Request` | JSON malformado, campos inválidos, filtros/paginação fora dos limites. | `quantity` zero. |
| `401 Unauthorized` | Sem token, token malformado, expirado, assinatura ou issuer inválidos. | Sem `Authorization`. |
| `403 Forbidden` | Token válido, mas sem authority exigida. | `VIEWER` solicita reprocessamento. |
| `404 Not Found` | Recurso inexistente ou não visível no escopo autorizado (decidir política antienumeração). | UUID sem pedido. |
| `409 Conflict` | Recurso/estado não permite operação ou idempotency key usada com outro payload. | Pedido já em processamento. |
| `413 Content Too Large` | Corpo excede limites configurados. | Lista abusivamente grande. |
| `429 Too Many Requests` | Só se uma política de rate limiting for aprovada; não está exigida ainda. | Limite por principal. |
| `500 Internal Server Error` | Erro inesperado sem detalhes internos. | Falha não classificada. |
| `503 Service Unavailable` | Dependência necessária indisponível para persistir a aceitação. | PostgreSQL fora do ar. |

## Matriz inicial de autorização

| Endpoint | Viewer | Operator | Admin | Client Credentials |
|---|---:|---:|---:|---:|
| Criar pedido | Negado por padrão | A decidir | A decidir | `orders:write` |
| Listar/detalhar/timeline | Sim, leitura do seu escopo | Sim | Sim | `orders:read`, limitado a ownership aprovado |
| Reprocessar | Não | Sim | Sim | Negado por padrão |
| Integrações/dashboard | Sim, leitura | Sim | Sim | Negado por padrão até definir necessidade |

Não inferir a existência de tenant: o `client_scope` da idempotência não resolve sozinho o isolamento de leitura. Definir vínculo entre client, pedido e autorização antes de permitir que clientes consultem por UUID.

## Como validar o contrato

- OpenAPI é fonte executável do contrato HTTP e precisa refletir DTOs/códigos reais.
- Testes API cobrem status, headers, Problem Details e regras de permissão.
- Testes de integração provam unicidade/concorrência da idempotência no PostgreSQL.
- Teste de cliente real ou roteiro curl cobre `201`, replay idempotente e conflito `409`.
- Verificar que campos sensíveis/entidades internas não aparecem em responses.

## Referências

- [RFC 9457 — Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html)
- [RFC 9110 — HTTP Semantics (201, 202, 409, 503)](https://www.rfc-editor.org/rfc/rfc9110.html)
