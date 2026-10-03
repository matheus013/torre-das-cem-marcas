# Torre: Andares, Biomas e Chefes

## Estado

**Implementado no jogo (decisoes 553 a 559).** Gerado a partir de `data/tower/tower_content.json` por `tools/content/build_tower.py`; edite o gerador e rode-o de novo. Valores provisorios para playtest.

## Estrutura

- Cem andares em dez biomas, seguindo a divisao do documento 05 e os documentos 28 a 37.
- **Andares comuns** sao mapas grandes (3200x2400 no andar 1 ate 4800x3600 a partir do andar 61) com matilhas espalhadas, cristas de obstaculos, pontos de patrulha, portal de retorno na entrada e escada no extremo oposto. A escada abre ao cumprir a cota de abates do andar.
- **Andares de chefe** sao arenas circulares pequenas (raio 430). A saida fica selada enquanto o chefe vive; a vitoria abre a escada. O chefe derrotado volta depois de 20 minutos; ate la o andar e passagem.
- O grupo atravessa os andares junto: a escada leva todos que estao no andar. Quem entra na Torre depois cai no andar atual. Com a Torre vazia, a proxima entrada comeca no andar de partida escolhido no mapa da Torre (ate o mais fundo ja alcancado).
- Profundidade: inimigos comuns e de elite ganham `1 + 0,085 x (andar - 1)` de Vida e `1 + 0,045 x (andar - 1)` de dano; perigos de bioma, `1 + 0,04 x (andar - 1)`. Chefes usam numeros proprios.
- Monstros patrulham o territorio e so perseguem quem chega a 520 unidades; dano acorda a matilha vizinha; quem se afasta demais de casa desiste.
- Respawn acelera com o tempo no andar: intervalo de `14 / (1 + tempo / 120)` segundos, no minimo 2,5, sempre a mais de 480 unidades do grupo.
- Recordes: melhor tempo por andar em SOLO, DUO, TRIO e SQUAD (maior numero de jogadores conectados durante a corrida). Andares comuns contam ate a descida; andares de chefe, ate a queda do chefe.

## Biomas

| Andares | Bioma | Mecanica ambiental | Perigo no jogo | Monstros | Materiais |
|---|---|---|---|---|---|
| 1-7 | Galerias Refeitas | Cicatrizacao | Parede em formacao (golpes em circulo sob os jogadores) | Larva de Junta, Raspador de Junta, Sentinela de Cal, Emboscado de Reboco, Molde de Ferramenta, Escora Hostil, Vigia Moldado | Pedra Regenerativa e materiais do recorte |
| 8-16 | Bosque dos Ventos Presos | Mares de Vento | Rajada (rajada em linha que empurra) | Semeador de Juncos, Planador de Rajada, Casca de Pressao, Predador da Calmaria | Junco Mineral, Membrana de Pressao |
| 17-27 | Manto dos Esporos | Rede Micelial | Nuvem de esporos (poca persistente (dano e lentidao)) | Esporinho, Tecelao Micelial, Sentinela de Chapeu, Devorador Branco | Lanterna de Esporo, Ambar Micelial |
| 28-39 | Bacias do Quarto Pulso | Ciclo das Quatro Aguas | Lamina d'agua (poca persistente (dano e lentidao)) | Filtrador, Anfibio de Canal, Predador de Lama, Colosso de Conchas | Lodo Mineral, Perola de Refluxo |
| 40-51 | Ermo do Trovao Preso | Acumulo e Descarga | Descarga (golpes em circulo sob os jogadores) | Escavador Vitreo, Carapaca Carregada, Cacador de Metal, Ninho de Descarga | Vidro Negro, Cristal de Carga |
| 52-63 | Arquivo das Rotas Mortas | Cartografia Reativa | Rota que se redesenha (linhas a partir do chefe) | Tracador, Devorador de Tinta, Sinaleiro Falso, Cartografo Oco | Tinta Mineral, Marco Gravado |
| 64-72 | Planicie dos Adormecidos | Movimento Colossal | Respiracao do colosso (anel (seguro so colado ao chefe)) | Limpador, Predador de Dobra, Migrante, Colosso Menor | Pele Mineral, Seiva Colossal |
| 73-81 | Eixos Partidos | Orientacao Gravitacional | Poco de vetor (puxao para o centro e explosao) | Aderente Menor, Planador de Eixo, Ilha Pesada, Cortador de Ancoras | Cabo de Lastro, Fragmento de Eixo |
| 82-93 | Campos do Quase | Possibilidades Transitorias | Possibilidade que se fixa (chuva de areas pela arena) | Eco de Presa, Flor de Escolha, Cacador de Versoes, Fixador Vivo | Petala Possivel, Semente do Quase |
| 94-100 | Obra Inacabada | Convergencia Regional | Convergencia (mistura de todos) | Operario Sem Autor, Molde Vivo, Marca Numerada, Eco Regional | Material Sem Autor, Marca de Mandato |

## Chefes

Todo chefe tem fases por Vida (habilidades novas e mais ritmo a cada fase), furia apos o tempo indicado (dano x1,5 e recargas x0,6) e combinacoes extras com dois, tres e quatro jogadores (golpes duplos, linhas cruzadas e chuva de areas). Toda habilidade de area e anunciada no chao antes do golpe.

| Andar | Chefe | Vida | Dano | Fases (Vida) | Furia | Habilidades |
|---|---|---|---|---|---|---|
| 4 | Guardiao de Enxerto | 900 | 24 | 60% | 150 s | golpes em circulo sob os jogadores; explosao ao redor do chefe; invoca criaturas do bioma (fase 2) |
| 7 | O Refeitor | 1400 | 28 | 65%, 30% | 180 s | cruz de quatro linhas; golpes em circulo sob os jogadores; anel (seguro so colado ao chefe) (fase 2); invoca criaturas do bioma (fase 2) |
| 16 | Pastor das Correntes | 2200 | 32 | 60%, 30% | 180 s | rajada em linha que empurra; rajada radial de projeteis; puxao para o centro e explosao (fase 2); chuva de areas pela arena (fase 2) |
| 27 | Guardia do No-Mae | 3200 | 36 | 60%, 30% | 200 s | poca persistente (dano e lentidao); explosao ao redor do chefe; invoca criaturas do bioma; anel (seguro so colado ao chefe) (fase 2) |
| 39 | Guardiao da Comporta | 4600 | 42 | 60%, 30% | 210 s | linhas a partir do chefe; poca persistente (dano e lentidao); investida em linha; rajada radial de projeteis (fase 2) |
| 51 | Coroa dos Condutores | 6200 | 48 | 65%, 35% | 220 s | chuva de areas pela arena; cruz de quatro linhas; rajada radial de projeteis; explosao ao redor do chefe (fase 2) |
| 63 | Guardiao do Marco Cego | 8000 | 54 | 60%, 30% | 230 s | linhas a partir do chefe; golpes em circulo sob os jogadores; investida em linha; anel (seguro so colado ao chefe) (fase 2) |
| 72 | Palpebra do Horizonte | 10500 | 60 | 60%, 30% | 240 s | anel (seguro so colado ao chefe); linhas a partir do chefe; invoca criaturas do bioma; chuva de areas pela arena (fase 2) |
| 81 | Guardiao do Eixo Zero | 13000 | 66 | 60%, 30% | 240 s | puxao para o centro e explosao; cruz de quatro linhas; rajada radial de projeteis; investida em linha (fase 2) |
| 93 | Guardiao da Ultima Escolha | 16000 | 72 | 65%, 35% | 250 s | chuva de areas pela arena; anel (seguro so colado ao chefe); linhas a partir do chefe; invoca criaturas do bioma (fase 2) |
| 100 | Regente Centesimo | 22000 | 80 | 70%, 40%, 15% | 260 s | cruz de quatro linhas; chuva de areas pela arena; anel (seguro so colado ao chefe); rajada radial de projeteis; puxao para o centro e explosao (fase 2); invoca criaturas do bioma (fase 2) |

## Andares

| Andar | Nome | Bioma | Tipo | Cota | Tamanho |
|---|---|---|---|---|---|
| 1 | Patio das Marcas | Galerias Refeitas | comum | 18 | 3200x2400 |
| 2 | Vias de Extracao | Galerias Refeitas | comum | 19 | 3226x2420 |
| 3 | Vias de Extracao | Galerias Refeitas | comum | 19 | 3253x2440 |
| 4 | Camara Refeita | Galerias Refeitas | chefe | - | 1400x1100 |
| 5 | Fratura Recente | Galerias Refeitas | comum | 20 | 3306x2480 |
| 6 | Fratura Recente | Galerias Refeitas | comum | 21 | 3333x2500 |
| 7 | Porta das Sete Molduras | Galerias Refeitas | chefe | - | 1400x1100 |
| 8 | Desfiladeiros do Sopro | Bosque dos Ventos Presos | comum | 22 | 3386x2540 |
| 9 | Desfiladeiros do Sopro | Bosque dos Ventos Presos | comum | 22 | 3413x2560 |
| 10 | Bosque Oco | Bosque dos Ventos Presos | comum | 23 | 3440x2580 |
| 11 | Bosque Oco | Bosque dos Ventos Presos | comum | 23 | 3466x2600 |
| 12 | Bosque Oco | Bosque dos Ventos Presos | comum | 24 | 3493x2620 |
| 13 | Calmaria Morta | Bosque dos Ventos Presos | comum | 24 | 3520x2640 |
| 14 | Calmaria Morta | Bosque dos Ventos Presos | comum | 25 | 3546x2660 |
| 15 | Calmaria Morta | Bosque dos Ventos Presos | comum | 25 | 3573x2680 |
| 16 | Pulmao da Pedra | Bosque dos Ventos Presos | chefe | - | 1400x1100 |
| 17 | Borda Seca | Manto dos Esporos | comum | 26 | 3626x2720 |
| 18 | Borda Seca | Manto dos Esporos | comum | 27 | 3653x2740 |
| 19 | Copa Baixa | Manto dos Esporos | comum | 27 | 3680x2760 |
| 20 | Copa Baixa | Manto dos Esporos | comum | 28 | 3706x2780 |
| 21 | Copa Baixa | Manto dos Esporos | comum | 28 | 3733x2800 |
| 22 | Encruzilhada das Lanternas | Manto dos Esporos | comum | 29 | 3760x2820 |
| 23 | Encruzilhada das Lanternas | Manto dos Esporos | comum | 29 | 3786x2840 |
| 24 | Encruzilhada das Lanternas | Manto dos Esporos | comum | 30 | 3813x2860 |
| 25 | Branco Esteril | Manto dos Esporos | comum | 30 | 3840x2880 |
| 26 | Branco Esteril | Manto dos Esporos | comum | 31 | 3866x2900 |
| 27 | No-Mae | Manto dos Esporos | chefe | - | 1400x1100 |
| 28 | Pedras de Vazante | Bacias do Quarto Pulso | comum | 32 | 3920x2940 |
| 29 | Pedras de Vazante | Bacias do Quarto Pulso | comum | 32 | 3946x2960 |
| 30 | Pedras de Vazante | Bacias do Quarto Pulso | comum | 33 | 3973x2980 |
| 31 | Canais de Pressao | Bacias do Quarto Pulso | comum | 33 | 4000x3000 |
| 32 | Canais de Pressao | Bacias do Quarto Pulso | comum | 34 | 4026x3020 |
| 33 | Canais de Pressao | Bacias do Quarto Pulso | comum | 34 | 4053x3040 |
| 34 | Bacia dos Naufragios | Bacias do Quarto Pulso | comum | 35 | 4080x3060 |
| 35 | Bacia dos Naufragios | Bacias do Quarto Pulso | comum | 35 | 4106x3080 |
| 36 | Bacia dos Naufragios | Bacias do Quarto Pulso | comum | 36 | 4133x3100 |
| 37 | Leito Oco | Bacias do Quarto Pulso | comum | 36 | 4160x3120 |
| 38 | Leito Oco | Bacias do Quarto Pulso | comum | 37 | 4186x3140 |
| 39 | Comporta do Quarto Pulso | Bacias do Quarto Pulso | chefe | - | 1400x1100 |
| 40 | Planicies de Vidro Negro | Ermo do Trovao Preso | comum | 38 | 4240x3180 |
| 41 | Planicies de Vidro Negro | Ermo do Trovao Preso | comum | 38 | 4266x3200 |
| 42 | Planicies de Vidro Negro | Ermo do Trovao Preso | comum | 39 | 4293x3220 |
| 43 | Campos de Carga | Ermo do Trovao Preso | comum | 39 | 4320x3240 |
| 44 | Campos de Carga | Ermo do Trovao Preso | comum | 40 | 4346x3260 |
| 45 | Campos de Carga | Ermo do Trovao Preso | comum | 40 | 4373x3280 |
| 46 | Abrigos Quebrados | Ermo do Trovao Preso | comum | 41 | 4400x3300 |
| 47 | Abrigos Quebrados | Ermo do Trovao Preso | comum | 41 | 4426x3320 |
| 48 | Abrigos Quebrados | Ermo do Trovao Preso | comum | 42 | 4453x3340 |
| 49 | Tempestade Espelhada | Ermo do Trovao Preso | comum | 42 | 4480x3360 |
| 50 | Tempestade Espelhada | Ermo do Trovao Preso | comum | 43 | 4506x3380 |
| 51 | Coroa dos Condutores | Ermo do Trovao Preso | chefe | - | 1400x1100 |
| 52 | Estradas Sobrepostas | Arquivo das Rotas Mortas | comum | 44 | 4560x3420 |
| 53 | Estradas Sobrepostas | Arquivo das Rotas Mortas | comum | 44 | 4586x3440 |
| 54 | Estradas Sobrepostas | Arquivo das Rotas Mortas | comum | 45 | 4613x3460 |
| 55 | Salas de Medida | Arquivo das Rotas Mortas | comum | 45 | 4640x3480 |
| 56 | Salas de Medida | Arquivo das Rotas Mortas | comum | 46 | 4666x3500 |
| 57 | Salas de Medida | Arquivo das Rotas Mortas | comum | 46 | 4693x3520 |
| 58 | Oficinas Desviadas | Arquivo das Rotas Mortas | comum | 47 | 4720x3540 |
| 59 | Oficinas Desviadas | Arquivo das Rotas Mortas | comum | 47 | 4746x3560 |
| 60 | Oficinas Desviadas | Arquivo das Rotas Mortas | comum | 48 | 4773x3580 |
| 61 | Duas Marchas | Arquivo das Rotas Mortas | comum | 48 | 4800x3600 |
| 62 | Duas Marchas | Arquivo das Rotas Mortas | comum | 49 | 4800x3600 |
| 63 | Marco Cego | Arquivo das Rotas Mortas | chefe | - | 1400x1100 |
| 64 | Horizonte Impossivel | Planicie dos Adormecidos | comum | 50 | 4800x3600 |
| 65 | Dorso das Estacoes | Planicie dos Adormecidos | comum | 50 | 4800x3600 |
| 66 | Dorso das Estacoes | Planicie dos Adormecidos | comum | 51 | 4800x3600 |
| 67 | Dorso das Estacoes | Planicie dos Adormecidos | comum | 51 | 4800x3600 |
| 68 | Vales de Pulso | Planicie dos Adormecidos | comum | 52 | 4800x3600 |
| 69 | Vales de Pulso | Planicie dos Adormecidos | comum | 52 | 4800x3600 |
| 70 | Campo das Mudas | Planicie dos Adormecidos | comum | 53 | 4800x3600 |
| 71 | Campo das Mudas | Planicie dos Adormecidos | comum | 53 | 4800x3600 |
| 72 | Palpebra do Horizonte | Planicie dos Adormecidos | chefe | - | 1400x1100 |
| 73 | Escadas Laterais | Eixos Partidos | comum | 54 | 4800x3600 |
| 74 | Escadas Laterais | Eixos Partidos | comum | 55 | 4800x3600 |
| 75 | Pocos de Vetor | Eixos Partidos | comum | 55 | 4800x3600 |
| 76 | Pocos de Vetor | Eixos Partidos | comum | 56 | 4800x3600 |
| 77 | Pocos de Vetor | Eixos Partidos | comum | 56 | 4800x3600 |
| 78 | Camara do Primeiro Lastro | Eixos Partidos | comum | 57 | 4800x3600 |
| 79 | Queda das Ancoras | Eixos Partidos | comum | 57 | 4800x3600 |
| 80 | Queda das Ancoras | Eixos Partidos | comum | 58 | 4800x3600 |
| 81 | Eixo Zero | Eixos Partidos | chefe | - | 1400x1100 |
| 82 | Bifurcacoes Vivas | Campos do Quase | comum | 59 | 4800x3600 |
| 83 | Bifurcacoes Vivas | Campos do Quase | comum | 59 | 4800x3600 |
| 84 | Bifurcacoes Vivas | Campos do Quase | comum | 60 | 4800x3600 |
| 85 | Bifurcacoes Vivas | Campos do Quase | comum | 60 | 4800x3600 |
| 86 | Jardins Possiveis | Campos do Quase | comum | 61 | 4800x3600 |
| 87 | Jardins Possiveis | Campos do Quase | comum | 61 | 4800x3600 |
| 88 | Jardins Possiveis | Campos do Quase | comum | 62 | 4800x3600 |
| 89 | Ruinas do Nunca | Campos do Quase | comum | 62 | 4800x3600 |
| 90 | Ruinas do Nunca | Campos do Quase | comum | 63 | 4800x3600 |
| 91 | Ruinas do Nunca | Campos do Quase | comum | 63 | 4800x3600 |
| 92 | Horizonte Reduzido | Campos do Quase | comum | 64 | 4800x3600 |
| 93 | Ultima Escolha | Campos do Quase | chefe | - | 1400x1100 |
| 94 | Vestibulo das Consequencias | Obra Inacabada | comum | 65 | 4800x3600 |
| 95 | Oficinas Sem Autor | Obra Inacabada | comum | 65 | 4800x3600 |
| 96 | Oficinas Sem Autor | Obra Inacabada | comum | 66 | 4800x3600 |
| 97 | Galeria dos Seis Fundamentos | Obra Inacabada | comum | 66 | 4800x3600 |
| 98 | Camara das Cem Marcas | Obra Inacabada | comum | 67 | 4800x3600 |
| 99 | Ultimo Limiar | Obra Inacabada | comum | 67 | 4800x3600 |
| 100 | Sala Sem Numero | Obra Inacabada | chefe | - | 1400x1100 |
