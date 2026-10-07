# N1: primeiro contrato narrativo jogavel

Entrega em 2026-10-07. Prova pequena da infraestrutura, nao conclusao do arco
Renovacao Antecipada nem nova explicacao canonica do Ultimo Lastro.

## Fluxo no jogo

1. Encontrar Nara Quiral em Aresta e aceitar **Registro da primeira rota**.
2. Entrar no andar 1 e examinar a marca no trecho central, indicada no mapa
   e por um contorno dourado junto a uma junta de pedra.
3. Retornar pela saida da Torre. Uma derrota tambem preserva a observacao.
4. Entregar o relato a Nara: um Musgo de Orientacao vai para as reservas de
   expedicao, exibidas no inventario como **Armazem da vila**.

O botao **Diario**, no cabecalho do menu de personagem/inventario/Torre,
abre as observacoes confirmadas. O objetivo atual acompanha a exploracao.
Interacao utiliza o comando ja configuravel, inclusive no controle.
Dialogos possuem foco inicial, navegacao de botoes e fechamento pelo comando
de voltar. Se Nara se afastar, a leitura permanece aberta, mas a transacao
fica desabilitada; o host verifica a distancia novamente ao receber o pedido.

## Autoridade e persistencia

- Catalogo: `data/narrative/first_route.json`; IDs estaveis para contrato,
  NPC, pista, recompensa e estados, com referencias cobertas pelo teste.
- Estado compartilhado por mundo: `available`, `active`, `evidence_found`,
  `report_ready`, `completed`. Nao ha escolhas pessoais nesta prova;
  portanto, nao foram introduzidas flags individuais sem uso.
- Aceitar/entregar exige jogador conectado, nao incapacitado, na vila e a
  ate 110 unidades de Nara. Examinar exige andar 1 e ate 90 da pista.
- Descoberta pertence ao grupo. A saida ou derrota confirmada de um membro
  na Torre leva o registro para Aresta; desconexao nao simula um retorno.
  Qualquer membro pode entregar depois, sem depender do ID de rede original.
- Recompensa ocorre apenas na transicao `report_ready -> completed`.
  Repeticao de comando, recarga, reconexao e entrada tardia nao a repetem.
- Save v10 grava estado e resultado do retorno. Saves v1-v9 sem narrativa
  iniciam o contrato disponivel, preservando os sistemas de progressao.
  Andares ja desbloqueados nao sao bloqueados pela nova missao.
- Save v10 com narrativa ausente, vazia ou inconsistente e rejeitado antes
  de alterar o mundo. A gravacao atomica e recuperacao `.bak` existentes
  continuam em uso; versoes futuras continuam protegidas de sobrescrita.
- Evidencia nao e loot: nao pode ser vendida, filtrada nem perdida na derrota.
  Falas sao escritas e funcionam offline, independentemente da IA opcional.
- Cliente envia apenas uma acao; posicao, etapa e recompensa sao verificadas
  pelo host. Snapshot existente distribui objetivo, dialogo e diario.

As reservas de expedicao (`banked_loot`) continuam distintas dos estoques
locais de trabalhadores (`warehouse.stock`). N1 nao muda essa economia.

## Verificacao

- `tests/narrative_progress_test.gd`: referencias, jogador/distancia/andar,
  idempotencia, revelacao por etapa, retirada, derrota, save JSON, recompensa
  apos recarga, migracao de equipamento/niveis/gemas, backup e foco do menu.
- `tests/narrative_online_smoke.sh`: processos ENet reais; cliente aceita,
  examina e entrega pela mesma rota de intencoes usada no jogo. Comandos
  duplicados, reconexao do mesmo perfil e entrada de novo jogador recebem
  diario concluido; host confirma exatamente uma recompensa.
  O teste posiciona os jogadores para isolar o contrato, sem validar caminhada.
- `tools/art/narrative_shots.gd`: 15 capturas GPU, estados de dialogo e pista
  em 1280x720, 1920x1080 e 640x720, em `art/shots/narrative/` (QA local).
- Suite `sh tests/run_all.sh`: 72 testes aprovados, nenhuma falha em
  2026-10-07. Inclui as provas de rede e regressao dos sistemas existentes.

## Limites e proximo marco

N2 integra abertura com Alda, contexto da crise, preparacao e orientacao de
partida. N3-N5 ainda precisam dos acontecimentos dos andares, objeto e custodia.
A marca de rota e a recompensa modesta de N1 sao uma prova de registro de
campo, nao substituem esses eventos nem revelam o agente da renovacao.

Permanecem pendentes: playtest com leitores novos, controles Xbox/PS fisicos,
contraste em hordas densas e substituicao da pedra reutilizada por arte propria
de junta marcada quando os eventos definitivos dos andares forem montados.
