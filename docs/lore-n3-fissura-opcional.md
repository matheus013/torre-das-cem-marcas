# N3.2: rota registrada e fissura opcional

Entrega de 2026-10-11. Complementa o socorro do primeiro andar, sem concluir
os eventos dos andares 2 e 3 nem todo o marco N3.

## No jogo

- Uma bifurcacao entre as duas salas do Patio das Marcas tem um ramal lateral
  de 420 unidades. Pedra, pavimento gasto e rotulos distinguem os dois destinos.
- A interacao na rota registrada confirma a preferencia no diario, sem custo,
  sem inimigos adicionais e sem fechar o desvio para qualquer integrante.
  "Registrada" nao significa ausencia de hordas: e o caminho principal existente.
- Antes de entrar na fissura, a dica avisa que a acao atrai dois inimigos.
  Confirmar cria dois inimigos comuns usando as regras atuais do andar;
  repetir o comando nao cria outra dupla.
- O vestigio fica no fim do ramal. Sua leitura exige proximidade e nenhum
  inimigo vivo a menos de 180 unidades. Nao exige matar todos os inimigos do mapa.
- A evidencia complementar aparece no diario e na fala de Nara. Nao substitui
  a primeira marca, nao revela a causa da renovacao e nao concede premio extra.
  Os inimigos continuam com o loot normal do jogo.
- Entrar, recuar ou ignorar a fissura nao fecha portal, escada nem rota principal.
  O socorro continua independente. Cada integrante pode seguir seu percurso.

## Estado e limites

`route_choice` registra vazio, rota registrada ou fissura; `fissure_found`
registra descoberta confirmada. O fato pertence ao mundo do host, nao obriga
o grupo a percorrer o mesmo caminho e nao e uma decisao politica irreversivel.
Passar da preferencia segura para investigacao da fissura continua permitido.

O host verifica ator conectado/consciente, contrato, andar, zona, distancia
e perigo. Cliente envia somente intencao. A evidencia e idempotente e nao
passa por filtro de loot ou venda automatica.

Save v14 inclui os campos novos. Saves v13 e anteriores nao inferem descoberta
nem escolha. Posicoes antigas de jogador/inimigos que coincidam com as novas
bordas do primeiro andar sao movidas ao ponto livre proximo, sem apagar atores
ou alterar inventario. Saves atuais incompletos ou contraditorios sao rejeitados.

O ramal permanece fisicamente aberto: esta entrega nao implementa paredes
dinamicas, teleporte, cutscene, votacao nem um atalho entre andares.

## Verificacao

- `tests/narrative_fissure_test.gd`: autoridade, estados, risco anunciado,
  dois guardas sem duplicacao, percurso livre, leitura protegida, contrato
  original, retorno, JSON/save, migracao e posicoes legadas em colisao.
- `tests/narrative_online_smoke.sh`: cliente confirma rota, fissura e vestigio,
  duplicatas, diario completo, reconexao e entrada tardia.
- `tools/art/fissure_shots.gd`: nove capturas de bifurcacao, guardas e retorno
  em 1280x720, 1920x1080 e 640x720.

Pendentes: balanceamento do risco/recompensa, compreensao sem orientacao,
controle fisico, abandono explicito do socorro e reputacao com efeito jogavel.

Suite local: 91 testes aprovados, zero falhas, incluindo rede. Regressao da
fissura e persistencia foram repetidas apos o ajuste final de migracao das
posicoes legadas. Capturas nativas conferidas; QA externo continua pendente.
