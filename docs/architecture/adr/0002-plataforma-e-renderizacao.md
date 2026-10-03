# ADR 0002 — Plataforma e renderização do MVP

## Estado

**Aceita provisoriamente em 1 de outubro de 2026.**

## Decisão

- Plataforma do MVP: computadores desktop.
- Alvo primário de distribuição: Windows 10 ou superior, 64 bits.
- Alvo de desenvolvimento e validação contínua: macOS em Apple Silicon.
- Linux será mantido compatível quando não gerar trabalho específico relevante, mas não bloqueia o MVP.
- Renderer: Compatibility, suficiente para 2D e mais amplo em hardware desktop.
- Janela lógica inicial: 1280 × 720, redimensionável.
- Física e gameplay: 60 atualizações por segundo.
- Texturas de pixel art: filtro nearest, sem mipmaps quando não houver redução de escala.
- Interface usa coordenadas independentes da arte e precisa permanecer legível em painéis de 640 × 360.

## Hipóteses a validar

- Quatro painéis de 640 × 360 preservam HUD e antecipações de combate.
- Compatibility sustenta efeitos e iluminação planejados sem perda de identidade.
- O Mac M1 com 8 GB suporta editor, quatro Viewports e ferramentas do projeto com margem adequada.

## Consequências

- O MVP não depende de Web, mobile ou console.
- Resolução de arte e escala final só serão travadas depois do teste visual dos quatro painéis.
- Exportações Windows precisam ser testadas em hardware Windows real antes do beta.
