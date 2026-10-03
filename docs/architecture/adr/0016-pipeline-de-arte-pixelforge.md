# ADR 0016 — Pipeline de arte com PixelForge

## Estado

Aceita em 2 de outubro de 2026. Substitui a parte da ADR 0012 e da decisão 496 que mantinha o protótipo somente em blockout geométrico.

## Contexto

O responsável pelo projeto pediu que a apresentação deixasse de ser blockout antes do fim do ciclo funcional. O PixelForge é uma API local e offline (SDXL-Turbo com o LoRA `pixel-art-xl`) que gera imagens por projeto, perfil de estilo e asset, guardando versões e seeds.

O modelo produz imagens de 512 ou 1024 px desenhadas em blocos de aproximadamente 8 × 8, com fundo branco imperfeito, objetos extras e cores fora de paleta. Elas não podem entrar no jogo sem tratamento.

## Decisão

- O PixelForge gera a arte-base; o repositório guarda o manifesto, as imagens brutas e o processamento, para que cada sprite seja reproduzível por chave e seed.
- `art/manifest.json` descreve cada asset: tipo, prompt, prompt negativo, seeds e tamanho. Prompts são escritos à mão; códigos hexadecimais de paleta não entram no prompt porque o modelo não os interpreta.
- `tools/pixelforge/pf.py` cria assets e jobs na API e baixa os resultados para `art/raw/`. Gerações existentes são reaproveitadas, salvo `--force`.
- `art/process.json` escolhe a imagem bruta de cada sprite final e seus parâmetros. `tools/art/process.sh` executa `tools/art/process_sprites.gd` no Godot headless.
- O processamento reduz blocos à grade real de pixels por moda de cor, remove o fundo conectado às bordas, mantém o corpo principal, recorta, ajusta à paleta de Aresta e aplica contorno de 1 px. Tiles usam redução de contraste e correção de cor em vez de paleta. O modo `split` transforma folhas com vários objetos em sprites separados.
- Sprites finais ficam em `assets/sprites/{characters,enemies,buildings,props,deco,tiles}` e são carregados por `SpriteLibrary`.

## Escala

- Um pixel de arte corresponde a um pixel de tela na janela lógica de 1280 × 720.
- Personagens e inimigos comuns usam bloco 12, com aproximadamente 44 px de altura; chefes usam bloco 8.
- Prédios, árvores e pilares são gerados em 1024 px com bloco 8, cerca de 128 px, mantendo prédios em torno de três alturas de personagem.
- Tiles de chão são gerados em 1024 px e reduzidos para 128 px.

## Apresentação no jogo

- Peças do cenário são posicionadas pela base do sprite e declaram área de colisão própria.
- Personagens, inimigos, invocações e cenário são ordenados por profundidade a cada quadro.
- Animação provisória é procedural: passo, respiração, espelhamento por direção, piscar de dano, sombra e camuflagem.
- Torre e interiores usam `CanvasModulate` e luzes 2D; a vila usa luz ambiente quente.
- Animações quadro a quadro ficam para depois: gerar cada quadro separadamente pelo modelo produz personagens inconsistentes.

## Pendências de arte

- Os ícones das 20 gemas (`assets/sprites/icons/<id_da_gema>.png`) e os oito sprites de efeito (`assets/sprites/vfx/`) estão no manifesto, mas ainda não foram gerados. O HUD e o `VfxLayer` já os carregam automaticamente quando existirem.
- O processador aceita `remove_all_background` (remove fundo enclausurado, útil para anéis) e `keep_all` (mantém partículas separadas).

## Consequências

- O jogo ganha identidade visual imediata, ainda sujeita a substituição por arte autoral.
- Arte gerada exige curadoria: escolher seeds, descartar objetos extras e revisar consistência de personagens.
- `art/raw/` ocupa espaço (cerca de 13 MB no primeiro pacote); `art/candidates/`, `art/shots/` e `art/preview.png` são descartáveis.
- A geração depende do PixelForge acessível na rede local; o jogo e os testes não dependem dele.
