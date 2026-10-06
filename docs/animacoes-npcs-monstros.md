# Animacoes de NPCs e monstros

Entrega validada em 2026-10-06: 17 NPCs e 55 inimigos, incluindo chefes,
regenerados no padrao visual dos players, sem PixelForge. Sao 72 atlas
de 256x256, cada um com 16 quadros de 64x64: frente, esquerda, direita e
costas; quatro fases por direcao, reproduzidas a 8 quadros/s.

Fontes e descricoes autorais: `art/actor-animations.json` e
`art/raw/animations/{npcs,enemies}`. Retratos estaticos tambem substituidos.
O importador identifica os intervalos transparentes reais da folha, evitando
cortar sprites quando a grade gerada tem espacamento desigual. Uma escala
comum por folha preserva proporcoes e o ponto dos pes permanece consistente.

NPCs e inimigos preservam a direcao de movimento no snapshot cooperativo.
Inimigos bloqueados ou parados deixam de pedalar no lugar. Chefes usam
escala visual 1.75, sem alterar colisao, alcance ou atributos de combate.
AtlasTexture fica em cache; o desenho estatico permanece como fallback.

Validacao: 1.152 poses distintas por ciclo/direcao, atlas completos,
ancoras, recortes, cache, idle, direcao de movimento e cortes adaptativos.
Auditoria das 72 fontes terminou sem silhuetas tocando os limites dos
recortes. Capturas reais por GPU verificaram todos os atores, quatro
direcoes e quatro fases, alem de capturas da vila e combate.
Validacao da entrega em copia isolada do trabalho concorrente; o estado
compartilhado de gameplay tem alteracoes em andamento e requer sua propria suite.

Reproduzir:

```sh
node tools/art/sync_actor_animation_pipeline.mjs
godot --headless --path . --script tools/art/import_character_animations.gd
sh tools/release/import.sh
godot --headless --path . --script tools/art/audit_actor_sources.gd
godot --headless --path . --script tests/actor_animation_test.gd
godot --path . --script tools/art/actor_animation_shots.gd
```

Ataques, morte e dano quadro a quadro continuam pendentes. Esta entrega
conclui locomocao, nao todo o pacote de arte nem os criterios da Steam.
