# Revisao de Aresta: hordas, expedicoes e RPG

Data: 2026-10-03. Base: `20ffed3`, com reorganizacao local de `project.godot`
preservada. Direcao confirmada pelo responsavel: **hordas + expedicoes**.

Esta e uma revisao e proposta de producao, nao uma alteracao automatica de
regras aprovadas. Novas mecanicas, economia, duracoes e limites abaixo precisam
de prototipo/playtest. Nao houve rebalanceamento, alteracao de save ou mudanca
do combate nesta entrega. Auditoria por subsistemas e caminhos criticos, nao
prova de que cada linha, andar, asset ou combinacao esteja correta.

## Diagnostico prioritario

| Prioridade | Achado | Evidencia | Acao antes de ampliar conteudo |
| --- | --- | --- | --- |
| P1 | Efeitos de equipamento/reliquia nao chegam ao combate | `equipment_loadout.gd:144` enumera mecanicas, sem consumidor no jogo principal; `world_simulation.gd:2686` consulta mecanicas de marcos, nao de itens | Integrar efeitos ao resolvedor/eventos; teste observavel por item |
| P1 | Parte dos atributos de itens nao produz efeito | `world_simulation.gd:2725` nao aplica `defense`, `magic_power`, `area`, `stability`, `interaction_speed` e `carry_capacity` vindos de equipamento | Registro canonico de atributos e consumidores; nao exibir bonus inerte |
| P1 | Saque antigo pode desaparecer silenciosamente | `world_simulation.gd:2567` remove a primeira entrada ao ultrapassar 120 drops, sem distinguir reliquia, carga perdida ou andar | Separar armazenamento persistente do limite de apresentacao; proteger carga/itens unicos |
| P1 | Vetores nao finitos entram na simulacao | `village_exploration.gd:319` valida tipo; `world_simulation.gd:559` aceita destino infinito | Validar finitude, limites e frequencia no limite autoritativo |
| P2 | Elo Residual escala com atributo inexistente | `beta_content.json:356` usa `luck`; atributos canonicos usam `fortune` | Corrigir catalogo/gerador e validar toda referencia de escala |
| P2 | Factory descarta metadados de equipamento | `beta_item_factory.gd:26` nao importa `two_handed`, tags e incompatibilidades | Completar traducao e teste de contrato; catalogo atual nao declara esses campos |
| P2 | Loot/economia tem poucos usos e pouca agencia | `leave_tower:930`, `use_quick_item:643`; catalogo tem materiais/consumiveis sem servico correspondente | Contratos, fabricacao reduzida e suprimentos reais antes de adicionar moedas |
| P2 | Co-op e documentacao ainda divergem | ADR 0018 menciona saque de quem matou; runtime coleta por proximidade. GDD historico fala em gemas fisicas/geracoes, beta salva gemas por personagem | Matriz implementado/proposto/adiado e regra de partilha visivel |

O beta tem 4 personagens, 8 gemas ativas, 12 suportes e 32 itens; destes, 24
sao equipamentos e 14 declaram mecanicas. A Torre adiciona 100 andares, 11
definicoes de chefe e 18 itens sem slot. Quantidade no catalogo nao comprova
variedade funcional, cobertura dos efeitos nem qualidade de cada andar.

### Reproducao

```sh
godot --headless --path . --script tools/bench/gameplay_audit.gd
godot --headless --path . --script tools/bench/gameplay_audit.gd -- --strict
```

Diagnostico reproduziu 7 ocorrencias: escala `luck`, tres itens sem alteracao
nos atributos derivados/gemas, metadados descartados, reliquia removida pelo
limite de drops e destino infinito aceito. Esses probes sao direcionados; nao
substituem testes de todos os contextos. `--strict` falha enquanto houver achados.
Sem `--strict`, codigo zero significa diagnostico executado, nao jogo aprovado.
O probe usa mundos em memoria e nao grava saves/configuracoes.

## O que preservar

- Simulacao autoritativa separada de apresentacao; solo e host usam as mesmas regras.
- Quatro personagens com passivas autorais e liberdade de gemas/equipamentos.
- Quatro comandos ativos, ataque basico automatico e mira automatica opcional.
- Suportes com capacidade e contrapartida: ja existe uma boa base de combinacoes.
- Vila como retorno com memoria, nao uma tela abstrata de upgrades.
- Risco de carga, retirada, resgate de aliado e ferimentos de expedicao.
- Conteudo orientado a dados, transacoes de equipamento, testes e CI.
- Persistencia protegida; preservar IDs e preparar migracoes antes de ampliar itens.

O principal problema nao e falta de sistemas: e a distancia entre sistemas
declarados, efeitos executados e decisoes que o jogador percebe.

## Posicionamento recomendado

**RPG cooperativo de expedicoes com combate de hordas, builds de gemas e uma
vila que muda com o que o grupo consegue trazer de volta.**

Combate acessivel, dominio por posicionamento e sinergia; tensao por decidir
entre proteger a carga ou continuar; progressao persistente sem apagar a
improvisacao de cada expedicao. Nao incluir fome, sede ou manutencao incessante
para justificar o termo survival. Nao tentar competir por numero de sistemas.

## Referencias e adaptacao

As fontes descrevem mecanicas existentes; nao provam que uma mecanica isolada
causou sucesso comercial. A aplicacao a Aresta e uma hipotese de design.

| Referencia primaria | Padrao estudado | Adaptacao, nao copia |
| --- | --- | --- |
| [Vampire Survivors / poncle](https://poncle.games/operation-guns) | Armas com evolucoes e pressao de tempo | Transformacao perceptivel da gema durante a expedicao |
| [Deep Rock Galactic: Survivor](https://store.steampowered.com/app/2321470/Deep_Rock_Galactic__Survivor/) | Hordas, recursos, objetivos e extracao | Explorar por objetivo, nao apenas completar contador de abates |
| [Grim Dawn: loot](https://www.grimdawn.com/guide/items/the-hunt-for-loot/) e [componentes](https://www.grimdawn.com/guide/items/components/) | Itens de fontes especificas e personalizacao de equipamento | Cacada direcionada e fabricacao que reduz dependencia da sorte |
| [V Rising: Jewels](https://blog.stunlock.com/dev-update-17-dark-magic-designs/) | Modificacoes individuais das magias, compativeis com progressao da area | Usar suportes/reliquias ja existentes em vez de criar outro sistema paralelo |
| [Hades: FAQ oficial](https://www.supergiantgames.com/blog/hades-faq/) | Retornos com personagens que lembram o jogador e desenvolvimento iterativo | Consequencias curtas na vila e releases guiadas por feedback |
| [Valve: AI Systems of Left 4 Dead](https://cdn.akamai.steamstatic.com/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf) | Alternancia de intensidade; ritmo distinto de dificuldade | Diretor com picos e respiros sem mudar dano secretamente |

## Ciclo de uma expedicao

Hipotese inicial: uma rota curta de 15-25 minutos, separada da campanha longa.
Conflita com o alvo historico de 30-60 minutos do recorte: precisa de aprovacao
e teste, nao substitui esse alvo automaticamente.

1. **Preparar:** selecionar personagem, loadout, um contrato e suprimentos.
2. **Entrar:** mostrar objetivo, ameacas da regiao e possivel recompensa.
3. **Sobreviver:** alternar enxames, elites com funcoes e pequenos respiros.
4. **Adaptar:** obter Marcas de Expedicao temporarias, entre encontros.
5. **Arriscar:** rota opcional oferece recompensa conhecida e custo informado.
6. **Retornar ou continuar:** extracao preserva carga; avancar conserva a build temporaria.
7. **Transformar a vila:** entregar contrato, fabricar, recuperar ferimentos e ver uma consequencia.

### Duas camadas de build

**Persistente:** personagem, atributos, marcos, equipamento, gemas, suportes,
receitas e servicos. E a identidade que o jogador leva para a Torre.

**Temporaria, proposta:** Marcas de Expedicao concedidas por objetivos/elites,
nao por todo nivel de personagem. Escolher uma de tres opcoes em um ponto
seguro. Tres categorias: tecnica, sobrevivencia e expedicao; iniciar com
seis opcoes totais e ate tres marcas ativas. Ofertas devem ser aplicaveis ao
loadout, sem duplicata morta e sem criar cura/barreira/projeteis recursivos.

Exemplos: primeira perfuracao gera ricochete limitado; dash deixa faixa de
controle; excesso de cura fortalece uma invocacao; marca de coleta amplia
alcance com contrapartida de combate. Cada marca precisa alterar uma decisao.

Solo pode pausar para escolher. Co-op escolhe em marco seguro validado pelo
host, com estado de pronto e tratamento de desconexao; nunca abrir escolha
ininterruptivel no meio da horda nem pausar o mundo de um jogador isoladamente.
Nao trocar gemas na Torre: marcas modificam a expedicao, preservando a regra
aprovada de loadout preparado na vila. Reiniciam na derrota/retirada, com
semantica de save definida antes da implementacao.

### Objetivos e rotas

Comecar com dois objetivos alem de abates: estabilizar uma fissura e recuperar
um cache defendido. Cada um reusa inimigos/telegrafias existentes e recompensa
um tipo conhecido de material/marca. Depois acrescentar elite alvo, mecanismo
do bioma e salas de risco. Escortas, cidades internas e grandes puzzles ficam
fora da primeira entrega.

Rotas: segura (material garantido), combate (marca), evento (troca com custo
explicito). Pontos de interesse aparecem no mapa; nao obrigar a vasculhar toda
arena vazia. Todo objetivo recebe versao solo e ajuste por grupo, sem classe
obrigatoria. Validar conectividade entre entrada, objetivo e saida por seed.

### Diretor de hordas

Estados pequenos: preparar, pressionar, pico, respiro. Entrada considera tempo,
ameacas vivas, dano recente, queda e objetivo; limita spawns e sobreposicao de
perigos. Respiro reduz novas ameacas, nao apaga inimigos nem altera dano/loot.
Chefes mantem roteiro proprio. Eventos e seed sao autoritativos e auditaveis.

O respawn acelerado atual pode ser parte da pressao de expedicao, mas nao deve
ser a unica fonte de ritmo. Separar escalada de risco de reposicao de inimigos.
Recordes devem fixar seed/modificadores/versao de regras para comparacao justa;
diretor adaptativo e ranking competitivo exigem modos/regras explicitos.

## Itemizacao proposta

### Cada camada precisa de uma funcao

| Camada | Funcao | Limite de complexidade inicial |
| --- | --- | --- |
| Arma/offhand | Forma de atacar ou sustentar a build | Fazer identidade funcional antes de criar dez armas iguais |
| Armadura/luvas/botas/calca | Defesa, execucao, mobilidade e sustentacao | Um beneficio principal e no maximo um secundario |
| Aneis/amuleto | Ajuste e sinergia de build | Efeitos curtos, limites compartilhados e comparacao simples |
| Reliquia | Transformacao de comportamento | Efeito observavel com gatilho, limite e contrapartida |
| Gemas/suportes | Ferramentas e especializacao | Reusar tags, capacidade e compatibilidade existentes |
| Suprimentos | Escolha de risco antes de entrar | Dois tipos operacionais inicialmente, sem nova barra permanente |
| Materiais/receitas | Progresso escolhido na vila | Poucos materiais com uso real e fontes identificaveis |

Manter cinco tiers e separar tier, fabricacao e efeito. Raridade maior nao
precisa ser melhor para toda build. Nao juntar tier, qualidade, integridade,
afixos, set, sockets, corrupcao e poder de item numa unica primeira entrega.

Proposta de orcamento: comum com propriedade simples; incomum com dois
atributos; raro com uma sinergia condicional; epico/lendario com identidade
autoral. Nao mudar o tier de itens existentes sem revisao/migracao. Duas
propriedades aleatorias por instancia (prefixo/sufixo) ficam para depois de
efeitos fixos e comparacao estarem corretos. Afixo de item e distinto de afixo
de inimigo; faixas e combinacoes invalidas devem ser declaradas por dados.

**Dez aneis e quatro reliquias:** manter capacidade aprovada. Testar primeiro
com cerca de quatro aneis e uma reliquia significativa; nao balancear inicio
assumindo 21 slots cheios. Progressao/ativacao gradual de slots seria nova
decisao e nao deve desativar slots de saves existentes silenciosamente.

### Primeira colecao funcional

Propostas para validar em prototipo, sem afirmar que ja executam:

| Item | Decisao que cria | Regra de seguranca |
| --- | --- | --- |
| Escudo de Escora | Sustentar posicao e mitigar impacto | Mitigacao com limite; comunicar defesa efetiva |
| Foco de Vidro Termico | Trocar protecao por potencia/area magica | Modifica somente tags aplicaveis; compara raio e dano final |
| Anel de Retorno | Sustentar Folego em enxames | Recuperacao por baixa com teto por segundo; nao contar secundario duas vezes |
| Anel de Area | Cobrir horda em vez de focar chefe | Aumento de raio explicito e limite compartilhado |
| Coracao de Junta | Reerguer barreira uma vez por encontro | Gatilho limitado; barreira recriada nao recria outra barreira |
| Molde sem Dono | Consumivel beneficia invocacao ativa | Uma replicacao por uso; nao gera copia de item nem nova carga |
| Lastro Partido | Dash cria campo de controle | Um campo por dono/cast; limite de duracao, nao stun permanente de chefe |
| Faixa/tonico | Preparar recuperacao ou sustento | Estoque/uso reais, sem cura infinita por ida e volta ao menu |

### Quatro builds para provar variedade

Nao sao classes obrigatorias; qualquer personagem pode usar os componentes.

| Build | Gemas/suportes ja existentes | Identidade e fraqueza |
| --- | --- | --- |
| Perfuracao e retorno | Agulha + perfuracao/ricochete | Limpa linhas; exige posicionamento e perde valor com poucos alvos |
| Controle de cicatriz | Prisao + Pulso + area/duracao | Junta e explode hordas; chefe exige janelas e menor controle |
| Oficina ambulante | Molde + Muralha + suporte de duracao | Domina uma zona; reposicionar tem custo |
| Rota de resgate | Passo + Semeadura + fluxo/estabilidade | Sustenta retirada/grupo; menor explosao ofensiva |

Objetivo: duas builds viaveis por personagem e ao menos uma escolha com
contrapartida por build. Medir combate, controle, mobilidade e sobrevivencia;
nao reduzir toda comparacao a DPS de alvo parado.

### Obtencao e fabricacao

Fontes visiveis por bioma/elite/chefe e codex de materiais. Um contrato oferece
recompensa escolhida ou receita; derrotar um chefe pela primeira vez entrega
progresso deterministico. RNG oferece surpresa, nao bloqueia a build basica.

Reaproveitar Pedra Regenerativa, Escama de Reboco e Argila de Enxerto. Forja
inicial fabrica uma base conhecida e melhora fabricacao uma vez com custo
claro; reciclar duplicatas gera material, com bloqueio para favorito/equipado.
Nao prometer forge/reciclagem enquanto `banked_loot` nao tiver consumo real.

Depois: trocar UMA propriedade mediante custo limitado, mantendo instancia e
procedencia. Nao re-rolar item inteiro infinitamente. Receita pertence ao mundo
ou personagem por regra explicita; fabricacao e salvamento sao transacionais.

## Co-op e risco de carga

O runtime protege equipamento adquirido imediatamente e derruba materiais na
derrota. Isso reduz risco do loot mais valioso; decidir explicitamente entre
manter essa regra acessivel ou usar mochila de expedicao para itens novos.
Mudar perda de equipamentos exige aprovacao e comunicacao antes de entrar.

Primeira entrega de partilha: materiais comuns no estoque do grupo ao extrair;
equipamento com curto direito de coleta/transferencia, identificado na UI.
Nao fazer quatro drops pessoais automaticamente: muda a economia. Registrar
proprietario, seed e ID; recolher, transferir e fabricar deve ser idempotente.

Descida/entrada de chefe: confirmar prontidao para nao puxar um aliado lendo
menu. Ao desconectar, definir quorum e reserva; convidado ve antes de entrar
que o progresso fica no host. Resgate, marcas e objetivos funcionam em solo.
Sem PvP ou crime/roubo entre jogadores na primeira entrega comercial.

## Boas praticas de producao e engenharia

### Arquitetura e dados

- Manter Godot/GDScript e o host autoritativo; nao migrar engine ou adicionar ECS por moda.
- Extrair regras de loot/equipamento, encontros e expedicao gradualmente, com APIs pequenas e testes de caracterizacao. A contagem de linhas sozinha nao obriga refatoracao.
- Definicao imutavel por ID; instancia guarda dono, afixos, integridade e localizacao. Um item deve ter uma unica fonte de verdade, nao virar moeda paralela no armazem.
- Registro de stats/efeitos/tags com tipo, unidade, fase, stacking e consumidor. Catalogo recusa ID desconhecido, referencia ausente e valor nao finito.
- Pipeline explicito: base, evolucoes, suportes, passiva, equipamento, temporarios e limites. Produzir trilha para tooltips/testes.
- Gatilhos carregam origem/cast/owner/parent; limitar profundidade, cooldown e quantidade. Efeito secundario nao pode disparar a si mesmo indefinidamente.
- Somar bonus de mesma categoria, aplicar multiplicadores em fases claras; teto de critico/controle/recarga documentado. Sem porcentagens negativas/overflow silenciosos.
- Cache de atributos/efeitos invalidado por equipar, evoluir, trocar e carregar; somente depois de medicao.
- Novo dado persistente exige migracao explicita, fixture e teste antes de subir versao do save; transacoes nao criam IDs novos ao reabrir menu.

### Desempenho e rede

Profiling antes de otimizar, como recomenda a [documentacao Godot](https://docs.godotengine.org/en/4.6/tutorials/performance/general_optimization.html).
Priorizar consultas espaciais para alvos/areas, IDs estaveis e caches nos hot
paths medidos. Agrupar atualizacao de inimigos distantes; separar estado de
simulacao do custo de desenhar luzes/particulas. Pooling apenas para alocacoes
que o profiler confirmar, nao uma reescrita de tudo.

Validar vetores finitos/alcance e tamanho de argumentos, rate limit por peer,
handshake, versao de protocolo, tamanho comprimido/descomprimido e schema de
snapshot. Perfil textual e identidade de reconexao, nao autenticacao forte.
Nao anunciar protecao anti-cheat contra host nem protecao contra roubo de ID.
Snapshots por relevancia, deltas e interpolacao de inimigos apos medir trafego
e latencia; testar 100/200 ms, jitter, perdas e reconexoes. Nao implementar
host migration, relay ou matchmaking antes do ciclo local ficar confiavel.

### UX, acessibilidade e audio

- HUD prioriza ameaca, Vida/Folego, recarga, objetivo, carga e saida. Poucas mensagens persistentes; log de combate separado.
- Telegrafo usa forma, animacao e som, nao somente vermelho/laranja. Ataque inimigo sempre acima de efeitos aliados em prioridade visual.
- Comparacao mostra efeito final e contrapartida, unidade (%/pontos/segundos), origem e compatibilidade; simular equipar sem aplicar a transacao.
- Inventario com ordenar, filtrar, comparar, marcar favorito e desmontar com confirmacao. Acao perigosa nao pode ser auto-selecionada pelo controle.
- Validar UI a 720p/1080p/ultrawide, textos PT-BR longos, foco de controle e desconexao. Capturas antigas de `docs/images` nao sao QA atual de todas as telas.
- Reducao de efeitos, tremor/flash ajustaveis, tamanho de texto e sinais redundantes; audio com prioridade/limite de vozes para evitar caos com quatro jogadores.
- Integrar impactos, habilidades, perigo, loot e retorno com licenca/proveniencia. Buses existentes sem sons nao entregam feedback de combate.

### Testes, conteudo e entrega

Testes de propriedades: nenhum item duplicado/perdido numa transacao, budget
conservado, valores finitos, limites de efeitos e mesma regra solo/co-op.
Replays de comandos/seed servem a regressao, sem prometer determinismo bit a
bit entre plataformas. Geradores precisam ser reprodutiveis e validar saida.

Fazer saves durante boss, queda, inventario cheio, transferencia e retorno;
reabrir em build seguinte. Soak, perfis de horda/efeitos e testes nativos dos
artefatos exportados. Unidade funcional, QA de gameplay e aprovacao Steam sao
gates distintos. Toda feature precisa de input, UI, audio/VFX, save, rede e teste,
ou deve estar identificada como incompleta/fora da promessa comercial.

## Medicoes desta revisao

- Suite local: **35 aprovados, zero falhas**. Isso nao detectou os bonus inertes.
- Benchmark existente, debug/headless nesta maquina: 160 configurados, 159 finais,
  media 4,666 ms e pior 8,030 ms para `step + view_snapshot`; snapshot comprimido
  7.172 bytes, estimativa 1.147,5 kbit/s por cliente a 20 Hz, sem overhead ENet.
- Caso configurado com 80: pico isolado de 40,814 ms. Nao inferir causa sem profiler.
- Casos de 8/40 terminaram com 63 inimigos: o benchmark atual nao fixa exatamente
  a populacao solicitada. Sem p95/p99, baseline hardware e render real.
- Sonda solo: andar 75 marcou `ok` apos 3 derrotas/252,4 s; andar 100 apos 1
  derrota/60,9 s. O piloto reentra automaticamente: `ok` nao significa vitoria
  sem derrota. Tambem inicia com nivel do andar e escolhas artificiais.

Nao usar estes numeros como requisito minimo comercial nem como prova de
diversao. Repetir release/render com cenas representativas, varias seeds,
quatro personagens e grupos 1-4; separar tempo ate falha e tempo ate concluir.

## Ordem recomendada

1. **G0: confianca no loot.** Corrigir bonus/mecanicas, escala e preservacao de drops; validar entradas/IDs.
2. **G1: microexpedicao completa.** Um contrato, dois objetivos, retorno e um uso real dos materiais.
3. **G2: improvisacao.** Seis marcas temporarias, escolhas seguras e resgate integrado.
4. **G3: builds desejaveis.** Primeira colecao funcional, comparacao, craft/reciclagem e fontes direcionadas.
5. **G4: ritmo e co-op.** Diretor, prontidao/partilha, audio/legibilidade e QA sob latencia.
6. **G5: prova comercial.** Playtest externo, estabilidade, migracao e gates Steam existentes.

Nao produzir mais biomas antes de uma rota curta demonstrar vontade de repetir.
Manter os 100 andares existentes para testes, sem anunciar todos como conteudo
acabado. Nao apagar sistemas aprovados: funcionalidades geracionais, politica
e cidades continuam horizonte, separadas do escopo publicavel.

## Criterios de playtest

Metas propostas para investigar, nao benchmarks de mercado nem metricas atuais:

- Cinco novos jogadores testam primeira sessao sem instrucao; ao menos quatro explicam objetivo, extracao e perda de carga.
- Cada personagem completa a rota com duas builds diferentes; grupo nao exige curador/tanque.
- Jogador consegue nomear uma decisao de build e uma decisao de risco por expedicao.
- Pelo menos tres caminhos de obtencao geram item/receita desejavel sem grind cego.
- Tempo em menu/inventario e repeticao de contratos sao observados, nao so XP/min.
- Registrar por que a pessoa morreu, retornou ou desistiu, e se deseja repetir; nao confundir retencao com obrigacao diaria.
- Logs locais opt-in de combate/itens sem ID pessoal/chave/IP; agregacao externa somente com consentimento e politica clara.

Sem temporada, passe, daily obrigatoria, gacha ou grind desenhado para impedir
o jogador de parar. O objetivo e uma expedicao boa, nao maximizar horas a qualquer custo.
