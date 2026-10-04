# Catalogo de gemas: 36 ativas + 40 suportes

Gerado por `python3 tools/content/build_skill_catalog.py`; confirme com `--check`.
Referencia de design: [GGG: suporte, especializacao e contrapartidas](https://www.pathofexile.com/forum/view-thread/3147753).
Inspiracao estrutural, sem copiar nomes, arte ou valores de Path of Exile. Fonte historica, nao guia de patch atual.

## Regras atuais

Quatro ativas equipadas; troca e ligacao em Aresta. Ate dois suportes por ativa, capacidade 2 + nivel da gema (3-5 no beta).
Categorias mecanica/buff compartilham slots e capacidade. Uma copia de cada suporte por personagem, sem equipar o mesmo suporte em dois slots.
36 ativas disponiveis no catalogo do beta; nao sao desbloqueios por loot. Saves antigos recebem novas entradas de progresso no carregamento.
IDs anteriores e escolhas salvas preservados. Graus 1-3 oferecem duas evolucoes por grau; nao confundir com marcos permanentes de personagem.
Valores sao ponto de partida de balanceamento, nao prova de viabilidade equivalente. Efeitos visuais/icone provisorios em pixel art; audio individual ainda pendente.

## Ativas

| Gema | Familia | Comportamento |
| --- | --- | --- |
| Agulha de Lastro | `projectile` | Projetil de precisao que acerta no destino da mira. |
| Passo Vetorial | `dash` | Esquiva com invulnerabilidade breve e custo de Folego. |
| Pulso de Cicatriz | `nova` | Pulso circular de dano ao redor do portador. |
| Prisao Gravitica | `field` | Campo persistente de pulsos; evolucoes adicionam atracao e colapso. |
| Muralha Refeita | `barrier` | Barreira pessoal; evolucoes adicionam contato, partilha ou explosao. |
| Elo Residual | `chain` | Corrente que salta entre inimigos distintos. |
| Molde Vigilante | `summon` | Invocacao fixa ataca inimigos proximos durante dez segundos. |
| Semeadura Vital | `sanctuary` | Cultivo que cura aliados dentro da zona e causa dano aos inimigos. |
| Estilhacos Lunares | `projectile` | Leque de tres impactos curtos para espalhar dano. |
| Lanca Ferral | `projectile` | Linha longa que atravessa tres alvos antes do impacto. |
| Orbe de Ruptura | `projectile` | Impacto largo e lento que rompe grupos compactos. |
| Corte Vetorial | `dash` | Avanco ofensivo que corta os inimigos no trajeto. |
| Salto de Guarda | `dash` | Retirada longa com barreira na chegada, sem dano direto. |
| Anel de Geada | `nova` | Pulso proximo que desacelera a horda. |
| Ruptura Sismica | `nova` | Explosao curta e forte que afasta ameacas. |
| Brasa Persistente | `field` | Zona fixa de pulsos rapidos que explode ao se extinguir. |
| Pantano Acido | `field` | Zona que combina lentidao e vulnerabilidade. |
| Casca Reativa | `barrier` | Barreira que pune contato e explode ao expirar. |
| Arco Voltaico | `chain` | Seis saltos de alcance curto aplicam vulnerabilidade leve. |
| Dreno em Rede | `chain` | Tres saltos que devolvem Vida ao portador. |
| Sentinela Ferral | `summon` | Sentinela fixa de longo alcance prioriza o inimigo com menos Vida. |
| Enxame Luminar | `summon` | Tres criaturas leves perseguem o alvo mais proximo. |
| Guardiao de Lastro | `summon` | Guardiao resistente acompanha o portador e repele inimigos. |
| Circulo de Reparo | `sanctuary` | Cultivo curto com cura forte; excesso vira barreira. |
| Abrigo de Escora | `sanctuary` | Zona ampla de cura leve que prolonga a estabilidade de aliados caidos. |
| Ceifa Ampla | `cone` | Corte em cone frontal; nao atinge inimigos atras do portador. |
| Sopro Criogenico | `cone` | Cone estreito e longo de lentidao intensa. |
| Raio Prismatico | `beam` | Feixe estreito que atinge todos os inimigos alinhados. |
| Fio Desintegrador | `beam` | Feixe largo e curto que aplica vulnerabilidade. |
| Laminas Orbitais | `orbit` | Tres laminas giram ao redor do portador e acertam por contato. |
| Satelites de Geada | `orbit` | Duas orbitas externas lentas controlam a aproximacao. |
| Mina de Lastro | `mine` | Arma apos um segundo e detona quando um inimigo se aproxima, ou ao expirar. |
| Semente Explosiva | `mine` | Armadilha rapida de explosao ampla e repulsao. |
| Chuva Ferral | `meteor` | Tres impactos atrasados cobrem pontos diferentes ao redor da mira. |
| Cometa de Vidro | `meteor` | Um impacto grande e lento; exige antecipar o movimento da horda. |
| Disco de Retorno | `boomerang` | Disco corta a linha de ida e retorna pela mesma rota. |

## 20 suportes mecanicos

| Suporte | Dreno | Efeito e contrapartida |
| --- | --- | --- |
| Projeteis Gemeos | 3 | Projeteis +1; potencia -22%. |
| Perfuracao Refeita | 2 | Atravessa mais dois alvos; potencia -10%. |
| Ricochete de Junta | 3 | Salta para mais dois alvos; alcance -15%. |
| Eco Atrasado | 4 | Repete apos 0,7 s; potencia -32%. |
| Impulso de Impacto | 2 | Repulsao +65; potencia -8%. |
| Busca Residual | 3 | Corrige o destino para um inimigo proximo da mira; velocidade visual -18%. |
| Retorno Vetorial | 2 | Projeteis retornam pela linha de ida; -15% de potencia. |
| Bifurcacao Residual | 3 | Do impacto saem duas linhas divergentes; -20% de potencia. |
| Explosao de Contato | 3 | Impacto ganha 55 unidades de area; -15% de potencia. |
| Novas Remotas | 2 | Pulso nasce na mira em vez do portador; recarga +15%. |
| Anel Vazio | 2 | Nao atinge o centro de 55 unidades; potencia +25%. |
| Zona Itinerante | 2 | Zona acompanha o portador; duracao -20%. |
| Detonacao Tardia | 3 | Explode com 45 de dano ao expirar; pulsos -20%. |
| Eco Triplo | 4 | Repete duas vezes com 0,45 s entre ecos; -50% de potencia. |
| Guarda Partilhada | 2 | Aliados proximos recebem 60% da barreira; barreira propria -15%. |
| Vigia Itinerante | 2 | Invocacao segue o portador; alcance -20%. |
| Enxame Duplo | 3 | Cria uma invocacao adicional respeitando o limite do tipo; -25% de potencia. |
| Corrente de Retorno | 2 | Ultimo alvo recebe um segundo acerto; -15% de potencia. |
| Conversao de Cultivo | 2 | Cura excedente vira barreira; cura -15%. |
| Salto Explosivo | 2 | Chegada causa 25 de dano em raio 80; custo +8 Folego. |

## 20 suportes de buff

| Suporte | Dreno | Efeito e contrapartida |
| --- | --- | --- |
| Area Expandida | 2 | Raio +30%; potencia -10%. |
| Foco Concentrado | 2 | Raio -28%; potencia +38%. |
| Fluxo Rapido | 3 | Recarga -22%; potencia -14%. |
| Duracao Estendida | 2 | Duracao +45%. |
| Drenagem Vital | 4 | Recupera 8% do dano como Vida; potencia -10%. |
| Sobrecarga Instavel | 5 | Potencia +55%; recarga +30%; custo +12 Folego. |
| Potencia Bruta | 2 | Potencia +22%; recarga +10%. |
| Precisao Lapidada | 2 | Chance critica +12 pontos percentuais; potencia -10%. |
| Alcance Treinado | 2 | Alcance +35%; recarga +8%. |
| Barreira Densa | 2 | Barreira +35%; duracao -15%. |
| Cura Reforcada | 2 | Cura por pulso +35%; intervalo +20%. |
| Ritmo de Cultivo | 2 | Intervalo dos pulsos -25%; potencia, cura e duracao -15%. |
| Passo Extenso | 2 | Distancia +30%; custo +5 Folego. |
| Passo Seguro | 2 | Invulnerabilidade +40%; distancia -15%. |
| Invocacao Celere | 2 | Intervalo de ataque -25%; potencia -15%. |
| Elo Amplo | 2 | Alcance dos saltos +35%; potencia -10%. |
| Estabilidade Solida | 2 | Estabilidade +20 pontos percentuais; cura -10%. |
| Sifao de Folego | 2 | Cada acerto devolve 2 Folego, ate 8 por segundo; potencia -15%. |
| Aegis por Acerto | 2 | Barreira +2 por acerto; potencia -15%. |
| Cadencia Precisa | 2 | Recarga -15%; custo +4 Folego. |

## Limites e semantica

Projeteis atuais resolvem acertos imediatamente e animam o trajeto; nao simulam fisica balistica ou colisao de projeteis com paredes.
Bifurcacao nasce no ponto de impacto; nao e um proc recursivo. Retorno e ricochetes mantem a semantica existente de acertos instantaneos.
Cone tem direcao e abertura; feixe tem largura. Orbitas acertam ao redor do portador, nao em todo o disco. Minas detonam uma vez apos armar/proximidade ou ao expirar.
Meteoros marcam locais fixos e atingem apos atraso; ecos/impactos agendados sao descartados ao mudar de andar/zona.
Limites: oito projeteis, oito orbitas, oito impactos e quatro ecos por ativacao; oito zonas/minas por gema/portador, substituindo a mais antiga.
Summons usam limites por definicao (2 sentinelas, 4 criaturas do enxame, 2 guardioes). Suporte de quantidade nao ultrapassa esses limites.
Sifao recupera ate oito pontos de Folego por segundo por portador, compartilhado entre suas habilidades; nao amplia Folego maximo.
UI lista apenas compatibilidade de familia/tags; as combinacoes e contrapartidas precisam de playtest. Raridades, aquisicao por contratos e balanceamento final continuam fora desta entrega.
