# Dificuldades, dia e noite, resistências, marés e Paragon

## Estado

**Em discussão.** Plano proposto em 2026-10-07 a pedido do responsável, para aprovar antes de
implementar. Substitui, quando aprovado, o backlog G6 e G7 do
[roadmap de gameplay](../roadmap-gameplay-survivors-rpg.md). Mudanças em relação ao backlog:
armas únicas passam a cair a partir da **dificuldade 2** (antes 3) e itens divinos a partir da
**dificuldade 4** (antes 5).

## Princípios

1. **Cada dificuldade muda como se joga, não só os números.** Toda dificuldade nova acrescenta pelo
   menos uma mecânica que exige resposta de build ou de execução. O aumento de Vida e dano existe,
   mas é moderado e nunca o principal.
2. **Escolhas de build pesam mais a cada dificuldade.** Resistências, penetração, sustentação,
   mobilidade e controle viram necessidades a partir da 3. Na 5, uma build sem foco não passa.
3. **Recompensa acompanha o risco.** Itens melhores, Paragon e materiais exclusivos só existem onde o
   desafio justifica.
4. **Nada bloqueia a história.** A dificuldade 1 é a campanha. Horários, marés e mutadores só mudam
   desafio e saque.
5. **Medido, não estimado.** Cada dificuldade tem metas de taxa de sucesso verificadas pelas sondas
   (`tools/bench/balance_probe.gd` com `--item=` e futuras opções de Paragon e dificuldade).

## 1. Dia e noite

### Relógio

- Relógio do mundo próprio, independente dos retornos à vila. Um dia completo dura **24 minutos de
  jogo**: manhã 6, tarde 6, entardecer 4, noite 8. O tempo passa na vila e na Torre; pausa de marco
  e menus em solo não contam.
- O host é a fonte do relógio; clientes recebem a hora no snapshot. O relógio fica no save.
- Indicador na HUD (sol, lua e minutos até a virada) e no mapa da Torre. Avisos ao entardecer
  ("A noite cai em 1 minuto") e ao amanhecer.
- A cada 7 noites ocorre a **Lua da Cicatriz**: noite especial com maré garantida e saque próprio
  (seção 4).

### O que muda à noite

Mecânicas, não só números:

- **Visibilidade:** monstros noturnos ficam semi-invisíveis fora do raio de luz da personagem. A luz
  passa a ser um atributo (afixo "Raio de luz", passivas e gemas sagradas iluminam). Mira automática
  só pega o que está iluminado.
- **Variantes noturnas:** cada bioma ganha 1 ou 2 monstros que só nascem à noite, com mecânica
  própria (ex.: Sombra de Lastro, que some e reaparece atrás da personagem; Lâmpada Errante, que
  apaga a luz em volta).
- **Elites caçadores:** à noite, pacotes elite patrulham e perseguem de mais longe.
- **Números:** Vida e dano dos inimigos +10% (pouco, de propósito).
- **Recompensas:** EXP +25%, chance de saque +30%, materiais noturnos (Orvalho Negro, Pólen Lunar)
  que alimentam receitas e a evolução da vila.

### O que muda de dia

- Monstros "da aurora" (ex.: Coletor de Âmbar) só nascem de manhã: fogem em vez de lutar e soltam
  Âmbar Solar ao serem pegos. Recompensa o jogo ofensivo e a mobilidade.
- Vendas e serviços da vila funcionam com preço normal; à noite alguns serviços fecham e outros
  (alquimia) abrem com receitas noturnas.

### Na vila

Já existe a rotina dos moradores por período. O relógio novo só passa a dirigi-la em tempo real.
A evolução da vila por riqueza (G7.5 a G7.7) segue em plano separado.

## 2. Resistências

### Tipos de dano

Físico e nove elementos, que já existem nos dados das gemas: fogo, gelo, raio, ácido, natureza,
trevas, sagrado, terra e arcano. O autoataque usa o tipo da arma (físico ou arcano). Golpes e perigos
dos inimigos ganham um tipo (os perigos já são temáticos por bioma: lava, gelo, descarga, ácido).

### Resistências dos inimigos

- Cada inimigo tem resistência por tipo, de **-50% (fraqueza)** a **+75% (teto)**.
- Origem: **raça** (ex.: Calcário resiste a físico 30% e é fraco a ácido -25%; Micelar resiste a
  natureza e é fraco a fogo), **bioma** (Bacias resistem a fogo; Campos resistem a raio) e
  **dificuldade** (resistência a tudo +10, +20, +30 e +40 nas dificuldades 2 a 5).
- **Penetração** reduz a resistência efetiva do alvo e só vale contra resistência positiva. Vem de
  afixos novos, marcos e passivas.
- **Quebra:** efeitos como a vulnerabilidade atual e uma nova "Quebra elemental" (debuff que reduz
  a resistência a um elemento por alguns segundos) abrem espaço para builds de suporte no co-op.
- **Adaptação** (dificuldade 4 e 5): elites e chefes ganham resistência ao elemento que mais os
  atingiu nos últimos 10 s. Força builds com dois elementos ou com quebra.

### Resistências da personagem

- Afixos novos de resistência por elemento e "todas as resistências". Teto de 75%, que relíquias
  divinas podem subir.
- **Penalidade por dificuldade** a todas as resistências: 0, 0, -20%, -40% e -60%. Na 5, vestir
  resistência vira prioridade de build.
- A aba de status detalhados (decisão 589) passa a mostrar resistências e penetração.

### Legibilidade

- Ao mirar um inimigo, a HUD mostra ícones de fraqueza (verde) e resistência (vermelho).
- Números de dano em cinza quando muito resistidos ("RESISTIU") e maiores quando atingem fraqueza.

## 3. As cinco dificuldades

Cada dificuldade é escolhida pelo host ao entrar na Torre e vale para o grupo. Para liberar a
seguinte, é preciso vencer o Regente Centésimo (andar 100) na anterior. Recordes, conjuntos de gema
e progresso de andar são guardados por dificuldade.

| | I. Expedição | II. Veterana | III. Mestra | IV. Mítica | V. Cicatriz |
|---|---|---|---|---|---|
| Para quem | História | Primeiro pós-jogo | Build pensada | Build otimizada | Build no limite |
| Vida / dano dos inimigos | x1 / x1 | x1,6 / x1,3 | x2,6 / x1,7 | x4 / x2,2 | x6 / x2,8 |
| Resistência dos inimigos | raça e bioma | +10 | +20 | +30 e adaptação | +40 e adaptação |
| Penalidade às suas resistências | 0 | 0 | -20% | -40% | -60% |
| Afixos de elite | 1 | 1 ou 2 | 2 | 2 ou 3 | 3 |
| Mutadores de andar | 0 | 0 | 1 | 2 | 3 (um deles cruel) |
| Marés especiais | Lua da Cicatriz | + 1 tipo | todas | todas, mais fortes | todas, com campeões |
| Chefes | kit atual | +1 habilidade | fases novas | forma ascendida | ascendida + teste de dano |
| Itens | até lendário | **armas únicas** | únicas mais comuns | **divinos** | divinos mais comuns |
| Paragon | não | não | sim | sim, EXP x1,5 | sim, EXP x2 |
| Meta de sucesso da sonda | 95% (build simples) | 85% com 1 única | 70% (Paragon 0 a 50) | 50% (Paragon 100 e 1 divino) | 30% (Paragon 150+, build otimizada) |

### Mecânicas por dificuldade

**I. Expedição.** O jogo atual. Lua da Cicatriz a cada 7 noites como introdução às marés.

**II. Veterana.**
- Resistências de raça e bioma passam a pesar (+10 em tudo).
- Elites com até 2 afixos; afixos novos de comportamento (seção 5).
- Cada chefe ganha uma habilidade nova ligada ao bioma.
- Armas únicas passam a cair; chefes e marés são as fontes principais.

**III. Mestra.**
- Penalidade de -20% nas suas resistências.
- 1 **mutador de andar** sorteado e anunciado na entrada (ex.: "Chão Vivo: poças que crescem",
  "Ecos: inimigos repetem o último golpe", "Fome: cura recebida -40%"). Cada mutador aumenta EXP e
  saque do andar.
- Chefes ganham fase nova abaixo de 30% de Vida.
- Paragon liberado.

**IV. Mítica.**
- Adaptação elemental de elites e chefes.
- 2 mutadores por andar.
- Chefes na **forma ascendida**: arena muda durante a luta e mecânicas combinadas (ex.: o Pastor das
  Correntes inverte a direção das rajadas e invoca pastores menores que curam o chefe).
- Itens **divinos** passam a cair.

**V. Cicatriz.**
- -60% nas suas resistências, 3 mutadores (um da lista "cruel": "Sem retorno: morrer encerra a
  expedição mesmo em grupo", "Cicatriz: Vida máxima cai 2% a cada queda no andar").
- Chefes ascendidos com **teste de dano**: escudo que precisa cair em N segundos ou a fase reinicia.
- Elites "Guardiões da Cicatriz": um por andar, com 3 afixos e drop garantido de material raro.
- **Pactos opcionais** antes de descer: aceitar uma maldição extra (ex.: "gemas custam Vida em vez de
  Fôlego") em troca de saque e EXP maiores. É a camada de otimização para quem já domina a 5.

## 4. Marés (hordas especiais)

Eventos anunciados no andar ("Uma maré se aproxima", 5 s de aviso no chão e na HUD), com objetivo e
recompensa próprios. Chance por andar cresce com a dificuldade e com a noite.

| Maré | Mecânica | Resposta esperada | Recompensa |
|---|---|---|---|
| Enxame | Centenas de inimigos fracos e rápidos em ondas | Área e alcance | Baú do Enxame |
| Cerco | Anel de atiradores que se fecha | Mobilidade e quebra do anel | Fragmentos de gema |
| Procissão | Um carregador lento escoltado por elites; foge se ferido | Dano em alvo único e controle | Item garantido do tier mais alto da dificuldade |
| Avalanche | Onda de inimigos lentos e muito resistentes | Penetração e quebra | Materiais de forja |
| Vínculo | Inimigos com Vida compartilhada em pares | Dano distribuído | Âmbar da Maré |
| Eclipse (só à noite) | Escuridão total exceto pela sua luz | Luz e percepção | Orvalho Negro em quantidade |
| Lua da Cicatriz (a cada 7 noites) | Todas as anteriores em sequência | Build completa | Relíquia da Lua (cosmético e progresso da vila); chance de divino da 4 em diante |

Na dificuldade 5, toda maré traz um **campeão**, um elite com nome, 3 afixos e drop próprio.

## 5. Afixos e mutadores novos

Para que dificuldade signifique mecânica, a lista de afixos de elite (hoje 12) ganha comportamentos:

- **Refletor:** devolve 20% do dano de um tipo de elemento.
- **Absorvente:** fica imune por 3 s ao último elemento que o atingiu.
- **Vinculado:** divide dano com um aliado próximo.
- **Profanador:** aura que reduz a cura recebida em 50%.
- **Caçador:** marca uma personagem e a persegue ignorando as outras.
- **Fissurador:** deixa fendas que explodem depois de 2 s.
- **Escudeiro:** dá barreira aos aliados em volta até morrer.

Mutadores de andar (sorteados na 3 em diante), com aumento de saque proporcional:

- **Normais:** Chão Vivo, Ecos, Fome (cura -40%), Pressa (inimigos +25% velocidade), Blindagem
  (+20% resistência física), Tempestade (raios periódicos), Escuridão (raio de luz -50%),
  Enxertia (inimigos mortos voltam uma vez com metade da Vida).
- **Cruéis (só na 5):** Sem Retorno, Cicatriz, Dívida (o Fôlego não regenera, só volta com abates).

## 6. Itens revolucionários: lendários, únicas, relíquias e divinos

### Regra central

Lendários, armas únicas e Relíquias precisam ser **revolucionários**: mudar como a personagem joga,
e não só quanto dano causa. Um item desses só é válido se passar no **teste da revolução**:

1. **Muda uma regra:** comportamento da gema, tipo de dano, recurso, mira, morte, recarga ou
   invocação. "+40% de dano de fogo" sozinho reprova.
2. **Cria uma build que não existia:** com o item, faz sentido trocar gemas, suportes, atributos ou
   escolhas de maestria. Se a build continua igual e só fica mais forte, reprova.
3. **Tem custo ou tensão** sempre que a regra nova for forte demais. Isso força escolha, e não troca
   automática.
4. **Lê em uma frase.** A primeira frase diz a regra nova; números vêm depois.

Números continuam existindo como apoio (ex.: "+20% de fogo"), mas nunca como a passiva principal.

### Escala de impacto

| Tier | Escopo da regra | Exemplo de direção |
|---|---|---|
| Lendário | Uma **categoria** inteira: elemento, tipo de dano, autoataque, invocação, defesa | Queimaduras não expiram e se espalham |
| Arma única | **Uma gema** muda de comportamento | A Bola de Fogo orbita e cresce em vez de ser lançada |
| Relíquia | Uma **regra do jogo**: recurso, recarga, morte, mira, cura | Gemas não recarregam com o tempo, só com abates |
| Divino (dificuldade 4+) | **Duas regras** quebradas ao mesmo tempo, ou uma regra central | Gemas sem recarga, cada lançamento custa Vida |

### Auditoria do que existe hoje

As 46 únicas e os 18 lendários do beta (decisão 580) passam na prova "levar a personagem até o fim da
história", mas a maioria **amplifica** em vez de **transformar**. Exemplos: cópias extras ("três
agulhas fantasmas", "duas Minas a mais", "segunda onda"), vulnerabilidade, cura por acerto e +40% por
elemento. As exceções que já se aproximam da regra são Recusa da Morte, Casca Espelhada, Passo Além e
Gatilho Ancestral.

Proposta: **reescrever as 64 passivas** com o teste acima, mantendo nome, gema e fonte, antes de as
únicas virarem recompensa da dificuldade 2. As cópias e bônus atuais podem continuar como afixos
de itens Raros e Épicos, que é onde números pertencem.

### Exemplos de reescrita

**Armas únicas (a gema muda):**
- **Bola de Fogo, Sol Cativo:** a bola não é mais lançada; orbita a personagem e cresce a cada
  inimigo em chamas por perto. Relançar a arremessa com tudo o que acumulou.
- **Esfera de Gelo, Prisão de Cristal:** inimigos mortos congelados viram estátuas que bloqueiam
  projéteis inimigos e explodem quando atingidas pelas suas gemas.
- **Saraivada de Flechas, Chuva Perpétua:** a Saraivada fica sempre ativa sobre a personagem; em
  troca, não tem recarga e consome Fôlego por segundo.
- **Passo Vetorial, Rastro:** o Passo deixa uma cópia sua que repete as próximas 3 gemas lançadas.
- **Muralha Refeita, Muralha Andante:** a Muralha acompanha a personagem e empurra inimigos.
- **Casca Reativa, Couraça de Espinhos:** o autoataque desliga; todo dano recebido é guardado e sai na
  próxima gema como dano extra.
- **Esporos, Hospedeiro:** inimigos infectados lutam por você por 5 s antes de morrer.
- **Molde Vigilante, Matriz Viva:** os Moldes copiam a última gema que você lançou.
- **Fio Desintegrador, Lâmina de Luz:** o fio fica preso à personagem e gira continuamente; a
  velocidade de giro sobe com a cadência.

**Lendários (a categoria muda):**
- **Fogo que Não Apaga:** queimaduras não expiram e acumulam; quem morre em chamas passa o fogo
  adiante. Fogo deixa de ser explosão e vira dano contínuo.
- **Inverno Interior:** inimigos congelados abaixo de 15% da Vida se estilhaçam; você fica imune a
  lentidão e congelamento.
- **Lente Arcana:** converte todo dano de gema em arcano. Ignora fraquezas e resistências de
  elemento, mas perde quebra elemental. É resposta direta à adaptação das dificuldades 4 e 5.
- **Erudição Absoluta:** gemas custam Vida em vez de Fôlego; Vida máxima +30%.
- **Gatilho Ancestral:** o autoataque passa a disparar a gema do Q com 40% da potência, e a gema
  do Q não pode ser lançada à mão.
- **Rebanho Fiel:** sua Vida máxima cai pela metade; invocações herdam seus afixos e resistências.

**Relíquias (a regra do jogo muda):**
- **Tempo Roubado:** gemas não recarregam com o tempo; cada abate adianta 1 s de todas.
- **Recusa da Morte:** mantém a regra de voltar da queda e ganha um custo: Vida máxima -10%.
- **Pacto de Sangue:** nenhuma cura funciona; todo abate dá barreira de 3% da Vida.
- **Olho do Regente:** chance de crítico fixa em 0; todo quinto acerto é crítico com +300%.
- **Bússola Torta:** desliga a mira automática; seus projéteis atravessam e voltam.
- **Lanterna de Âmbar:** à noite, sua luz queima inimigos e revela os invisíveis; de dia, Vida
  máxima -10%. Liga as Relíquias ao ciclo de dia e noite.

As 4 vagas de Relíquia (documento 68) passam a ser **a principal camada de otimização**: combinar
2 a 4 regras quebradas é o que torna a dificuldade 5 possível.

### Liberação por dificuldade

- **Lendários e Relíquias:** já existem na 1, raros (Relíquias só de chefes e raids, decisão 552).
  Da 3 em diante ganham mais fontes (marés e Guardiões).
- **Armas únicas** (decisões 574 e 580): só caem a partir da **dificuldade 2**. Fontes: chefes,
  marés e Guardiões.
- **Itens divinos** (raridade nova acima de lendário, cor branco-dourada e som próprio): só a
  partir da **dificuldade 4**.
  - Exemplos: "Coroa Sem Fim: gemas sem recarga, cada lançamento custa 5% da Vida"; "Lança das
    Nove Marés: cada acerto alterna entre todos os elementos e aplica a quebra de cada um".
  - Primeira leva de 12 divinos, pelo menos um para cada estilo (cada personagem, veneno, invocação,
    autoataque, defesa e elementos).
  - Fontes: chefes ascendidos (chance baixa), Lua da Cicatriz, Guardiões da 5 e uma **receita de
    ascensão** (3 armas únicas da mesma gema mais material raro), para reduzir o azar.
  - Regra de co-op: cada jogador sorteia o próprio saque divino (sem disputa).

### Como garantir

- Cada passiva ganha no gerador uma etiqueta de regra (`transforma`, `converte`, `substitui
  recurso`, `troca mira`, `morte`, `recarga`, `invocação`). O `--check` dos geradores e um teste
  falham se algum lendário, única, Relíquia ou divino não tiver etiqueta, ou se a passiva só tiver
  `mods` numéricos.
- O motor `item_passives.gd` ganha as ações que essas regras pedem: transformar o comportamento da
  gema (órbita, permanente, preso à personagem), converter tipo de dano, trocar o recurso de custo,
  mudar a regra de recarga, desligar autoataque ou mira e herdar atributos nas invocações.
- Cada item novo entra com teste que prova a regra (ex.: com Tempo Roubado, a recarga não anda sem
  abate).

## 7. Paragon

Da dificuldade 3 em diante a personagem precisa crescer depois do nível 100. Paragon resolve isso
sem inflar o nível base:

- **Níveis Paragon** começam após o nível 100, com EXP vinda só das dificuldades 3 a 5 (x1,5 na 4 e
  x2 na 5). Teto de **200**. Curva crescente: chegar ao 150 é o ponto de equilíbrio da 5.
- Cada nível dá **1 ponto** num **tabuleiro de Paragon** por personagem, em quatro trilhas:
  - **Ofensiva:** dano por tipo, crítico, penetração.
  - **Defensiva:** Vida, resistências, redução de dano.
  - **Utilidade:** Fôlego, recarga, velocidade, raio de luz.
  - **Elemental:** quebra e bônus por elemento.
- Nós pequenos dão +1% a +2%. A cada 10 pontos numa trilha surge um **nó notável** com mecânica
  (ex.: "Abates com fogo deixam brasas", "Cada 5% de resistência acima do teto vira 1% de dano").
- **Respec** em Aresta, pago em prata, para incentivar testar builds.
- Bônus de **Legado:** cada 10 níveis Paragon de uma personagem dá +1 ponto às outras da mesma conta.
  É pequeno e conversa com o tema geracional.
- Balanceamento: na 5, Paragon dá cerca de 35% do poder, equipamento 40% e gemas mais escolhas
  25%. Nenhuma fonte sozinha vence a 5.

## 8. Interface e co-op

- **Seleção de dificuldade** no portal da Torre (host), com descrição das mecânicas, recompensas e
  mutadores visíveis antes de descer.
- **Mapa da Torre:** recordes e progresso por dificuldade; mutadores do andar atual.
- **HUD:** relógio, indicador de maré, mutadores ativos e ícones de resistência do alvo.
- **Co-op:** a dificuldade do grupo é a do host. Quem ainda não liberou pode entrar com aviso, mas
  não recebe saque da tier bloqueada para não pular progressão.
- **Status detalhados:** resistências, penetração, Paragon e bônus por mutador.

## 9. Ordem de implementação e esforço

Esforço com desenvolvimento assistido e testes: P até meio dia, M 1 a 2 dias, G 3 a 5 dias.

| Fase | Entrega | Depende de | Esforço |
|---|---|---|---|
| 0 | Aprovar este documento e as decisões abertas (seção 10) | — | — |
| 1 | Relógio de dia e noite, HUD, save, co-op; noite com EXP e saque maiores | — | M |
| 2 | Tipos de dano, resistências de inimigos e personagem, afixos de resistência e penetração, legibilidade | — | G |
| 3 | Estrutura de dificuldades: seleção, liberação, tabela de números, recordes e saque por dificuldade (únicas na 2) | 2 | G |
| 4 | Afixos de elite novos e mutadores de andar | 3 | G |
| 5 | Marés (6 tipos e Lua da Cicatriz) e variantes noturnas por bioma | 1, 3 | G |
| 6 | Paragon: EXP, tabuleiro, nós notáveis, respec, Legado | 3 | G |
| 2b | Itens revolucionários: ações novas no motor de passivas, reescrita das 46 únicas e 18 lendários, Relíquias de regra, etiqueta e teste da revolução | 2 | G x 2 |
| 7 | Itens divinos: raridade, 12 itens, receita de ascensão | 2b, 3 | G |
| 8 | Chefes: habilidade extra (2), fases (3), formas ascendidas (4), teste de dano (5) | 3 | G x 2 |
| 9 | Sondas por dificuldade e calibragem até as metas da tabela; playtests | todas | M a G |

Total estimado: **9 a 12 semanas**. As fases 1 e 2 podem começar em paralelo e já mudam o jogo
atual (a 1 dá ritmo, a 2 dá profundidade de build). Cada fase entra com testes e documento próprios,
como as anteriores.

## 10. Decisões abertas

1. **Duração do dia:** 24 minutos de jogo, ou outra?
2. **Dificuldade por mundo ou por personagem?** Proposta: por mundo (escolhida pelo host), com
   progresso de liberação por personagem.
3. **Paragon por personagem ou por conta?** Proposta: por personagem, com o bônus de Legado.
4. **Liberação da próxima dificuldade:** vencer o Regente (andar 100) é longo; alternativa é
   liberar pelo chefe do andar 72.
5. **Mutadores cruéis na 5:** obrigatórios (1 por andar) ou só via Pactos opcionais?
6. **Reescrita das únicas e lendários atuais:** substituir as passivas de hoje (proposta) ou manter
   as atuais e criar itens novos ao lado?
7. **Números da tabela** (Vida e dano por dificuldade) são o ponto de partida; a calibragem final vem
   das sondas.
