# Armas e afinidades

Implementado em 2026-10-04; valores iniciais, ainda sujeitos a playtests.
Perfis: `data/combat/weapon_profiles.json`. Os IDs das quatro armas existentes
foram preservados: saves antigos recebem o tipo ao reconstituir o item.

| Personagem | Arma inicial | Tipo | Alcance | Dano base | Intervalo base | Escala por ponto |
| --- | --- | --- | --- | --- | --- | --- |
| Eloa | Filamentos de Forja | Foco | 340 | 18 | 0.80s | Inteligencia 0.6%, Sabedoria 0.3% |
| Sena | Lanca de Duas Rotas | Lanca | 220 | 22 | 0.75s | Forca 0.5%, Agilidade 0.3% |
| Cira | Manoplas de Placa Viva | Manoplas | 125 | 15 | 0.40s | Forca 0.4%, Vitalidade 0.4% |
| Rui | Bastao Modular de Campo | Bastao | 160 | 28 | 1.00s | Sabedoria 0.4%, Forca 0.4% |

Guarda (decisao 577): reducao do dano recebido enquanto a arma esta equipada, para
compensar o risco da luta colada. Manoplas 38% e roubo de Vida 6%; bastao 18%; lanca 5%;
foco 0%. Aparece na ficha e no tooltip da arma.

Foco: dano arcano, +2 pontos percentuais de critico, vulnerabilidade de 8%
por 2 segundos. Dano arcano ignora a reducao fisica de Pele de Pedra; nao
existe ainda uma matriz completa de resistencias elementais.
Lanca: linha com ate dois alvos e +6 pontos percentuais de critico.
Manoplas: alvo unico, golpes rapidos, pequena repulsao, -3 pontos de critico.
Bastao: cone de 1.7 radianos, repulsao de 35 unidades, sem ajuste de critico.
Alcances usam unidades do mundo, nao metros. Intervalos sao alterados pela
cadencia derivada; critico final permanece limitado a 50%.

## Afinidade

| Personagem | Foco | Lanca | Manoplas | Bastao |
| --- | --- | --- | --- | --- |
| Eloa | 115% | 85% | 80% | 100% |
| Sena | 85% | 115% | 100% | 90% |
| Cira | 90% | 95% | 115% | 100% |
| Rui | 85% | 100% | 95% | 115% |

100% e neutro; 115% multiplica dano por 1.15. Nao ha bloqueio de equipamento
por personagem. Afinidades afetam o ataque automatico, nao as gemas: cada
skill conserva sua propria escala, evitando punir builds magicas com lanca.

`dano = base * (1 + soma(atributo * escala)) * afinidade/100 * fabricacao * potencia_do_nivel * modificador_automatico`

Na aba Personagem aparecem dano, alcance, intervalo, critico, tipo, escalas
e todas as afinidades. Ataques sem arma usam perfil neutro. Evolucoes de
ataque automatico continuam aplicando seus efeitos e correntes adicionais.
Tags, incompatibilidades e armas de duas maos agora sao importadas pela
factory; as armas iniciais nao receberam restricoes retroativas de duas maos.

Pendencias: animacoes especificas, audio, resistencias, comparacao no
inventario e balanceamento com hordas/chefes. Tipos distintos nao significam
que todas as mecanicas antigas descritas nos itens ja tenham consumidor.
