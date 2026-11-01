# ADR-001 — Monólito modular para API e worker separado

- **Status:** aceita como direção de arquitetura pelo guia principal; detalhes de ownership do banco aguardam validação.
- **Data:** 2026-11-01

## Contexto

O FlowBridge precisa receber pedidos por HTTP e executar integrações demoradas/falíveis de forma assíncrona. Vários microsserviços aumentariam infraestrutura e carga cognitiva antes de o domínio estar claro. Um único processo síncrono, por outro lado, obrigaria a API a esperar frete/faturamento e deixaria falhas externas dentro do ciclo da requisição.

## Decisão

Organizar a API como monólito modular com módulos de negócio (`orders`, `processing`, `integrations`, `outbox`, `identity`, `shared`) e executar o consumidor como worker Spring Boot separado. API e worker compartilham PostgreSQL nesta versão educacional e comunicam intenção/eventos por RabbitMQ, não por chamada HTTP síncrona entre processos.

Os módulos são limites de código no mesmo deployment da API, não serviços independentes. Criar abstrações somente quando houver regra/limite real; não abrir um projeto por módulo.

## Como funciona

O controller HTTP traduz contrato para caso de uso; domínio mantém regras/transições; infraestrutura implementa JPA, banco, broker e adaptadores. O worker lê um evento e executa o caso de uso de processamento em seu processo. PostgreSQL guarda fonte de verdade e histórico.

```mermaid
flowchart LR
  API[API modular\norders / processing / outbox / identity] --> DB[(PostgreSQL)]
  API --> OUT[Outbox publisher]
  OUT --> MQ[RabbitMQ]
  MQ --> W[Worker\nprocessing / integrations]
  W --> DB
```

## Problema resolvido e motivo

- Separa requisição rápida de trabalho lento.
- Torna testáveis as regras sem impor deployment distribuído a cada módulo.
- Ensina boundaries, consistência eventual e mensageria com custo local razoável.
- Permite observar disponibilidade/escala separada do worker quando isso for útil.

## Alternativas

- **Monólito totalmente síncrono:** mais simples, mas não atende processamento desacoplado e retry de mensagem.
- **Vários microsserviços com banco próprio:** fronteiras mais isoladas, mas traz comunicação, deploy, observabilidade e consistência distribuída desnecessários no escopo atual.
- **API e worker no mesmo processo:** menor operação inicial, mas piora isolamento de ciclo de vida; segue possível como alternativa se deployment local ficar excessivamente complexo.

## Consequências e limites

- API e worker acoplam-se ao contrato dos eventos e ao esquema PostgreSQL. Migrations precisam ser compatíveis com os dois; definir um dono lógico por tabela e um único processo migrador.
- Banco compartilhado é deliberado para primeira versão, não recomendação geral para microsserviços.
- A fila não oferece execução exatamente uma vez. Worker precisa tolerar redelivery.
- Um deployment simples não traz alta disponibilidade; HA/SLA estão fora de escopo.

## Como testar

Testes de domínio isolados; integração de migrations/repositories com PostgreSQL real; teste com RabbitMQ real para evento; prova de que iniciar API não inicia worker embutido; falha/restart e redelivery; revisão de que nenhuma regra crítica ficou dentro do controller.

## Aprovação pendente

O guia já fixa monólito modular + worker. O proprietário deve revisar especificamente banco compartilhado, dono de migrations e se o worker pode ler/gravar entidades selecionadas de forma direta.
