# Backlog: hordas + expedicoes

Data: 2026-10-03. Direcao confirmada: hordas + expedicoes.
Base e evidencias: [revisao do projeto](revisao-projeto-survivors-rpg.md).
Complementa, nao substitui, o [roadmap Steam EA](roadmap-steam-acesso-antecipado.md).

Status em 2026-10-11 (faxina feita: G0 conferido contra os testes, G6/G7 unidos ao G8 sem
contagem dupla, entregas recentes registradas abaixo): frente ativa junto de cenarios/UI. Lore, fechamento
do MVP e publicacao Steam ficam em backlog; preservar saves, rede e CI.
Foco atual (2026-10-11): epico E1, que une o restante de G0, G3, G6 e G8. Depois, ritmo em G4.
G1 sem expansao narrativa; G2/G6-G8 dependem das decisoes registradas.
G5 e requisitos comerciais ficam em backlog. Correcoes e prototipos abaixo
nao sao considerados concluidos apenas porque existem sistemas relacionados.
Nao atribuir prazo antes de estimar cada ticket. Gates sao criterios de saida,
nao promessa comercial. Mudancas de regras aprovadas exigem decisao registrada.

Entrega adicional em 2026-10-04: marcos permanentes de nivel agora pausam a
simulacao e abrem escolhas automaticamente, por solicitacao do responsavel.
Solo/co-op compartilham a regra; desconectados nao bloqueiam a retomada.
Isso nao implementa as Marcas de Expedicao temporarias propostas em G2 nem
resolve os achados de G0.

## Entregas fora dos gates (2026-10-04 a 2026-10-11)

Pedidos do responsavel ja implementados, testados e registrados, que nao correspondem a um item
dos gates acima (a contagem de % considera so os itens com caixa):

- Itens e build: passivas exclusivas, afixos e nivel do item, inventario no estilo Hero Siege,
  status detalhados e previas de escolha, maestria das gemas em 21 niveis (decisoes 580, 583, 584,
  588, 589); revisao revolucionaria de 37 unicas e 16 lendarios e Pacto de Sangue (599).
- Combate: venenos e colonia de esporos, dano continuo inbloqueavel, ataque no clique e ataque
  automatico opcional, Saraivada sem limite de tempo (586, 590, 591, 592, 595).
- Torre: chefes sem recarga, escada por 10 minutos, respawn 2x, monstros 10x Vida e +50% de
  velocidade, 2 aneis e quatro lendarios pedidos (587, 596).
- Vila e menus: autosave e CONTINUAR, bestiario, vender tudo, reset de atributos, loja da Forja e
  armazem so de materiais (582, 593, 594); skin de interface e revisao visual dos cenarios.
- Plano: documento 76 aprovado (597, 598).

## E1: pos-jogo e builds (epico, foco a partir de 2026-10-11)

Une o que resta de G0, G3, G6 e G8 numa ordem que evita retrabalho (pedido do responsavel). Os
itens mantem o codigo original e saem das secoes de origem, que passam a apontar para ca; a
contagem de % considera cada item uma unica vez. Plano de design: documentos 76 e 77.

### Fase 0: fundacao

Antes de qualquer sistema novo: cada comando novo do epico nasce validado e coberto pelo CI.

- [ ] G0.6: validar vetores finitos, limites, IDs e frequencia de comandos no host. Aceite: entradas invalidas nao alteram estado; comandos legitimos seguem funcionando em solo/co-op. Parcial (2026-10-11): intencoes de rede validam tipos e a mira do ataque rejeita vetores nao finitos; falta limitar a frequencia de comandos no host.
- [ ] G0.7: transformar probes confirmados em regressao no runner/CI. Aceite: suite e auditoria estrita passam; nao remover checks para fazer o gate ficar verde. Parcial (2026-10-11): o CI (`.github/workflows/tests.yml`) roda a suite inteira; falta a auditoria estrita no runner.

### Fase 1: escala de numeros e resistencias

Mudam todos os numeros do jogo; vem antes de qualquer balanceamento.

- [ ] G8.13: escala exponencial de numeros (bilhoes de Vida e dano na dificuldade 5, secao 3.1 do documento 76): fontes de poder multiplicativas, efeitos por fracao de Vida e numeros abreviados (mil, mi, bi) na HUD e nos menus.
- [ ] G8.3: resistencias: fisico e 9 elementos, resistencia dos inimigos por raca, bioma e dificuldade (-50% a +75%), penetracao, Quebra elemental, adaptacao (dificuldades 4 e 5), resistencias da personagem com teto 75% e penalidade por dificuldade (0/0/-20/-40/-60), icones de fraqueza na HUD e numeros "RESISTIU".

### Fase 2: dificuldades e pipeline unico de saque

Um so lugar define chances e quantidades de drop por dificuldade, fonte e evento; noite e mares so encaixam nele.

- [ ] G8.5: estrutura das cinco dificuldades (G6.1): dificuldade do mundo, escolhida pelo host no portal entre as liberadas; concluir o andar 100 libera a seguinte naquele mundo; tabela de Vida/dano/resistencia/afixos, recordes e saque por dificuldade; unicas a partir da 2 (G6.2).
- [ ] G3.3: fontes direcionadas por inimigo/contrato e uma receita garantida de marco, com regra de partilha visivel; nao prometer drop aleatorio garantido.

### Fase 3: dia e noite

Usa o pipeline de saque da fase 2.

- [ ] G8.1: relogio de dia e noite (2 h; manha 30 min, tarde 30, entardecer 20, noite 40) na vila e na Torre, do host, no snapshot e no save; HUD com hora e avisos; noite com EXP +25%, saque +30% e inimigos +10%; Lua da Cicatriz a cada 3 noites.
- [ ] G8.2: noite com mecanica: raio de luz como atributo, inimigos fora da luz semi-invisiveis e fora da mira automatica, variantes noturnas por bioma, elites cacadores; monstros da aurora de manha; materiais por horario (Orvalho Negro, Polen Lunar, Ambar Solar).

### Fase 4: afixos, mutadores e mares

- [ ] G8.6: sete afixos de elite com comportamento (Refletor, Absorvente, Vinculado, Profanador, Cacador, Fissurador, Escudeiro) e mutadores de andar (8 normais a partir da 3, 3 crueis na 5) com bonus de saque.
- [ ] G8.7: mares (Enxame, Cerco, Procissao, Avalanche, Vinculo, Eclipse e Lua da Cicatriz) com aviso, objetivo e recompensa; campeao em toda mare da 5.

### Fase 5: Paragon, divinos e chefes

- [ ] G8.8: Paragon da conta apos o nivel 100 (dificuldades 3 a 5, teto 200, EXP x1,5 na 4 e x2 na 5): nivel e EXP no perfil do jogador, somando todas as personagens e mundos; tabuleiro de 4 trilhas por personagem com todos os pontos da conta, nos notaveis a cada 10 pontos e respec em prata.
- [ ] G8.9: itens divinos a partir da 4 (G6.3): raridade nova, 12 itens que quebram duas regras, receita de ascensao (3 unicas da mesma gema e material raro), saque individual no co-op.
- [ ] G8.10: chefes por dificuldade: habilidade extra (2), fase nova abaixo de 30% (3), forma ascendida (4), teste de dano com escudo cronometrado (5); Guardioes da Cicatriz e Pactos na 5.

### Fase 6: telas de itens

Colecao, inventario (origem, favoritos, filtros, ordenacao), tabela de itens e suprimentos numa so passada de interface.

- [ ] G8.12: UI de colecao de lendarios, unicos, Reliquias e divinos (G6.5).
- [ ] G3.4: comparacao de efeito final, unidades, origem, favoritos, filtros e ordenar; navegacao completa sem mouse. Parcial: comparacao do efeito final pronta (`equipment_comparison_test.gd`); faltam origem, favoritos, filtros e ordenacao.
- [ ] G3.6: tabela de itens implementados/propostos/adiados; efeitos adicionais so entram na promessa comercial apos teste/UI/save/rede.
- [ ] G3.5: suprimentos com item/quantidade/efeito real, evitando nomes diferentes para a mesma cura generica.

### Fase 7: calibragem final

Por ultimo de proposito: calibrar antes das fases 1 a 5 seria refeito.

- [ ] G8.11: sondas por dificuldade e calibragem ate as metas (1: 95% com build simples; 2: 85% com 1 unica; 3: 70% com Paragon 0 a 50; 4: 50% com Paragon 100 e 1 divino; 5: 30% com Paragon 150+ e build otimizada); playtests (G6.4).
- [ ] G3.2: validar builds de perfuracao, controle, invocacao e resgate com gemas/suportes atuais; cada personagem tem ao menos duas opcoes viaveis.
- [ ] G8.14: itens de suporte para a colonia de esporos (decisao 591) que a tornem viavel na dificuldade 5 (ex.: teto do acumulo, heranca da Cepa, mutacao por salto, fracao em chefes).

## G0: confiar no combate e no loot

Autoataque em 2026-10-04: dois encaixes de suporte (capacidade 6),
compatibilidade por arma e efeitos reais no ataque, sem duplicar a copia
entre autoataque e skills. UI de adicionar/remover, snapshot do host e
migracao de saves cobertos por regressao. Suporte incompativel fica inativo
ao trocar arma. Balanceamento dessa nova combinacao continua pendente em G3.2.

Loot em 2026-10-04: limite de 120 aplicado somente ao snapshot visual,
com selecao por proximidade dividida entre aliados conectados. O estado
autoritativo conserva os drops, inclusive reliquias e carga perdida.
Reload preserva zona de chefe, andar, qualidade e pilhas acima de 9999.
Regressao cobre JSON/save/reload e recuperacao de todos os itens omitidos
da visualizacao. Memoria e custo de ordenacao sob sessoes longas ainda
exigem medicao em G4.4; nao fecha os demais achados de G0.

HUD em 2026-10-04: seis sugestoes implementadas (recursos das skills,
barreira, efeitos com duracao, mira/alvo, grupo/resgate/reconexao e avisos).
Ver [HUD de combate](hud-combate.md). Dados replicados pelo host; sem mudar
balanceamento. Nao fecha QA externo, audio nem acessibilidade completa.

Descricoes por hover adicionadas em 2026-10-04 a itens/equipamentos nos menus
e skills no menu/HUD. A descricao identifica bonus e efeitos ainda sem
consumidor no beta. Isso melhora G3.4, mas nao fecha comparacao de atributos,
filtros/favoritos nem a integracao de efeitos pendente em G0.3/G0.4.

Polimento imediato em 2026-10-04: listas alfabeticas de gemas/suportes,
descricao ao passar o cursor, custo de Folego/cargas e recarga ajustada por
Sabedoria; suportes sem capacidade ficam desabilitados. Arma equipada tem
nome e padrao/tipo de dano visiveis; trocar aba/reabrir menu retorna ao topo.
Sem alteracao de balanceamento ou fechamento dos gates restantes.

Entrega 2026-10-04: catalogo ampliado para 36 ativas + 20 suportes mecanicos
+ 20 buffs, novos icones, geometria e efeitos reais; quatro tipos de arma
inicial com escalas e afinidades. Testes de catalogo, compatibilidade e
execucao cobrem esta base. G3.2 continua aberto: viabilidade e balanceamento
precisam de playtests. G0.1 tem `fortune` corrigido e validacao de escalas;
G0.2 tem importacao de metadados corrigida. Os gates completos permanecem
pendentes de suas evidencias de aceitacao, sem declarar G0 concluido.

- [x] G0.1: validar referencias de atributos do catalogo/gerador; corrigir `luck` para `fortune` sem alterar IDs. Aceite: todas as escalas existem e Elo Residual responde a Fortune. Evidencia (faxina 2026-10-11): o gerador converte `luck` em `fortune`, a validacao do catalogo rejeita escala desconhecida (`beta_content_catalog_test.gd`) e o Elo Residual escala com Inteligencia e Fortune.
- [x] G0.2: importar tags, incompatibilidades e `two_handed`. Aceite: teste via factory impede equipar combinacoes invalidas, sem apagar itens do inventario. Evidencia: `weapon_combat_test.gd` (tags, incompatibilidades e duas maos importados) e `equipment_loadout_test.gd` (duas maos com offhand ocupada e recusada sem tirar o item do inventario).
- [x] G0.3: registrar cada atributo equipado e seu consumidor. Aceite: cada bonus exibido altera uma medida observavel, ou fica explicitamente indisponivel no beta. Evidencia: `balance_rules_test.gd` falha se algum item tiver atributo sem efeito; atributos ainda sem consumidor aparecem como indisponiveis na descricao.
- [x] G0.4: conectar mecanicas de itens a eventos/resolvedores com limites de procs. Aceite: teste de comportamento por efeito habilitado, sem recursao, duplicacao de carga ou acumulo ao reequipar. Evidencia: motor de passivas (decisoes 580 e 599) com testes por efeito em `item_passives_test.gd`, `revolution_uniques_test.gd` e `revolution_legendaries_test.gd`; passivas nao disparam passivas, sem recursao nem acumulo ao reequipar.
- [x] G0.5: proteger reliquias e carga perdida do limite de drops. Aceite: exceder 120 entradas preserva propriedade e recuperacao, inclusive apos save/reload; cap de representacao nao destroi estado. Evidencia: `ground_loot_preservation_test.gd`; partilha existente preservada, sem introduzir propriedade individual nova.
- G0.6 -> E1, fase 0.
- G0.7 -> E1, fase 0.

Risco: efeitos mudam balanceamento; protecao de loot pode aumentar memoria.
Medir carga e testar saves existentes. Nao exigir que todo efeito proposto seja
implementado para fechar G0: itens indisponiveis devem sair da promessa/drop
ativo sem apagar instancias historicas.

## G1: uma microexpedicao completa

Dependencia: G0, sem regressao de persistencia EA3.

- [ ] G1.1: registrar duracao e politica de perda. Rota de 15-25 minutos e proposta, nao substituicao silenciosa da meta historica de 30-60 minutos; equipamentos atualmente ficam seguros, materiais ficam em risco.
- [ ] G1.2: contrato local com objetivo, risco, recompensa e fontes de loot visiveis; estado aceito/concluido/resgatado persistido uma unica vez.
- [ ] G1.3: prototipar estabilizar fissura e recuperar cache guardado; concluir solo ou em grupo, sem travar por morte/desconexao de um participante.
- [ ] G1.4: escolha continuar/retornar com carga legivel, resgate e prontidao do grupo; evitar retirada unilateral acidental.
- [ ] G1.5: bancada com um upgrade util e reciclagem usando materiais existentes; protecao de favoritos/equipados e transacao atomica.

Aceite: partida nova -> contrato -> objetivo -> extracao -> recompensa ->
melhoria -> nova partida, usando teclado e controle, sem comando de debug.
Repetir reload e desconexao em cada transacao sem recompensa duplicada.

## G2: improvisacao durante a expedicao

Dependencia: G1 e aprovacao do ciclo temporario.

- [ ] G2.1: seis Marcas de Expedicao definidas em dados, com efeito, contrapartida, tags e limite; escolher uma de tres em local seguro, ate tres ativas no prototipo.
- [ ] G2.2: selecao individual com foco de controle, prontidao co-op e fallback para desconexao; nao pausar o grupo no meio da horda.
- [ ] G2.3: definir save/reconexao/abandono; marcas nao viram equipamento permanente nem permitem trocar gemas livremente na Torre.
- [ ] G2.4: medir escolhas e efeitos, garantindo que nenhuma opcao ofertada seja inerte para a build atual.

Aceite: mesmo personagem experimenta duas rotas de build perceptivelmente
diferentes; os efeitos somem no encerramento e sobrevivem a reconexao prevista.
Decisao aberta: duracao das marcas entre andares e contrato.

## G3: itemizacao pequena e desejavel

Entrega parcial de G3.4 em 2026-10-11: comparacao de equipamentos no
inventario por hover/foco, com faixa fixa legivel e sem scroll horizontal.
Mostra a peca efetivamente substituida, atributos derivados e autoataque
apos troca (incluindo qualidade, nivel, afixos, passivas fixas e suportes).
Usa os calculos do runtime sem modificar mochila, estado ou RNG; avisa
conflitos e suportes que ficarao inativos. Nao e estimativa de DPS contra
um inimigo, nem simula gatilhos futuros de passiva/skills. Origem, favoritos,
ordenacao e filtros de inventario continuam pendentes; G3.4 nao esta fechado.
Ver [ciclo visual/gameplay 1](visual-gameplay-ciclo-1.md).

Dependencia: G0/G1; G2 nao e necessario para craft basico.

- [x] G3.1: primeira colecao testada. Superada: 23 lendarios, 46 armas unicas e 7 reliquias com passivas exclusivas e testes por efeito (decisoes 580, 596 e 599), com 13 encaixes (decisao 596, 2 aneis) e saves antigos preservados.
- G3.2 -> E1, fase 7.
- G3.3 -> E1, fase 2.
- G3.4 -> E1, fase 6.
- G3.5 -> E1, fase 6.
- G3.6 -> E1, fase 6.

Aceite: jogador identifica um item desejado, onde encontra e como ele muda sua
build. Equipar/desequipar/reabrir nao duplica efeitos. Adiar sets, multiplos
novos sockets, corrupcao e reroll amplo ate provar a economia reduzida.

## G6: pos-jogo, dificuldades e itens divinos (pedido de 2026-10-06)

Detalhado e acompanhado no G8 (plano do documento 76); os itens abaixo ficam como origem do pedido
e nao entram na contagem, para nao contar o mesmo trabalho duas vezes.

- G6.1 cinco dificuldades -> G8.5.
- G6.2 unicas a partir da dificuldade 2 -> G8.5.
- G6.3 itens divinos a partir da 4 -> G8.9.
- G6.4 balancear as dificuldades 3 a 5 -> G8.11.
- G6.5 colecao de lendarios, unicos e divinos -> G8.12.
- G6.6 itens revolucionarios -> G8.4 (concluido em 2026-10-11, decisao 599).
- G6.7 resistencias, mares, mutadores e Paragon -> G8.3, G8.6, G8.7 e G8.8.

Aceite: cada dificuldade tem saque e desafio distintos medidos pela sonda; um jogador
sem lendarios conclui a historia e um jogador com um lendario sente que ele e essencial
nas dificuldades 3 a 5.

## G7: dia e noite, horarios especiais e evolucao da vila (backlog, pedido de 2026-10-06)

Hoje o periodo do dia so avanca a cada retorno de expedicao e muda luz e rotina da vila
(decisao 561). Ainda nao implementado:

- G7.1 -> G8.1 (detalhado no plano do documento 76; nao conta duas vezes).
- G7.2 -> G8.1 (detalhado no plano do documento 76; nao conta duas vezes).
- G7.3 -> G8.2 (detalhado no plano do documento 76; nao conta duas vezes).
- G7.4 -> G8.2 (detalhado no plano do documento 76; nao conta duas vezes).
- [ ] G7.5: qualidade e nivel de tudo produzido na vila (forja, cozinha, oficinas, servicos) dependem do nivel da vila e do nivel de vida dos moradores envolvidos.
- [ ] G7.6: o nivel da vila evolui pela riqueza acumulada; cada nivel aumenta a capacidade maxima do armazem e libera producao melhor.
- [ ] G7.7: cada expedicao traz itens exclusivos da viagem (ex.: reliquias de andar, registros, sementes) que alimentam a evolucao da vila; definir taxa por andar e dificuldade para nao virar farm de um andar so.

Aceite: o jogador percebe a hora do dia e decide quando descer; a vila sobe de nivel por
escolhas visiveis de investimento; nenhum horario bloqueia a historia, so o saque especial.

## G8: plano de dificuldades, dia e noite, resistencias, mares e Paragon (backlog, plano de 2026-10-07)

Plano completo em `game-design/76-dificuldades-dia-e-noite-e-paragon.md` (em discussao; decisoes
abertas na secao 10 do documento). Detalha G6 e G7.1 a G7.4. Fases, em ordem:

- [x] G8.0: aprovar o documento 76. Decisoes 597 e 598 (2026-10-11): dia de 2 h, dificuldade do mundo, Paragon da conta, proxima dificuldade ao concluir o andar 100, mutadores crueis obrigatorios na 5 e revisao das passivas pelo teste da revolucao.
- G8.1 -> E1, fase 3.
- G8.2 -> E1, fase 3.
- G8.3 -> E1, fase 1.
- [x] G8.4: itens revolucionarios (G6.6): acoes novas no motor de passivas, reescrita das 46 unicas e 18 lendarios, Reliquias de regra, etiqueta de regra no gerador e teste que reprova passiva so numerica. Feito em 2026-10-11 (decisao 599, documento 77).
- G8.5 -> E1, fase 2.
- G8.6 -> E1, fase 4.
- G8.7 -> E1, fase 4.
- G8.8 -> E1, fase 5.
- G8.9 -> E1, fase 5.
- G8.10 -> E1, fase 5.
- G8.11 -> E1, fase 7.
- G8.12 -> E1, fase 6.
- G8.13 -> E1, fase 1.
- G8.14 -> E1, fase 7.

Estimativa: 9 a 12 semanas. G8.1 e G8.3 podem comecar em paralelo.

## G4: ritmo, legibilidade e co-op

- [ ] G4.1: prototipar diretor de preparar/pressionar/pico/relaxar em uma rota; ajustar populacao, nao dano oculto. Boss e records competitivos usam regras registradas separadas.
- [ ] G4.2: sinais de ameaca por forma/animacao/som; audio com licencas e limites de vozes; reduzir flash/tremor/efeitos sem ocultar perigo.
- [ ] G4.3: ownership de loot, transferencias, prontidao e progresso visiveis; host valida transacoes; solo nao depende de classe obrigatoria.
- [ ] G4.4: perfil release com render e 1-4 jogadores; p95/p99, memoria e rede em varias seeds. Otimizar gargalos medidos antes de extrair sistemas ou adotar indice espacial.
- [ ] G4.5: QA sob latencia/perda/reconexao e Xbox/DualShock 4/DualSense reais, USB/Bluetooth/Steam Input; registrar o que nao foi testado.

Aceite: uma rota longa de teste e duas consecutivas sem crescimento sem limite,
perda de item ou bloqueio de grupo. Orcamentos de desempenho dependem de
hardware minimo medido; os benchmarks headless atuais nao definem esse minimo.

## G5: evidencias para publicar

- [ ] G5.1: cinco participantes novos em primeira sessao; observar objetivo, extracao, morte, decisao de build e desejo de repetir, sem roteiro verbal.
- [ ] G5.2: playtests solo/co-op de rotas e fontes de loot; alterar uma hipotese por rodada e registrar resultados, inclusive negativos.
- [ ] G5.3: fixture historica, atualizacao e falhas reais de escrita/recuperacao em Windows/Linux; completar EA3.
- [ ] G5.4: estabilidade prolongada e QA dos pacotes release, licencas, suporte e limites de conteudo comunicados; completar EA1-EA4.
- [ ] G5.5: conta/loja/depots/revisoes Valve e requisitos comerciais do roadmap Steam; nenhuma automatizacao substitui essas aprovacoes.

Aceite final: evidencias de jogo funcional e entretenimento testado, progresso
preservado e gates comerciais aprovados. Numero de andares ou testes verdes,
isoladamente, nao constitui prontidao para venda.
