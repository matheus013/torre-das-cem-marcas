# ADR 0019 — Andares, chefes, perigos e recordes da Torre

## Estado

Aceita em 2 de outubro de 2026. Substitui o Pátio fixo e a sala especial da Câmara Refeita (ADR 0017 e decisões 526 e 528) por cem andares gerados a partir de dados.

## Contexto

A Torre tinha um único mapa (Pátio das Marcas) do tamanho de uma tela e uma sala de chefe lateral. O pedido era cobrir os dez biomas da divisão do documento 05 com um chefe por bioma, andares comuns enormes para explorar, arenas pequenas e difíceis para os chefes, respawn que acelera com o tempo e recordes de tempo por tamanho de grupo.

## Decisão

### Conteúdo

- `tools/content/build_tower.py` gera `data/tower/tower_content.json`: biomas (tile, props, ambiente, perigo, elenco, materiais), cem andares (nome do documento regional, tipo, tamanho, cota, multiplicadores de profundidade, semente), onze chefes com kits e as habilidades extras por tamanho de grupo. O mesmo script registra os sprites de cada bioma em `art/manifest.json` e `art/process.json` para o PixelForge.
- `TowerContent` (`src/gameplay/world/tower_content.gd`) carrega o arquivo uma vez. A simulação soma inimigos, raças, itens e tabelas da Torre ao catálogo do beta.

### Layout

- `FloorLayout` (`src/gameplay/world/floor_layout.gd`) gera o mapa de forma determinística a partir da semente do andar: obstáculos com pegada sólida, cristas que formam corredores, pontos de patrulha, entrada, portal de retorno e escada. Andares de chefe são arenas circulares cercadas por props.
- Host e clientes geram o mesmo layout; só o número do andar trafega no snapshot. Uma grade espacial de 128 unidades limita a colisão às células vizinhas.

### Simulação

- A zona `tower` passa a ser sempre o andar ativo (`current_floor`). O grupo atravessa os andares junto: a escada leva todos os jogadores do andar.
- `start_floor` cria a população em matilhas com a escala de profundidade, ou o chefe com seu kit. `floor_run` guarda tempo, abates, cota, escada aberta, pico de jogadores e se a corrida já foi registrada.
- Monstros têm território (`home`), patrulham e só perseguem dentro de 520 unidades. Dano os provoca e acorda vizinhos; afastar-se demais de casa encerra a perseguição.
- O respawn usa os pontos de patrulha do andar, longe do grupo, com intervalo que cai com o tempo no andar.
- Chefes e perigos criam telegrafias (`Telegraph`: círculo, anel e retângulo) resolvidas ao fim do aviso, com empurrão, puxão, investida ou zona persistente. Chefes trocam de fase pela Vida, entram em fúria pelo tempo e ganham habilidades extras pelo tamanho do grupo.
- Recordes: `records[andar][modo]` guarda os cinco melhores tempos. O evento `record` faz o host gravar `user://aresta_floor_records.json`; o menu mostra o mapa da Torre e os recordes.
- O jogador ganha 3% de potência por nível e a escala de atributos declarada em cada gema, para acompanhar a profundidade.

### Apresentação

- A cena desenha o chão do bioma, a arena, o portal (selado durante o chefe), a escada (selada até a cota), telegrafias com preenchimento progressivo, zonas de perigo, luzes do andar e a barra do chefe. Props e inimigos fora da câmera não são desenhados.
- A aba TORRE (tecla `T`) lista os andares alcançados, recordes por modo e permite escolher o andar de partida.

### Calibragem

- `tools/bench/balance_probe.gd` roda andares de amostra sem janela, em solo ou em grupo (`-- --party=4`), e mede tempo, dano sofrido, quedas e derrotas. Os multiplicadores de Vida dos chefes e o dano do Regente ficam em `BOSS_HEALTH_CALIBRATION` e `REGENTE_DAMAGE_SCALE` no gerador, que também escreve o documento 75.

## Consequências

- `tests/tower_floors_test.gd` verifica biomas, chefes, layouts, habilidades em área, combinações de grupo, perigos, patrulha e recordes.
- Medição com quatro jogadores e 162 monstros no andar 60: 3,9 ms por quadro em média, picos de 15 ms; snapshot comprimido de cerca de 6 KB.
- A sala especial (`SpecialBossRoomState`) deixou de ser usada pela simulação; o andar 4 é a Câmara Refeita.
- Interpretar o layout no cliente evita tráfego, mas exige que host e cliente usem o mesmo `tower_content.json`.
