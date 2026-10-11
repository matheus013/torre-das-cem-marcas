# Roadmap: integracao da lore ao jogo

Atualizado em 2026-10-07. Objetivo: transformar a lore aprovada em objetivos,
descobertas, escolhas e consequencias jogaveis, sem interromper o ciclo de
hordas, preparacao, expedicao e retorno. Este documento planeja implementacao;
registra entregas verificadas e pendencias; nao modifica o canone.

## Marco principal

Entregar **Renovacao Antecipada**, em Aresta e nos andares 1 a 4: o jogador
entende por que parte, encontra sinais do Ultimo Lastro, enfrenta a Camara
Refeita, decide a custodia do objeto e percebe a reacao da vila na mesma
sessao. A conclusao deve deixar uma razao narrativa para a proxima expedicao.

O recorte aprovado mira 90 a 150 minutos para a primeira conclusao e 30 a
60 minutos para a expedicao principal. Sao alvos de playtest, nao duracoes
garantidas nem justificativa para prolongar dialogos ou adicionar grind.

## Base e limites

- Reutilizar combate, progressao, inventario, vila, servicos, mapas e saves.
- A existencia de um NPC, chefe ou andar nao comprova que seu papel narrativo
  esteja implementado. N0 deve verificar essas correspondencias.
- Preservar os cem andares testaveis e o progresso existente. O primeiro arco
  nao exige escrever nem bloquear toda a campanha de uma vez.
- Manter balanceamento, animacoes de combate, desempenho e QA externo em
  paralelo. A narrativa nao substitui os criterios de acesso antecipado.
- Contratos, dialogos e pistas essenciais devem funcionar offline e sem IA.
  IA opcional de moradores nao decide fatos canonicos, recompensas ou flags.

## Fontes de verdade

- [Recorte vertical](game-design/57-recorte-vertical.md): estrutura e custodia.
- [Ultimo Lastro](game-design/60-expedicao-do-ultimo-lastro.md): objeto e revelacoes.
- [Galerias Refeitas](game-design/28-regiao-1-galerias-refeitas.md): primeira regiao.
- [Elenco](game-design/13-personagens-jogaveis.md) e
  [relacoes](game-design/14-relacoes-do-elenco.md): vozes e vinculos.
- [Historia Velada](game-design/52-dez-volumes-da-historia-velada.md): fontes,
  contradicoes e limites do que pode ser revelado.
- [Cooperativo vigente](game-design/63-cooperativo-online-e-combate-de-hordas.md):
  substitui as regras antigas incompativeis de co-op local do recorte.
- [Fracasso e geracoes](game-design/55-roguelike-geracional-e-reencarnacao.md):
  distinguir regra de producao de representacao simplificada no recorte.

Conflitos entre documentos e runtime devem ser registrados antes da correcao.
Mudancas de canone ou novas regras irreversiveis exigem aprovacao do responsavel.

## Ordem de entrega

| Marco | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| N0 | Matriz canone/runtime e roteiro do primeiro arco | Documentos existentes | Auditoria concluida em 2026-10-07; conflitos registrados |
| N1 | Estado narrativo, persistencia e prova ponta a ponta | N0 | Prova implementada e validada em 2026-10-07 |
| N2 | Abertura em Aresta e contrato de expedicao | N1 | Implementado; playtest de compreensao pendente |
| N3 | Eventos e descobertas dos andares 1 a 3 | N2 | Parcial: socorro e fissura opcional no andar 1; andares 2 e 3 pendentes |
| N4 | Objeto, chefe e retirada do andar 4 | N3 | Pendente |
| N5 | Relatorio, custodia e consequencias na vila | N4 | Pendente |
| N6 | Fracasso, repeticao, co-op e acessibilidade | Regras desde N0; validacao apos N5 | Pendente |
| N7 | Playtest e candidato narrativo do primeiro arco | N0 a N6 | Pendente |

N6 nao e uma permissao para adiar saves, rede ou controles: esses requisitos
acompanham todas as entregas. N6 fecha a cobertura dos caminhos completos.
Nao ha prazo ou percentual de conclusao antes da auditoria de N0.

## N0: mapear antes de integrar

Entregas: [matriz canone/runtime](lore-matriz-canone-runtime.md) e
[roteiro de gatilhos e revelacoes](lore-roteiro-renovacao-antecipada.md).
Concluir a auditoria nao implementa eventos nem aprova propostas de conciliacao.

- [x] Criar matriz com fato canonico, fonte, NPC/item/local, gatilho,
  implementacao existente, lacuna e marco responsavel.
- [x] Mapear Alda, Nara, Dalia e demais envolvidos aos IDs reais dos moradores;
  manter seus servicos e rotinas, sem criar duplicatas narrativas.
- [x] Auditar o acesso atual aos andares 1 a 4, chefe, retirada, morte e retorno.
  Separar o que pode ser reutilizado do que precisa de adaptacao.
- [x] Definir cadeia do arco: crise -> contrato -> pistas -> objeto ->
  confronto -> retirada -> custodia -> consequencia -> proxima investigacao.
- [x] Criar matriz de revelacoes: verdade do canone, conhecimento de cada NPC,
  evidencia encontrada e informacao acessivel ao jogador em cada etapa.
- [x] Listar conflitos e decisoes tecnicas abertas, incluindo resolucao de
  votos no co-op e tratamento do mundo existente na chegada do novo arco.

**Saida:** cada acontecimento do recorte tem fonte, gatilho e consequencia;
segredos do Ultimo Lastro e da Segunda Ascensao nao vazam nas falas iniciais.

## N1: infraestrutura narrativa minima

Entrega: [estado narrativo e primeiro contrato](lore-n1-estado-narrativo.md).
Estado e recompensa pertencem ao mundo; esta prova nao exige flags pessoais.

- [x] Usar dados estruturados para dialogos, objetivos, pistas e recompensas,
  com IDs estaveis e referencias validadas. Seguir o catalogo existente.
- [x] Implementar estados explicitos de missao e flags de mundo/perfil,
  distinguindo descoberta, escolha confirmada e recompensa entregue.
- [x] Integrar eventos reais da simulacao, sem depender de texto de fala,
  tempo de tela ou repeticao de polling para avancar objetivos.
- [x] Persistir progresso com migracao e backup. Saves antigos nao perdem
  itens, niveis ou acesso; avancos narrativos nao sao inferidos sem evidencia.
- [x] Host valida interacoes, escolhas e recompensas. Clientes recebem o
  estado confirmado, inclusive ao entrar tarde ou reconectar.
- [x] Entregar dialogo, objetivo acompanhado e diario de descobertas com
  teclado/mouse e foco de controle; evitar texto longo durante combate.
- [x] Provar um fluxo pequeno: aceitar pedido, encontrar evidencia, retornar,
  conversar e receber recompensa uma unica vez, inclusive apos recarregar.

**Saida:** prova ponta a ponta passa em solo e host/cliente; interagir duas
vezes ou reenviar comando nao duplica progresso, itens ou recompensas.

## N2: Aresta e motivo para partir

Entrega: [abertura e preparacao](lore-n2-abertura-e-preparacao.md).
Falas autorais, preparo individual, direcao de moradores e contexto persistente.
Meta de compreensao em cinco minutos ainda depende de playtest externo.

- [x] Alda apresenta a Renovacao Antecipada como problema concreto da vila.
- [x] Nara oferece o contrato, explica risco e encaminha preparacao/retorno.
- [x] Oficina, enfermaria e comercio fornecem falas contextuais curtas,
  preservando acesso aos atendimentos existentes.
- [x] Eloa, Sena, Cira e Rui recebem reacoes coerentes com seus vinculos;
  nenhuma personagem e obrigatoria para concluir a historia.
- [x] Introduzir rumores divergentes como relatos, nao como verdade absoluta.

**Saida:** jogador novo identifica objetivo e destino sem ler um compendio.
Alvo proposto de playtest: conseguir explicar a primeira missao em ate 5
minutos, sem impedir quem deseja explorar a vila antes de partir.

## N3: andares 1 a 3 com acontecimentos

Primeira entrega: [socorro no Patio das Marcas](lore-n3-socorro-primeira-rota.md).
Trabalhador acompanhado ate o portal, diario e reacao de Nara, persistencia
e estado compartilhado pelo host. Abandono explicito e reputacao
jogavel permanecem pendentes; o primeiro item abaixo ainda nao esta concluido.

Segunda entrega: [rota registrada e fissura opcional](lore-n3-fissura-opcional.md).
Ramal sinalizado, risco comunicado, dois inimigos adicionais e evidencia
complementar persistente. Rota principal e retorno continuam abertos; nao
conclui o pedido de ajuda com abandono/reputacao nem os eventos dos andares 2 e 3.

- [ ] Andar 1: rota segura/fissura opcional e pedido de ajuda com desfecho.
- [ ] Andar 2: trabalhadores, coleta e uma rota alterada pela Cicatrizacao;
  garantir caminho de retorno valido, sem prender o grupo por acidente.
- [ ] Andar 3: escolher entre trabalhadores, equipamento e rota de retorno,k
  com pressao ajustada ao solo e ao tamanho do grupo.
- [ ] Inserir as recompensas previstas: pedra regenerativa, fragmentos de
  molde, musgo de orientacao e equipamento perdido com procedencia.
- [ ] Dar aos itens descricoes curtas e evidencias consultaveis no diario;
  preservar propriedades de combate, economia e filtros de loot existentes.
- [ ] Conectar cada escolha a um efeito posterior mensuravel; evitar tarefas
  de matar/coletar sem contexto apenas para aumentar a duracao.

**Saida:** cada andar ensina algo pela acao e revela uma pista; prioridades
distintas alteram o encontro seguinte ou o retorno, sem exigir grupo especifico.

## N4: Camara Refeita e objeto impossivel

- [ ] Apresentar o recipiente Ferral ligado ao Primeiro Lastro como evidencia
  parcial. Nao explicar antecipadamente as Duas Marchas nem o agente oculto.
- [ ] Eloa tem uma resposta propria; ferramenta da Casa das Expedicoes permite
  avancar com qualquer outra personagem ou composicao.
- [ ] Integrar o Guardiao de Enxerto ao objeto e a renovacao, reutilizando o
  encontro existente quando compativel; nao confundir com o Refeitor do andar 7.
- [ ] Implementar e testar os desfechos previstos para o confronto, sem tratar
  um chefe contido/incapacitado como morto em falas, loot e flags.
- [ ] Apos o confronto, oferecer retirada imediata ou busca curta de prova
  adicional, com risco comunicado e rota de saida confiavel.

**Saida:** objeto e prova adicional sao distintos; cada desfecho permite
retorno valido e produz um relatorio consistente, em solo e co-op.

## N5: retorno que muda a vila

- [ ] Relatorio resume descobertas, trabalhadores, perdas e provas obtidas.
- [ ] Entregar as quatro opcoes canonicas: custodia publica, Ferral, conselho
  ou ocultacao temporaria. Explicar efeitos conhecidos sem revelar segredos.
- [ ] Cada opcao altera falas e pelo menos um resultado jogavel definido,
  como acesso, preparo ou servico; nenhuma oferece somente vantagens.
- [ ] Conectar pedra regenerativa a uma primeira melhoria comunitaria visivel,
  respeitando os estoques e transacoes do armazem existente.
- [ ] Registrar uma consequencia persistente e abrir o proximo objetivo,
  sem implementar toda a segunda regiao como dependencia deste marco.

**Saida:** a escolha tem efeito perceptivel na mesma sessao e permanece apos
salvar/carregar. Repetir o relatorio nao repete a recompensa ou a obra.

## N6: caminhos alternativos e robustez

- [ ] Definir confirmacao/votacao para custodia e transicoes coletivas,
  incluindo empate, abstencao, desconexao e entrada tardia. Regra aprovada,
  explicita e validada pelo host; sem decisao silenciosa por um cliente.
- [ ] Conversas pessoais nao pausam o combate dos outros. Momentos coletivos
  usam area segura e confirmacao; pausa solo respeita as regras existentes.
- [ ] Testar morte parcial, retirada precoce, fracasso e retorno sem objeto,
  com falas e recompensas coerentes e oportunidade de continuar.
- [ ] Auditar Queda Total contra o runtime. Planejar a vinheta simplificada
  prevista no recorte; nao prometer sucessores jogaveis nem simular salto
  geracional sobre saves atuais sem migracao e validacao especificas.
- [ ] Repeticoes variam contratos, reacoes e eventos sem desfazer custodia,
  revelar segredos cedo ou refazer obrigatoriamente toda a exposicao inicial.
- [ ] Testar foco, leitura, voltar/fechar, tamanho de texto e diario em
  720p, 1080p e janela estreita; validar tambem controles Xbox/PS fisicos.

**Saida:** nenhum caminho essencial bloqueia progresso, exige uma personagem,
duplica recompensa ou perde decisao apos reconexao/migracao de save.

## N7: validacao com jogadores

- [ ] Suite automatizada cobre referencias, spoilers por etapa, objetivos,
  recompensas idempotentes, saves e escolhas sincronizadas.
- [ ] Completar o arco com cada protagonista em solo e em grupos de 2 a 4.
- [ ] Fazer playtest com pessoas que nao conhecem a lore; observar sem
  explicar objetivos nem corrigir interpretacoes durante a sessao.
- [ ] Registrar entendimento da missao, descoberta lembrada, consequencia
  percebida, motivo para voltar, tempo de leitura e pontos de abandono.
- [ ] Medir desempenho e leitura de combate nos eventos narrativos com hordas.
- [ ] Corrigir bloqueadores e repetir o playtest antes de declarar o arco pronto.

**Saida:** jogadores conseguem explicar por que partiram, o que descobriram
e o que mudou em Aresta; concluem sem ajuda do desenvolvedor. Evidencias e
problemas restantes ficam registrados. Quantidade de texto nao e criterio.

## Expansao depois do primeiro arco

Expandir por arcos de regiao: objetivo, pistas, encontro, retorno e consequencia.
Usar a distribuicao de revelacoes do Ultimo Lastro, nao despejar a cosmologia
no inicio. Os Dez Testemunhos entram por fontes verificaveis e descobertas
opcionais; informacao essencial nunca depende de drop raro.

Ficam fora desta primeira entrega: campanha narrativa dos cem andares,
Segunda Ascensao completa, multiverso, Terras Sagradas, geracoes sucessoras
jogaveis, romance e simulacao politica/judicial ampla. Conteudo tecnico desses
andares pode continuar disponivel para teste, sem anunciar campanha concluida.

## Proximo passo executavel

N2 implementado: avancar para N3, com pedido de ajuda e acontecimentos nos
andares 1 a 3, usando as validacoes, contrato, preparo e diario existentes.
Ao concluir cada marco, atualizar este roadmap com testes, capturas, lacunas
e alteracoes reais. Publicacao continua subordinada ao
[roadmap de acesso antecipado](roadmap-steam-acesso-antecipado.md).
