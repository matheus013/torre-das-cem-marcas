# Revisão revolucionária de armas únicas e lendários

## Estado

**Em implementação** (decisão 598, 2026-10-11). Aplica o teste da revolução do
[documento 76, seção 6](76-dificuldades-dia-e-noite-e-paragon.md) a todas as passivas existentes:
quem só amplifica (cópia extra, +% de elemento, vulnerabilidade, cura por acerto) é reescrito para
mudar uma regra; quem já muda regra fica. Nome do item, gema, encaixe e fonte de drop não mudam, e
saves antigos continuam válidos: a passiva vem dos dados do item.

## Ferramentas novas do motor

- **Transformação da gema** (armas únicas): `transform` sobrescreve campos da gema resolvida
  (inclusive a mecânica) e `transform_from` deriva campos de outros (ex.: dano final a partir da
  barreira). É o que permite "a Bola de Fogo vira um sol que segue você".
- **Regras** (lendários e relíquias): chaves em `mods` lidas em pontos fixos da simulação: custo
  em Vida, recarga só por abates, queimadura eterna, crítico em cadência, autoataque que lança a
  gema do Q, cura que vira barreira, imunidade a dano de contato, entre outras.
- **Ações e filtros novos**: aplicar veneno a partir do acerto, lançar uma gema com campos
  alterados (`override`), filtros por Fôlego e por movimento.
- **Comportamentos novos de gema**: Saraivada ancorada, órbita em volta do inimigo, minas que
  perseguem, santuário que acelera recargas ou impede quedas, meteoro que mira o mais forte e poça
  de esporos.

## Armas únicas

| Gema | Antes | Veredito | Depois |
|---|---|---|---|
| Agulha de Lastro | Agulha Fantasma: 3 agulhas a cada 2 lançamentos | Reescrever | **Agulha Errante**: ricocheteia entre até 6 inimigos e volta à mão |
| Lança Ferral | vulnerável e explosão no abate | Reescrever | **Lança de Ida e Volta**: atravessa tudo e volta atravessando de novo |
| Estilhaços Lunares | críticos adiantam todas as recargas | Manter | ciclo de crítico e recarga já muda a build |
| Orbe de Ruptura | estouro a cada acerto | Reescrever | **Orbe Gravitacional**: para no alvo como campo que puxa por 3 s e explode com o dobro do golpe |
| Bola de Fogo | queimadura e explosão | Reescrever | **Sol Cativo**: vira um sol que acompanha a personagem queimando em volta |
| Bolha Corrosiva | corrosão e nova bolha no abate | Reescrever | **Bolha que se Divide**: ao estourar, divide-se em 3 |
| Cometa Sombrio | abate zera a recarga | Manter | reinício por abate muda o ritmo |
| Esfera de Gelo | congela e expõe | Reescrever | **Zero Absoluto**: inimigo atingido abaixo de 25% se estilhaça e solta 3 esferas menores |
| Disco de Retorno | segundo disco | Reescrever | **Discos Gêmeos**: dois discos orbitam a personagem por 8 s |
| Saraivada de Flechas | raio no abate | Reescrever | **Olho da Tempestade**: fica ancorada onde foi lançada, com o dobro de flechas |
| Passo Vetorial | bônus depois do Passo | Manter | ritmo de investidas |
| Corte Vetorial | explosão na chegada | Reescrever | **Corte em Cadeia**: abater com o Corte zera a recarga dele |
| Salto de Guarda | invulnerável, barreira e cura | Reescrever | **Salto do Martelo**: vira golpe de aterrissagem que esmaga e repele |
| Pulso Cicatriz | cura por inimigo | Reescrever | **Pulso Constante**: dispara sozinho a cada 1,5 s |
| Anel de Geada | congela e expõe | Reescrever | **Inverno que Prende**: congela totalmente por 1,5 s, sem causar dano |
| Ruptura Sísmica | dois tremores extras | Reescrever | **Fenda**: vira uma fissura em linha reta até o alvo |
| Prisão Gravítica | colapso no abate | Reescrever | **Repulsão**: segue a personagem e expulsa inimigos |
| Brasa Persistente | queimadura dobrada | Reescrever | **Fogueira Perene**: não se apaga; lançar de novo a muda de lugar |
| Pântano Ácido | mais vulnerável e lento | Reescrever | **Pântano Contagioso**: quem morre dentro abre um novo Pântano |
| Raízes Presas | prendem mais | Reescrever | **Trilha de Raízes**: acompanham a personagem e prendem quem chega perto |
| Muralha Refeita | potência e defesa | Reescrever | **Muralha Ofensiva**: a barreira que sobrar explode com 3x o valor |
| Casca Reativa | devolve 400% | Manter | espinhos mudam a build |
| Elo Residual | novo Elo no abate | Manter | propagação por abates |
| Arco Voltaico | recarga por salto | Reescrever | **Arco Infinito**: salta até 30 vezes |
| Dreno em Rede | cura e barreira | Reescrever | **Fome da Rede**: cada abate da Rede dá +2% de dano de trevas até sair da Torre (até +200%) |
| Molde Vigilante | Molde novo a cada 8 s | Manter | invocação autônoma |
| Sentinela Ferral | Sentinela extra | Reescrever | **Sentinela Eterna**: não expira; lançar de novo a move |
| Enxame Luminar | enxame extra e cura | Reescrever | **Enxame Faminto**: cada abate gera um novo enxame |
| Guardião de Lastro | Guardião ao ser ferida | Manter | invocação reativa |
| Semeadura Vital | cura e barreira | Reescrever | **Jardim Andante**: o Jardim acompanha a personagem |
| Círculo de Reparo | cura e recarga | Reescrever | **Círculo do Tempo**: dentro dele as recargas andam 3x mais rápido |
| Abrigo de Escora | invulnerável e meio dano | Reescrever | **Abrigo Inquebrável**: dentro dele ninguém cai; golpe fatal deixa com 1 de Vida |
| Ceifa Ampla | recarga e cura por abate | Reescrever | **Ceifa Giratória**: corta 360 graus |
| Sopro Criogênico | congela e devolve Fôlego | Reescrever | **Raio Congelante**: vira um feixe longo de gelo |
| Raio Prismático | expõe e explode no crítico | Reescrever | **Prisma Dividido**: cada lançamento sai em 3 feixes para alvos diferentes |
| Fio Desintegrador | executa abaixo de 30% | Manter | execução |
| Lâminas Orbitais | cura, Fôlego e velocidade | Reescrever | **Ciclone Perpétuo**: as Lâminas não expiram |
| Satélites de Geada | congela e pulsa | Reescrever | **Constelação**: os Satélites orbitam o inimigo mais próximo |
| Mina de Lastro | duas minas extras | Reescrever | **Mina Viva**: as Minas perseguem inimigos |
| Semente Explosiva | replanta no abate | Manter | propagação por abates |
| Chuva Ferral | segunda onda | Reescrever | **Artilharia Ferral**: cai sozinha a cada 2 s no inimigo mais próximo |
| Cometa de Vidro | estilhaça no abate | Reescrever | **Cometa Guiado**: cai sempre no inimigo com mais Vida perto do alvo |
| Pilar Sagrado | cura e expõe | Reescrever | **Pilar Fixo**: fica de pé 8 s ferindo quem chega perto |
| Esporos | infecta mais dois | Reescrever | **Cogumelos**: hospedeiros mortos viram cogumelos que reinfectam por 10 s |
| Poça de Veneno | segunda poça | Reescrever | **Poça Viva**: a Poça acompanha a personagem |
| Trovão Descendente | chance de ramificar | Reescrever | **Raio em Cadeia**: o Trovão salta entre 5 inimigos |

## Lendários e relíquias

| Item | Antes | Veredito | Depois |
|---|---|---|---|
| Coroa de Brasa | fogo +40% e explosão | Reescrever | **Fogo que Não Apaga**: queimaduras não expiram e passam para os vizinhos de quem morre em chamas |
| Manto do Inverno | gelo +40% e expõe | Reescrever | **Inverno Interior**: acertos de gelo estilhaçam inimigos abaixo de 20% da Vida |
| Luvas da Tempestade | metade dos acertos ramifica | Reescrever | **Sobrecarga**: gemas de raio não têm recarga e custam o dobro de Fôlego |
| Botas do Brejo | ácido e natureza +35% | Reescrever | **Raiz e Ácido**: todo acerto de ácido ou natureza também envenena |
| Véu do Eclipse | trevas +40% e cura no abate | Reescrever | **Pacto Sombrio**: gemas de trevas custam Vida em vez de Fôlego e causam +60% |
| Anel do Sol Partido | cura e barreira ao lançar sagradas | Reescrever | **Luz Excedente**: cura acima da Vida máxima vira barreira |
| Anel da Terra Viva | terra +40% e barreira | Reescrever | **Pedra Viva**: parada por 1 s, recebe 40% menos dano |
| Lente Arcana | arcano +40% e recarga no crítico | Reescrever | **Clarividência**: chance de crítico zera; todo 5º acerto de gema é crítico com +200% |
| Punho da Montanha | físico +35% e tremor | Reescrever | **Peso da Montanha**: 25% mais lenta; cada ponto de Força dá 1% de dano físico |
| Tomo do Erudito | mágico +30% e Fôlego | Reescrever | **Erudição Absoluta**: todas as gemas custam Vida em vez de Fôlego; Vida máxima +30% |
| Gatilho Ancestral | gema do Q a cada 4 acertos | Reescrever | **Gatilho Ancestral**: o autoataque passa a lançar a gema do Q com 40% da potência |
| Calça do Pastor | invocações +50% | Reescrever | **Rebanho Eterno**: invocações não expiram |
| Coração Imortal | volta da queda | Manter | já muda a regra da morte |
| Ampulheta Partida | abate adianta recargas | Reescrever | **Tempo Roubado**: recargas não andam com o tempo; cada abate adianta 1 s de todas |
| Fôlego Primordial | Fôlego máximo e regeneração | Reescrever | **Pulmão do Mundo**: andando, gemas não custam Fôlego; parada, custam o dobro |
| Couraça do Colosso | -25% de dano e barreira | Reescrever | **Colosso**: 30% mais lenta e imune a dano de contato |
| Presa da Serpente | envenenado explode e deixa poça | Manter | já muda a regra |
| Botas do Caçador | acúmulos de potência e velocidade | Reescrever | **Rastro de Caça**: andar deixa um rastro que fere quem pisa |
| Botas do Vendaval, Anel da Corda Infinita, Anel do Furor, Sino do Fôlego Leve | pedidos de 2026-10-08 | Manter | pedidos explícitos do responsável |
| Lastro Partido | Passo abre Prisão | Manter | já muda a regra |
| **Pacto de Sangue** (novo, relíquia) | — | Novo | nenhuma cura funciona; todo abate dá barreira de 3% da Vida |

## Ordem

1. Motor de transformação e armas únicas que só precisam dele e das ações atuais.
2. Regras dos lendários.
3. Comportamentos novos de gema (âncora, órbita no alvo, minas, santuários, meteoro, cogumelos).

Cada lote entra com teste de comportamento por item e passa pela suíte completa.
