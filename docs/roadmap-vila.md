# Roadmap da vila: Aresta que cresce com a campanha

Pedido de 2026-10-13. Detalha G7.5, G7.6 e G7.7 do
[backlog de gameplay](roadmap-gameplay-survivors-rpg.md) e transforma em sistema jogável o que
os documentos [04 (economia, vila e progressão)](game-design/04-economia-vila-e-progressao.md),
[21 (economia pessoal e fundos)](game-design/21-economia-pessoal-e-fundos.md) e
[vila e serviços](vila-e-servicos.md) já definem.

Objetivo: tudo o que o jogador junta na vila e na Torre tem destino, a vila sobe de nível por
investimentos visíveis, e cada nível rende algo que se sente na próxima expedição. As
dificuldades não mudam; a vila só melhora a personagem, os serviços e a economia.

## 1. Estado atual (2026-10-13)

O que já funciona:

- Lavradores, mineiros e lenhadores colhem, carregam e entregam madeira, minério e alimentos ao
  armazém, com capacidade de 1000 por recurso. Os estoques, as reservas dos pontos e os
  trabalhadores vão para o save.
- Cinco atendimentos usam o estoque:

  | Atendente | Serviço |
  |---|---|
  | Cássio | Suprimento |
  | Maura | Tratamento |
  | Sira | Remédios |
  | Dália | Reparo |
  | Lior | Ração |

- Materiais da Torre ficam no armazém de expedições. Pólen Lunar e prata lapidam o Selo na Forja.
  A Ascensão de divinos também fica na Forja.
- O reforço da vila acontece com 3 pedras regenerativas (`village_progress` 0 → 1). É o único
  marco de evolução hoje.
- Os moradores têm memórias, rotina de dia e de noite e caminhos no AStarGrid2D.

O que falta:

- Não existe nível da vila, e `village_progress` vai só até 1.
- Os recursos não têm para onde ir. No save do jogador, os três estoques estão travados em 1000
  e há 2688 pedras regenerativas guardadas sem uso.
- A produção não tem qualidade. O suprimento de Sira é igual ao de Cássio.
- A Torre não traz nada exclusivo para a vila. Os materiais servem só para a forja.
- Não há projetos de obra, contratos do conselho, nível de vida dos moradores nem uma tela da
  vila.

## 2. Pilares

1. **Todo recurso tem um destino.** Madeira, minério, alimentos, pedras, prata e itens de
   expedição alimentam obras ou serviços. Estoque cheio é sinal de que falta obra, nunca de
   desperdício.
2. **O investimento é visível.** Cada nível e cada obra muda o mapa: prédios, ruas, luz, muralha
   e moradores novos. A vila é o registro visual da campanha (documento 04).
3. **O retorno se sente na Torre.** Todo nível rende pelo menos um efeito que a personagem leva
   para a próxima descida, como suprimento melhor, serviço novo ou bônus de expedição.
4. **Sem farm de um andar só.** Os itens de expedição seguem uma taxa por andar e por
   dificuldade, com rendimento decrescente para o mesmo andar no mesmo dia.
5. **Sem punição que apague progresso.** Crises suspendem benefícios, mas não destroem
   investimento nem forçam reinício (documento 04, "Regressão e crise").

## 3. Fases

A ordem segue a dependência. Cada fase fecha com testes headless no `tests/run_all.sh`, entrada
no registro de decisões e a página da wiki atualizada.

### V1: nível da vila e tesouro (G7.6)

- [ ] V1.1: criar `src/gameplay/village/village_growth.gd` (RefCounted, dados puros) com
  `riqueza_investida`, `nivel` (1 a 10), `obras` concluídas e `obra_em_andamento`. O módulo
  substitui `village_progress`: um save antigo com `village_progress = 1` vira nível 1 com
  o reforço concluído.
- [ ] V1.2: a riqueza conta só o que foi **investido** em obras e doações ao tesouro, nunca o
  estoque parado. Pesos iniciais:

  | Recurso | Peso por unidade |
  |---|---|
  | Madeira | 1 |
  | Alimentos | 1 |
  | Minério | 1,5 |
  | Pedra regenerativa | 10 |
  | Prata | 0,1 |
  | Item de expedição | Valor da tabela V4 |

- [ ] V1.3: faixas de nível (riqueza acumulada):

  | Nível | Riqueza acumulada |
  |---:|---:|
  | 1 | 0 |
  | 2 | 500 |
  | 3 | 1.500 |
  | 4 | 3.500 |
  | 5 | 7.000 |
  | 6 | 12.000 |
  | 7 | 20.000 |
  | 8 | 32.000 |
  | 9 | 50.000 |
  | 10 | 75.000 |

  Os valores se recalibram com a sonda de economia (V8.4).
- [ ] V1.4: a capacidade do armazém passa a ser `1000 + 500 × (nível − 1)` por recurso, e os
  trabalhadores entregam mais por viagem nos níveis 4 e 8.
- [ ] V1.5: o host doa ao tesouro no quadro do armazém. Validação de zona, distância e saldo
  segue o mesmo padrão dos atendimentos, e uma falha não gasta nada.
- [ ] V1.6: o save leva `village_growth` e o schema sobe de versão. Saves antigos carregam
  no nível 1, com o reforço preservado se já tinham `village_progress = 1`.
- [ ] Testes: `village_growth_test.gd` cobre faixas, pesos, capacidade, save e migração do
  reforço, e verifica que doação inválida não gasta.

### V2: obras (os sumidouros)

Brina Pedralva (obra) mantém o quadro de projetos. Cada obra tem custo em recursos locais, pedras
e prata, um tempo de construção em ciclos do relógio do mundo com trabalhadores visíveis no
canteiro, um nível mínimo e um efeito. Uma obra por vez, e duas pessoas não financiam a mesma
etapa em dobro.

- [ ] V2.1: catálogo de obras em `data/village/village_projects.json`, gerado por
  `tools/content/build_village_projects.py` com `--check`. Primeiro lote, por área do documento 04:

  | Obra | Nível mín. | Atendente | Efeito |
  |---|---:|---|---|
  | Muralha de paliçada | 1 | Brina | Visual da muralha, guardas com rota nova. Libera o nível 2. |
  | Forja ampliada | 2 | Dália | Reparo −30% de custo. Lapidação do Selo −25% de prata. |
  | Estufa da botica | 2 | Sira | Suprimento de Sira cura +25% (base da qualidade em V3). |
  | Celeiro | 2 | Lior | +1 ponto de colheita nos campos. A ração rende 2 suprimentos. |
  | Enfermaria de pedra | 3 | Maura | Tratamento dá "Bem cuidado" (+10% de Vida máxima na próxima expedição). |
  | Feira coberta | 3 | Cássio | Loja com 2 peças a mais e chance de peça épica. |
  | Arquivo de mapas | 4 | Oren | Mostra os mutadores e a maré do andar antes de descer. +5% de EXP na expedição. |
  | Torre de vigia | 4 | Tamar | Avisa a Lua da Cicatriz um ciclo antes. Ronda noturna iluminada. |
  | Mina escorada | 5 | — | +1 ponto de minério e regeneração 50% mais rápida. |
  | Serraria d'água | 5 | — | Idem para madeira. |
  | Posto de expedições | 6 | Nara | Contratos de expedição (V6). +1 suprimento inicial. |
  | Laboratório de alquimia | 7 | Sira | Elixires de expedição (V3.4). |
  | Oficina de selos | 8 | Dália | Lapidação do Selo até +7. |
  | Praça iluminada | 9 | — | Bônus de noite na vila: rotina festiva e memória dos moradores. |
  | Memorial da Torre | 10 | Alda | Registro da campanha: nomes de chefes vencidos, marcos de Paragon e divinos. |

- [ ] V2.2: estado da obra em `village_growth` (etapa, progresso e quem financiou). O progresso
  anda com o relógio do mundo, sem simulação offline (mesma regra dos trabalhadores).
- [ ] V2.3: visual em `village_plan.gd`. Cada obra concluída troca obstáculos e sprites do mapa
  (a mesma via que hoje usa `village_progress`) e aparece de dia e de noite em
  `tools/art/village_shots.gd`.
- [ ] V2.4: efeitos das obras via um `village_bonus(peer)` lido pelos serviços, pela loja e pela
  expedição. Bônus da personagem entram como passivas no motor de `item_passives.gd`, como o
  Paragon.
- [ ] V2.5: o save do jogador. As 2688 pedras e os estoques cheios bastam para várias obras de
  uma vez, o que serve de prova de que o sumidouro funciona.
- [ ] Testes: `village_projects_test.gd` cobre custo, nível mínimo, fila única, progresso pelo
  relógio, efeito aplicado, save e cliente que não financia sem estar perto. O
  `map_connectivity_test` continua passando com todas as obras concluídas.

### V3: qualidade da produção (G7.5)

- [ ] V3.1: a qualidade de cada coisa produzida na vila usa as mesmas faixas dos itens
  (`regular` → `masterwork`):

  ```
  qualidade = f(nível da vila, nível de vida do morador envolvido, obra do ofício)
  ```

- [ ] V3.2: suprimentos ganham qualidade. Cura e duração do efeito escalam pela faixa, e o
  limite de 9 suprimentos continua.
- [ ] V3.3: Dália reforja peças da loja com piso de qualidade igual ao nível da forja, e a
  feira vende peças com nível mínimo pela vila. A loja continua sem gemas de chefe nem
  divinos, e os Selos continuam caindo só dos chefes.
- [ ] V3.4: elixires de expedição (com o Laboratório de alquimia): um por expedição, de 10 a
  20 minutos, com bônus pequenos e claros, como +10% de EXP, +15% de raio de luz ou +10% de
  resistência a um elemento. Custam alimentos e material da Torre.
- [ ] Testes: `village_quality_test.gd` cobre a faixa por nível, a vida do morador e a cura do
  suprimento por qualidade.

### V4: itens de expedição (G7.7)

- [ ] V4.1: novos materiais, exclusivos da viagem, que só servem à vila:

  | Item | Origem | Uso |
  |---|---|---|
  | Relíquia de andar | Chefe de andar | Obras de nível 6+, Memorial |
  | Registro de exploração | Baú, evento de andar, explorar o andar todo | Arquivo, contratos |
  | Semente da Torre | Comuns de biomas vegetais, campos | Estufa, Celeiro, alimentos raros |
  | Veio cristalino | Comuns de biomas minerais | Mina escorada, Oficina de selos |
  | Âmbar da maré | Já existe (marés) | Laboratório de alquimia |

- [ ] V4.2: taxa por andar e por dificuldade, com `andar / 10` e `× (1, 1,3, 1,6, 2, 2,5)`
  por dificuldade. Rendimento decrescente no mesmo andar no mesmo dia do relógio: 100%, 60%,
  30%, depois 10%. A tabela fica no `tower_content` para a wiki listar.
- [ ] V4.3: valor de riqueza por item (peso do V1.2): relíquia 200, registro 40, semente 15,
  veio 25. O valor sobe com o andar de origem.
- [ ] V4.4: os itens vão para o armazém de expedições (o mesmo de hoje) e aparecem no filtro de
  saque como "vila", sem nunca virar prata automaticamente.
- [ ] Testes: `expedition_village_items_test.gd` cobre a taxa crescente por andar e por
  dificuldade, o rendimento decrescente no mesmo andar, o reset no dia seguinte e a ausência
  de venda pelo filtro.

### V5: moradores e nível de vida

- [ ] V5.1: consumo diário. A vila come alimentos por morador a cada dia do relógio. Sem
  comida, cai o nível de vida, que baixa a qualidade (V3) e suspende o bônus das obras do
  ofício até repor o estoque. Nada é destruído.
- [ ] V5.2: nível de vida por morador (0 a 5): alimentação, moradia (obras residenciais) e
  ofício ativo. Fica visível no diálogo e no quadro da vila.
- [ ] V5.3: população cresce com o nível. Aparecem novos moradores e visitantes (caravana,
  estudioso, aventureiro), reutilizando famílias de sprites animados. Visitantes trazem uma
  oferta temporária de loja ou de contrato (documento 04, "Fluxo de visitantes").
- [ ] V5.4: memórias dos moradores para obras concluídas e níveis da vila, para que eles
  comentem o crescimento.
- [ ] Testes: `village_life_test.gd` cobre o consumo diário, o nível de vida, a suspensão e o
  retorno de bônus e a população por nível.

### V6: conselho e contratos

- [ ] V6.1: Alda Serrin (conselho) publica pedidos de quantidade, prazo em dias do relógio,
  qualidade mínima e recompensa em prata, riqueza e reputação. Um pedido aberto aceita
  entrega parcial.
- [ ] V6.2: contratos de expedição com Nara (Posto de expedições), por exemplo "vencer o chefe
  do andar 40 na dificuldade 3" ou "trazer 5 registros do bioma X", com recompensa em itens
  de vila e prata.
- [ ] V6.3: no máximo 3 pedidos ativos. Renovam por dia e não punem quem ignora.
- [ ] Testes: `village_contracts_test.gd` cobre a geração por nível, a entrega parcial, o
  prazo, a recompensa e o save.

### V7: crise (opcional, só depois de V1 a V6)

- [ ] V7.1: na Lua da Cicatriz, chance de um evento de vila (incêndio, praga nos campos,
  caravana atacada). Ele suspende um ofício até que uma pequena obra de reparo seja paga.
- [ ] V7.2: o reparo deixa marca visual (documento 04) e nunca reduz o nível nem apaga obra.
- [ ] Decidir com o jogador antes de implementar. Pode sair do escopo.

### V8: interface, wiki e calibração

- [ ] V8.1: aba **Vila** no menu da personagem com nível, barra de riqueza, armazém com as
  capacidades, obra em andamento, próximas obras e o que cada uma libera, nível de vida e
  contratos.
- [ ] V8.2: o quadro de Brina no mundo abre a mesma tela no modo de obras. Controle e teclado
  como nos atendimentos.
- [ ] V8.3: página **Vila** na wiki (`tools/wiki/wiki_pages.gd`) com níveis, obras, itens de
  expedição e taxas, gerada dos dados.
- [ ] V8.4: sonda de economia `tools/bench/village_probe.gd`. Simula N expedições por andar e
  dificuldade, com recursos coletados por dia, e mede quantas horas leva cada nível. A meta
  inicial é o nível 5 no fim da campanha da dificuldade 1 e o nível 10 por volta da
  dificuldade 4.
- [ ] V8.5: README, `vila-e-servicos.md` e registro de decisões atualizados.

## 4. Ordem sugerida e tamanho

| Fase | Depende de | Tamanho | Entrega para o jogador |
|---|---|---|---|
| V1 | — | M | Nível da vila e armazém maior |
| V2 | V1 | G | Estoque cheio e pedras guardadas viram obras e bônus |
| V4 | V1 | M | A Torre passa a alimentar a vila |
| V3 | V1, V2 | M | Suprimentos e loja melhores |
| V8.1–8.2 | V1, V2 | M | Tela da vila (pode ir junto da V2) |
| V5 | V2, V3 | M | Vila viva, com consumo e população |
| V6 | V4, V5 | M | Pedidos e contratos |
| V8.3–8.5 | tudo | P | Wiki, sonda e docs |
| V7 | tudo | P | Opcional |

Primeiro corte jogável (V1, V2 com as 5 primeiras obras, e V8.1): o save atual já sobe 3 ou
4 níveis com o que está parado no armazém.

## 5. Critérios de aceite

- No save de referência, nenhum recurso fica parado no teto sem obra disponível para gastá-lo.
- Cada nível da vila muda o mapa e rende pelo menos um efeito sentido na Torre.
- Repetir o mesmo andar rende no máximo 10% do item de vila depois da terceira vez no dia.
- Toda regra nova tem teste headless com saída `*_OK` no `tests/run_all.sh`.
- No co-op, o host valida tudo e duas pessoas não consomem o mesmo estoque nem financiam a
  mesma etapa em dobro.
- Nenhuma mudança reduz a dificuldade dos inimigos.
