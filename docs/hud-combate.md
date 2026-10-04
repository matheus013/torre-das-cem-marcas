# HUD de combate

Entrega 2026-10-04: seis melhorias solicitadas, sem alterar regras de combate.

| Componente | Comportamento |
| --- | --- |
| Skills | Pronta, recarga, sem Folego ou personagem caido. Cargas disponiveis continuam utilizaveis durante a recarga de outra carga. |
| Barreira | Quantidade atual e segundos restantes acima da barra inferior. |
| Efeitos | Icones com duracao e descricao por hover: barreira, invulnerabilidade, cultivo, estabilidade, lentidao ambiental e Ferimento de Expedicao. |
| Mira | Estado ligada/desligada, nome e Vida do alvo mais proximo, marca dourada no mundo. Lentidao/vulnerabilidade do alvo incluem tempo restante. Sem inimigo, indica SEM ALVO. |
| Grupo | Ate tres aliados, ordenados por peer: Vida/Folego atuais e maximos, barreira, localizacao, reconexao, tempo de queda e progresso de resgate. |
| Avisos | Vida critica a 25% ou menos, Folego insuficiente por 2.5s e escada liberada por 4s. Queda local mostra tempo/progresso de resgate. |

Efeitos de zona desaparecem ao sair do raio; seus tempos indicam o fim da
zona, nao uma garantia de permanencia no personagem. Ferimentos duram ate
retornar a vila, com penalidade de Vida limitada a 50% pela regra existente.
Icones reutilizam arte do proprio jogo. Efeitos sem implementacao nao sao
anunciados como buffs. Estado vem da simulacao autoritativa e segue no
snapshot para clientes; apenas a mira manual/automatica e preferencia local.

Avisos repetidos nao reiniciam o temporizador continuamente. Vida critica
usa texto e contorno, sem flashes. Avisos mudam de posicao em janelas
estreitas para nao cobrir o grupo. A escala minima do HUD compensa o
esticamento da janela, preservando os menus e a camera existentes.

Testes: custos iguais ao requisito de cast, estados/cargas, efeitos dentro e
fora de zonas, protecoes removidas, barreira, grupo, alvo/manual, avisos sem
spam, resgate local e redimensionamento. Capturas nativas usam estado
controlado de quatro jogadores (nao um playtest de balanceamento) em
1280x720, 640x720 e 1920x1080, incluindo mira desligada.

Pendentes fora desta entrega: audio/haptics, preferencias adicionais de
acessibilidade, QA com controles fisicos e legibilidade de todos os menus
em resolucoes pequenas. Os gates de publicacao Steam continuam abertos.
