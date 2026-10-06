# Backlog: hordas + expedicoes

Data: 2026-10-03. Direcao confirmada: hordas + expedicoes.
Base e evidencias: [revisao do projeto](revisao-projeto-survivors-rpg.md).
Complementa, nao substitui, o [roadmap Steam EA](roadmap-steam-acesso-antecipado.md).

Status: diagnostico concluido; correcoes e prototipos abaixo ainda pendentes.
Nao atribuir prazo antes de estimar cada ticket. Gates sao criterios de saida,
nao promessa comercial. Mudancas de regras aprovadas exigem decisao registrada.

Entrega adicional em 2026-10-04: marcos permanentes de nivel agora pausam a
simulacao e abrem escolhas automaticamente, por solicitacao do responsavel.
Solo/co-op compartilham a regra; desconectados nao bloqueiam a retomada.
Isso nao implementa as Marcas de Expedicao temporarias propostas em G2 nem
resolve os achados de G0.

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

- [ ] G0.1: validar referencias de atributos do catalogo/gerador; corrigir `luck` para `fortune` sem alterar IDs. Aceite: todas as escalas existem e Elo Residual responde a Fortune.
- [ ] G0.2: importar tags, incompatibilidades e `two_handed`. Aceite: teste via factory impede equipar combinacoes invalidas, sem apagar itens do inventario.
- [ ] G0.3: registrar cada atributo equipado e seu consumidor. Aceite: cada bonus exibido altera uma medida observavel, ou fica explicitamente indisponivel no beta.
- [ ] G0.4: conectar mecanicas de itens a eventos/resolvedores com limites de procs. Aceite: teste de comportamento por efeito habilitado, sem recursao, duplicacao de carga ou acumulo ao reequipar.
- [x] G0.5: proteger reliquias e carga perdida do limite de drops. Aceite: exceder 120 entradas preserva propriedade e recuperacao, inclusive apos save/reload; cap de representacao nao destroi estado. Evidencia: `ground_loot_preservation_test.gd`; partilha existente preservada, sem introduzir propriedade individual nova.
- [ ] G0.6: validar vetores finitos, limites, IDs e frequencia de comandos no host. Aceite: entradas invalidas nao alteram estado; comandos legitimos seguem funcionando em solo/co-op.
- [ ] G0.7: transformar probes confirmados em regressao no runner/CI. Aceite: suite e auditoria estrita passam; nao remover checks para fazer o gate ficar verde.

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

Dependencia: G0/G1; G2 nao e necessario para craft basico.

- [ ] G3.1: primeira colecao testada: quatro aneis e uma reliquia, sem mudar os 21 slots aprovados nem invalidar saves; efeitos fixos antes de afixos aleatorios.
- [ ] G3.2: validar builds de perfuracao, controle, invocacao e resgate com gemas/suportes atuais; cada personagem tem ao menos duas opcoes viaveis.
- [ ] G3.3: fontes direcionadas por inimigo/contrato e uma receita garantida de marco, com regra de partilha visivel; nao prometer drop aleatorio garantido.
- [ ] G3.4: comparacao de efeito final, unidades, origem, favoritos, filtros e ordenar; navegacao completa sem mouse.
- [ ] G3.5: suprimentos com item/quantidade/efeito real, evitando nomes diferentes para a mesma cura generica.
- [ ] G3.6: tabela de itens implementados/propostos/adiados; efeitos adicionais so entram na promessa comercial apos teste/UI/save/rede.

Aceite: jogador identifica um item desejado, onde encontra e como ele muda sua
build. Equipar/desequipar/reabrir nao duplica efeitos. Adiar sets, multiplos
novos sockets, corrupcao e reroll amplo ate provar a economia reduzida.

## G6: pos-jogo, dificuldades e itens divinos (backlog, pedido de 2026-10-06)

Base pronta: decisao 580 (todo lendario e arma unica tem passiva exclusiva, forte o bastante
para uma unica peca levar a personagem ate o fim da historia). Ainda nao implementado:

- [ ] G6.1: cinco dificuldades da campanha. A 1 e a historia; as seguintes reescalam Vida, dano, populacao e tabelas de saque, com registro proprio de recordes e regra de desbloqueio (concluir a anterior). Definir se cada dificuldade e por mundo ou por personagem e como o co-op mistura dificuldades.
- [ ] G6.2: armas unicas so caem da dificuldade 3 em diante. Hoje (beta, sem dificuldades) chefes garantem uma unica de uma gema equipada, elites tem 5% e comuns 1% (decisao 574); ao entrar G6.1, essa regra passa a valer so na 3+.
- [ ] G6.3: itens divinos (nova raridade acima de lendario, cor e som proprios) so na dificuldade 5. Extremamente fortes: duas passivas, ou uma passiva que muda regras (ex.: gema sem recarga, todos os elementos ao mesmo tempo, Saraivada permanente). Definir quantidade, slots, fonte (chefes do pos-jogo, receitas) e regra de partilha no co-op.
- [ ] G6.4: balancear as dificuldades 3 a 5 assumindo pelo menos um lendario ou unico equipado, com a sonda `tools/bench/balance_probe.gd --item=` como base.
- [ ] G6.5: UI de colecao de lendarios, unicos e divinos (encontrados e faltantes, de onde vem cada um).

Aceite: cada dificuldade tem saque e desafio distintos medidos pela sonda; um jogador
sem lendarios conclui a historia e um jogador com um lendario sente que ele e essencial
nas dificuldades 3 a 5.

## G7: dia e noite, horarios especiais e evolucao da vila (backlog, pedido de 2026-10-06)

Hoje o periodo do dia so avanca a cada retorno de expedicao e muda luz e rotina da vila
(decisao 561). Ainda nao implementado:

- [ ] G7.1: ciclo de dia e noite com relogio proprio (duracao a definir) que vale na vila e na Torre, sincronizado no co-op e salvo no mundo. Indicador de hora na HUD e no mapa.
- [ ] G7.2: a noite deixa monstros mais fortes (Vida e dano) e paga mais EXP e saque; os multiplicadores entram na sonda de balanceamento e nos recordes por andar (registrar o periodo da corrida).
- [ ] G7.3: itens que so caem em certos horarios (ex.: materiais noturnos, de amanhecer, de lua cheia), com origem visivel na descricao.
- [ ] G7.4: monstros especiais que so nascem em certos horarios, com aviso legivel e saque proprio.
- [ ] G7.5: qualidade e nivel de tudo produzido na vila (forja, cozinha, oficinas, servicos) dependem do nivel da vila e do nivel de vida dos moradores envolvidos.
- [ ] G7.6: o nivel da vila evolui pela riqueza acumulada; cada nivel aumenta a capacidade maxima do armazem e libera producao melhor.
- [ ] G7.7: cada expedicao traz itens exclusivos da viagem (ex.: reliquias de andar, registros, sementes) que alimentam a evolucao da vila; definir taxa por andar e dificuldade para nao virar farm de um andar so.

Aceite: o jogador percebe a hora do dia e decide quando descer; a vila sobe de nivel por
escolhas visiveis de investimento; nenhum horario bloqueia a historia, so o saque especial.

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
