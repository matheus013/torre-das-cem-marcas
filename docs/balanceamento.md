# Balanceamento de personagens, gemas e itens

Revisão de 2026-10-06. Objetivo: as quatro personagens viáveis solo e em grupo, gemas sem
outliers extremos e itens cujo valor sobe com a raridade. Valores provisórios para playtest.

## Como medir

```sh
# Personagens: andares 1 a 100 (comuns e chefes), 3 sementes; vários grupos em paralelo
godot --headless --path . --script tools/bench/balance_probe.gd -- --characters=cira --seeds=3
godot --headless --path . --script tools/bench/balance_probe.gd -- --characters=eloa,sena,cira,rui --seeds=3
# Gemas: dano que cada gema soma ao ataque automático, contra horda e contra chefe
godot --headless --path . --script tools/bench/gem_probe.gd -- --gems=agulha_lastro,lanca_ferral
```

A sonda de personagens distribui pontos nos atributos que a arma inicial escala (como um
jogador razoável), mantém distância de combate conforme o alcance da arma, foge de telegrafias
e abandona alvos que não perdem vida em 4 s (inalcançáveis atrás de obstáculos). Não tem busca
de caminho: no andar 9 ela fica presa num bolsão de pedras, então ele saiu da amostra (vale
QA manual).

A sonda de gemas joga com o Rui, cuja passiva não depende de lançar gemas, com atributos
iguais, e usa novas e órbitas de perto. Cada gema foi medida também com a Eloa; só gemas fora
da faixa nas duas medições foram ajustadas, pelo índice médio (1,0 = mediana das gemas de dano).

## Personagens solo (sucesso, tempo médio por andar, mortes por andar)

| | Antes | Depois |
| --- | --- | --- |
| Eloa | 100% · 37 s · 0,11 | 100% · 37 s · 0,06 |
| Sena | 100% · 45 s · 0,11 | 100% · 51 s · 0,17 |
| Rui | 86% · 96 s · 1,03 | 94% · 74 s · 0,53 |
| Cira | 36% · 209 s · 6,14 | 92% · 74 s · 0,42 |

Grupos (duplas e quarteto): 97% a 100% de sucesso, 28 s a 41 s por andar.

Causa principal: manoplas (alcance 105) e bastão (160) exigem luta colada sem nada que
compensasse o risco. Correções:

- **Guarda** por arma, redução do dano recebido: manoplas 38%, bastão 18%, lança 5%, foco 0%.
- **Manoplas**: roubo de Vida 6%, alcance 105 → 125, potência 12 → 15.
- **Bastão**: intervalo 1,1 → 1,0 s.

**Pendente:** o chefe final (andar 100) solo continuava fora do alcance da Cira (0/3); nem 50%
de guarda resolve. Com gemas evoluídas pelo uso (decisão 579) ela vence 2 de 3. Ele concentra cruz, rajada em leque, puxão e anel em volta de si, e pune
quem luta colado. Decisão de design de chefe: janela segura para corpo a corpo, rajada que
nasce afastada do chefe, ou aceitar que o último chefe exige alcance ou grupo.

## Gemas conquistadas (decisão 579)

Com cada personagem começando só com a gema inicial, a sonda passou a montar a build que a
personagem teria em cada andar: gema inicial mais os conjuntos dos chefes abaixo do andar, quatro
gemas de dano que escalam com os atributos dela (uma por mecânica) e um nível de gema a cada 6
andares desde a obtenção, com a primeira evolução de cada nível. O Guardião de Enxerto (andar 4),
enfrentado só com a gema inicial, teve a Vida reduzida de 2,5× para 1,4× da base (Cira 0/3 e Eloa
1/3 → todas 3/3, de 30 a 54 s).

| Solo | Antes (4 gemas fixas) | Depois |
| --- | --- | --- |
| Eloa | 100% · 37 s | 97% · 62 s |
| Sena | 100% · 51 s | 97% · 59 s |
| Rui | 94% · 74 s | 92% · 87 s |
| Cira | 92% · 74 s | 94% · 79 s |

Andares iniciais ficam mais lentos (só uma gema até o andar 4), e a Cira passou a vencer o chefe
final em 2 de 3 sementes. **Pendente:** o andar 75 (exploração, cota 75) segue o mais apertado:
Rui 0/3 e as demais 2/3 dentro do limite de 300 s da sonda.

## Gemas (potência)

| Gema | Antes | Depois | Motivo (índice) |
| --- | ---: | ---: | --- |
| Agulha de Lastro | 35 | 21 | 3,2× (recarga 1,5 s; gema inicial, corte limitado a -40%) |
| Lança Ferral | 42 | 25 | 2,4× |
| Sentinela Ferral | 34 | 20 | 2,6× |
| Enxame Luminar | 7 | 4,2 | 2,6× (três criaturas) |
| Molde Vigilante | 16 | 11 | 2,0× |
| Mina de Lastro | 65 | 48 | 1,6× |
| Cometa Sombrio | 40 | 31 | 1,5× |
| Guardião de Lastro | 20 | 16 | 1,45× |
| Satélites de Geada | 10 | 16 | 0,35× |
| Lâminas Orbitais | 14 | 22 | 0,37× |
| Chuva Ferral | 28 | 45 | 0,37× |
| Raízes Presas | 6 | 8,4 | 0,39× (controle: reforço menor) |
| Sopro Criogênico | 18 | 25 | controle |
| Dreno em Rede | 22 | 29 | 0,55× (também cura) |
| Fio Desintegrador | 26 | 32 | 0,70× |
| Saraivada de Flechas | — | 4 | nova, 24 flechas por rajada; medida com Fôlego real, índice ~1,2 (perfuração 1) |

## Itens

Defesa passou a funcionar: redução de dano `defesa / (defesa + 100)`, teto de 50%. Atributos sem
efeito foram trocados (potência mágica → Inteligência, velocidade de interação → Agilidade,
carga e estabilidade → Vida, Vitalidade e Defesa). Cada peça recebeu atributos dentro de um
orçamento por raridade, em pontos de atributo primário: comum ~7, incomum ~11, raro ~17,
épico 25, lendário 35. Antes, raros, épicos e lendários só tinham efeitos especiais ainda não
implementados e valiam menos que um item comum. Os efeitos especiais seguem listados e entram
por cima quando forem implementados.

`tests/balance_rules_test.gd` falha se uma raridade não valer mais que a anterior, se um item
tiver atributo sem efeito, se uma arma mais curta tiver menos guarda ou se a defesa mudar de fórmula.

## Economia e saque

Prata de Ordel (documento 58): 120 P iniciais por personagem. Venda manual de peças do
inventário (comum 8, incomum 20, raro 45, épico 90, lendário 180 P, vezes a fabricação).
Filtro de saque deixa no chão, apagados, os equipamentos abaixo da raridade escolhida
(materiais sempre são recolhidos). Autovenda, ao voltar à vila, vende as peças abaixo da
raridade escolhida; equipadas e armas únicas nunca. Bolsa e preferências ficam no save.
