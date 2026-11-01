# Diretrizes visuais — FlowBridge

## Identidade

- **Azul-marinho:** base e áreas de fundo (`#071426`, `#0B1E36`). Comunica tecnologia sem competir com o conteúdo.
- **Ciano:** destaques, fluxo e nós principais (`#35D6E8`, `#73E6F2`). Usar com moderação.
- **Branco:** títulos e texto principal (`#F5FAFF`).
- **Azul-claro secundário:** texto auxiliar (`#A9C4D8`).
- **Acento opcional:** azul vivo (`#4D8DFF`) para estados/linhas; não introduzir cores de status sem significado.

## Composição

- Preferir layouts horizontais 1200 × 627 para ilustrações destinadas a uma publicação no LinkedIn.
- Manter um título curto, uma ideia central e espaço em branco. Evitar colocar o texto completo do post dentro da imagem.
- Usar nós, conectores, trilhas ou pontos para representar APIs, eventos e sistemas. Setas devem indicar uma direção compreensível.
- Preferir SVG editável e vetorial para diagramas conceituais. Não embutir logos/marcas de terceiros nem sugerir parceria.
- Utilizar fontes sem serifa comuns (`Inter`, `Segoe UI`, `Arial`, `sans-serif`) e tamanhos legíveis. Garantir contraste entre texto e fundo.
- A peça de kickoff deve dizer “planejamento” e “arquitetura conceitual”; não usar telas, números, badges de sucesso ou estados que pareçam produto funcional.
- Capturas futuras só podem mostrar produto realmente executado, com dados sintéticos e sem credenciais, tokens ou informação pessoal.

## Linguagem visual de arquitetura

- **API:** retângulo arredondado identificado como `API`.
- **Broker:** nó/cápsula identificada como `RabbitMQ` ou `Broker de mensagens`.
- **Worker:** retângulo identificado como `Worker`.
- **Banco:** cilindro ou forma equivalente identificada como `PostgreSQL`/`Banco`.
- **Outbox:** o pedido e o evento Outbox devem aparecer dentro de uma mesma fronteira de transação no PostgreSQL; a seta de publicação sai do Outbox Publisher após o commit e segue para RabbitMQ. Não desenhar publicação direta da API como fluxo final confiável.
- **Integrações externas:** grupo com nome “Frete”/“Faturamento simulados” ou “Integrações externas”; indicar explicitamente quando for conceitual.
- **Tecnologias planejadas:** listar como texto, por exemplo “Java • Spring Boot • Angular — planejadas”. Evitar logos oficiais sem necessidade.

## Acessibilidade e revisão

- Texto essencial deve existir como texto SVG, não apenas como forma.
- Fornecer `<title>` e `<desc>` no SVG; não depender somente de cor para comunicar estado.
- Revisar a imagem em escala reduzida de feed, confirmar que título/subtítulo continuam legíveis e que setas não cruzam rótulos.
- Incluir descrição alternativa ao publicar, explicando o diagrama em uma frase.
- Validar XML, viewBox/dimensões, links externos e textos antes de usar. A imagem só vai ao LinkedIn após aprovação manual do proprietário.
