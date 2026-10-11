# N3.1: socorro no Patio das Marcas

Entrega de 2026-10-11: primeiro acontecimento jogavel do N3. Nao conclui o
marco N3 nem o arco Renovacao Antecipada.

## No jogo

- Apos aceitar o contrato, um trabalhador aguarda junto da primeira marca.
- Examinar a marca conserva a prioridade da interacao existente. A proxima
  interacao permite iniciar o acompanhamento; sair sem ajudar continua valido.
- O trabalhador caminha pelo percurso registrado ate o portal. Exige um
  acompanhante conectado e consciente a ate 160 unidades e espera quando
  existe inimigo vivo a menos de 180 unidades. Nao e uma escolta com barra
  de Vida: o perigo interrompe o movimento, sem executar o trabalhador.
- Qualquer integrante pode continuar a escolta; classe especifica nao e exigida.
- Trocar de andar, retirar ou desconectar deixa o acompanhamento suspenso.
  Regressar ao primeiro andar retoma a posicao confirmada, sem recriar premio.
- Chegar ao portal registra o desfecho uma unica vez, remove o NPC do andar,
  acrescenta registro ao diario e uma reacao de Nara. Moradores recebem um fato
  publico de resgate; nenhum spoiler da origem da renovacao e acrescentado.
- Nao ha moeda, reputacao numerica nem item novo nesta entrega. A reacao e
  narrativa; economia e melhorias comunitarias continuam nos marcos seguintes.

## Persistencia e rede

Save v13 acrescenta `rescue_state` e `rescue_progress`. Saves anteriores
migram para trabalhador aguardando, sem inferir resgate por nivel ou andar.
Tipos, limites, numeros nao finitos e estados contraditorios sao rejeitados
antes de alterar o mundo. A conclusao exige chegar ao destino, nao abrir fala.

O host verifica jogador, contrato, zona, andar e distancia. Clientes enviam
somente a intencao `rescue_worker`, nao posicao nem progresso. Snapshot transmite
o trabalhador e o resultado; entrada tardia e reconexao recebem o estado atual.
O resgate compartilhado nao muda custodia nem introduz votacao politica.

## Validacao

- `tests/narrative_rescue_test.gd`: permissao, distancia, idempotencia,
  acompanhamento por outro jogador, perigo, rota sem colisoes, save JSON,
  migracao v12, rejeicao de dados invalidos e reacao no retorno.
- `tests/narrative_online_smoke.sh`: intencao enviada pelo cliente, duplicatas,
  escolta pelo host, conclusao, diario, reconexao e entrada tardia.
- `tools/art/rescue_shots.gd`: nove capturas de encontro, acompanhamento e Nara
  em 1280x720, 1920x1080 e 640x720.

Suite local: 90 testes aprovados, zero falhas, incluindo rede. A regressao de
resgate e a prova de rede tambem passaram apos o ajuste final da chegada ao
portal; capturas atualizadas e conferidas. Controle fisico e playtest externo
continuam pendentes.

## Pendencias

Rota segura versus fissura opcional, registro explicito de abandono, reputacao
com efeitos jogaveis, eventos dos andares 2 e 3 e playtest de compreensao.
A escolta opcional nao bloqueia contrato, escada, portal nem recompensa do N1.
