# ADR 0020 — Moradores de Aresta: modo padrão e modo com modelo de linguagem

## Estado

Aceita em 2 de outubro de 2026 por pedido do responsável pelo projeto. Atualiza a seção "Modelos de linguagem" da ADR 0006 e do documento 64: um modelo pode agora **escolher a ação** de um morador, não apenas variar a fala, mas somente entre ações já validadas pelo jogo.

## Contexto

A vila parecia uma cidade fantasma: nenhum morador, nenhuma rotina, nenhuma fala. A mente sistêmica (`NpcMind`) existia só em teste. O responsável pediu NPCs com dois modos: um padrão e um controlado por modelo de linguagem, configurável entre provedores.

## Decisão

### Simulação

- `VillageLife` (`src/simulation/npc/village_life.gd`) pertence à `WorldSimulation` e roda só no host. Carrega `data/village/village_content.json` (gerado por `tools/content/build_village.py`): onze moradores nomeados dos documentos 07 e 09 e dezenove moradores comuns.
- Cada morador tem local de trabalho, casa, pontos de encontro e ronda (`WorldLayout.VILLAGE_SPOTS`), uma `NpcMind` com traços e valores, lembranças de eventos e fatos recentes.
- A cada decisão o host monta as **ações candidatas válidas** para aquele momento: trabalhar, passear, descansar, vigiar (guarda), conversar com outro morador, cumprimentar ou comentar notícias com um jogador próximo; numa conversa (tecla `E`): responder, contar notícias, fazer um pedido, aconselhar ou encerrar.
- O período do dia (manhã, tarde, entardecer, noite) avança a cada retorno de expedição, respeitando a regra de que o calendário avança por ações (decisão 20), e muda os pesos da rotina.
- Eventos verdadeiros viram lembranças dos moradores nomeados: retorno com pedras e andar alcançado, queda, recorde e reforço construído.

### Modo padrão

- `NpcMind.choose_action` escolhe pela utilidade (traços, valores e período), com pequena variação pela semente do mundo.
- A fala é autoral, composta por intenção, ofício e fatos verdadeiros (andar mais fundo, pedra armazenada, últimas notícias), evitando repetir a mesma frase seguida.

### Modo com IA

- Só os moradores nomeados consultam o modelo: em conversas e, no máximo, a cada 25 a 35 segundos de rotina quando há jogadores na vila.
- O prompt traz personalidade, opiniões públicas, período, quem está perto, fatos verdadeiros da vila, o que o morador soube e a lista fechada de ações. Segredos dos documentos ficam fora do prompt.
- `NpcModelClient` (`src/core/ai/npc_model_client.gd`) envia o pedido por HTTP ao provedor configurado: Ollama (`/api/chat` com `format: json`), servidor compatível com OpenAI (`/v1/chat/completions`) ou Anthropic (`/v1/messages`). No máximo `max_concurrent` pedidos simultâneos.
- A resposta precisa ser JSON `{acao, fala}`. A ação só é aceita se estiver na lista enviada; a fala é limpa e limitada a 160 caracteres. Ação inválida, erro de rede ou tempo esgotado (9 s) fazem a decisão padrão assumir.
- O modelo nunca escreve estado: posição, alvo e lembranças são aplicados pelo próprio `VillageLife` a partir da ação escolhida.

### Configuração

- `NpcAiConfig` (`src/core/ai/npc_ai_config.gd`): modo, provedor, endereço, modelo, nome da variável de ambiente da chave, tempo limite, concorrência e temperatura.
- Fontes, em ordem crescente: padrões, `user://aresta_npc_ai.cfg`, variáveis `ARESTA_NPC_*` e argumentos `--npc-*`. A chave de API nunca é gravada, só o nome da variável.
- Interface: botão "MORADORES (IA)" na tela de título e "Moradores" no menu dev, com teste de conexão; `F6` alterna o modo durante o jogo (host).

### Rede e salvamento

- O snapshot leva posição, ação, fala e indicador de "pensando" de cada morador, o período e as últimas falas. Clientes nunca consultam o modelo.
- O salvamento guarda o período, as lembranças e os fatos de cada morador.

## Consequências

- `tests/npc_ai_test.gd` sobe um servidor falso no formato do Ollama e verifica rotinas, conversa padrão, resposta do modelo aplicada, ação inventada recusada, queda por tempo esgotado e leitura dos formatos OpenAI e Anthropic.
- Com o modo com IA, decisões deixam de ser reproduzíveis a partir da semente; por isso só ações de baixo impacto (deslocamento e fala) passam pelo modelo. Decisões com consequência sistêmica (crime, economia, política) continuam exclusivas da Utility AI.
- Latência do modelo aparece como "..." sobre o morador; o jogo nunca espera pela resposta.
