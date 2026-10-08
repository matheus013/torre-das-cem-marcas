# N2: abertura em Aresta e preparacao

Implementado em 2026-10-07 sobre o contrato de campo do N1. Esta entrega
apresenta o problema da Renovacao Antecipada e o primeiro destino; nao
conclui o arco nem explica a origem do objeto ou da renovacao.

## No jogo

- O objetivo inicial leva a Alda no Conselho. O texto mostra a direcao do
  morador e um contorno dourado o destaca quando entra no campo de visao.
- Alda explica o risco para as rotas, trabalho e materiais de Aresta.
  **Registrar pedido de Alda** confirma o contexto no diario e encaminha
  para Nara na Casa das Expedicoes. Apenas abrir a conversa nao grava a flag.
- Nara mantem o contrato do primeiro andar. Aceita-lo diretamente continua
  permitido: Alda e os servicos nao viram requisitos para entrar na Torre.
- O preparo mostra Vida, Folego, ferimentos, suprimentos e menor integridade
  equipada, usando o estado real de cada jogador. Aponta os atendentes
  existentes, sem inventar novas compras, taxas ou curas.
- Nara explica portao, primeiro destino, retorno e risco de perder a carga.
  O registro nao exige compra. A observacao continua protegida na derrota.
- Saves avancados podem selecionar **andar 1 para a proxima entrada** junto
  de Nara, explicitamente. Andares desbloqueados permanecem acessiveis.
  Se outro integrante ja estiver na Torre, o painel avisa que entrar agora
  acompanha o andar do grupo; a escolha vale quando a Torre estiver vazia.
- Dalia, Maura e Cassio apresentam contexto curto no mesmo menu de servicos.
  **Conversar** abre a fala autoral e um rumor identificado como nao confirmado.
  Tamar tambem oferece um relato da vigilia, sem bloquear o portao.
- Eloa, Sena, Cira e Rui possuem reacoes proprias na abertura e com Nara.
  Elas refletem curiosidade material, cuidado com retirada, autonomia corporal
  e seguranca estrutural, sem restringir builds ou exigir uma personagem.

Os rumores divergem entre mapas desatualizados, pedra que se recompoe e
contato com material recente. Sao possibilidades levantadas por moradores,
nao eventos confirmados nem pistas que resolvam o misterio.

## Dados e persistencia

Catalogo autoral: `data/narrative/village_opening.json`. Mantem os NPCs,
rotinas, servicos e geografia existentes. Alda continua no Conselho; nao
foi movida silenciosamente para outro bairro por causa do roteiro.

`opening_known` pertence ao mundo do host, foi introduzida no save v11 e
continua presente nas versoes seguintes. Comandos duplicados nao repetem a
confirmacao nem concedem recompensa. O host verifica ator, zona e distancia
ate Alda; selecionar destino exige proximidade de Nara e contrato ativo.

Saves anteriores a v11 sem a flag iniciam com a abertura nao registrada,
preservando o estado do contrato, relato, inventario e andares. Saves atuais
sem a flag ou com tipo invalido sao rejeitados antes de modificar o mundo.
Recuperacao atomica e backup seguem a infraestrutura existente do N1.

Falas essenciais e rumores desta entrega nao dependem da IA opcional dos
moradores. O snapshot confirma fatos comuns; a apresentacao escolhe a
reacao e o preparo do jogador local, sem enviar esses textos como comandos.

## Validacao

- `tests/narrative_opening_test.gd`: referencias de NPCs, quatro reacoes,
  ausencia de revelacoes tardias, leitura sem avancar flag, confirmacao
  idempotente, distancia/estado/ator, migracao v10 e rejeicao de flag invalida.
- Cobertura de acesso direto a Nara com os quatro protagonistas, preservacao
  dos andares e escolha explicita do primeiro destino; preparo medido e
  aviso sobre grupo presente na Torre.
- Cobertura de contexto sem remover ofertas de servicos, rumores separados,
  diario sem transacoes e foco em texto com rolagem automatica.
- `tests/narrative_online_smoke.sh`: cliente confirma Alda antes do contrato;
  comandos duplicados, reconexao e entrada tardia preservam contexto e diario.
- `tools/art/narrative_shots.gd`: 24 capturas GPU de Alda, Nara, oficina,
  rumor e evidencia em 1280x720, 1920x1080 e 640x720.
- `sh tests/run_all.sh`: 79 testes aprovados no checkout compartilhado em
  2026-10-07, nenhuma falha. As ultimas verificacoes focadas de abertura
  e capturas tambem passaram apos os ajustes de preparo e foco.

Pendente: controle Xbox/PS fisico e playtest com quem nao conhece a lore.
Entender objetivo e destino em ate cinco minutos continua sendo um alvo de
playtest, nao um resultado comprovado por testes automatizados.

## Proximo marco

N3 deve transformar os andares 1 a 3 em acontecimentos: pedido de ajuda,
rota alterada e prioridade entre trabalhadores, equipamento e retorno.
O registro fixo do N1 permanece como prova da infraestrutura, nao substitui
essas escolhas nem produz reputacao ou consequencias que ainda nao existem.
