# Plano de conteúdo — FlowBridge

## Princípio editorial

Publicar quando houver uma ideia técnica que valha compartilhar, uma decisão com trade-off real ou uma demonstração que possa ser verificada. As fases são marcos para revisar o que mudou, não uma obrigação de produzir um post para cada pequena tarefa. Combinar assuntos relacionados em uma narrativa quando isso deixa o aprendizado mais claro.

O status abaixo descreve planejamento editorial. Nada na tabela afirma que uma funcionalidade já existe.

## Trilhas e oportunidades de publicação

| Momento sugerido | Assuntos que podem formar um post | Evidência necessária antes de escrever | Estado editorial |
|---|---|---|---|
| Kickoff / Fase 0 | Objetivo do portfólio; aprendizado como parte do projeto; uso transparente de IA; escopo ainda em planejamento; repositório público. | Escopo aprovado ou declarar que o planejamento está em andamento. Não alegar implementação. | Rascunho atualizado em `01-project-kickoff.md`; aguardando revisão e aprovação do proprietário. |
| Fechamento da Fase 0 | Planejamento e arquitetura; monólito modular + worker; contratos; decisões, alternativas e questões ainda abertas. | ADRs/requisitos revisados e decisões aprovadas; explicar que diagramas são propostas quando ainda pendentes. | Planejado; criar post apenas após validação da fase. |
| Fase 1 | Java e Spring Boot; estrutura do backend; Maven Wrapper; Angular CLI; Docker/Compose, redes, volumes e health checks. | Builds/comandos reais e serviços funcionando; diferenciar esqueleto de funcionalidades. | Planejado; possível combinar tooling e ambiente em uma história. |
| Fase 2 | Backend modular e API REST; modelo de pedido; SQL/PostgreSQL e migrations; validação e contrato HTTP. | Endpoint realmente implementado, migrations/testes executados e resposta real revisada. | Planejado; separar TDD se houver um aprendizado específico. |
| Fases 2–3 | TDD e testes automatizados: ciclos RED → GREEN → REFACTOR; diferença entre unitário e integração; idempotência e concorrência. | Mostrar um teste realmente executado, motivo da falha inicial e comportamento final; não inventar cobertura. | Planejado; juntar idempotência ao post de TDD se a história ficar mais forte. |
| Fase 4 | OAuth 2.0, OIDC, Keycloak, PKCE; autenticação x autorização; roles/scopes e proteção no backend. | Fluxo real e testes 401/403/permitido; nunca expor tokens/segredos. | Planejado; publicar após integração funcionar. |
| Fase 5 | RabbitMQ, broker/exchange/queue, evento versionado, worker e consistência eventual. | Evento observado com broker real/teste de integração; demonstrar estado e limites de redelivery. | Planejado; combinar conceitos de mensageria com resultado do worker. |
| Fase 6 | Idempotência do consumidor e Outbox Pattern; janela de dupla escrita; retry/backoff, DLQ e reprocessamento. | Testes de falha realistas e limites conhecidos; não alegar exactly-once. | Planejado; pode render um ou dois posts se houver dois aprendizados distintos. |
| Fase 7 | Angular e construção do dashboard; integração com REST/OIDC; estados de loading/erro/vazio/sucesso e acessibilidade. | Capturas da aplicação realmente implementada com dados sintéticos e autorização real. | Planejado; publicação de uma demonstração útil, sem tratar mock como produto pronto. |
| Fases 1 e 8 | Docker/Compose, CI/CD, observabilidade, logs/correlation ID e métricas. | Configuração, pipeline, testes e logs inspecionados; não expor endpoints/segredos internos. | Planejado; compartilhar quando houver um ciclo de ponta a ponta. |
| Fase 9 / conclusão | Demonstração final; o que foi aprendido; limites, falhas resolvidas e o que ainda evoluiria; papel da IA. | Clone limpo, README e comandos validados; claims conferidos com o código final. | Planejado; post de encerramento apenas após aceite final. |

## Cadência sugerida

Sem calendário rígido. Como referência, de 5 a 8 publicações ao longo do projeto podem cobrir kickoff, planejamento, backend/TDD, segurança, mensageria/confiabilidade, dashboard/observabilidade e conclusão. Combinar ou pular marcos se uma fase não trouxer aprendizado demonstrável. Uma pausa ou atraso também não precisa virar post.

## Como atualizar o plano

Ao fim de cada fase, avaliar:

1. O que mudou no código que pode ser demonstrado?
2. Que comando de teste foi realmente executado e qual foi o resultado observado?
3. Qual conceito ficou mais claro para o proprietário, segundo a revisão dele?
4. Qual decisão ou desafio é útil para outras pessoas desenvolvedoras?
5. O que ainda está planejado, incompleto ou incerto?
6. Existe material visual seguro e fiel ao estado real?

Se não houver respostas apoiadas por evidência, registrar o estado e esperar por um marco com conteúdo. Todo texto continua sendo rascunho até aprovação explícita; publicação externa não faz parte deste fluxo.
