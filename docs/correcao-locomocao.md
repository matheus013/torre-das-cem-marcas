# Correcao de repouso e caminhada

Revisao de 2026-10-07 dos quatro protagonistas e dos 17 modelos de NPC.
Os moradores que compartilham um modelo recebem a mesma correcao.

## Problemas encontrados

- A pose parada usava a segunda coluna da caminhada: personagens ficavam
  congelados no meio de um passo.
- A fase dos NPCs dependia da coordenada X no mapa, causando saltos no ciclo.
- O relogio global iniciava caminhadas no meio do ciclo e nao acompanhava
  a distancia percorrida.

## Implementacao

Fontes v3 geradas pelo OpenAI imagegen, sem PixelForge, com cinco colunas e
quatro direcoes: frente, esquerda, direita e costas. A primeira coluna e
repouso, as quatro seguintes sao fases de caminhada. Sao 20 poses por modelo,
420 no conjunto de protagonistas e NPCs.
Referencias e prompts usados estao em `art/locomotion-generation.json`.

O importador separa `*_idle.png` (64x256) e `*_walk.png` (256x256).
Uma escala comum preserva as proporcoes; os pes terminam na linha 60 de cada
celula de 64x64. O retrato estatico vem do repouso, nao de um passo.
O recortador aceita grades 4x4 e 5x4 com intervalos transparentes desiguais.

Cada protagonista/NPC tem sua propria fase baseada em deslocamento.
Parar, teleportar ou trocar personagem reinicia a fase. A direcao de repouso
continua sendo a ultima direcao do snapshot. Registros de atores removidos
sao descartados. Nada disso altera colisao, dano ou velocidade de movimento.

Os 55 inimigos mantem suas folhas v2 e o fallback de repouso anterior.
Sua reproducao nao depende mais da coordenada X. Este trabalho nao inclui
novas animacoes quadro a quadro de ataque, dano ou morte.

## Reproduzir a verificacao

```sh
godot --headless --path . --script tools/art/import_character_animations.gd
sh tools/release/import.sh
godot --headless --path . --script tools/art/audit_actor_sources.gd
godot --headless --path . --script tests/character_animation_test.gd
godot --headless --path . --script tests/actor_animation_test.gd
godot --headless --path . --script tests/actor_locomotion_test.gd
godot --path . --script tools/art/locomotion_shots.gd
```

As pranchas de GPU em `art/shots/locomotion` mostram repouso e caminhada
lado a lado, nas quatro direcoes e fases. Os testes verificam cobertura,
quadros distintos, ausencia de cortes, alinhamento, cache e reinicios.
Isso nao substitui playtests externos de qualidade de animacao.

Validacao final: 68 testes aprovados, zero falhas, em copia isolada de
`ac1c53a` com as alteracoes desta entrega; inclui os dois testes de rede.
Auditoria das 76 fontes (21 humanoides v3 e 55 inimigos v2) sem silhuetas
cortadas. Pranchas de GPU cobrem os 21 modelos e capturas reais da vila foram
conferidas. O checkout compartilhado tem gameplay concorrente em alteracao;
essa suite nao declara aprovadas as alteracoes ainda nao incluidas na copia.
Executavel macOS release exportado da mesma copia passou no autoteste fora
do checkout, incluindo presenca dos atlas de repouso de protagonistas e NPCs.
O autoteste de pacote passa a exigir esses atlas nas tres plataformas do CI.

## Backup

Antes das alteracoes foi salvo, fora do repositorio:
`../backups/game-dev-2026-10-07-before-idle-walk-fix.tar.gz`.

SHA256: `9e6eaef9bbdd113523d9043b56b311d28699b6f2adb931928fa068e4eb9e1e4a`.
As fontes v2 tambem permanecem no historico e em `art/raw/animations`.
