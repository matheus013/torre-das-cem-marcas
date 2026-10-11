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
| Botas do Vendaval | Botas | **Passo de Vendaval**: Velocidade de movimento +60%. |
| Anel da Corda Infinita | Anel | **Rajada Sem Fim**: Cada volta completa da Saraivada de Flechas lanca de graca a gema do W no inimigo mais proximo, ignorando a recarga e o Folego. |
| Anel do Furor | Anel | **Furor do Arqueiro**: Cada volta completa da Saraivada de Flechas da 1 acumulo por 10 s (ganhar outro renova todos): +2% de velocidade, +4% de dano e -1,5% de dano recebido por acumulo, ate 25 (+50%, +100% e -37,5%). |
| Sino do Folego Leve | Reliquia | **Ar Leve**: Todas as gemas custam 50% menos Folego, inclusive o custo por segundo da Saraivada de Flechas. |
| Lastro Partido | Reliquia | **Peso Vetorial**: Toda gema de movimento abre uma Prisao Gravitica no ponto de chegada com 120% da potencia. Velocidade +10%. |

## Armas unicas (uma por gema)

Alem da passiva, cada arma da +50% a potencia principal da gema, -25% de recarga e uma assinatura da mecanica.

| Arma | Gema | Passiva |
|---|---|---|
| Fio do Primeiro Lastro | Agulha de Lastro | **Agulha Errante**: A Agulha nao para no primeiro alvo: ricocheteia entre ate 6 inimigos e volta a mao. |
| Presa de Ferral | Lanca Ferral | **Lanca de Ida e Volta**: A Lanca atravessa todos os inimigos no caminho e volta atravessando de novo. |
| Leque da Lua Partida | Estilhacos Lunares | **Lua Cheia**: Criticos dos Estilhacos reduzem 1 s da recarga de todas as gemas e devolvem 3 de Folego. Chance critica +10%. |
| Coracao da Ruptura | Orbe de Ruptura | **Orbe Gravitacional**: O Orbe para no ponto mirado como um campo que puxa os inimigos por 3 s e explode com o dobro do golpe. |
| Brasa do Primeiro Lume | Bola de Fogo | **Sol Cativo**: A Bola de Fogo vira um sol que acompanha a personagem por 6 s, queimando quem chega perto (acertos incendeiam com 60% do golpe em 3 s). |
| Fel da Bolha Acre | Bolha Corrosiva | **Bolha que se Divide**: Ao estourar, a Bolha se divide em 3 bolhas que seguem viagem. |
| Rastro da Noite Funda | Cometa Sombrio | **Eclipse Faminto**: Abate com o Cometa Sombrio zera a recarga dele e recupera 4% da Vida. |
| Nucleo do Inverno | Esfera de Gelo | **Zero Absoluto**: Inimigo comum ou elite atingido pela Esfera abaixo de 25% da Vida se estilhaca, soltando 3 esferas menores (40% do golpe) contra os mais proximos. |
| Disco Sem Fim | Disco de Retorno | **Discos Gemeos**: O Disco nao e lancado: dois discos orbitam a personagem por 8 s cortando quem chega perto. |
| Arco das Tres Tempestades | Saraivada de Flechas | **Tempestade Triplice**: Flecha que abate vira um raio no corpo: 250% do golpe em area e 1 de Folego. |
| Vetor Sem Sombra | Passo Vetorial | **Passo Alem**: Depois do Passo, todas as gemas ganham +50% de potencia por 4 s e as outras recargas andam 1,5 s. |
| Gume do Vetor | Corte Vetorial | **Corte em Cadeia**: Abater um inimigo com o Corte zera a recarga dele: com alvos por perto, da para cortar sem parar. |
| Asa da Retirada | Salto de Guarda | **Salto do Martelo**: O Salto vira um golpe de aterrissagem: esmaga em volta com 250% da barreira de chegada e repele os atingidos. |
| Batimento da Cicatriz | Pulso de Cicatriz | **Pulso Constante**: O Pulso dispara sozinho a cada 1,5 s enquanto houver inimigos perto, sem custo. |
| Halo da Geada Eterna | Anel de Geada | **Inverno que Prende**: O Anel imobiliza por completo por 1,5 s (metade em chefes), mas quase nao causa dano. |
| Punho do Abalo | Ruptura Sismica | **Fenda**: A Ruptura vira uma fissura em linha reta ate o alvo, atingindo e repelindo tudo no caminho. |
| Ancora do Peso Cativo | Prisao Gravitica | **Repulsao**: A Prisao acompanha a personagem e expulsa os inimigos de perto, ferindo quem insiste. |
| Tocha que Nao Apaga | Brasa Persistente | **Fogueira Perene**: A Brasa nao se apaga: so pode haver uma, e lancar de novo a muda de lugar. |
| Raiz do Brejo Acre | Pantano Acido | **Pantano Contagioso**: Inimigo que morre dentro do Pantano abre um novo Pantano no lugar (60% da potencia). |
| Enxerto das Raizes | Raizes Presas | **Trilha de Raizes**: As Raizes acompanham a personagem e prendem quem chega perto. |
| Pedra que se Refaz | Muralha Refeita | **Muralha Ofensiva**: A barreira que sobrar quando a Muralha acaba explode em volta com 3x o valor. |
| Carapaca Vingativa | Casca Reativa | **Casca Espelhada**: Todo golpe recebido volta em area com 400% do dano. Dano recebido -15%. |
| Corrente Remanescente | Elo Residual | **Elo Infinito**: Inimigo abatido pelo Elo dispara um novo Elo contra o inimigo mais proximo com 80% da potencia. |
| Bobina do Arco | Arco Voltaico | **Arco Infinito**: O Arco salta ate 30 vezes entre inimigos proximos. |
| Teia Sedenta | Dreno em Rede | **Fome da Rede**: Cada abate feito pela Rede da +2% de dano de trevas ate sair da Torre (ate +200%). |
| Matriz do Vigia | Molde Vigilante | **Matriz Viva**: Um Molde novo surge sozinho a cada 8 s ao lado do inimigo mais proximo. |
| Olho da Sentinela | Sentinela Ferral | **Matilha**: Uma Sentinela extra se ergue sozinha a cada 10 s; abates das sentinelas devolvem 2 de Folego. |
| Colmeia de Luz | Enxame Luminar | **Enxame Faminto**: Cada abate do Enxame gera um enxame novo no lugar (no maximo um por segundo). |
| Juramento do Guardiao | Guardiao de Lastro | **Guardiao Imortal**: Ao ser ferida, um Guardiao surge de graca (uma vez a cada 15 s) com barreira de 20% da Vida. |
| Cajado da Primeira Colheita | Semeadura Vital | **Jardim Andante**: O Jardim acompanha a personagem enquanto dura. |
| Selo do Reparo | Circulo de Reparo | **Circulo Sagrado**: O Circulo cura 20% da Vida e adianta 3 s a recarga de todas as gemas. |
| Viga do Abrigo | Abrigo de Escora | **Abrigo Inabalavel**: Erguer o Abrigo da 2 s de invulnerabilidade e metade do dano recebido por 6 s. |
| Foice da Grande Ceifa | Ceifa Ampla | **Ceifa Giratoria**: A Ceifa corta em 360 graus em volta da personagem. |
| Pulmao de Gelo | Sopro Criogenico | **Raio Congelante**: O Sopro vira um feixe longo e fino que congela tudo em linha. |
| Prisma Absoluto | Raio Prismatico | **Prisma Dividido**: Cada lancamento do Raio sai em 3 feixes, um para cada inimigo diferente (os extras com 70%). |
| Lamina Desfiada | Fio Desintegrador | **Desintegracao**: O Fio executa inimigos comuns e elites abaixo de 30% da Vida. |
| Eixo das Tres Laminas | Laminas Orbitais | **Ciclone Perpetuo**: As Laminas nao expiram: ficam girando ate a personagem sair do andar. |
| Orbita Invernal | Satelites de Geada | **Orbita Glacial**: Os Satelites congelam (70% por 1,5 s) e, a cada 3 s em combate, pulsam gelo em volta com 100% da potencia da gema. |
| Detonador de Lastro | Mina de Lastro | **Campo Minado**: Cada Mina vem com mais duas em volta, com potencia total. |
| Semente do Estrondo | Semente Explosiva | **Semente Fertil**: Inimigo abatido pela Semente planta outra no lugar com 60% da potencia. |
| Ceu de Ferral | Chuva Ferral | **Artilharia Ferral**: A Chuva cai sozinha a cada 2 s no inimigo mais proximo. |
| Cauda do Cometa | Cometa de Vidro | **Vidro Estilhacado**: Inimigo abatido pelo Cometa estilhaca: 60% do golpe em area e lentidao de 60%. |
| Coluna da Alvorada | Pilar Sagrado | **Pilar Fixo**: O Pilar fica de pe por 8 s ferindo quem chega perto. |
| Esporangio Ancestral | Esporos | **Colonia Primordial**: Cada lancamento infecta tambem os dois inimigos mais proximos do alvo. |
| Calice do Lodo | Poca de Veneno | **Poca Viva**: A Poca de Veneno acompanha a personagem. |
| Voz do Trovao | Trovao Descendente | **Raio em Cadeia**: O Trovao salta entre ate 5 inimigos proximos. |
