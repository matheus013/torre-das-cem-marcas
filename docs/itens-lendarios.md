# Itens lendarios e armas unicas

Gerado por `tools/content/build_legendary_items.py` a partir de `tools/content/legendary_passives.py`
(decisao 580). Toda peca lendaria tem uma passiva exclusiva, executada por
`src/gameplay/items/item_passives.gd`. Meta: uma unica peca basta para levar a personagem ate o fim
da historia; as dificuldades do pos-jogo (backlog G6) vao exigi-las. Valores provisorios para playtest.

## Lendarios genericos

| Item | Encaixe | Passiva |
|---|---|---|
| Coroa de Brasa | Amuleto | **Fogo que Nao Apaga**: Gemas de fogo +40%. Acertos delas incendeiam (60% do golpe em 3 s) e quem morre em chamas explode. |
| Manto do Inverno Longo | Armadura | **Inverno Interior**: Gemas de gelo +40%; acertos delas congelam (70% por 1,5 s) e expoem o alvo (+20%). Dano recebido -15%. |
| Luvas da Tempestade | Luvas | **Tempestade nas Maos**: Gemas de raio +40%; metade dos acertos delas ramifica em area com 70% do golpe. |
| Botas do Brejo Antigo | Botas | **Raiz e Acido**: Gemas de acido e natureza +35%. Acido deixa o alvo 30% mais vulneravel; natureza cura a cada acerto. |
| Veu do Eclipse | Calca | **Fome do Eclipse**: Gemas de trevas +40%; cada abate delas cura 4% da Vida e devolve 3 de Folego. |
| Anel do Sol Partido | Anel | **Sol Partido**: Gemas sagradas +40%; lancar uma delas cura 8% da Vida e da 8% em barreira. |
| Anel da Terra Viva | Anel | **Pedra Viva**: Gemas de terra +40% e dano recebido -10%; lancar uma delas da 12% da Vida em barreira. |
| Lente Arcana | Mao secundaria | **Lente Arcana**: Gemas arcanas +40%; todo critico de gema adianta 0,5 s a recarga de todas as gemas. |
| Punho da Montanha | Luvas | **Peso da Montanha**: Gemas fisicas e autoataque +35%; criticos fisicos racham o chao com 100% do golpe em area. |
| Tomo do Erudito | Mao secundaria | **Erudicao Absoluta**: Gemas magicas +30%; cada lancamento magico devolve 4 de Folego. |
| Gatilho Ancestral | Anel | **Gatilho Ancestral**: Autoataque +40% de dano e +15% de cadencia; a cada 4 acertos ele dispara a gema de Q de graca com 60% da potencia. |
| Calca do Pastor de Moldes | Calca | **Rebanho Fiel**: Invocacoes +50% de potencia e duram 25% mais; invocar cura 5% da Vida. |
| Coracao Imortal | Reliquia | **Recusa da Morte**: Golpe fatal nao derruba: volta com 60% da Vida, 3 s de invulnerabilidade e uma explosao sagrada (uma vez a cada 90 s). |
| Ampulheta Partida | Reliquia | **Tempo Roubado**: Cada abate adianta 0,35 s a recarga de todas as gemas. Recargas -10%. |
| Folego Primordial | Amuleto | **Pulmao do Mundo**: Folego maximo +40 e regeneracao +60%; cada abate devolve 3 de Folego. |
| Couraca do Colosso | Armadura | **Colosso**: Dano recebido -25%; ao ser ferida, ganha barreira de 15% da Vida (a cada 6 s). |
| Presa da Serpente | Amuleto | **Mordida Final**: Inimigo envenenado (qualquer veneno) que morre explode com 20% da propria Vida maxima em volta e deixa uma Poca de Veneno: com todas as melhorias se a gema estiver equipada; senao, de nivel 1. Toda Presa traz alcance de proliferacao de veneno de +30% a +100%, que amplia a explosao, a poca e o espalhamento dos esporos. |
| Botas do Cacador | Botas | **Frenesi da Caca**: Cada abate da +8% de potencia e +4% de velocidade por 6 s, acumulando ate 6 vezes. |
| Lastro Partido | Reliquia | **Peso Vetorial**: Toda gema de movimento abre uma Prisao Gravitica no ponto de chegada com 120% da potencia. Velocidade +10%. |

## Armas unicas (uma por gema)

Alem da passiva, cada arma da +50% a potencia principal da gema, -25% de recarga e uma assinatura da mecanica.

| Arma | Gema | Passiva |
|---|---|---|
| Fio do Primeiro Lastro | Agulha de Lastro | **Agulha Fantasma**: A cada 2 lancamentos, tres agulhas fantasmas partem sozinhas contra os inimigos mais proximos com potencia total. |
| Presa de Ferral | Lanca Ferral | **Presa Dilacerante**: Acertos da Lanca deixam o alvo vulneravel (+35% de dano recebido por 4 s); abates estouram o corpo em area com 100% do golpe. |
| Leque da Lua Partida | Estilhacos Lunares | **Lua Cheia**: Criticos dos Estilhacos reduzem 1 s da recarga de todas as gemas e devolvem 3 de Folego. Chance critica +10%. |
| Coracao da Ruptura | Orbe de Ruptura | **Ruptura Continua**: Todo acerto do Orbe rompe em area: 60% do golpe a ate 110 de distancia. |
| Brasa do Primeiro Lume | Bola de Fogo | **Coracao de Fornalha**: Acertos incendeiam (80% do golpe em 3 s). Inimigo em chamas abatido pela Bola de Fogo explode com 80% da potencia da gema. |
| Fel da Bolha Acre | Bolha Corrosiva | **Acido Voraz**: Acertos corroem (+30% de dano recebido por 5 s); cada abate dispara uma nova bolha contra o inimigo mais proximo. |
| Rastro da Noite Funda | Cometa Sombrio | **Eclipse Faminto**: Abate com o Cometa Sombrio zera a recarga dele e recupera 4% da Vida. |
| Nucleo do Inverno | Esfera de Gelo | **Zero Absoluto**: Acertos congelam (lentidao 85% por 2 s; metade em chefes) e deixam o alvo 30% mais vulneravel. |
| Disco Sem Fim | Disco de Retorno | **Disco Insaciavel**: Cada lancamento solta um segundo disco 0,4 s depois com 70% da potencia; acertos devolvem Folego. |
| Arco das Tres Tempestades | Saraivada de Flechas | **Tempestade Triplice**: Flecha que abate vira um raio no corpo: 250% do golpe em area e 1 de Folego. |
| Vetor Sem Sombra | Passo Vetorial | **Passo Alem**: Depois do Passo, todas as gemas ganham +50% de potencia por 4 s e as outras recargas andam 1,5 s. |
| Gume do Vetor | Corte Vetorial | **Gume do Horizonte**: Ao chegar, o Corte explode em volta com 150% da potencia da gema e deixa os atingidos vulneraveis. |
| Asa da Retirada | Salto de Guarda | **Asa Inquebravel**: O Salto da 1,2 s de invulnerabilidade, barreira de 25% da Vida e cura 8%. |
| Batimento da Cicatriz | Pulso de Cicatriz | **Cicatriz Viva**: Cada inimigo atingido pelo Pulso cura 2% da Vida; abates com ele reduzem 0,8 s da recarga. |
| Halo da Geada Eterna | Anel de Geada | **Inverno Eterno**: O Anel congela (lentidao 90% por 2,5 s; metade em chefes) e deixa os atingidos 40% mais vulneraveis. |
| Punho do Abalo | Ruptura Sismica | **Falha Viva**: Cada Ruptura gera dois tremores seguidos com 60% da potencia. |
| Ancora do Peso Cativo | Prisao Gravitica | **Singularidade**: Inimigo abatido pela Prisao colapsa: 200% da potencia da gema em area. |
| Tocha que Nao Apaga | Brasa Persistente | **Brasa Eterna**: Os pulsos da Brasa incendeiam com o dobro do golpe em 4 s. Gemas de fogo +15%. |
| Raiz do Brejo Acre | Pantano Acido | **Pantano Vivo**: Quem pisa no Pantano fica 40% mais vulneravel e 40% mais lento. |
| Enxerto das Raizes | Raizes Presas | **Raiz Mestra**: As Raizes prendem de vez (lentidao 95% por 1 s) e cada pulso cura 1% da Vida. |
| Pedra que se Refaz | Muralha Refeita | **Muralha Viva**: Erguer a Muralha da +40% de potencia e -30% de dano recebido por 6 s. |
| Carapaca Vingativa | Casca Reativa | **Casca Espelhada**: Todo golpe recebido volta em area com 400% do dano. Dano recebido -15%. |
| Corrente Remanescente | Elo Residual | **Elo Infinito**: Inimigo abatido pelo Elo dispara um novo Elo contra o inimigo mais proximo com 80% da potencia. |
| Bobina do Arco | Arco Voltaico | **Bobina Sobrecarregada**: Cada salto do Arco reduz 0,25 s da recarga dele; criticos descarregam 150% do golpe em area. |
| Teia Sedenta | Dreno em Rede | **Rede Faminta**: Cada alvo drenado cura 2% da Vida e soma 2% em barreira. |
| Matriz do Vigia | Molde Vigilante | **Matriz Viva**: Um Molde novo surge sozinho a cada 8 s ao lado do inimigo mais proximo. |
| Olho da Sentinela | Sentinela Ferral | **Matilha**: Uma Sentinela extra se ergue sozinha a cada 10 s; abates das sentinelas devolvem 2 de Folego. |
| Colmeia de Luz | Enxame Luminar | **Enxame Solar**: Um enxame extra a cada 9 s; cada ferroada cura 1% da Vida. |
| Juramento do Guardiao | Guardiao de Lastro | **Guardiao Imortal**: Ao ser ferida, um Guardiao surge de graca (uma vez a cada 15 s) com barreira de 20% da Vida. |
| Cajado da Primeira Colheita | Semeadura Vital | **Jardim Eterno**: Semear cura 15% da Vida e da 15% em barreira; a cada 6 s em combate o jardim cura mais 4%. |
| Selo do Reparo | Circulo de Reparo | **Circulo Sagrado**: O Circulo cura 20% da Vida e adianta 3 s a recarga de todas as gemas. |
| Viga do Abrigo | Abrigo de Escora | **Abrigo Inabalavel**: Erguer o Abrigo da 2 s de invulnerabilidade e metade do dano recebido por 6 s. |
| Foice da Grande Ceifa | Ceifa Ampla | **Grande Ceifa**: Cada abate da Ceifa reduz 0,6 s da recarga dela e cura 1,5% da Vida. |
| Pulmao de Gelo | Sopro Criogenico | **Folego do Inverno**: O Sopro congela (lentidao 80% por 2 s) e cada alvo devolve 1 de Folego. |
| Prisma Absoluto | Raio Prismatico | **Prisma Solar**: O Raio deixa o alvo 25% mais vulneravel; criticos explodem em luz com 80% da potencia da gema. |
| Lamina Desfiada | Fio Desintegrador | **Desintegracao**: O Fio executa inimigos comuns e elites abaixo de 30% da Vida. |
| Eixo das Tres Laminas | Laminas Orbitais | **Ciclone de Laminas**: Cada corte das Laminas cura 0,6% da Vida e devolve Folego. Velocidade de movimento +15%. |
| Orbita Invernal | Satelites de Geada | **Orbita Glacial**: Os Satelites congelam (70% por 1,5 s) e, a cada 3 s em combate, pulsam gelo em volta com 100% da potencia da gema. |
| Detonador de Lastro | Mina de Lastro | **Campo Minado**: Cada Mina vem com mais duas em volta, com potencia total. |
| Semente do Estrondo | Semente Explosiva | **Semente Fertil**: Inimigo abatido pela Semente planta outra no lugar com 60% da potencia. |
| Ceu de Ferral | Chuva Ferral | **Diluvio Ferral**: Cada Chuva traz uma segunda onda 1 s depois com 80% da potencia. |
| Cauda do Cometa | Cometa de Vidro | **Vidro Estilhacado**: Inimigo abatido pelo Cometa estilhaca: 60% do golpe em area e lentidao de 60%. |
| Coluna da Alvorada | Pilar Sagrado | **Pilar Eterno**: Erguer o Pilar cura 10% da Vida e da 10% em barreira; quem e atingido fica 30% mais vulneravel. |
| Esporangio Ancestral | Esporos | **Colonia Primordial**: Cada lancamento infecta tambem os dois inimigos mais proximos do alvo. |
| Calice do Lodo | Poca de Veneno | **Lodo Gemeo**: Cada Poca de Veneno abre uma segunda poca ao lado com 70% da potencia. |
| Voz do Trovao | Trovao Descendente | **Ceu Partido**: Cada raio tem 40% de chance de ramificar no alvo: 60% do golpe em area. |
