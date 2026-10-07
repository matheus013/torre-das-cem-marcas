# Vila, moradores e servicos

Entrega em 2026-10-07. Aresta ocupa 3840x2400, com centro de expedicoes,
bairro residencial, praca/feira, oficinas, fazendas, pedreira e serraria.
As portas da casa e da Torre foram preservadas para compatibilidade.
Sao 37 moradores, incluindo seis novos residentes/trabalhadores e Sira.
Os novos moradores reutilizam familias de sprites animados existentes.

Elen e dois residentes permanecem em casa. Regente, comerciante, curador,
medica, ferreira, alquimista e supervisor agricola permanecem no oficio.
Guardas fazem rondas e outros moradores circulam. AStarGrid2D contorna
construcoes e arvores, sem tentar atravessar obstaculos em linha reta.

## Producao e armazem

Lavradores, mineiros e lenhadores colhem em pontos definidos. Cada ponto
tem 12 unidades, produz 2 por ciclo de 8 segundos e recupera 2 a cada
60 segundos. A carga de seis unidades precisa ser levada fisicamente ao
armazem. A capacidade e 1000 por recurso. Estoque cheio nao apaga carga.
A noite, trabalhadores entregam antes de voltar para casa; se o armazem
estiver cheio, conservam a carga consigo em casa. Nao ha simulacao offline.

O quadro junto ao armazem mostra madeira, minerio e alimentos. Receitas
de servicos consomem essas reservas, compartilhadas pelo grupo. Materiais
da Torre continuam no banco de expedicoes ja existente; nao sao confundidos
com os recursos locais. Save v9 persiste estoques, reservas dos pontos,
tempos de regeneracao e carga/estado dos trabalhadores. Saves anteriores
continuam carregando com economia vazia e recursos locais disponiveis.

## Atendimentos

Interagir perto do atendente abre um menu com precos, receitas, saldo,
estoque, compra, conversa e fechamento. Botoes aceitam foco por controle.

| Atendente | Funcao | Custo |
| --- | --- | --- |
| Cassio | Compra de um suprimento de cura | 18 prata |
| Maura | Vida/folego completos e remocao de ferimentos | Gratuito |
| Sira | Preparo de tres suprimentos | 12 prata, 6 alimentos, 2 madeira |
| Dalia | Reparo das pecas equipadas e do inventario | 30 prata, 4 minerio |
| Lior | Racao de viagem: um suprimento | 3 alimentos |

O host valida identidade do servico, conexao, zona, distancia, saldo,
materiais e limite de nove suprimentos. Falha nao gasta nada; duas pessoas
nao conseguem consumir o mesmo estoque. Cura/reparo desnecessarios nao
cobram recursos. Os servicos nao vendem gemas de chefes nem alteram sua progressao.

## Mapas e QA

Os cem andares agora usam seis conjuntos tematicos e um eixo desobstruido
entre entrada, clareiras e escada. Estruturas grandes nao sao repetidas como
matagais. Arenas usam um motivo coerente no perimetro. Interior da casa
mantem mobiliario organizado e a camara legada ganhou piso explicito.

`tests/map_connectivity_test.gd` valida destinos da vila e todos os cem
andares, incluindo surgimento de inimigos. Testes de economia e servicos
cobrem entregas, noite, saves, limites, transacoes e interface. Suite isolada
da primeira entrega: 61 testes aprovados, incluindo duas provas de rede.
Alteracoes paralelas de itemizacao nao fazem parte dessa validacao.

`tools/art/map_shots.gd` gera planta completa e dez pranchas dos cem mapas.
`tools/art/village_shots.gd` captura nove locais de dia e de noite no jogo.

Ainda faltam ferramentas do jogador para coleta manual, construcao gerenciada,
mercado de equipamento e contratos de producao. O ciclo automatico dos moradores
e os cinco atendimentos acima ja sao funcionais.
