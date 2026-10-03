# ADR 0018 — Simulação do mundo e sessão online de Aresta

## Estado

Aceita em 2 de outubro de 2026. Aplica a ADR 0004 (host autoritativo) ao jogo principal e completa a ADR 0007 (gemas de habilidade) no combate.

## Contexto

A cena `village_exploration.gd` concentrava regras, estado e desenho de uma única personagem. O Marco 1 exige que um host e três clientes compartilhem Aresta e a Torre sem divergência, e o sistema de gemas tinha resolvedor e laboratório, mas suportes, evoluções e níveis não participavam do combate.

## Decisão

### Separação entre simulação e apresentação

- `WorldSimulation` (`src/gameplay/world/world_simulation.gd`) é um `RefCounted` sem nós que contém todo o estado autoritativo: até quatro jogadores por `peer_id`, zonas, inimigos, projéteis, efeitos persistentes, salas especiais, respawn, escalada de ameaça, EXP, equipamento, gemas e salvamento.
- `WorldLayout` (`src/gameplay/world/world_layout.gd`) guarda mapas, portas, peças de cenário e obstáculos como dados estáticos compartilhados pela simulação e pelo desenho.
- A simulação só se comunica por três saídas: `view_snapshot()` (estado compacto para desenho), `drain_events()` (efeitos visuais por zona, mensagens por jogador e limpeza de efeitos) e `menu_model(peer)` (dados do menu do jogador).
- `village_exploration.gd` passou a ser apresentação e sessão: lê entrada, envia intenções, desenha o snapshot e aplica eventos. Não altera estado de jogo diretamente.

### Sessão

- Modos: `solo` (host local sem rede), `host` (ENet, porta padrão 7777) e `client`. `SessionLaunch` (`src/core/net/session_launch.gd`) transporta o pedido do menu ou de `--host-session`, `--join-session=IP` e `--session-port=N`.
- Clientes enviam somente intenções: movimento (`unreliable_ordered`) e ações (`reliable`: skill, item rápido, personagem, atributo, marco, equipar, retirar, gema do slot, suporte, evolução e pedido de menu). O host valida tipo e faixa de cada argumento antes de chamar a simulação.
- O host simula a cada quadro físico, envia eventos assim que ocorrem e snapshots a 20 Hz. Clientes interpolam posições de jogadores e recebem o modelo do menu sob demanda.
- Um peer só vira jogador depois do `hello` com seu perfil (`ProfileIdentity`, `user://aresta_profile.cfg` ou `--profile=`). O host então reconecta a personagem reservada desse perfil ou cria um jogador novo.
- Desconexão reserva a personagem por `RECONNECT_GRACE` (60 s): ela para, não recebe comandos, não é alvo nem sofre dano. Reconectar transfere estado, efeitos e eventos agendados para o novo `peer_id`. Ao expirar, a carga na arena se perde e o jogador sai. Perda do host devolve o cliente ao menu.
- Snapshots viajam como `var_to_bytes` comprimido com zstd e tamanho original; o cliente rejeita tamanhos acima de 1 MB e qualquer conteúdo que não seja dicionário.
- Solo e host executam exatamente o mesmo caminho de intenções; a diferença é apenas o transporte.

### Regras cooperativas adotadas

- Personagens são únicas por sessão; a primeira livre é atribuída ao entrar e a troca só ocorre fora da Torre.
- Inimigos perseguem o jogador mais próximo na arena; projéteis inimigos atingem qualquer jogador.
- EXP de uma baixa vai inteira para todos os jogadores na arena; saque vai para quem derrotou.
- Entrar na Câmara Refeita leva todos os jogadores do Pátio; quem entra na Torre durante o confronto vai direto para a sala; vencer e sair devolve todos ao Pátio.
- Santuário cura aliados no raio; barreiras com `allies_receive_barrier` alcançam aliados próximos.
- Gemas, equipamento e progresso pertencem à personagem, não ao jogador.
- Escalonamento por grupo (`party_size`, `PARTY_SCALING`): a cada passo a simulação ajusta a capacidade de retorno, o limiar de chefes e a Vida de elites e chefes a partir de `base_max_health`, preservando a fração de Vida; `_update_reinforcements` completa a população-alvo pelo ponto de entrada mais distante do grupo; `reward_share` filtra o saque por baixa com sorteio determinístico. O snapshot inclui `party_size` e `party_budget`, mostrados no HUD da sessão.
- O salvamento pertence ao host (versão 7). `Esc` do host salva antes de encerrar. A versão 6, com equipamento único, é migrada para a personagem salva.

### Gemas no combate

- Cada personagem guarda quatro slots, suportes por slot e nível, EXP e escolhas de cada gema.
- Resolução: base → evoluções escolhidas por nível → suportes ordenados por id (`SkillEffectResolver`).
- Capacidade de suporte é `2 + nível da gema`, com no máximo dois suportes por slot, tags compatíveis e sem repetir suporte entre slots.
- Gemas ganham a mesma EXP da personagem; subir de nível exige `80 × nível` e a evolução do nível atual escolhida. O beta limita gemas ao nível 3.
- Troca de gema, suportes e evoluções só acontecem fora da Torre.
- Modificadores executados: contagem de projéteis em leque, perfuração, ricochete, homing, retorno, área no impacto, dano de rastro e chegada do dash, barreira na chegada, repulsão, lentidão, vulnerabilidade, barreira por acerto, atração, campos que seguem, excesso de cura em barreira, dano ao expirar, saltos reais de corrente, cura por salto, repetição no último alvo, repetições agendadas (eco), roubo de vida e chance crítica adicional.
- `extra_charge` vira cargas por slot (recarga uma a uma) e `stability` reduz o dano recebido dentro de santuários, limitada a 60%.

### Progressão e saque

- `MilestoneEffects` (`src/gameplay/progression/milestone_effects.gd`) agrega as escolhas de marco em modificadores, ajustes de passiva e mecânicas; a simulação guarda o resultado por personagem e o recalcula ao escolher, trocar de personagem ou carregar.
- `PassiveRuntime.configure` recebe os ajustes sobre `DEFAULTS`; sem marcos, as passivas reproduzem a decisão 520.
- As mecânicas de marco são executadas nos pontos de combate já existentes: uso de gema, acerto, baixa, dano recebido, passo do jogador e ataque automático. O catálogo valida que todo parâmetro e mecânica citados existem.
- `LootDifficulty` (`src/gameplay/loot/loot_difficulty.gd`) calcula a dificuldade da baixa e dela tira multiplicadores de chance e quantidade para `EnemyLootResolver`, a chance e o tier do item bônus e a fabricação dos equipamentos; todos os sorteios usam semente e sequência de baixas, mantendo o host determinístico. `EquipmentLoadout` aplica o fator de fabricação aos bônus.
- `ground_items` guarda o saque no chão com zona, posição, item, quantidade e tier. O snapshot envia `drops`, o salvamento guarda as pilhas e a coleta ocorre no passo de cada jogador conectado na arena.

## Consequências

- Regras novas entram na simulação e passam a valer em solo e online ao mesmo tempo.
- `tests/world_simulation_test.gd` cobre quatro jogadores, gemas e salvamento sem cena; `tests/village_exploration_smoke_test.gd` cobre a cena em solo; `tests/village_online_smoke.sh` executa host e três clientes em processos separados com piloto automático e verifica personagens únicas e salvamento sem divergência.
- Medição (`tools/bench/world_simulation_bench.gd`, quatro jogadores): 1,1 ms por quadro com 6 inimigos e 2,8 ms com 160; snapshot de 73 KB comprimido para 3,7 KB (cerca de 600 kbit/s por cliente). Snapshots acima do MTU ainda fragmentam; deltas e identificadores estáveis de inimigo ficam para depois.
- `tests/run_all.sh` executa todos os testes e as duas provas de rede; serve de base para a integração contínua.
- Agentes (`--autopilot`) e `tools/play_local_coop.sh` permitem observar quatro jogadores reais na mesma máquina.
- Clientes não interpolam inimigos; isso será revisto com mais latência real.
- O protótipo antigo da arena (`network_prototype`) permanece apenas como referência no menu dev.
