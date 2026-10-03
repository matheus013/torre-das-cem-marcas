# ADR 0005 — Combate de hordas e entrada

## Estado

**Aceita em 1 de outubro de 2026.**

## Contexto

O combate foi redefinido para priorizar pressão de hordas e decisões de posicionamento. O jogador move com o mouse, ataques básicos acontecem automaticamente e quatro habilidades ativas usam `Q`, `W`, `E` e `R`.

## Decisão

- Botão direito define ou atualiza um destino no chão.
- Cursor define alvo ou direção das habilidades que precisam de mira.
- Ataque básico automático é parte da simulação autoritativa.
- `Q/W/E/R` são quatro comandos semânticos estáveis, embora o efeito varie por personagem.
- Cliente pode prever deslocamento e apresentação, mas host confirma posição, recarga, acerto e resultado.
- Alvos automáticos usam consulta espacial e critérios por kit, sem varrer todos os inimigos a cada ataque.
- Hordas usam agregação espacial, limites de efeitos e atualização distribuída para preservar desempenho.
- Navegação começa simples na prova; mapas finais exigem navegação compatível com grande quantidade de agentes.

## Critérios da prova

- Um host e um cliente movem personagens independentes por destino.
- O host mantém estado canônico de jogadores e inimigos.
- Ataques automáticos removem alvos válidos sem comando manual.
- `Q/W/E/R` chegam ao host, respeitam recarga e produzem efeito replicado.
- A tela permanece legível com ao menos quatro jogadores e uma horda representativa do recorte.

## Consequências

- Os quatro kits aprovados precisam ser convertidos para a nova gramática sem perder mecanismo autoral.
- Câmera compartilhada, split-screen, mira manual permanente e três técnicas deixam de orientar código e interface.
- O sandbox de combate antecede a adaptação completa de inventário, progressão e mapas.
