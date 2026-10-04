# Aresta — A Torre das Cem Marcas

RPG de ação roguelike em pixel art para **um a quatro jogadores**, solo ou em cooperativo online. Na vila de Aresta, você monta seu quadro de expedição e desce a **Torre das Cem Marcas**: cem andares, dez biomas, um chefe guardando o fim de cada região e uma vila que se lembra do que você fez.

![A praça de Aresta](docs/images/vila-praca.png)

> **Estado:** beta jogável em desenvolvimento (Godot 4.6.3, GDScript). Números de combate, saque e progressão são provisórios e servem para playtest.

Preparação para distribuição: [roadmap Steam em acesso antecipado](docs/roadmap-steam-acesso-antecipado.md) e [registro de execução](docs/steam-ea-execucao.md). Builds release: `sh tools/release/build.sh all` (Windows e Linux; exige templates Godot 4.6.3). Artefatos em `builds/` ainda precisam de QA antes da publicação.

---

## Sumário

- [Como instalar e abrir](#como-instalar-e-abrir)
- [Como jogar](#como-jogar)
  - [Objetivo](#objetivo)
  - [Controles](#controles)
  - [As quatro personagens](#as-quatro-personagens)
  - [A vila de Aresta](#a-vila-de-aresta)
  - [A Torre](#a-torre)
  - [Chefes](#chefes)
  - [Gemas: suas habilidades](#gemas-suas-habilidades)
  - [Níveis, atributos e árvores de evolução](#níveis-atributos-e-árvores-de-evolução)
  - [Saque e equipamento](#saque-e-equipamento)
  - [Morrer na Torre](#morrer-na-torre)
  - [Recordes](#recordes)
- [Cooperativo online](#cooperativo-online)
- [Moradores com IA](#moradores-com-ia)
- [Para desenvolvedores](#para-desenvolvedores)

---

## Como instalar e abrir

1. Instale o **[Godot 4.6.3](https://godotengine.org/download/archive/4.6.3-stable/)** (versão padrão, não a .NET).
2. Clone o repositório:

   ```sh
   git clone https://github.com/matheus013/torre-das-cem-marcas.git
   cd torre-das-cem-marcas
   ```

3. Abra o jogo:

   ```sh
   godot --path . -- --public
   ```

   Isso abre a **tela de título**, como um jogador veria. Sem `-- --public`, o jogo abre no **modo dev**, com laboratório de build, editores de conteúdo e provas técnicas. Para ir direto à vila, use `godot --path . res://src/prototype/village/village_exploration.tscn`.

   Também dá para abrir a pasta pelo editor do Godot (**Importar** → `project.godot`) e apertar **F5**.

Na tela de título:

| Botão | O que faz |
|---|---|
| **JOGAR** | Aresta e a Torre em solo |
| **HOSPEDAR CO-OP** | abre seu mundo para até três amigos (porta 7777) |
| **ENTRAR EM CO-OP** | entra no mundo de um amigo pelo IP |
| **MORADORES (IA)** | escolhe o modo dos moradores: padrão ou com modelo de linguagem |
| **OPÇÕES** | vídeo, limite de FPS, VSync e volumes; preferências persistem entre sessões |

---

## Como jogar

### Objetivo

Desça a Torre andar por andar, derrote os monstros, recolha o saque e volte vivo para Aresta. Cada pedra regenerativa entregue fortalece a vila. Cada andar alcançado fica liberado como ponto de partida. Cada chefe derrotado abre o caminho para o próximo bioma. O fundo fica no **andar 100**.

### Controles

As teclas abaixo são os padrões. Em **OPÇÕES → Controles**, selecione uma ação e pressione a nova tecla; **Aplicar** grava a mudança. Conflitos no mesmo contexto são bloqueados. **Esc** cancela a captura e permanece reservado para a pausa. O movimento pelo botão direito do mouse continua disponível.

| Tecla | Ação |
|---|---|
| **Botão direito do mouse** (ou setas) | andar até o ponto; mantenha pressionado para seguir o cursor |
| **Q, W, E, R** | usar as quatro Gemas Ativas na direção do cursor |
| *(automático)* | ataque básico no inimigo mais próximo dentro do alcance |
| **1** | item rápido de cura (na Torre) |
| **E** | conversar com o morador mais próximo (na vila) |
| **I** | inventário e equipamento |
| **C** | personagem: atributos e evoluções |
| **G** | skills: gemas, suportes e evoluções de gema |
| **T** | Torre: mapa, recordes e andar de partida |
| **V** | trocar de personagem (fora da Torre) |
| **F5 / F9** | salvar / carregar o mundo (solo ou host) |
| **F6** | alternar os moradores entre modo padrão e com IA (solo ou host) |
| **Esc** | abrir opções e pausar no solo; no co-op o mundo continua. **Voltar ao menu** encerra a sessão (o host salva antes) |
| **H** | ligar/desligar a mira automática no inimigo vivo mais próximo da mesma zona |

O mapeamento inicial de controle usa os botões normalizados de Xbox e PlayStation:

| Ação | Xbox | PS4 / PS5 |
|---|---|---|
| Movimento / mira | analógico esquerdo / direito | analógico esquerdo / direito |
| Gemas 1 a 4 | LB, RB, X, Y | L1, R1, quadrado, triângulo |
| Conversar / confirmar | A | cruz |
| Cancelar | B | círculo |
| Item rápido | RT | R2 |
| Inventário | View | Share / Create |
| Personagem / gemas / Torre / trocar personagem | direcional cima / esquerda / baixo / direita | direcional cima / esquerda / baixo / direita |
| Pausa | Menu / Start | Options |
| Alternar mira automática | clicar analógico esquerdo (L3) | L3 |

Salvar, carregar e alternar moradores também estão na aba **Sessão** das opções. A mira automática é opcional, conserva a preferência e usa a mira manual quando não há inimigos. A navegação dos menus aceita direcional/analógico e confirmação/cancelamento. A configuração de IP do co-op e de provedores de IA ainda exige entrada de texto. Compatibilidade por USB/Bluetooth com controles físicos precisa de QA antes de anunciar suporte completo na Steam.

### As quatro personagens

Ao abrir o jogo você escolhe quem desce. Não existem classes: qualquer personagem usa qualquer gema e equipamento. O que muda é a **Passiva Autoral**, única de cada uma:

| Personagem | Passiva | Como funciona |
|---|---|---|
| **Eloa Ferral** | Luz Residual | acertos deixam resíduos de luz; a próxima gema os conduz até inimigos próximos |
| **Sena Rotavela** | Duas Correntes | repetir a mesma gema acumula Traçado (mais potência); variar acumula Desvio (mais velocidade, menos Fôlego) |
| **Cira Salvedra** | Placas Adaptativas | dano recebido vira uma amostra que reduz golpes, fortalece a próxima gema e, cheia, explode em área |
| **Rui Pedralva** | Oportunidade Estrutural | acertos perto de obstáculos revelam pontos no chão; pisar neles dá barreira e causa um impacto |

### A vila de Aresta

Aresta é seu porto seguro: casas, feira, forja, enfermaria, conselho, arquivo, plantações e trinta moradores com trabalho, casa e rotina. O período do dia avança a cada volta da Torre; à noite os lampiões acendem e a vila se recolhe.

- Converse com os moradores com **E**. Eles lembram suas expedições, pedras entregues, quedas e recordes.
- **Gemas e suportes só podem ser trocados na vila.** Na Torre o loadout fica travado.
- Ao voltar com pedra regenerativa, ela vai para o armazém. Com pedra suficiente, a vila ergue reforços.
- A entrada da Torre fica no edifício alto ao leste.

![Aresta à noite](docs/images/vila-noite.png)

### A Torre

São cem andares em dez biomas: Galerias Refeitas, Bosque dos Ventos Presos, Manto dos Esporos, Bacias do Quarto Pulso, Ermo do Trovão Preso, Arquivo das Rotas Mortas, Planície dos Adormecidos, Eixos Partidos, Campos do Quase e Obra Inacabada. Cada um tem monstros, materiais e um perigo de ambiente próprios.

- **Andares comuns são grandes.** Explore, ache matilhas e derrote monstros. Fora de combate eles patrulham; quando você chega perto, partem para cima.
- **Cota de abates:** a escada para o próximo andar fica selada até você derrotar monstros suficientes (veja *ABATES x/y* no topo da tela e no minimapa).
- **Respawn acelera:** quanto mais tempo você fica no andar, mais rápido os monstros voltam.
- **Perigos do bioma** aparecem como áreas laranja no chão (rajadas de vento, nuvens de esporos, descargas). Saia delas antes que o aviso se complete.
- **Portal de retorno:** na entrada de cada andar, leva você de volta a Aresta com tudo que carrega.
- Quanto mais fundo, mais fortes os monstros.

![Um andar do Ermo do Trovão Preso](docs/images/andar-ermo.png)

### Chefes

Cada região termina num **chefe em arena pequena**: Guardião de Enxerto (andar 4), O Refeitor (7), Pastor das Correntes (16), Guardiã do Nó-Mãe (27), Guardião da Comporta (39), Coroa dos Condutores (51), Guardião do Marco Cego (63), Pálpebra do Horizonte (72), Guardião do Eixo Zero (81), Guardião da Última Escolha (93) e o Regente Centésimo (100).

- A saída fica **selada** até o chefe cair.
- Ataques de área são anunciados por **formas vermelhas no chão** que se preenchem até o golpe: círculos, anéis (no anel, o seguro é colado ao chefe), linhas, cruzes, investidas, chuvas de área e puxões.
- Chefes mudam de fase ao perder vida e entram em **fúria** se a luta demora.
- Em grupo, ganham combinações de ataque extras.
- Derrotado, o chefe só volta depois de 20 minutos; até lá o andar é passagem livre.

![Pastor das Correntes](docs/images/chefe-pastor.png)

### Gemas: suas habilidades

As quatro teclas **Q, W, E, R** usam **Gemas Ativas** (projétil, investida, explosão, campo de atração, barreira, corrente, invocação, santuário). Na aba **Skills** (**G**), dentro da vila, você pode:

- trocar a gema de cada tecla;
- encaixar **Gemas de Suporte** (projéteis extras, perfuração, ricochete, área maior, eco, roubo de vida…), até dois por gema e conforme a capacidade;
- escolher a **evolução** de cada nível da gema. Gemas ganham a mesma experiência que a personagem.

![Aba de skills](docs/images/menu-skills.png)

### Níveis, atributos e árvores de evolução

- Personagens vão do **nível 1 ao 100**. Cada nível dá **+5 de Vida** e mais potência.
- Níveis comuns dão **5 pontos de atributo** (Vitalidade, Força, Inteligência, Agilidade, Sorte, Sabedoria). Cada gema escala com os atributos que declara.
- Os níveis **10, 20 … 100** oferecem uma **evolução** entre seis opções: Essência (fortalece a passiva), Adaptação (sobrevivência) e Convergência (grupo). Toda opção do nível 100 é uma mecânica nova.
- Ao chegar a um marco, a simulacao pausa e a tela de escolhas abre automaticamente; o jogo retoma depois das escolhas dos jogadores conectados.

### Saque e equipamento

- Catalogo atual: [36 skills e 40 suportes](docs/catalogo-gemas.md), incluindo multishot, ricochete, roubo de Vida e Folego.
- Cada personagem inicia com um [tipo de arma distinto](docs/armas-e-afinidades.md), com escala por atributos e afinidades percentuais.

- O saque **cai no chão**: passe por cima para recolher.
- Equipamentos e itens raros brilham e mostram o nome na cor do tier: Comum, Incomum, Raro, Épico, Lendário.
- Inimigos mais difíceis (elites, chefes, graus altos, afixos) e grupos maiores deixam **mais saque e de melhor qualidade**.
- Equipamentos têm **fabricação** (Improvisada, Regular, Refinada, Magistral), que aumenta os bônus da peça.
- Equipe pela aba **Inventário** (**I**). Equipar num espaço ocupado troca as peças.

### Cair e morrer na Torre

- **Em grupo:** com vida zero você **cai** por 20 segundos (14 na segunda queda, 8 na terceira). Um aliado parado ao seu lado por 3 segundos o **estabiliza**; você volta com 25% de vida e um Ferimento de Expedição (−10% de vida máxima até voltar à vila).
- **Derrota:** em solo, na quarta queda, se a janela acabar ou se o grupo inteiro cair, você volta a Aresta e **sua carga fica no chão** onde caiu. Volte ao mesmo andar para recuperá-la. Experiência e equipamento equipado não se perdem.
- Fora de combate, depois de 4 segundos sem levar dano, a vida se recupera aos poucos.

### Recordes

O tempo de cada andar entra nos recordes da aba **Torre** (**T**), separados por **SOLO, DUO, TRIO e SQUAD**. Andares comuns contam até a descida; andares de chefe, até a queda do chefe. Na mesma aba você escolhe em que andar já alcançado começa a próxima descida.

---

## Cooperativo online

Até quatro jogadores no mesmo mundo, com host autoritativo.

- **Hospedar:** tela de título → **HOSPEDAR CO-OP**. Libere a porta **7777** (UDP) se jogar pela internet.
- **Entrar:** tela de título → **ENTRAR EM CO-OP** → IP do host (`127.0.0.1` na mesma máquina).

Regras do grupo:

- cada personagem só pode estar com um jogador;
- a escada leva todo o grupo para o próximo andar;
- a experiência vai para todos no andar; o saque é de quem recolher;
- a dificuldade cresce com o tamanho do grupo (mais monstros, elites e chefes mais resistentes);
- quem cair da conexão tem 60 segundos para voltar com a mesma personagem;
- o mundo, o salvamento e os recordes ficam com o host.

Para testar sozinho com quatro janelas, cada uma jogada por um agente:

```sh
sh tools/play_local_coop.sh
```

---

## Moradores com IA

Os moradores têm dois modos (botão **MORADORES (IA)** ou **F6** durante o jogo):

- **Padrão:** a mente sistêmica do jogo decide o que cada morador faz e as falas são escritas à mão, usando fatos reais da sua campanha. Não precisa de nada além do jogo.
- **Com IA:** um modelo de linguagem escolhe entre as mesmas ações permitidas e escreve a fala com a personalidade de cada morador. Se o modelo falhar ou demorar, o modo padrão assume.

Provedores aceitos:

| Provedor | Exemplo de configuração |
|---|---|
| **Ollama** (local ou na rede) | endereço `http://127.0.0.1:11434`, modelo `qwen2.5:3b` (`ollama pull qwen2.5:3b`) |
| **Compatível com OpenAI** (LM Studio, llama.cpp, vLLM) | endereço do servidor, rota `/v1/chat/completions` |
| **Anthropic** | modelo `claude-haiku-4-5-20251001`, chave na variável `ANTHROPIC_API_KEY` |

A chave de API **nunca é gravada**: o jogo guarda só o nome da variável de ambiente. Também dá para configurar por linha de comando:

```sh
godot --path . -- --public --npc-mode=ia --npc-provider=ollama --npc-url=http://127.0.0.1:11434 --npc-model=qwen2.5:3b
```

---

## Para desenvolvedores

### Estrutura

| Pasta | Conteúdo |
|---|---|
| `src/gameplay/` | simulação autoritativa do mundo (`world/world_simulation.gd`), andares, gemas, progressão, saque e encontros |
| `src/simulation/npc/` | mente dos NPCs e vida da vila |
| `src/core/` | rede, modo dev e cliente de IA dos moradores |
| `src/prototype/village/` | cena principal: apresentação, sessão online, HUD e menus |
| `data/` | conteúdo do beta, da Torre e da vila (gerados por `tools/content/`) |
| `assets/sprites/` | sprites processados (gerados no PixelForge) |
| `docs/` | game design, arquitetura (ADRs) e roadmap |
| `tests/` | testes headless e provas de rede |
| `tools/` | geradores de conteúdo, pipeline de arte, benchmark e jogo local em co-op |

### Testes e balanceamento

```sh
sh tests/run_all.sh    # todos os testes headless e as provas de rede (host + 3 clientes)
godot --headless --path . --script tools/bench/balance_probe.gd             # sonda de balanceamento em solo
godot --headless --path . --script tools/bench/balance_probe.gd -- --party=4  # e em grupo
```

O GitHub Actions roda `tests/run_all.sh` a cada push em `main` (`.github/workflows/tests.yml`).

### Atalhos de desenvolvimento

- Modo dev (padrão): menu com Laboratório de Build, Central de Conteúdo e provas técnicas. `-- --public` mostra a tela pública; na tela pública, **F12** volta ao modo dev.
- **F7** (modo dev): ganha a experiência de um nível.
- Argumentos da cena da vila: `--host-session`, `--join-session=IP`, `--session-port=N`, `--character=sena`, `--start-floor=16`, `--autopilot`, `--profile=NOME`.

### Conteúdo e arte

```sh
python3 tools/content/build_tower.py            # 100 andares, biomas e chefes
python3 tools/content/build_character_trees.py  # árvores de evolução 10–100
python3 tools/content/build_village.py          # moradores da vila
python3 tools/pixelforge/pf.py <chaves>         # gera sprites no PixelForge (art/manifest.json)
tools/art/process.sh <grupos>                   # processa para a paleta do jogo
godot --headless --path . --import              # importa os PNGs
```

### Documentação

- [Game design](docs/game-design/README.md)
- [Torre: andares, biomas e chefes](docs/game-design/75-torre-andares-biomas-e-chefes.md)
- [Árvores de evolução 1 a 100](docs/game-design/74-arvores-de-evolucao-1-a-100.md)
- [Arquitetura e ADRs](docs/architecture/README.md)
- [Roadmap até o MVP](docs/roadmap-ate-mvp.md)
- [Revisão: hordas, expedições e RPG](docs/revisao-projeto-survivors-rpg.md)
- [Backlog de gameplay e itemização](docs/roadmap-gameplay-survivors-rpg.md)
