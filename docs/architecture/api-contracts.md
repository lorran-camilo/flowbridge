# FlowBridge — contratos REST propostos

**Estado:** contratos aprovados na Fase 0; API ainda não implementada.
**Base URL local planejada:** `http://localhost:8080/api/v1`.
**Formato:** JSON UTF-8; documentação OpenAPI acompanha o contrato implementado.

## Convenções

- Recursos ficam sob `/api/v1`. Versão na URI torna mudanças incompatíveis explícitas.
- Datas em RFC 3339/ISO 8601 UTC; IDs UUID; valores monetários decimais representados como JSON number e validados no servidor. Evitar floating point na lógica Java/SQL.
- Pedido criado usa `201 Created`: a entidade existe e pode ser consultada mesmo que o processamento siga assíncrono. `Location: /api/v1/orders/{id}` identifica o recurso. O corpo indica `RECEIVED`, não conclusão.
- `POST /orders` exige `Idempotency-Key`, delimitada pelo `client_id` validado. Mesma chave/payload dentro de 24h retorna o resultado original; payload diferente retorna `409`. Após 24h, a chave pode ser reutilizada sem remover pedido ou histórico anterior.
- Toda operação de cliente máquina é filtrada por `client_id`. Isso inclui listagem, UUID direto, timeline e qualquer subrecurso. UUID inexistente e UUID fora do escopo do `client_id` autenticado retornam a mesma resposta `404`, sem diferença no corpo que revele existência.
- `X-Correlation-Id` é aceito se válido ou gerado pela API. Resposta retorna o ID para rastreamento. Não aceitar valores arbitrariamente longos.
- Paginação proposta: `page` começando em 0, `size` default 20 e máximo 100, ordenação whitelist (default `createdAt,desc`).
- Erros seguem Problem Details (RFC 9457) com `type`, `title`, `status`, `detail`, `instance`, `code`, `correlationId`; `errors[]` opcional contém campo/código/mensagem segura. Nunca incluir stack trace.

## DTOs

### `CreateOrderRequest`

```json
{
  "externalReference": "ERP-12345",
  "currency": "USD",
  "shipping": {
    "originZoneCode": "ZONE-A",
    "destinationZoneCode": "ZONE-B",
    "totalWeightGrams": 1250
  },
  "items": [
    { "sku": "SKU-001", "description": "Item sintético", "quantity": 2, "unitPrice": 19.95 }
  ]
}
```

- `externalReference`: opcional/informativo; sem unicidade aprovada.
- `currency`: requerido; 3 letras maiúsculas (ISO 4217 proposta).
- `shipping.originZoneCode`, `destinationZoneCode`: códigos sintéticos obrigatórios, validados contra conjunto permitido; não são endereço.
- `shipping.totalWeightGrams`: inteiro positivo usado pelo simulador; não se recebe peso por item nem se consulta catálogo nesta versão.
- `items`: pelo menos um; cada `sku` não vazio, `quantity > 0`, `unitPrice >= 0`, limite de tamanho/quantidade a fixar.
- `total` não é enviado/confiado ao cliente: API calcula a soma dos itens.
- O valor de frete é calculado deterministicamente pelo adaptador simulado e persistido como resultado da integração; não é uma cotação comercial.

### `OrderResponse`

```json
{
  "id": "uuid",
  "externalReference": "ERP-12345",
  "status": "RECEIVED",
  "currency": "USD",
  "shipping": { "originZoneCode": "ZONE-A", "destinationZoneCode": "ZONE-B", "totalWeightGrams": 1250 },
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

Proposta de representação: `OrderSummary` omite `items` e `OrderResponse` de detalhe os inclui. Confirmar os schemas e exemplos ao elaborar OpenAPI; respostas nunca expõem entidades JPA.

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

`reason` é obrigatório. Reprocessamento apenas por pessoa com role `OPERATOR`/`ADMIN`; client credentials não pode solicitar. Uma geração nova é criada; o worker determina quais etapas refazer pelo grafo de dependências versionado, começando na etapa falha e incluindo descendentes invalidados. Preserva sucesso anterior apenas quando regra/versão, hash de entradas e pré-requisitos ainda coincidem; mantém todo histórico.

```json
{
  "orderId": "uuid",
  "processingGeneration": 2,
  "status": "RECEIVED",
  "reason": "Falha simulada corrigida para demonstração"
}
```

## Endpoints

| Método e caminho | Parâmetros/headers/body | Sucesso | Erros principais | Acesso proposto |
|---|---|---|---|---|
| `POST /orders` | Bearer; `Idempotency-Key`; `X-Correlation-Id` opcional; `CreateOrderRequest` | `201`, `Location`, `OrderResponse` | `400` JSON/validação/header; `401`; `403`; `409` chave reutilizada diferente; `413` limite de payload; `503` banco indisponível | client `orders:write`; pedido fica associado ao `client_id` autenticado |
| `GET /orders` | `page`, `size`, `sort`; filtros `status`, `externalReference`, `createdFrom`, `createdTo` | `200 PageResponse<OrderSummary>` | `400` filtro/paginação inválidos; `401`; `403` | `VIEWER`/`OPERATOR`/`ADMIN` leitura operacional; client `orders:read` apenas seus pedidos, filtro imposto no servidor |
| `GET /orders/{id}` | path UUID | `200 OrderResponse` | `400` UUID inválido; `401`; `403`; `404` inexistente ou fora do escopo do client | usuário com leitura; client `orders:read` com `client_id` igual ao pedido |
| `GET /orders/{id}/timeline` | path UUID; paginação se histórico crescer | `200 PageResponse<TimelineEntry>` | `400`; `401`; `403`; `404` inexistente ou fora do escopo do client | leitura humana operacional; client `orders:read` com verificação de ownership |
| `POST /orders/{id}/reprocess` | Bearer; `X-Correlation-Id`; `ReprocessOrderRequest` | `202 Accepted`, `Location` para pedido/tentativa e `ReprocessResponse` | `400` motivo inválido/ausente; `401`; `403`; `404`; `409` estado não `FAILED`/reprocessamento já em andamento; `503` se gravação não persistir | pessoa `OPERATOR`/`ADMIN`; client proibido |
| `GET /integrations` | paginação/filtros de tipo/status se necessários | `200 PageResponse<IntegrationSummary>` | `400`; `401`; `403` | leitura operacional |
| `GET /integrations/{integrationType}/executions` | path enum `FREIGHT` ou `BILLING`, paginação | `200 PageResponse<IntegrationExecution>` | `400` tipo/paginação inválidos; `401`; `403` | leitura operacional |
| `GET /dashboard/summary` | janela `from`/`to` opcional proposta | `200 DashboardSummary` | `400`; `401`; `403` | usuário com leitura operacional |

`integrationType` identifica o tipo lógico do adaptador (`FREIGHT` ou `BILLING`), não uma instância configurável. O modelo atual não define entidades de integração configuráveis; por isso não há UUID de integração neste recurso. Endpoints operacionais de integrações/dashboard são humanos no baseline; clients recebem `403`.

`GET /health` e endpoints de health/metrics são operacionais, não contratos de negócio; serão definidos na Fase 1/8 com exposição restrita conforme o caso.

## Erros e semântica

| Status | Uso proposto | Exemplo |
|---|---|---|
| `400 Bad Request` | JSON malformado, campos inválidos, filtros/paginação fora dos limites. | `quantity` zero. |
| `401 Unauthorized` | Sem token, token malformado, expirado, assinatura ou issuer inválidos. | Sem `Authorization`. |
| `403 Forbidden` | Token válido, mas sem authority exigida. | `VIEWER` solicita reprocessamento. |
| `404 Not Found` | Recurso inexistente ou fora do escopo autorizado; pedidos e subrecursos de clients retornam a mesma resposta nos dois casos. | UUID sem pedido ou pertencente a outro `client_id`. |
| `409 Conflict` | Recurso/estado não permite operação ou idempotency key usada com outro payload. | Pedido já em processamento. |
| `413 Content Too Large` | Corpo excede limites configurados. | Lista abusivamente grande. |
| `429 Too Many Requests` | Só se uma política de rate limiting for aprovada; não está exigida ainda. | Limite por principal. |
| `500 Internal Server Error` | Erro inesperado sem detalhes internos. | Falha não classificada. |
| `503 Service Unavailable` | Dependência necessária indisponível para persistir a aceitação. | PostgreSQL fora do ar. |

## Matriz de autorização aprovada como baseline

| Endpoint | Viewer | Operator | Admin | Client Credentials |
|---|---:|---:|---:|---:|
| Criar pedido | Negado por padrão | Negado por padrão | Negado por padrão | `orders:write`; associa `client_id` autenticado |
| Listar/detalhar/timeline | Sim | Sim | Sim | `orders:read`; todas as queries filtradas por `client_id`, inclusive UUID |
| Reprocessar | Não | Sim | Sim | Negado por padrão |
| Integrações/dashboard | Sim, leitura operacional | Sim | Sim | Negado |

Um UUID não é autorização. Para clients, o serviço aplica `client_id` no predicado de banco antes de retornar pedido ou subrecurso. Recurso inexistente e recurso de outro client têm mesmo status e corpo público `404`; essa política está definida, não pendente.

## Definições e portões do contrato

- **Obrigatórias antes da Fase 1:** semântica de autorização por principal e `client_id`; resposta `404` uniforme para UUID inexistente/fora do escopo; formatos dos recursos principais; semântica de criação/replay idempotente; fluxo Outbox e códigos HTTP fundamentais. Estes pontos estão definidos neste documento.
- **Durante a elaboração do OpenAPI na Fase 1/2:** traduzir o contrato para schemas, exemplos, enumerações, formatos e limites técnicos de campos. Isso não pode criar regra de negócio nova. A lista permitida de zonas/moedas e limites numéricos/tamanhos deve ser publicada junto à validação de entrada; se isso exigir regra de negócio ainda ausente, apresentar a lacuna ao proprietário. Confirmar também se listagens usam DTO resumido e quais defaults de paginação e janela do dashboard serão documentados.
- **Fora do escopo inicial ou condicionado a decisão posterior:** rate limiting (`429`), health/metrics como contrato de negócio, unicidade de `externalReference`, filtros adicionais e políticas de produção. Não são pré-requisitos para iniciar a Fase 1.

Proposta técnica já registrada: paginação inicia em `page=0`, `size=20`, máximo 100 e whitelist de ordenação com `createdAt,desc` por padrão; formalizar defaults no OpenAPI. `GET /integrations/{integrationType}/executions` usa os tipos estáveis já existentes no domínio: `FREIGHT` e `BILLING`. A janela padrão do dashboard e os filtros exatos podem ser registrados ao escrever OpenAPI, sem alterar a semântica de resumo por janela.

## Como validar o contrato

- OpenAPI é fonte executável do contrato HTTP e precisa refletir DTOs/códigos reais.
- Testes API cobrem status, headers, Problem Details e regras de permissão.
- Testes de integração provam unicidade/concorrência da idempotência no PostgreSQL.
- Teste de cliente real ou roteiro curl cobre `201`, replay idempotente e conflito `409`.
- Verificar que campos sensíveis/entidades internas não aparecem em responses.

## Referências

- [RFC 9457 — Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html)
- [RFC 9110 — HTTP Semantics (201, 202, 409, 503)](https://www.rfc-editor.org/rfc/rfc9110.html)
