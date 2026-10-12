# Avaliacao de builds por dificuldade

Gerado por `tools/bench/build_probe_all.sh` (sonda `tools/bench/build_lab.gd`, decisao 610). Para cada gema
ativa e cada autoataque a sonda seleciona um set por busca gulosa em simulacao (nao um otimo global: evolucoes de maestria, par de suportes,
arma, lendarios e divinos encaixe a encaixe, Paragon) e o avalia com o poder esperado em cada dificuldade:
1 nivel do andar e equipamento inicial; 2 nivel 100, unica e lendarios; 3 + Paragon 50; 4 + Paragon 100 e
1 divino; 5 + Paragon 175 e set completo. Pontos de controle: chefes dos andares 16, 51 e 100 (matar antes
da furia e aguentar 3 golpes da maior habilidade) e matilhas de 6 comuns nos andares 30, 75 e 99 (limpar
em ate 20 s e aguentar o contato de 3 comuns por esse tempo). Dano medido em arena de alvos fixos, sem esquiva
nem posicionamento fino: e uma estimativa, nao uma partida.

Medicoes: 14 s por arena, alvos imoveis, uma semente, equipamento com afixos favoraveis. Passar nesta
estimativa nao certifica uma campanha real nem todas as combinacoes de quatro gemas. Dano fixo e dano
por fracao da Vida sao separados; a avaliacao usa a Vida do inimigo e a Ressonancia da dificuldade.

Celula: `OK` passa em todos os 6 pontos; senao `aprovados/6`, quantas vezes falta de dano no pior ponto
(`dano x12` = precisa de 12 vezes mais dano) e `morre` se algum ponto falha por sobrevivencia.

## Resumo

| Build | DPS fixo chefe (d5) | DPS fixo matilha (d5) | Dif. 1 | Dif. 2 | Dif. 3 | Dif. 4 | Dif. 5 |
|---|---|---|---|---|---|---|---|
| Abrigo de Escora | 10,8 mil | 22,5 mil | 0/6 · dano x14,21 · morre | 0/6 · dano x225 · morre | 0/6 · dano x8,6 mil · morre | 0/6 · dano x61,3 mil · morre | 0/6 · dano x31,7 mil · morre |
| Agulha de Lastro | 967,9 mil | 3,8 mi | 1/6 · dano x23,78 · morre | OK | 2/6 · dano x6,27 · morre | 0/6 · dano x17,22 · morre | 0/6 · dano x564 · morre |
| Anel de Geada | 12,2 mil | 332,7 mil | 0/6 · dano x3,30 · morre | 0/6 · dano x19,31 · morre | 0/6 · dano x545 · morre | 0/6 · dano x10,6 mil · morre | 0/6 · dano x27,9 mil · morre |
| Arco Voltaico | 136,9 mil | 2,8 mi | 2/6 · dano x4,15 · morre | 3/6 · dano x2,85 · morre | 0/6 · dano x78,30 · morre | 0/6 · dano x1,1 mil · morre | 0/6 · dano x2,5 mil · morre |
| Bola de Fogo | 134,1 mil | 739,0 mil | 4/6 · dano x1,97 · morre | 4/6 · dano x1,91 · morre | 0/6 · dano x54,14 · morre | 0/6 · dano x1,1 mil · morre | 0/6 · dano x2,5 mil · morre |
| Bolha Corrosiva | 1,5 mi | 8,4 mi | 3/6 · dano x2,41 · morre | OK | 0/6 · dano x26,03 · morre | 0/6 · dano x111 · morre | 0/6 · dano x234 · morre |
| Brasa Persistente | 62,6 mil | 391,4 mil | 2/6 · dano x3,33 · morre | 3/6 · dano x3,23 · morre | 0/6 · dano x91,98 · morre | 0/6 · dano x2,0 mil · morre | 0/6 · dano x5,4 mil · morre |
| Casca Reativa | 6,9 mil | 42,8 mil | 0/6 · dano x3,86 · morre | 0/6 · dano x46,03 · morre | 0/6 · dano x1,4 mil · morre | 0/6 · dano x24,3 mil · morre | 0/6 · dano x49,7 mil · morre |
| Ceifa Ampla | 129,7 mil | 867,2 mil | 0/6 · dano x17,58 · morre | 4/6 · dano x1,47 | 0/6 · dano x43,78 · morre | 0/6 · dano x794 · morre | 0/6 · dano x4,2 mil · morre |
| Chuva Ferral | 2,3 mil | 12,4 mil | 0/6 · dano x13,44 · morre | 0/6 · dano x218 · morre | 0/6 · dano x8,4 mil · morre | 0/6 · dano x55,1 mil · morre | 0/6 · dano x150,9 mil · morre |
| Circulo de Reparo | 3,5 mil | 10,9 mil | 0/6 · dano x13,35 · morre | 0/6 · dano x124 · morre | 0/6 · dano x4,7 mil · morre | 0/6 · dano x11,5 mil · morre | 0/6 · dano x97,3 mil · morre |
| Cometa Sombrio | 4,4 mi | 22,2 mi | 3/6 · dano x1,75 · morre | OK | 1/6 · dano x22,14 · morre | 0/6 · dano x27,50 · morre | 0/6 · dano x77,98 · morre |
| Cometa de Vidro | 489,4 mil | 17,9 mi | 1/6 · dano x3,24 · morre | OK | 0/6 · dano x14,66 · morre | 0/6 · dano x361 · morre | 0/6 · dano x697 · morre |
| Corte Vetorial | 166,5 mil | 998,2 mil | 1/6 · dano x73,16 · morre | 4/6 · dano x1,31 | 0/6 · dano x39,08 · morre | 0/6 · dano x794 · morre | 0/6 · dano x3,3 mil · morre |
| Disco de Retorno | 3,7 mil | 45,9 mil | 0/6 · dano x19,64 · morre | 1/6 · dano x34,10 · morre | 0/6 · dano x1,1 mil · morre | 0/6 · dano x28,0 mil · morre | 0/6 · dano x145,7 mil · morre |
| Dreno em Rede | 280,1 mil | 5,8 mi | 2/6 · dano x2,75 · morre | 5/6 · dano x1,09 | 0/6 · dano x30,05 · morre | 0/6 · dano x428 · morre | 0/6 · dano x1,2 mil · morre |
| Elo Residual | 2,3 mi | 7,6 mi | 2/6 · dano x3,34 · morre | 3/6 · dano x2,55 · morre | 0/6 · dano x70,43 · morre | 0/6 · dano x64,72 · morre | 0/6 · dano x148 · morre |
| Enxame Luminar | 397,5 mil | 400,7 mil | 2/6 · dano x1,97 · morre | 4/6 · dano x4,39 · morre | 0/6 · dano x135 · morre | 0/6 · dano x761 · morre | 0/6 · dano x1,4 mil · morre |
| Esfera de Gelo | 1,2 mi | 6,5 mi | 4/6 · dano x2,05 · morre | OK | 0/6 · dano x24,96 · morre | 0/6 · dano x140 · morre | 0/6 · dano x276 · morre |
| Esporos | 5,5 mil | 12,8 mil | 2/6 · dano x5,70 · morre | 3/6 · dano x1,80 · morre | 3/6 · dano x2,15 · morre | 3/6 · dano x2,43 · morre | 3/6 · dano x2,43 · morre |
| Estilhacos Lunares | 8,7 mi | 30,4 mi | 1/6 · dano x17,84 · morre | OK | OK | 0/6 · dano x14,81 · morre | 0/6 · dano x39,06 · morre |
| Fio Desintegrador | 164,9 mil | 4,3 mi | 2/6 · dano x2,64 · morre | 5/6 · dano x1,18 | 0/6 · dano x32,71 · morre | 0/6 · dano x725 · morre | 0/6 · dano x2,1 mil · morre |
| Guardiao de Lastro | 13,4 mil | 65,4 mil | 0/6 · dano x3,23 · morre | 1/6 · dano x14,69 · morre | 0/6 · dano x447 · morre | 0/6 · dano x8,6 mil · morre | 0/6 · dano x25,4 mil · morre |
| Laminas Orbitais | 50,0 mil | 747,1 mil | 0/6 · dano x23,78 · morre | 3/6 · dano x8,05 · morre | 0/6 · dano x242 · morre | 0/6 · dano x2,2 mil · morre | 0/6 · dano x10,9 mil · morre |
| Lanca Ferral | 3,0 mi | 6,4 mi | 1/6 · dano x19,02 · morre | OK | 0/6 · dano x15,38 · morre | 0/6 · dano x52,44 · morre | 0/6 · dano x185 · morre |
| Mina de Lastro | 246,9 mil | 1,6 mi | 0/6 · dano x13,19 · morre | 4/6 · dano x1,46 · morre | 0/6 · dano x41,39 · morre | 0/6 · dano x649 · morre | 0/6 · dano x1,4 mil · morre |
| Molde Vigilante | 336,0 mil | 331,0 mil | 1/6 · dano x2,81 · morre | 3/6 · dano x6,25 · morre | 0/6 · dano x191 · morre | 0/6 · dano x1,0 mil · morre | 0/6 · dano x1,6 mil · morre |
| Muralha Refeita | 361 | 1,4 mil | 0/6 · dano x57,49 · morre | 0/6 · dano x394 · morre | 0/6 · dano x15,0 mil · morre | 0/6 · dano x269,3 mil · morre | 0/6 · dano x944,7 mil · morre |
| Orbe de Ruptura | 477,9 mil | 2,9 mi | 2/6 · dano x11,95 · morre | OK | 1/6 · dano x14,04 · morre | 0/6 · dano x319 · morre | 0/6 · dano x714 · morre |
| Pantano Acido | 145,4 mil | 842,8 mil | 1/6 · dano x3,33 · morre | 3/6 · dano x3,36 · morre | 0/6 · dano x96,03 · morre | 0/6 · dano x879 · morre | 0/6 · dano x2,3 mil · morre |
| Passo Vetorial | 251,3 mil | 1,5 mi | 0/6 · dano x8,45 · morre | 4/6 · dano x1,70 · morre | 0/6 · dano x51,80 · morre | 0/6 · dano x622 · morre | 0/6 · dano x2,2 mil · morre |
| Pilar Sagrado | 983,8 mil | 4,9 mi | 3/6 · dano x3,01 · morre | OK | 1/6 · dano x16,95 · morre | 0/6 · dano x122 · morre | 0/6 · dano x347 · morre |
| Poca de Veneno | 28,0 mil | 161,3 mil | 0/6 · dano x16,59 · morre | 1/6 · dano x5,81 · morre | 0/6 · dano x167 · morre | 0/6 · dano x3,9 mil · morre | 0/6 · dano x12,2 mil · morre |
| Prisao Gravitica | 674,0 mil | 4,0 mi | 4/6 · dano x3,19 · morre | 4/6 · dano x2,42 · morre | 0/6 · dano x68,05 · morre | 0/6 · dano x220 · morre | 0/6 · dano x506 · morre |
| Pulso de Cicatriz | 408,6 mil | 7,5 mi | 2/6 · dano x3,41 · morre | OK | 1/6 · dano x13,55 · morre | 0/6 · dano x293 · morre | 0/6 · dano x835 · morre |
| Raio Prismatico | 113,1 mil | 2,8 mi | 3/6 · dano x1,71 · morre | 4/6 · dano x1,62 · morre | 0/6 · dano x44,70 · morre | 0/6 · dano x1,1 mil · morre | 0/6 · dano x3,0 mil · morre |
| Raizes Presas | 65,3 mil | 391,8 mil | 2/6 · dano x6,16 · morre | 2/6 · dano x4,21 · morre | 0/6 · dano x123 · morre | 0/6 · dano x2,3 mil · morre | 0/6 · dano x5,2 mil · morre |
| Ruptura Sismica | 32,0 mil | 151,0 mil | 0/6 · dano x13,58 · morre | 1/6 · dano x12,10 · morre | 0/6 · dano x338 · morre | 0/6 · dano x3,9 mil · morre | 0/6 · dano x10,6 mil · morre |
| Salto de Guarda | 43,6 mil | 211,3 mil | 0/6 · dano x112 · morre | 1/6 · dano x6,79 · morre | 0/6 · dano x202 · morre | 0/6 · dano x2,8 mil · morre | 0/6 · dano x12,5 mil · morre |
| Saraivada de Flechas | 150,8 mil | 489,1 mil | 3/6 · dano x1,69 · morre | 2/6 · dano x4,17 · morre | 0/6 · dano x123 · morre | 0/6 · dano x978 · morre | 0/6 · dano x3,6 mil · morre |
| Satelites de Geada | 21,8 mil | 610,8 mil | 0/6 · dano x57,20 · morre | 1/6 · dano x40,21 · morre | 0/6 · dano x811 · morre | 0/6 · dano x7,4 mil · morre | 0/6 · dano x15,6 mil · morre |
| Semeadura Vital | 104,2 mil | 625,6 mil | 0/6 · dano x64,35 · morre | 2/6 · dano x4,18 · morre | 0/6 · dano x128 · morre | 0/6 · dano x1,0 mil · morre | 0/6 · dano x3,3 mil · morre |
| Semente Explosiva | 74,2 mil | 353,3 mil | 0/6 · dano x3,42 · morre | 3/6 · dano x3,56 · morre | 0/6 · dano x98,17 · morre | 0/6 · dano x1,9 mil · morre | 0/6 · dano x4,6 mil · morre |
| Sentinela Ferral | 343,7 mil | 349,2 mil | 2/6 · dano x1,65 · morre | 3/6 · dano x6,28 · morre | 0/6 · dano x193 · morre | 0/6 · dano x1,0 mil · morre | 0/6 · dano x1,6 mil · morre |
| Sopro Criogenico | 19,2 mil | 1,9 mi | 0/6 · dano x15,35 · morre | 2/6 · dano x12,76 | 0/6 · dano x379 · morre | 0/6 · dano x11,9 mil · morre | 0/6 · dano x17,7 mil · morre |
| Trovao Descendente | 1,5 mi | 7,3 mi | 0/6 · dano x13,33 · morre | OK | 1/6 · dano x9,81 · morre | 0/6 · dano x190 · morre | 0/6 · dano x234 · morre |
| Autoataque: Bastao (Rui) | 965 | 5,2 mil | 0/6 · dano x37,09 · morre | 0/6 · dano x180 · morre | 0/6 · dano x6,3 mil · morre | 0/6 · dano x87,0 mil · morre | 0/6 · dano x565,1 mil · morre |
| Autoataque: Foco (Eloa) | 28,9 mil | 262,7 mil | 2/6 · dano x3,42 · morre | 1/6 · dano x8,14 · morre | 0/6 · dano x263 · morre | 0/6 · dano x6,3 mil · morre | 0/6 · dano x11,8 mil · morre |
| Autoataque: Lanca (Sena) | 165,1 mil | 1,2 mi | 0/6 · dano x4,28 · morre | 4/6 · dano x1,32 | 0/6 · dano x41,18 · morre | 0/6 · dano x1,1 mil · morre | 0/6 · dano x3,3 mil · morre |
| Autoataque: Manoplas (Cira) | 5,2 mil | 30,5 mil | 0/6 · dano x62,81 · morre | 0/6 · dano x62,89 · morre | 0/6 · dano x1,8 mil · morre | 0/6 · dano x35,0 mil · morre | 0/6 · dano x104,6 mil · morre |

**Builds que vencem tudo:** dificuldade 1: 0 de 50, dificuldade 2: 11 de 50, dificuldade 3: 1 de 50, dificuldade 4: 0 de 50, dificuldade 5: 0 de 50

Gemas sem tag de dano: Passo Vetorial, Muralha Refeita, Salto de Guarda, Casca Reativa, Circulo de Reparo, Abrigo de Escora.
Falhar no criterio ofensivo nao mede o valor de cura, controle ou protecao dessas gemas;
nao usar essa comparacao sozinha para conceder buffs de dano.

## Continuidade em 2026-10-12

Cobertura validada: 50 assuntos distintos, cinco dificuldades e seis pontos por dificuldade.
31 resultados vieram dos JSONs anteriores; 10 foram recuperados de logs com DONE e todos os 30 pontos; 9 foram executados nesta retomada.
Logs preservam DPS arredondado e a configuracao final da dificuldade 5. Os sets intermediarios
das dificuldades 2-4 nao estavam nos logs: constam como null no JSON recuperado. Nao foram inventados.
A recuperacao serve para triagem; calibracao fina exige reexecutar esses 10 casos com precisao integral.
Nao foram alterados fatores de gemas, atributos ou dificuldades nesta rodada.

- Recuperadas: Agulha de Lastro, Anel de Geada, Bolha Corrosiva, Elo Residual, Enxame Luminar, Guardiao de Lastro, Laminas Orbitais, Molde Vigilante, Ruptura Sismica, Satelites de Geada
- Reexecutadas: Abrigo de Escora, Cometa Sombrio, Estilhacos Lunares, Pantano Acido, Pilar Sagrado, Semente Explosiva, Trovao Descendente, Autoataque: Foco (Eloa), Autoataque: Manoplas (Cira)

## Falta de dano por dificuldade

Mediana e pior caso de quantas vezes mais dano seria preciso (1 = no limite) e motivo das falhas.

| Dificuldade | Mediana chefe | Pior chefe | Mediana matilha | Pior matilha | Falhas por sobrevivencia |
|---|---|---|---|---|---|
| 1 | x2,16 | x64,35 | x1,92 | x112 | 124 |
| 2 | x1,03 | x338 | x0,84 | x394 | 43 |
| 3 | x30,43 | x12,6 mil | x20,85 | x15,0 mil | 116 |
| 4 | x361 | x269,3 mil | x160 | x130,9 mil | 148 |
| 5 | x909 | x944,7 mil | x329 | x383,7 mil | 150 |

## Set selecionado de cada build (dificuldade 5)

### Abrigo de Escora

- **Personagem:** Eloa
- **Evolucoes:** 5 Cura Farta, 10 Cultivo Longo, 15 Colheita Excedente, 20 Cultivo Movel, 21 Santuario Eterno
- **Suportes:** Area Expandida
- **Equipamento:** Lanca das Nove Mares, Tomo do Erudito, Coroa Sem Fim, Manto da Peste Eterna, Punho da Primeira Lei, Botas da Obra Infinita, Calca do Pastor de Moldes, Filamento do Circuito Eterno, Anel do Sol Partido, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 1,0 mil / matilha 1,0 mil · d3 chefe 1,1 mil / matilha 1,1 mil · d4 chefe 1,1 mil / matilha 6,4 mil · d5 chefe 10,8 mil / matilha 22,5 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Agulha de Lastro

- **Personagem:** Cira
- **Evolucoes:** 5 Disparo Gemeo, 10 Impacto Amplo, 15 Busca Certeira, 20 Disparo Veloz, 21 Leque Total
- **Suportes:** Eco Triplo
- **Equipamento:** Fio do Primeiro Lastro, Egide Imovel, Coroa de Brasa, Manto da Peste Eterna, Punho da Montanha, Botas do Cacador, Calca do Pastor de Moldes, Agulha do Horizonte, Anel da Corda Infinita, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 297,5 mil / matilha 991,0 mil · d3 chefe 435,9 mil / matilha 1,4 mi · d4 chefe 3,8 mi / matilha 13,3 mi · d5 chefe 967,9 mil / matilha 3,8 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Anel de Geada

- **Personagem:** Eloa
- **Evolucoes:** 5 Potencia Refinada, 10 Anel Oco, 15 Pulso Gelido, 20 Reserva Profunda, 21 Pulso Triplo
- **Suportes:** Foco Concentrado, Anel Vazio
- **Equipamento:** Halo da Geada Eterna, Tomo do Erudito, Coroa de Brasa, Manto do Inverno Longo, Punho da Primeira Lei, Botas do Brejo Antigo, Calca do Pastor de Moldes, Gatilho Ancestral, Filamento do Circuito Eterno, Ampulheta Partida
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 3,5 mil / matilha 12,1 mil · d3 chefe 4,5 mil / matilha 16,7 mil · d4 chefe 6,2 mil / matilha 157,6 mil · d5 chefe 12,2 mil / matilha 332,7 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Arco Voltaico

- **Personagem:** Eloa
- **Evolucoes:** 5 Potencia Refinada, 10 Ultimo Elo, 15 Elo Critico, 20 Reserva Profunda, 21 Tempestade em Cadeia
- **Suportes:** Sobrecarga Instavel, Potencia Bruta
- **Equipamento:** Bobina do Arco, Egide Imovel, Coroa Sem Fim, Manto do Inverno Longo, Punho da Primeira Lei, Botas da Obra Infinita, Calca do Pastor de Moldes, Gatilho Ancestral, Filamento do Circuito Eterno, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 24,8 mil / matilha 82,1 mil · d3 chefe 34,9 mil / matilha 116,1 mil · d4 chefe 59,6 mil / matilha 1,2 mi · d5 chefe 136,9 mil / matilha 2,8 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Bola de Fogo

- **Personagem:** Eloa
- **Evolucoes:** 5 Cadencia Treinada, 10 Ricochete, 15 Reserva Profunda, 20 Disparo Veloz, 21 Retorno
- **Suportes:** Eco Triplo
- **Equipamento:** Brasa do Primeiro Lume, Lente Arcana, Coroa Sem Fim, Manto do Inverno Longo, Luvas da Tempestade, Botas do Brejo Antigo, Calca do Pastor de Moldes, Filamento do Circuito Eterno, Anel da Corda Infinita, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 24,7 mil / matilha 134,8 mil · d3 chefe 33,9 mil / matilha 186,3 mil · d4 chefe 59,7 mil / matilha 326,0 mil · d5 chefe 134,1 mil / matilha 739,0 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Bolha Corrosiva

- **Personagem:** Eloa
- **Evolucoes:** 5 Cadencia Treinada, 10 Ricochete, 15 Reserva Profunda, 20 Disparo Veloz, 21 Leque Total
- **Suportes:** Eco Triplo
- **Equipamento:** Fel da Bolha Acre, Lente Arcana, Coroa Sem Fim, Manto do Inverno Longo, Luvas da Tempestade, Botas do Brejo Antigo, Veu do Eclipse, Filamento do Circuito Eterno, Anel da Corda Infinita, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 51,1 mil / matilha 299,5 mil · d3 chefe 70,4 mil / matilha 414,1 mil · d4 chefe 595,9 mil / matilha 3,4 mi · d5 chefe 1,5 mi / matilha 8,4 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Brasa Persistente

- **Personagem:** Eloa
- **Evolucoes:** 5 Campo Amplo, 10 Pulsos Rapidos, 15 Campo Itinerante, 20 Exposicao, 21 Campo Eterno
- **Suportes:** Sobrecarga Instavel, Foco Concentrado
- **Equipamento:** Tocha que Nao Apaga, Lente Arcana, Coroa de Brasa, Manto da Peste Eterna, Luvas da Tempestade, Botas do Brejo Antigo, Calca do Pastor de Moldes, Anel do Sol Partido, Anel da Corda Infinita, Ampulheta Partida
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 14,6 mil / matilha 87,8 mil · d3 chefe 19,9 mil / matilha 121,2 mil · d4 chefe 33,3 mil / matilha 203,7 mil · d5 chefe 62,6 mil / matilha 391,4 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Casca Reativa

- **Personagem:** Eloa
- **Evolucoes:** 5 Barreira Densa, 10 Casca Explosiva, 15 Espinhos, 20 Barreira Leve, 21 Explosao Final
- **Suportes:** Area Expandida
- **Equipamento:** Lanca das Nove Mares, Tomo do Erudito, Coroa Sem Fim, Manto da Peste Eterna, Punho da Primeira Lei, Botas do Brejo Antigo, Calca do Pastor de Moldes, Filamento do Circuito Eterno, Anel da Corda Infinita, Ampulheta Partida
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 1,5 mil / matilha 5,1 mil · d3 chefe 1,7 mil / matilha 6,3 mil · d4 chefe 2,7 mil / matilha 12,3 mil · d5 chefe 6,9 mil / matilha 42,8 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Ceifa Ampla

- **Personagem:** Cira
- **Evolucoes:** 5 Corte Longo, 10 Cadencia Treinada, 15 Ferida Aberta, 20 Gume Critico, 21 Leque da Ceifa
- **Suportes:** Sobrecarga Instavel, Area Expandida
- **Equipamento:** Foice da Grande Ceifa, Lente Arcana, Coroa de Brasa, Manto da Peste Eterna, Punho da Montanha, Botas da Obra Infinita, Coracao da Cicatriz Viva, Anel da Terra Viva, Agulha do Horizonte, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 32,1 mil / matilha 193,4 mil · d3 chefe 41,9 mil / matilha 252,5 mil · d4 chefe 83,2 mil / matilha 478,4 mil · d5 chefe 129,7 mil / matilha 867,2 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Chuva Ferral

- **Personagem:** Eloa
- **Evolucoes:** 5 Cadencia Treinada, 10 Queda Rapida, 15 Reserva Profunda, 20 Impacto Exposto, 21 Chuva de Fogo
- **Suportes:** Cadencia Precisa
- **Equipamento:** Lanca das Nove Mares, Tomo do Erudito, Coroa Sem Fim, Manto da Peste Eterna, Punho da Primeira Lei, Botas da Obra Infinita, Veu do Eclipse, Filamento do Circuito Eterno, Anel da Corda Infinita, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 1,0 mil / matilha 1,1 mil · d3 chefe 1,1 mil / matilha 1,1 mil · d4 chefe 1,2 mil / matilha 6,1 mil · d5 chefe 2,3 mil / matilha 12,4 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Circulo de Reparo

- **Personagem:** Eloa
- **Evolucoes:** 5 Cadencia Treinada, 10 Cultivo Longo, 15 Reserva Profunda, 20 Cultivo Movel, 21 Santuario Eterno
- **Suportes:** Fluxo Rapido, Cadencia Precisa
- **Equipamento:** Selo do Reparo, Egide Imovel, Coroa Sem Fim, Manto da Peste Eterna, Punho da Primeira Lei, Botas da Obra Infinita, Calca do Pastor de Moldes, Filamento do Circuito Eterno, Anel da Corda Infinita, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 1,6 mil / matilha 1,9 mil · d3 chefe 1,6 mil / matilha 1,9 mil · d4 chefe 9,0 mil / matilha 11,3 mil · d5 chefe 3,5 mil / matilha 10,9 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Cometa Sombrio

- **Personagem:** Eloa
- **Evolucoes:** 5 Perfuracao Funda, 10 Impacto Amplo, 15 Reserva Profunda, 20 Estilhacos, 21 Leque Total
- **Suportes:** Eco Triplo, Ricochete de Junta
- **Equipamento:** Rastro da Noite Funda, Lente Arcana, Coroa Sem Fim, Manto do Inverno Longo, Luvas da Tempestade, Botas do Brejo Antigo, Veu do Eclipse, Anel da Corda Infinita, Anel do Sol Partido, Ampulheta Partida
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 60,1 mil / matilha 312,0 mil · d3 chefe 82,8 mil / matilha 431,5 mil · d4 chefe 2,4 mi / matilha 12,2 mi · d5 chefe 4,4 mi / matilha 22,2 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Cometa de Vidro

- **Personagem:** Eloa
- **Evolucoes:** 5 Cadencia Treinada, 10 Cratera, 15 Reserva Profunda, 20 Potencia Refinada, 21 Cataclismo
- **Suportes:** Eco Triplo
- **Equipamento:** Cauda do Cometa, Egide Imovel, Coroa de Brasa, Manto do Inverno Longo, Punho da Primeira Lei, Botas da Obra Infinita, Calca do Pastor de Moldes, Gatilho Ancestral, Anel da Corda Infinita, Ampulheta Partida
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 90,6 mil / matilha 506,1 mil · d3 chefe 125,1 mil / matilha 700,2 mil · d4 chefe 183,0 mil / matilha 6,6 mi · d5 chefe 489,4 mil / matilha 17,9 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Corte Vetorial

- **Personagem:** Cira
- **Evolucoes:** 5 Passo Longo, 10 Chegada Explosiva, 15 Guarda de Chegada, 20 Retomada, 21 Tempestade Vetorial
- **Suportes:** Eco Atrasado, Fluxo Rapido
- **Equipamento:** Gume do Vetor, Lente Arcana, Coroa Sem Fim, Manto da Peste Eterna, Punho da Montanha, Botas do Cacador, Coracao da Cicatriz Viva, Filamento do Circuito Eterno, Agulha do Horizonte, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 35,9 mil / matilha 220,7 mil · d3 chefe 46,9 mil / matilha 290,6 mil · d4 chefe 83,2 mil / matilha 487,7 mil · d5 chefe 166,5 mil / matilha 998,2 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Disco de Retorno

- **Personagem:** Cira
- **Evolucoes:** 5 Fio Denso, 10 Corte Fundo, 15 Retorno Faminto, 20 Disco Veloz, 21 Disco Vampiro
- **Suportes:** Sobrecarga Instavel, Potencia Bruta
- **Equipamento:** Disco Sem Fim, Lente Arcana, Coroa de Brasa, Manto do Inverno Longo, Punho da Montanha, Botas do Cacador, Coracao da Cicatriz Viva, Agulha do Horizonte, Gatilho Ancestral, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 1,4 mil / matilha 16,6 mil · d3 chefe 1,7 mil / matilha 21,0 mil · d4 chefe 2,4 mil / matilha 28,6 mil · d5 chefe 3,7 mil / matilha 45,9 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Dreno em Rede

- **Personagem:** Eloa
- **Evolucoes:** 5 Potencia Refinada, 10 Ultimo Elo, 15 Elo Critico, 20 Reserva Profunda, 21 Tempestade em Cadeia
- **Suportes:** Potencia Bruta, Sobrecarga Instavel
- **Equipamento:** Teia Sedenta, Tomo do Erudito, Coroa de Brasa, Manto do Inverno Longo, Punho da Primeira Lei, Botas do Brejo Antigo, Veu do Eclipse, Gatilho Ancestral, Anel da Corda Infinita, Ampulheta Partida
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 66,8 mil / matilha 213,6 mil · d3 chefe 94,5 mil / matilha 302,4 mil · d4 chefe 154,2 mil / matilha 3,2 mi · d5 chefe 280,1 mil / matilha 5,8 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Elo Residual

- **Personagem:** Eloa
- **Evolucoes:** 5 Potencia Refinada, 10 Ultimo Elo, 15 Elo Critico, 20 Reserva Profunda, 21 Tempestade em Cadeia
- **Suportes:** Sobrecarga Instavel, Cadencia Precisa
- **Equipamento:** Corrente Remanescente, Tomo do Erudito, Coroa Sem Fim, Manto do Inverno Longo, Luvas da Tempestade, Botas do Brejo Antigo, Veu do Eclipse, Filamento do Circuito Eterno, Anel da Corda Infinita, Coracao Imortal
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 30,0 mil / matilha 91,5 mil · d3 chefe 42,1 mil / matilha 129,0 mil · d4 chefe 1,0 mi / matilha 3,3 mi · d5 chefe 2,3 mi / matilha 7,6 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Enxame Luminar

- **Personagem:** Eloa
- **Evolucoes:** 5 Cadencia Treinada, 10 Ataque Rapido, 15 Reserva Profunda, 20 Forja Forte, 21 Colosso
- **Suportes:** Sobrecarga Instavel, Potencia Bruta
- **Equipamento:** Colmeia de Luz, Lente Arcana, Coroa Sem Fim, Manto do Inverno Longo, Punho da Primeira Lei, Botas do Brejo Antigo, Calca do Pastor de Moldes, Anel do Sol Partido, Anel da Corda Infinita, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 56,3 mil / matilha 53,2 mil · d3 chefe 71,2 mil / matilha 67,4 mil · d4 chefe 182,7 mil / matilha 172,2 mil · d5 chefe 397,5 mil / matilha 400,7 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Esfera de Gelo

- **Personagem:** Eloa
- **Evolucoes:** 5 Cadencia Treinada, 10 Ricochete, 15 Reserva Profunda, 20 Estilhacos, 21 Leque Total
- **Suportes:** Eco Triplo
- **Equipamento:** Nucleo do Inverno, Lente Arcana, Coroa Sem Fim, Manto do Inverno Longo, Luvas da Tempestade, Botas da Obra Infinita, Calca do Pastor de Moldes, Filamento do Circuito Eterno, Anel do Tempo Partido, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 53,4 mil / matilha 281,2 mil · d3 chefe 73,5 mil / matilha 388,8 mil · d4 chefe 472,9 mil / matilha 2,5 mi · d5 chefe 1,2 mi / matilha 6,5 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Esporos

- **Personagem:** Eloa
- **Evolucoes:** 5 Colonia Voraz, 10 Esporos Densos, 15 Alcance da Infeccao, 20 Esporo Leve, 21 Esporangio Vivo
- **Suportes:** Potencia Bruta, Cadencia Precisa
- **Equipamento:** Esporangio Ancestral, Egide Imovel, Coroa Sem Fim, Manto da Peste Eterna, Punho da Primeira Lei, Botas da Obra Infinita, Calca do Pastor de Moldes, Filamento do Circuito Eterno, Anel do Tempo Partido, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 2,5 mil / matilha 3,3 mil · d3 chefe 2,5 mil / matilha 3,4 mil · d4 chefe 2,6 mil / matilha 7,2 mil · d5 chefe 5,5 mil / matilha 12,8 mil
- **Dano por fracao da Vida:** d2 chefe 1.4167%/s / matilha 3.8667%/s por alvo · d3 chefe 1.4167%/s / matilha 3.8667%/s por alvo · d4 chefe 1.4167%/s / matilha 4.1143%/s por alvo · d5 chefe 1.4167%/s / matilha 5.1429%/s por alvo

### Estilhacos Lunares

- **Personagem:** Cira
- **Evolucoes:** 5 Disparo Gemeo, 10 Ricochete, 15 Busca Certeira, 20 Estilhacos, 21 Leque Total
- **Suportes:** Eco Triplo, Ricochete de Junta
- **Equipamento:** Leque da Lua Partida, Egide Imovel, Folego Primordial, Manto da Peste Eterna, Punho da Montanha, Botas do Cacador, Coracao da Cicatriz Viva, Anel do Furor, Agulha do Horizonte, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 2,3 mi / matilha 7,5 mi · d3 chefe 2,9 mi / matilha 9,6 mi · d4 chefe 4,5 mi / matilha 14,9 mi · d5 chefe 8,7 mi / matilha 30,4 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Fio Desintegrador

- **Personagem:** Eloa
- **Evolucoes:** 5 Potencia Refinada, 10 Feixe Duplo, 15 Foco Critico, 20 Reserva Profunda, 21 Prisma
- **Suportes:** Sobrecarga Instavel, Potencia Bruta
- **Equipamento:** Lamina Desfiada, Tomo do Erudito, Coroa de Brasa, Manto do Inverno Longo, Punho da Primeira Lei, Botas do Brejo Antigo, Veu do Eclipse, Gatilho Ancestral, Anel da Corda Infinita, Ampulheta Partida
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 39,8 mil / matilha 236,9 mil · d3 chefe 56,0 mil / matilha 335,4 mil · d4 chefe 91,1 mil / matilha 2,4 mi · d5 chefe 164,9 mil / matilha 4,3 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Guardiao de Lastro

- **Personagem:** Eloa
- **Evolucoes:** 5 Cadencia Treinada, 10 Alcance do Vigia, 15 Reserva Profunda, 20 Alcance Treinado, 21 Colosso
- **Suportes:** Sobrecarga Instavel, Alcance Treinado
- **Equipamento:** Juramento do Guardiao, Lente Arcana, Coroa Sem Fim, Manto da Peste Eterna, Luvas da Tempestade, Botas do Brejo Antigo, Calca do Pastor de Moldes, Anel da Terra Viva, Anel do Sol Partido, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 4,1 mil / matilha 15,9 mil · d3 chefe 5,4 mil / matilha 20,4 mil · d4 chefe 7,7 mil / matilha 29,8 mil · d5 chefe 13,4 mil / matilha 65,4 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Laminas Orbitais

- **Personagem:** Cira
- **Evolucoes:** 5 Orbita Extra, 10 Orbita Larga, 15 Giro Longo, 20 Potencia Refinada, 21 Ciclone
- **Suportes:** Area Expandida, Sobrecarga Instavel
- **Equipamento:** Eixo das Tres Laminas, Tomo do Erudito, Coroa Sem Fim, Manto da Peste Eterna, Punho da Montanha, Botas do Cacador, Veu do Eclipse, Anel da Terra Viva, Anel da Corda Infinita, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 17,1 mil / matilha 29,0 mil · d3 chefe 22,2 mil / matilha 37,6 mil · d4 chefe 29,6 mil / matilha 448,5 mil · d5 chefe 50,0 mil / matilha 747,1 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Lanca Ferral

- **Personagem:** Cira
- **Evolucoes:** 5 Disparo Gemeo, 10 Ricochete, 15 Busca Certeira, 20 Estilhacos, 21 Leque Total
- **Suportes:** Eco Triplo
- **Equipamento:** Presa de Ferral, Lente Arcana, Coroa Sem Fim, Manto da Peste Eterna, Punho da Montanha, Botas do Cacador, Coracao da Cicatriz Viva, Anel da Terra Viva, Filamento do Circuito Eterno, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 189,7 mil / matilha 435,3 mil · d3 chefe 257,9 mil / matilha 591,0 mil · d4 chefe 1,3 mi / matilha 2,8 mi · d5 chefe 3,0 mi / matilha 6,4 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Mina de Lastro

- **Personagem:** Eloa
- **Evolucoes:** 5 Carga Ampla, 10 Carga Pesada, 15 Mina Reserva, 20 Estilhaco Exposto, 21 Mina Colossal
- **Suportes:** Eco Atrasado, Foco Concentrado
- **Equipamento:** Detonador de Lastro, Lente Arcana, Coroa Sem Fim, Manto do Inverno Longo, Luvas da Tempestade, Botas da Obra Infinita, Calca do Pastor de Moldes, Anel do Sol Partido, Anel da Corda Infinita, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 32,3 mil / matilha 215,9 mil · d3 chefe 44,3 mil / matilha 298,5 mil · d4 chefe 101,6 mil / matilha 674,0 mil · d5 chefe 246,9 mil / matilha 1,6 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Molde Vigilante

- **Personagem:** Rui
- **Evolucoes:** 5 Cadencia Treinada, 10 Ataque Rapido, 15 Reserva Profunda, 20 Forja Forte, 21 Colosso
- **Suportes:** Sobrecarga Instavel, Potencia Bruta
- **Equipamento:** Matriz do Vigia, Lente Arcana, Coroa Sem Fim, Manto do Inverno Longo, Punho da Primeira Lei, Botas do Brejo Antigo, Calca do Pastor de Moldes, Anel da Terra Viva, Filamento do Circuito Eterno, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 37,3 mil / matilha 37,4 mil · d3 chefe 47,4 mil / matilha 47,5 mil · d4 chefe 126,5 mil / matilha 125,9 mil · d5 chefe 336,0 mil / matilha 331,0 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Muralha Refeita

- **Personagem:** Cira
- **Evolucoes:** 5 Barreira Densa, 10 Guarda Partilhada, 15 Espinhos, 20 Barreira Reserva, 21 Explosao Final
- **Suportes:** Foco Concentrado
- **Equipamento:** Lanca das Nove Mares, Egide Imovel, Folego Primordial, Manto da Peste Eterna, Punho da Montanha, Botas da Obra Infinita, Coracao da Cicatriz Viva, Anel da Terra Viva, Agulha do Horizonte, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 140 / matilha 593 · d3 chefe 145 / matilha 604 · d4 chefe 245 / matilha 1,0 mil · d5 chefe 361 / matilha 1,4 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Orbe de Ruptura

- **Personagem:** Cira
- **Evolucoes:** 5 Cadencia Treinada, 10 Ricochete, 15 Reserva Profunda, 20 Disparo Veloz, 21 Retorno
- **Suportes:** Eco Triplo
- **Equipamento:** Coracao da Ruptura, Lente Arcana, Coroa de Brasa, Manto da Peste Eterna, Punho da Montanha, Botas da Obra Infinita, Coracao da Cicatriz Viva, Anel da Terra Viva, Agulha do Horizonte, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 102,8 mil / matilha 609,7 mil · d3 chefe 130,6 mil / matilha 774,2 mil · d4 chefe 206,6 mil / matilha 1,2 mi · d5 chefe 477,9 mil / matilha 2,9 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Pantano Acido

- **Personagem:** Eloa
- **Evolucoes:** 5 Campo Amplo, 10 Pulsos Rapidos, 15 Colapso, 20 Reserva Profunda, 21 Campo Eterno
- **Suportes:** Eco Atrasado, Foco Concentrado
- **Equipamento:** Raiz do Brejo Acre, Lente Arcana, Coroa Sem Fim, Manto do Inverno Longo, Luvas da Tempestade, Botas do Brejo Antigo, Calca do Pastor de Moldes, Filamento do Circuito Eterno, Anel do Tempo Partido, Sino do Folego Leve
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 14,0 mil / matilha 81,1 mil · d3 chefe 19,1 mil / matilha 111,9 mil · d4 chefe 75,1 mil / matilha 426,6 mil · d5 chefe 145,4 mil / matilha 842,8 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Passo Vetorial

- **Personagem:** Sena
- **Evolucoes:** 5 Passo Longo, 10 Rastro Cortante, 15 Guarda de Chegada, 20 Retomada, 21 Tempestade Vetorial
- **Suportes:** Eco Atrasado
- **Equipamento:** Vetor Sem Sombra, Lente Arcana, Coroa de Brasa, Manto da Peste Eterna, Punho da Montanha, Botas da Obra Infinita, Coracao da Cicatriz Viva, Filamento do Circuito Eterno, Agulha do Horizonte, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 45,0 mil / matilha 137,8 mil · d3 chefe 55,9 mil / matilha 175,4 mil · d4 chefe 106,1 mil / matilha 534,3 mil · d5 chefe 251,3 mil / matilha 1,5 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Pilar Sagrado

- **Personagem:** Rui
- **Evolucoes:** 5 Impacto Denso, 10 Queda Rapida, 15 Reserva Profunda, 20 Potencia Refinada, 21 Cataclismo
- **Suportes:** Foco Concentrado, Sobrecarga Instavel
- **Equipamento:** Coluna da Alvorada, Lente Arcana, Coroa Sem Fim, Manto do Inverno Longo, Luvas da Tempestade, Botas do Brejo Antigo, Calca do Pastor de Moldes, Anel do Sol Partido, Anel da Corda Infinita, Sino do Folego Leve
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 78,2 mil / matilha 473,7 mil · d3 chefe 108,2 mil / matilha 655,7 mil · d4 chefe 540,7 mil / matilha 2,7 mi · d5 chefe 983,8 mil / matilha 4,9 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Poca de Veneno

- **Personagem:** Eloa
- **Evolucoes:** 5 Toxina Densa, 10 Poca Duradoura, 15 Reabrir a Poca, 20 Potencia Refinada, 21 Toxina Letal
- **Suportes:** Foco Concentrado, Potencia Bruta
- **Equipamento:** Calice do Lodo, Lente Arcana, Coroa Sem Fim, Manto do Inverno Longo, Punho da Primeira Lei, Botas do Brejo Antigo, Calca do Pastor de Moldes, Anel do Sol Partido, Filamento do Circuito Eterno, Ampulheta Partida
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 8,1 mil / matilha 42,8 mil · d3 chefe 11,0 mil / matilha 59,1 mil · d4 chefe 16,9 mil / matilha 92,3 mil · d5 chefe 28,0 mil / matilha 161,3 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Prisao Gravitica

- **Personagem:** Eloa
- **Evolucoes:** 5 Potencia Refinada, 10 Pulsos Rapidos, 15 Campo Itinerante, 20 Exposicao, 21 Campo Eterno
- **Suportes:** Sobrecarga Instavel, Foco Concentrado
- **Equipamento:** Lanca das Nove Mares, Lente Arcana, Coroa Sem Fim, Manto do Inverno Longo, Luvas da Tempestade, Botas do Brejo Antigo, Veu do Eclipse, Anel do Sol Partido, Filamento do Circuito Eterno, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 23,5 mil / matilha 96,7 mil · d3 chefe 32,2 mil / matilha 133,5 mil · d4 chefe 299,7 mil / matilha 1,2 mi · d5 chefe 674,0 mil / matilha 4,0 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Pulso de Cicatriz

- **Personagem:** Eloa
- **Evolucoes:** 5 Potencia Refinada, 10 Anel Oco, 15 Eco do Pulso, 20 Fissura, 21 Pulso Triplo
- **Suportes:** Sobrecarga Instavel, Foco Concentrado
- **Equipamento:** Batimento da Cicatriz, Tomo do Erudito, Coroa de Brasa, Manto do Inverno Longo, Punho da Primeira Lei, Botas do Brejo Antigo, Veu do Eclipse, Gatilho Ancestral, Anel da Corda Infinita, Coracao Imortal
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 98,1 mil / matilha 475,6 mil · d3 chefe 138,3 mil / matilha 670,9 mil · d4 chefe 225,1 mil / matilha 4,1 mi · d5 chefe 408,6 mil / matilha 7,5 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Raio Prismatico

- **Personagem:** Eloa
- **Evolucoes:** 5 Potencia Refinada, 10 Feixe Duplo, 15 Foco Critico, 20 Recarga Focada, 21 Lanca de Luz
- **Suportes:** Sobrecarga Instavel, Cadencia Precisa
- **Equipamento:** Prisma Absoluto, Tomo do Erudito, Coroa de Brasa, Manto do Inverno Longo, Punho da Primeira Lei, Botas do Brejo Antigo, Calca do Pastor de Moldes, Anel do Sol Partido, Gatilho Ancestral, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 29,1 mil / matilha 152,9 mil · d3 chefe 41,0 mil / matilha 216,3 mil · d4 chefe 61,8 mil / matilha 1,5 mi · d5 chefe 113,1 mil / matilha 2,8 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Raizes Presas

- **Personagem:** Cira
- **Evolucoes:** 5 Campo Amplo, 10 Pulsos Rapidos, 15 Colapso, 20 Exposicao, 21 Buraco Negro
- **Suportes:** Sobrecarga Instavel, Potencia Bruta
- **Equipamento:** Enxerto das Raizes, Lente Arcana, Coroa Sem Fim, Manto da Peste Eterna, Punho da Montanha, Botas do Brejo Antigo, Veu do Eclipse, Filamento do Circuito Eterno, Anel do Sol Partido, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 11,2 mil / matilha 60,1 mil · d3 chefe 14,9 mil / matilha 82,5 mil · d4 chefe 29,3 mil / matilha 169,0 mil · d5 chefe 65,3 mil / matilha 391,8 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Ruptura Sismica

- **Personagem:** Eloa
- **Evolucoes:** 5 Potencia Refinada, 10 Anel Oco, 15 Pulso Gelido, 20 Reserva Profunda, 21 Supernova
- **Suportes:** Sobrecarga Instavel, Foco Concentrado
- **Equipamento:** Punho do Abalo, Tomo do Erudito, Coroa de Brasa, Manto da Peste Eterna, Luvas da Tempestade, Botas do Brejo Antigo, Calca do Pastor de Moldes, Anel da Terra Viva, Anel do Sol Partido, Ampulheta Partida
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 5,1 mil / matilha 19,3 mil · d3 chefe 7,1 mil / matilha 26,9 mil · d4 chefe 16,9 mil / matilha 79,5 mil · d5 chefe 32,0 mil / matilha 151,0 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Salto de Guarda

- **Personagem:** Cira
- **Evolucoes:** 5 Potencia Refinada, 10 Rastro Cortante, 15 Guarda de Chegada, 20 Retomada, 21 Tempestade Vetorial
- **Suportes:** Eco Atrasado
- **Equipamento:** Asa da Retirada, Egide Imovel, Coroa de Brasa, Manto da Peste Eterna, Punho da Montanha, Botas da Obra Infinita, Coracao da Cicatriz Viva, Anel da Terra Viva, Agulha do Horizonte, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 7,3 mil / matilha 34,4 mil · d3 chefe 9,7 mil / matilha 44,9 mil · d4 chefe 23,8 mil / matilha 114,9 mil · d5 chefe 43,6 mil / matilha 211,3 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Saraivada de Flechas

- **Personagem:** Sena
- **Evolucoes:** 5 Folego Predador, 10 Rajadas Rapidas, 15 Pontas Largas, 20 Potencia Refinada, 21 Tempestade de Flechas
- **Suportes:** Sobrecarga Instavel, Potencia Bruta
- **Equipamento:** Lanca das Nove Mares, Lente Arcana, Coroa de Brasa, Manto da Peste Eterna, Punho da Montanha, Botas do Cacador, Coracao da Cicatriz Viva, Agulha do Horizonte, Anel da Corda Infinita, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 15,6 mil / matilha 56,0 mil · d3 chefe 20,1 mil / matilha 73,7 mil · d4 chefe 67,5 mil / matilha 197,7 mil · d5 chefe 150,8 mil / matilha 489,1 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Satelites de Geada

- **Personagem:** Cira
- **Evolucoes:** 5 Orbita Extra, 10 Laminas Largas, 15 Giro Longo, 20 Orbita Gelida, 21 Ciclone
- **Suportes:** Foco Concentrado, Detonacao Tardia
- **Equipamento:** Orbita Invernal, Egide Imovel, Coroa Sem Fim, Manto do Inverno Longo, Punho da Montanha, Botas do Cacador, Coracao da Cicatriz Viva, Anel da Terra Viva, Agulha do Horizonte, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 1,2 mil / matilha 37,5 mil · d3 chefe 2,3 mil / matilha 52,1 mil · d4 chefe 9,0 mil / matilha 277,8 mil · d5 chefe 21,8 mil / matilha 610,8 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Semeadura Vital

- **Personagem:** Cira
- **Evolucoes:** 5 Circulo Amplo, 10 Cultivo Longo, 15 Pulsos Rapidos, 20 Espinhos do Jardim, 21 Santuario Eterno
- **Suportes:** Eco Atrasado
- **Equipamento:** Cajado da Primeira Colheita, Lente Arcana, Coroa Sem Fim, Manto da Peste Eterna, Punho da Montanha, Botas do Brejo Antigo, Calca do Pastor de Moldes, Filamento do Circuito Eterno, Anel da Terra Viva, Coracao Imortal
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 11,3 mil / matilha 68,3 mil · d3 chefe 14,3 mil / matilha 86,7 mil · d4 chefe 64,3 mil / matilha 386,1 mil · d5 chefe 104,2 mil / matilha 625,6 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Semente Explosiva

- **Personagem:** Eloa
- **Evolucoes:** 5 Carga Ampla, 10 Carga Pesada, 15 Estilhaco Lento, 20 Estilhaco Exposto, 21 Mina Colossal
- **Suportes:** Sobrecarga Instavel, Foco Concentrado
- **Equipamento:** Semente do Estrondo, Tomo do Erudito, Coroa de Brasa, Manto da Peste Eterna, Luvas da Tempestade, Botas do Brejo Antigo, Calca do Pastor de Moldes, Anel do Sol Partido, Anel da Corda Infinita, Sino do Folego Leve
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 13,2 mil / matilha 71,6 mil · d3 chefe 18,7 mil / matilha 101,7 mil · d4 chefe 35,0 mil / matilha 166,4 mil · d5 chefe 74,2 mil / matilha 353,3 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Sentinela Ferral

- **Personagem:** Eloa
- **Evolucoes:** 5 Cadencia Treinada, 10 Ataque Rapido, 15 Reserva Profunda, 20 Forja Forte, 21 Colosso
- **Suportes:** Sobrecarga Instavel, Potencia Bruta
- **Equipamento:** Olho da Sentinela, Lente Arcana, Coroa Sem Fim, Manto do Inverno Longo, Punho da Primeira Lei, Botas do Brejo Antigo, Calca do Pastor de Moldes, Filamento do Circuito Eterno, Anel do Sol Partido, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 37,2 mil / matilha 37,2 mil · d3 chefe 47,0 mil / matilha 47,0 mil · d4 chefe 131,9 mil / matilha 130,0 mil · d5 chefe 343,7 mil / matilha 349,2 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Sopro Criogenico

- **Personagem:** Cira
- **Evolucoes:** 5 Potencia Refinada, 10 Cadencia Treinada, 15 Ferida Aberta, 20 Reserva Profunda, 21 Ceifa Tripla
- **Suportes:** Sobrecarga Instavel, Foco Concentrado
- **Equipamento:** Pulmao de Gelo, Egide Imovel, Coroa Sem Fim, Manto da Peste Eterna, Punho da Montanha, Botas do Cacador, Coracao da Cicatriz Viva, Agulha do Horizonte, Filamento do Circuito Eterno, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 3,7 mil / matilha 225,3 mil · d3 chefe 4,8 mil / matilha 291,7 mil · d4 chefe 5,5 mil / matilha 9,1 mi · d5 chefe 19,2 mil / matilha 1,9 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Trovao Descendente

- **Personagem:** Eloa
- **Evolucoes:** 5 Impacto Denso, 10 Queda Rapida, 15 Reserva Profunda, 20 Potencia Refinada, 21 Cataclismo
- **Suportes:** Eco Triplo, Foco Concentrado
- **Equipamento:** Voz do Trovao, Lente Arcana, Coroa Sem Fim, Manto do Inverno Longo, Punho da Montanha, Botas do Brejo Antigo, Calca do Pastor de Moldes, Filamento do Circuito Eterno, Anel da Corda Infinita, Sino do Folego Leve
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 138,4 mil / matilha 682,4 mil · d3 chefe 193,0 mil / matilha 958,7 mil · d4 chefe 348,3 mil / matilha 1,7 mi · d5 chefe 1,5 mi / matilha 7,3 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Autoataque: Bastao (Rui)

- **Personagem:** Rui
- **Suportes:** Sobrecarga Instavel
- **Equipamento:** Detonador de Lastro, Tomo do Erudito, Coroa de Brasa, Manto da Peste Eterna, Punho da Montanha, Botas da Obra Infinita, Coracao da Cicatriz Viva, Gatilho Ancestral, Filamento do Circuito Eterno, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 425 / matilha 1,3 mil · d3 chefe 454 / matilha 1,4 mil · d4 chefe 759 / matilha 2,4 mil · d5 chefe 965 / matilha 5,2 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Autoataque: Foco (Eloa)

- **Personagem:** Eloa
- **Suportes:** Bifurcacao Residual, Projeteis Gemeos
- **Equipamento:** Corrente Remanescente, Tomo do Erudito, Coroa Sem Fim, Manto da Peste Eterna, Punho da Primeira Lei, Botas da Obra Infinita, Veu do Eclipse, Gatilho Ancestral, Filamento do Circuito Eterno, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 5,8 mil / matilha 35,5 mil · d3 chefe 7,0 mil / matilha 48,1 mil · d4 chefe 10,5 mil / matilha 79,0 mil · d5 chefe 28,9 mil / matilha 262,7 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Autoataque: Lanca (Sena)

- **Personagem:** Sena
- **Suportes:** Foco Concentrado
- **Equipamento:** Fio do Primeiro Lastro, Egide Imovel, Folego Primordial, Manto da Peste Eterna, Punho da Montanha, Botas do Cacador, Coracao da Cicatriz Viva, Gatilho Ancestral, Agulha do Horizonte, Lastro Partido
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 35,8 mil / matilha 177,9 mil · d3 chefe 44,5 mil / matilha 226,9 mil · d4 chefe 61,5 mil / matilha 325,4 mil · d5 chefe 165,1 mil / matilha 1,2 mi
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

### Autoataque: Manoplas (Cira)

- **Personagem:** Cira
- **Suportes:** Sobrecarga Instavel
- **Equipamento:** Batimento da Cicatriz, Tomo do Erudito, Presa da Serpente, Manto da Peste Eterna, Punho da Primeira Lei, Botas do Brejo Antigo, Veu do Eclipse, Gatilho Ancestral, Filamento do Circuito Eterno, Cetro da Legiao
- **Paragon 175:** defensiva 61, elemental 26, ofensiva 62, utilidade 26
- **DPS fixo:** d2 chefe 750 / matilha 4,5 mil · d3 chefe 1,0 mil / matilha 6,1 mil · d4 chefe 1,9 mil / matilha 10,5 mil · d5 chefe 5,2 mil / matilha 30,5 mil
- **Dano por fracao da Vida:** d2 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d3 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d4 chefe 0.0000%/s / matilha 0.0000%/s por alvo · d5 chefe 0.0000%/s / matilha 0.0000%/s por alvo

