# N3.3: Cicatrizacao no andar 2

Entrega de 2026-10-11. Implementa a mudanca de rota do recorte vertical,
sem antecipar a causa da Renovacao Antecipada. Trabalhadores e coleta
narrativa do andar 2 ainda nao fazem parte desta entrega.

## Fluxo jogavel

- Com o contrato iniciado, examinar a junta instavel no trecho central
  das Vias de Extracao com a interacao existente de teclado ou controle.
- A junta fica visivel antes da interacao. O desvio ao sul possui desgaste
  de piso, linha tracejada e legenda; nao exige item, classe ou recompensa.
- O host inicia um aviso de cinco segundos. O combate continua; a pausa
  de escolhas de nivel congela tambem o acontecimento.
- Ao terminar o aviso, tres segmentos de pedra recompostos bloqueiam o
  trecho central. A colisao corresponde aos assets existentes da galeria.
- O fechamento aguarda personagens, corpos caidos/desconectados e inimigos
  vivos sairem da passagem. Enquanto isso, a HUD explica a espera.
- Loot no trecho fechado e reposicionado em terreno acessivel, sem alterar
  itens de outras zonas. O desvio liga os dois lados, a escada e o portal.
- A observacao entra no diario compartilhado e na reacao de Nara. Nao
  conclui a primeira marca, entrega recompensa ou explica segredos da lore.

## Autoridade e persistencia

Estados `unseen`, `warning`, `closed`, com cronometro finito de 0 a 5.
Interacao validada pelo host: contrato, andar, zona, conexao, personagem
consciente e distancia. Reenvio nao reinicia aviso nem duplica paredes.

O aviso para quando nao ha jogador conectado no andar 2 e continua no
retorno. A passagem fechada permanece registrada nas reentradas desse mundo.
Isso e uma observacao persistente, nao um sorteio novo a cada expedicao.

Save v15 persiste estado e tempo. Saves anteriores migram para `unseen`,
sem inventar descobertas nem retirar itens. O layout fechado e derivado
sem modificar o cache do mapa original. Clientes atualizam a geometria
mesmo quando o numero do andar nao muda; reconexao/entrada tardia recebem
o estado confirmado.

## Validacao

- `tests/narrative_cicatrization_test.gd`: autoridade, reenvio, aviso,
  corpos desconectados/caidos, inimigos, loot, cache imutavel, desvio
  completo com raio 24, reentrada, saves e migracao v14.
- `tests/cicatrization_online_smoke.sh`: comando de cliente duplicado,
  aviso antes da colisao, diario, mapa local fechado, reconexao e entrada tardia.
- `tools/art/cicatrization_shots.gd`: nove capturas em 1280x720, 1920x1080
  e 640x720 para junta, aviso e passagem fechada, em `art/shots/cicatrization`.
- `sh tests/run_all.sh`: 93 testes aprovados, zero falhas, incluindo as
  quatro provas de rede. Testes focados de Cicatrizacao e ausencia de
  scroll horizontal repetidos apos os ajustes finais.
- Capturas revisadas em janela estreita, 720p e 1080p; legenda do desvio
  reposicionada acima da HUD. Controles Xbox/PS fisicos e compreensao do
  desvio ainda precisam de playtest externo.

## Pendencias de N3

Trabalhadores/coleta e suas consequencias no andar 2; prioridades do
andar 3; abandono/reputacao do socorro no andar 1. N3 permanece parcial.
