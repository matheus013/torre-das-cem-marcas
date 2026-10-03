# Arvores de Evolucao 1 a 100

## Estado

**Implementado no jogo (decisao 549).** Gerado a partir de `data/beta/beta_content.json` por `tools/content/build_character_trees.py`; edite o gerador e rode-o de novo em vez de editar o JSON a mao. Valores sao provisorios e pertencem ao playtest.

## Regras

- Eloa, Sena, Cira e Rui progridem do nivel 1 ao 100.
- Niveis comuns concedem cinco pontos de atributo; os niveis 10, 20 ... 100 concedem uma escolha de evolucao.
- Cada nivel de personagem soma 5 de Vida maxima.
- Cada marco oferece seis escolhas: duas de Essencia (evolucoes da Passiva Autoral), duas de Adaptacao e duas de Convergencia. Linhas nao bloqueiam umas as outras.
- Os niveis 10 e 20 mantem nomes e textos do documento 71, agora com efeitos executaveis.
- Dos niveis 30 a 90, Essencia e propria de cada personagem; Adaptacao e Convergencia vem de um catalogo geral, sem listas de classe (documento 66).
- Toda escolha do nivel 100 e uma mecanica nova; duas delas seguem os exemplos do documento 66 (excesso de Folego vira escudo; ataque automatico copia a ultima gema).
- O progresso completo concede 450 pontos e dez escolhas.

## Vocabulario de efeitos

- **Modificadores:** Vida e Folego maximos, recuperacao de Folego, potencia (global e por tag), recarga, critico, dano recebido, movimento, ataque automatico, raio, duracao, roubo de vida, cura e Folego por baixa, barreira por gema, auras para aliados a ate 180 unidades (limitadas a 30%), barreiras e curas recebidas.
- **Parametros da passiva:** limites, duracoes, potencias e gatilhos de Luz Residual, Duas Correntes, Placas Adaptativas e Oportunidade Estrutural (`PassiveRuntime.DEFAULTS`).
- **Mecanicas:** eco de gema, estilhaco ao derrotar, segundo folego, escudo de Folego, impressao no ataque automatico, salto do ataque automatico, condicao partilhada, recarga por baixa, laco de barreira, invocacao por baixa, resgate de aliado, onda ao fim do dash e acertos de aliados alimentando a passiva.

## Eloa Ferral

**Passiva — Luz Residual.**

| Nivel | Linha | Escolha | Efeito |
|---|---|---|---|
| 10 | Essencia | Malha Estavel | Permite manter quatro residuos; cada conducao individual perde um pouco de potencia. |
| 10 | Essencia | Sobretensao | Consome todos os residuos para ampliar o proximo efeito e aumenta temporariamente o custo de Folego. |
| 10 | Adaptacao | Dissipador Ferral | Descartar um residuo superaquecido recupera Folego e reduz interrupcao recebida. |
| 10 | Adaptacao | Fio de Guarda | Conduzir uma protecao por um residuo concede barreira curta no ponto final. |
| 10 | Convergencia | Circuito Partilhado | Aliados podem ativar residuos de Eloa com potencia reduzida. |
| 10 | Convergencia | No Material | Barreiras, summons e mecanismos aliados podem sustentar um residuo. |
| 20 | Essencia | Arco Recursivo | A primeira conducao de cada habilidade retorna por um segundo caminho com potencia reduzida. |
| 20 | Essencia | Constelacao Residual | Tres residuos proximos formam automaticamente um circuito que replica efeitos de area. |
| 20 | Adaptacao | Passo Luminar | Uma esquiva pode atravessar instantaneamente para um residuo visivel e o consome. |
| 20 | Adaptacao | Prisma de Emergencia | Ao sofrer dano grave com carga maxima, consome os residuos e cria uma onda protetora. |
| 20 | Convergencia | Rede Expedicionaria | Cada aliado pode carregar um no movel que participa das conducoes de Eloa. |
| 20 | Convergencia | Memoria de Circuito | Completar um circuito registra sua forma; a proxima ativacao pode repeti-la uma vez. |
| 30 | Essencia | Fio Longo | Conducoes alcancam 80 unidades a mais e causam +4. |
| 30 | Essencia | Brasa Residual | Residuos duram 2 s a mais e conduzem +3. |
| 30 | Adaptacao | Casco de Campo | +25 de Vida maxima e 5% menos dano recebido. |
| 30 | Adaptacao | Passo Treinado | +6% de movimento e +15% de recuperacao de Folego. |
| 30 | Convergencia | Presenca Firme | Aliados a ate 180 unidades recebem 5% menos dano. |
| 30 | Convergencia | Sinal de Avanco | Aliados a ate 180 unidades causam 5% mais dano com gemas. |
| 40 | Essencia | Malha Densa | Mantem um residuo adicional. |
| 40 | Essencia | Retorno Aceso | Conducoes retornam com +25% da potencia. |
| 40 | Adaptacao | Folego Fundo | +25 de Folego maximo; cada baixa devolve 4 de Folego. |
| 40 | Adaptacao | Reflexo de Corte | Recargas 6% mais rapidas. |
| 40 | Convergencia | Laco de Protecao | 30% de toda barreira recebida tambem protege aliados proximos. |
| 40 | Convergencia | Pontaria Coletiva | Acertos em inimigos lentos ou vulneraveis causam 12% a mais. |
| 50 | Essencia | Circuito Pleno | Conducoes 30% mais fortes. |
| 50 | Essencia | Sobrecarga Domada | Cada residuo consumido +6% de potencia na gema; conducao concede 6 de barreira. |
| 50 | Adaptacao | Segunda Respiracao | Abaixo de 30% de Vida, ganha 40 de barreira (uma vez a cada 30 s). |
| 50 | Adaptacao | Pele Calejada | 10% menos dano recebido e +30 de Vida maxima. |
| 50 | Convergencia | Fogo Cruzado | O ataque automatico salta para mais um inimigo com 50% do dano. |
| 50 | Convergencia | Resgate Atento | Aliado proximo abaixo de 30% de Vida recebe 35 de barreira (a cada 20 s). |
| 60 | Essencia | Constelacao Menor | Tres residuos formam circuito: +25 de dano no centro ao conduzir. |
| 60 | Essencia | Residuo Persistente | Residuos duram 3 s a mais e um residuo adicional. |
| 60 | Adaptacao | Colheita de Campo | Cada baixa cura 3 de Vida; 3% do dano causado vira Vida. |
| 60 | Adaptacao | Ritmo Constante | Ataque automatico 12% mais rapido e 10% mais forte. |
| 60 | Convergencia | Eco de Grupo | Aliados proximos +8% de dano com gemas; areas 10% maiores. |
| 60 | Convergencia | Muro Compartilhado | Aliados proximos recebem 7% menos dano; cada gema concede 4 de barreira. |
| 70 | Essencia | Arco Duplo | Conducoes retornam com +35% da potencia. |
| 70 | Essencia | Prisma Atento | Com residuos cheios, dano grave gera +25 de barreira e onda. |
| 70 | Adaptacao | Escudo de Folego | Com Folego cheio, a recuperacao excedente vira barreira (ate 40). |
| 70 | Adaptacao | Angulo Morto | +5% de chance critica e +15% de dano critico. |
| 70 | Convergencia | Marca Comum | Acertos em inimigos lentos ou vulneraveis +20%; condicoes duram 15% mais. |
| 70 | Convergencia | Fileira Unida | 45% de toda barreira recebida tambem protege aliados proximos. |
| 80 | Essencia | Corrente Ferral | Conducoes 35% mais fortes e 60 unidades mais longas. |
| 80 | Essencia | Memoria Viva | A cada segunda conducao, ela se repete por completo. |
| 80 | Adaptacao | Recarga de Batalha | Cada baixa reduz em 0,5 s todas as recargas. |
| 80 | Adaptacao | Muralha Interior | Barreiras recebidas +25%, curas +20% e +40 de Vida maxima. |
| 80 | Convergencia | Estilhaco Coletivo | Inimigos derrotados explodem: 25 de dano em raio 90. |
| 80 | Convergencia | Arsenal Aberto | Gemas de area e de projetil +12% de potencia. |
| 90 | Essencia | Malha Soberana | Mantem dois residuos adicionais. |
| 90 | Essencia | Luz Concentrada | Cada residuo consumido +10% de potencia; constelacao +30. |
| 90 | Adaptacao | Marca do Sobrevivente | Abaixo de 35% de Vida, ganha 80 de barreira (a cada 25 s); 8% menos dano. |
| 90 | Adaptacao | Impulso Final | +8% de movimento, recargas 8% mais rapidas e +5% de potencia. |
| 90 | Convergencia | Vigilia Mutua | Aliado abaixo de 35% recebe 60 de barreira (a cada 15 s); aliados proximos 5% menos dano. |
| 90 | Convergencia | Convergencia Total | Aliados proximos +10% de dano com gemas; +6% de potencia propria. |
| 100 | Essencia | Circuito Eterno | Toda conducao se repete por completo e retorna com mais 50%. |
| 100 | Essencia | Coracao de Residuo | Conduzir com tres residuos explode o circuito (+45) e concede 15 de barreira. |
| 100 | Adaptacao | Folego Transbordante | Excesso de Folego vira escudo (ate 90) e o Folego recupera 25% mais rapido. |
| 100 | Adaptacao | Impressao do Golpe | O ataque automatico copia lentidao, vulnerabilidade e roubo de vida da ultima gema e causa 20% mais dano. |
| 100 | Convergencia | Condicao Partilhada | Acertos em inimigos lentos ou vulneraveis +30%; toda gema deixa o alvo vulneravel (10%). |
| 100 | Convergencia | Eco Duplo | A cada terceira gema, ela se repete com 50% da potencia. |

## Sena Rotavela

**Passiva — Duas Correntes.**

| Nivel | Linha | Escolha | Efeito |
|---|---|---|---|
| 10 | Essencia | Plano Cumprido | Tracado decai mais devagar e fortalece a proxima acao repetida ao longo de uma rota. |
| 10 | Essencia | Mudanca de Rumo | Converte todo Tracado em Desvio e libera uma reacao sem custo em intervalo limitado. |
| 10 | Adaptacao | Passo de Emergencia | Desvio maximo torna a proxima esquiva gratuita e deixa um marco de retorno. |
| 10 | Adaptacao | Ponto Movel | Um dos extremos da rota pode acompanhar Sena, um aliado ou um summon. |
| 10 | Convergencia | Via Compartilhada | Aliados que percorrem a rota acumulam uma protecao breve e alimentam o Tracado de Sena. |
| 10 | Convergencia | Retirada Ordenada | Sair de uma zona perigosa por uma rota concede resistencia a interrupcao ao grupo. |
| 20 | Essencia | Cartografia Cinetica | Concluir uma rota pode criar o primeiro trecho da proxima, permitindo cadeias de percurso. |
| 20 | Essencia | Contrarrota | Percorrer uma rota no sentido inverso transforma o proximo impacto recebido em contra-ataque. |
| 20 | Adaptacao | Rota Impossivel | Sena pode tracar por um perigo ou obstaculo breve; a passagem desaparece depois do uso. |
| 20 | Adaptacao | Improviso Perfeito | Ao atingir Desvio maximo, a primeira acao diferente ecoa em versao reduzida. |
| 20 | Convergencia | Rede de Caravana | Permite tres marcos conectados, formando duas rotas simultaneas para o grupo. |
| 20 | Convergencia | Todos Retornam | Um aliado derrubado cria uma rota de resgate que acelera aproximacao e retirada. |
| 30 | Essencia | Traco Firme | Cada Tracado +3% de potencia. |
| 30 | Essencia | Desvio Leve | Cada Desvio -5% de Folego e +2% de movimento. |
| 30 | Adaptacao | Casco de Campo | +25 de Vida maxima e 5% menos dano recebido. |
| 30 | Adaptacao | Passo Treinado | +6% de movimento e +15% de recuperacao de Folego. |
| 30 | Convergencia | Presenca Firme | Aliados a ate 180 unidades recebem 5% menos dano. |
| 30 | Convergencia | Sinal de Avanco | Aliados a ate 180 unidades causam 5% mais dano com gemas. |
| 40 | Essencia | Rota Longa | Tracado e Desvio acumulam um ponto a mais. |
| 40 | Essencia | Contrapeso | Sofrer dano com Tracado devolve +10 de dano por ponto ao redor. |
| 40 | Adaptacao | Folego Fundo | +25 de Folego maximo; cada baixa devolve 4 de Folego. |
| 40 | Adaptacao | Reflexo de Corte | Recargas 6% mais rapidas. |
| 40 | Convergencia | Laco de Protecao | 30% de toda barreira recebida tambem protege aliados proximos. |
| 40 | Convergencia | Pontaria Coletiva | Acertos em inimigos lentos ou vulneraveis causam 12% a mais. |
| 50 | Essencia | Plano Mestre | Cada Tracado +5% de potencia e improvisar nao o reduz. |
| 50 | Essencia | Salto Improvisado | Em Desvio maximo, a acao diferente ecoa com +30% de potencia. |
| 50 | Adaptacao | Segunda Respiracao | Abaixo de 30% de Vida, ganha 40 de barreira (uma vez a cada 30 s). |
| 50 | Adaptacao | Pele Calejada | 10% menos dano recebido e +30 de Vida maxima. |
| 50 | Convergencia | Fogo Cruzado | O ataque automatico salta para mais um inimigo com 50% do dano. |
| 50 | Convergencia | Resgate Atento | Aliado proximo abaixo de 30% de Vida recebe 35 de barreira (a cada 20 s). |
| 60 | Essencia | Correnteza | Cada Desvio +4% de movimento. |
| 60 | Essencia | Guarda de Rota | Gemas com Tracado protegem aliados proximos (+6 por ponto). |
| 60 | Adaptacao | Colheita de Campo | Cada baixa cura 3 de Vida; 3% do dano causado vira Vida. |
| 60 | Adaptacao | Ritmo Constante | Ataque automatico 12% mais rapido e 10% mais forte. |
| 60 | Convergencia | Eco de Grupo | Aliados proximos +8% de dano com gemas; areas 10% maiores. |
| 60 | Convergencia | Muro Compartilhado | Aliados proximos recebem 7% menos dano; cada gema concede 4 de barreira. |
| 70 | Essencia | Rota Ampla | Um ponto a mais em cada corrente e +2% de potencia por Tracado. |
| 70 | Essencia | Desvio Perfeito | Em Desvio maximo, a proxima acao diferente e gratuita. |
| 70 | Adaptacao | Escudo de Folego | Com Folego cheio, a recuperacao excedente vira barreira (ate 40). |
| 70 | Adaptacao | Angulo Morto | +5% de chance critica e +15% de dano critico. |
| 70 | Convergencia | Marca Comum | Acertos em inimigos lentos ou vulneraveis +20%; condicoes duram 15% mais. |
| 70 | Convergencia | Fileira Unida | 45% de toda barreira recebida tambem protege aliados proximos. |
| 80 | Essencia | Contrarrota Afiada | Dano recebido com Tracado devolve +20 por ponto. |
| 80 | Essencia | Eco de Caravana | Eco do improviso +30% de potencia. |
| 80 | Adaptacao | Recarga de Batalha | Cada baixa reduz em 0,5 s todas as recargas. |
| 80 | Adaptacao | Muralha Interior | Barreiras recebidas +25%, curas +20% e +40 de Vida maxima. |
| 80 | Convergencia | Estilhaco Coletivo | Inimigos derrotados explodem: 25 de dano em raio 90. |
| 80 | Convergencia | Arsenal Aberto | Gemas de area e de projetil +12% de potencia. |
| 90 | Essencia | Mapa Completo | Cada Tracado +6% de potencia. |
| 90 | Essencia | Vento Contrario | Cada Desvio +5% de movimento; trocar de rota com Tracado alto e gratuito. |
| 90 | Adaptacao | Marca do Sobrevivente | Abaixo de 35% de Vida, ganha 80 de barreira (a cada 25 s); 8% menos dano. |
| 90 | Adaptacao | Impulso Final | +8% de movimento, recargas 8% mais rapidas e +5% de potencia. |
| 90 | Convergencia | Vigilia Mutua | Aliado abaixo de 35% recebe 60 de barreira (a cada 15 s); aliados proximos 5% menos dano. |
| 90 | Convergencia | Convergencia Total | Aliados proximos +10% de dano com gemas; +6% de potencia propria. |
| 100 | Essencia | Correntes Unidas | Improvisar tambem gera Tracado: as duas correntes deixam de se anular. |
| 100 | Essencia | Rota Absoluta | Repetir com Tracado maximo ecoa a gema com 60% da potencia. |
| 100 | Adaptacao | Folego Transbordante | Excesso de Folego vira escudo (ate 90) e o Folego recupera 25% mais rapido. |
| 100 | Adaptacao | Impressao do Golpe | O ataque automatico copia lentidao, vulnerabilidade e roubo de vida da ultima gema e causa 20% mais dano. |
| 100 | Convergencia | Condicao Partilhada | Acertos em inimigos lentos ou vulneraveis +30%; toda gema deixa o alvo vulneravel (10%). |
| 100 | Convergencia | Eco Duplo | A cada terceira gema, ela se repete com 50% da potencia. |

## Cira Salvedra

**Passiva — Placas Adaptativas.**

| Nivel | Linha | Escolha | Efeito |
|---|---|---|---|
| 10 | Essencia | Reacao em Cadeia | Descargas espalham a amostra entre alvos preparados, mas conservam parte da Instabilidade. |
| 10 | Essencia | Saturacao Escolhida | Permite manter uma amostra alem do limite seguro para fortalecer seu proximo uso. |
| 10 | Adaptacao | Placas de Abrigo | O revestimento protege tambem um aliado proximo com potencia reduzida. |
| 10 | Adaptacao | Compatibilidade Forcada | A primeira propriedade incompativel fica isolada antes de aumentar o dano recebido. |
| 10 | Convergencia | Transposicao Segura | Ao retirar uma condicao de aliado, Cira escolhe armazenar, dissipar ou preparar o agressor. |
| 10 | Convergencia | Amostra Partilhada | Um aliado pode consumir a amostra armazenada para modificar sua proxima habilidade. |
| 20 | Essencia | Catalisador Vivo | Toda Gema Ativa herda uma variacao da amostra enquanto houver Instabilidade. |
| 20 | Essencia | Ruptura Controlada | Instabilidade maxima libera uma grande reacao escolhida em vez de punir Cira imediatamente. |
| 20 | Adaptacao | Pele de Muitas Camadas | Cira pode manter duas amostras defensivas e alternar entre seus revestimentos. |
| 20 | Adaptacao | Metabolismo de Crise | Sob Vida baixa, parte do dano vira Instabilidade e pode ser descarregada para sobreviver. |
| 20 | Convergencia | Laboratorio Ambulante | Efeitos persistentes de aliados geram amostras fracas que Cira pode coletar. |
| 20 | Convergencia | Reacao Coletiva | Acertos aliados em alvo preparado propagam a propriedade uma vez por preparacao. |
| 30 | Essencia | Placa Espessa | Amostra reduz mais 5% do dano. |
| 30 | Essencia | Reacao Viva | Descarga causa +20 de dano. |
| 30 | Adaptacao | Casco de Campo | +25 de Vida maxima e 5% menos dano recebido. |
| 30 | Adaptacao | Passo Treinado | +6% de movimento e +15% de recuperacao de Folego. |
| 30 | Convergencia | Presenca Firme | Aliados a ate 180 unidades recebem 5% menos dano. |
| 30 | Convergencia | Sinal de Avanco | Aliados a ate 180 unidades causam 5% mais dano com gemas. |
| 40 | Essencia | Amostra Dupla | Armazena uma amostra adicional. |
| 40 | Essencia | Instabilidade Util | Instabilidade sobe 30% mais rapido; descarga 20 unidades maior. |
| 40 | Adaptacao | Folego Fundo | +25 de Folego maximo; cada baixa devolve 4 de Folego. |
| 40 | Adaptacao | Reflexo de Corte | Recargas 6% mais rapidas. |
| 40 | Convergencia | Laco de Protecao | 30% de toda barreira recebida tambem protege aliados proximos. |
| 40 | Convergencia | Pontaria Coletiva | Acertos em inimigos lentos ou vulneraveis causam 12% a mais. |
| 50 | Essencia | Infusao Forte | Amostra consumida +20% de potencia na gema. |
| 50 | Essencia | Revestimento Reativo | Armazenar amostra concede +10 de barreira. |
| 50 | Adaptacao | Segunda Respiracao | Abaixo de 30% de Vida, ganha 40 de barreira (uma vez a cada 30 s). |
| 50 | Adaptacao | Pele Calejada | 10% menos dano recebido e +30 de Vida maxima. |
| 50 | Convergencia | Fogo Cruzado | O ataque automatico salta para mais um inimigo com 50% do dano. |
| 50 | Convergencia | Resgate Atento | Aliado proximo abaixo de 30% de Vida recebe 35 de barreira (a cada 20 s). |
| 60 | Essencia | Crise Controlada | Abaixo de 35% de Vida, 20% do dano vira Instabilidade. |
| 60 | Essencia | Descarga Contida | Descarga conserva +30% da Instabilidade. |
| 60 | Adaptacao | Colheita de Campo | Cada baixa cura 3 de Vida; 3% do dano causado vira Vida. |
| 60 | Adaptacao | Ritmo Constante | Ataque automatico 12% mais rapido e 10% mais forte. |
| 60 | Convergencia | Eco de Grupo | Aliados proximos +8% de dano com gemas; areas 10% maiores. |
| 60 | Convergencia | Muro Compartilhado | Aliados proximos recebem 7% menos dano; cada gema concede 4 de barreira. |
| 70 | Essencia | Camadas Vivas | Uma amostra adicional e mais 5% de reducao. |
| 70 | Essencia | Catalise | Amostra consumida +25% de potencia. |
| 70 | Adaptacao | Escudo de Folego | Com Folego cheio, a recuperacao excedente vira barreira (ate 40). |
| 70 | Adaptacao | Angulo Morto | +5% de chance critica e +15% de dano critico. |
| 70 | Convergencia | Marca Comum | Acertos em inimigos lentos ou vulneraveis +20%; condicoes duram 15% mais. |
| 70 | Convergencia | Fileira Unida | 45% de toda barreira recebida tambem protege aliados proximos. |
| 80 | Essencia | Grande Reacao | Descarga 60% mais forte e 40 unidades maior. |
| 80 | Essencia | Pele de Crise | Mais 20% do dano sob Vida baixa vira Instabilidade. |
| 80 | Adaptacao | Recarga de Batalha | Cada baixa reduz em 0,5 s todas as recargas. |
| 80 | Adaptacao | Muralha Interior | Barreiras recebidas +25%, curas +20% e +40 de Vida maxima. |
| 80 | Convergencia | Estilhaco Coletivo | Inimigos derrotados explodem: 25 de dano em raio 90. |
| 80 | Convergencia | Arsenal Aberto | Gemas de area e de projetil +12% de potencia. |
| 90 | Essencia | Laboratorio Completo | Uma amostra adicional e +10 de barreira ao armazenar. |
| 90 | Essencia | Ruptura Total | Descarga causa +60. |
| 90 | Adaptacao | Marca do Sobrevivente | Abaixo de 35% de Vida, ganha 80 de barreira (a cada 25 s); 8% menos dano. |
| 90 | Adaptacao | Impulso Final | +8% de movimento, recargas 8% mais rapidas e +5% de potencia. |
| 90 | Convergencia | Vigilia Mutua | Aliado abaixo de 35% recebe 60 de barreira (a cada 15 s); aliados proximos 5% menos dano. |
| 90 | Convergencia | Convergencia Total | Aliados proximos +10% de dano com gemas; +6% de potencia propria. |
| 100 | Essencia | Forma Adaptada | Gemas aproveitam a amostra sem consumi-la. |
| 100 | Essencia | Nucleo Instavel | Com metade da Instabilidade, cada gema dispara uma descarga menor. |
| 100 | Adaptacao | Folego Transbordante | Excesso de Folego vira escudo (ate 90) e o Folego recupera 25% mais rapido. |
| 100 | Adaptacao | Impressao do Golpe | O ataque automatico copia lentidao, vulnerabilidade e roubo de vida da ultima gema e causa 20% mais dano. |
| 100 | Convergencia | Condicao Partilhada | Acertos em inimigos lentos ou vulneraveis +30%; toda gema deixa o alvo vulneravel (10%). |
| 100 | Convergencia | Eco Duplo | A cada terceira gema, ela se repete com 50% da potencia. |

## Rui Pedralva

**Passiva — Oportunidade Estrutural.**

| Nivel | Linha | Escolha | Efeito |
|---|---|---|---|
| 10 | Essencia | Obra Reutilizavel | Desmontar uma construcao intacta devolve material e uma Oportunidade. |
| 10 | Essencia | Demolicao Calculada | Destruir construcao propria gera impacto e expoe pontos fracos proximos. |
| 10 | Adaptacao | Kit Autonomo | Gasta material carregado para criar Oportunidade quando o ambiente nao oferece nenhuma. |
| 10 | Adaptacao | Escora Movel | Uma escora pode ser recolhida e reposicionada antes de sofrer dano. |
| 10 | Convergencia | Planta Partilhada | Aliados podem concluir uma construcao marcada usando acertos ou efeitos compativeis. |
| 10 | Convergencia | Ponto de Trabalho | Construcoes ativas concedem estabilidade breve a aliados que trabalham ao redor delas. |
| 20 | Essencia | Cidade Instantanea | Tres construcoes proximas combinam-se numa obra maior com funcao emergente. |
| 20 | Essencia | Colapso Dirigido | Demolir uma obra pode propagar um colapso controlado por estruturas marcadas. |
| 20 | Adaptacao | Geometria Portatil | Uma construcao leve pode ser fixada a Rui, aliado ou summon e mover-se com ele. |
| 20 | Adaptacao | Obra sem Chao | Gasta duas Oportunidades para construir temporariamente sem apoio estrutural valido. |
| 20 | Convergencia | Mutirao | Efeitos aliados que atravessam uma obra podem reparar ou transformar sua funcao. |
| 20 | Convergencia | Arquitetura Viva | Summons e campos persistentes podem funcionar como pontos estruturais das obras de Rui. |
| 30 | Essencia | Viga Extra | Uma Oportunidade adicional. |
| 30 | Essencia | Impacto Calculado | Oportunidades causam +10 de dano. |
| 30 | Adaptacao | Casco de Campo | +25 de Vida maxima e 5% menos dano recebido. |
| 30 | Adaptacao | Passo Treinado | +6% de movimento e +15% de recuperacao de Folego. |
| 30 | Convergencia | Presenca Firme | Aliados a ate 180 unidades recebem 5% menos dano. |
| 30 | Convergencia | Sinal de Avanco | Aliados a ate 180 unidades causam 5% mais dano com gemas. |
| 40 | Essencia | Canteiro Rapido | Oportunidades surgem a cada terceiro acerto. |
| 40 | Essencia | Abrigo de Obra | Oportunidades concedem +10 de barreira. |
| 40 | Adaptacao | Folego Fundo | +25 de Folego maximo; cada baixa devolve 4 de Folego. |
| 40 | Adaptacao | Reflexo de Corte | Recargas 6% mais rapidas. |
| 40 | Convergencia | Laco de Protecao | 30% de toda barreira recebida tambem protege aliados proximos. |
| 40 | Convergencia | Pontaria Coletiva | Acertos em inimigos lentos ou vulneraveis causam 12% a mais. |
| 50 | Essencia | Demolicao Fina | Oportunidades 40% mais fortes e 20 unidades maiores. |
| 50 | Essencia | Obra Duravel | Oportunidades duram 6 s a mais e devolvem 8 de Folego. |
| 50 | Adaptacao | Segunda Respiracao | Abaixo de 30% de Vida, ganha 40 de barreira (uma vez a cada 30 s). |
| 50 | Adaptacao | Pele Calejada | 10% menos dano recebido e +30 de Vida maxima. |
| 50 | Convergencia | Fogo Cruzado | O ataque automatico salta para mais um inimigo com 50% do dano. |
| 50 | Convergencia | Resgate Atento | Aliado proximo abaixo de 30% de Vida recebe 35 de barreira (a cada 20 s). |
| 60 | Essencia | Colapso em Serie | Usar uma Oportunidade abala as proximas (+40%). |
| 60 | Essencia | Cidade Rapida | Tres Oportunidades em 6 s erguem obra maior (+40 de dano). |
| 60 | Adaptacao | Colheita de Campo | Cada baixa cura 3 de Vida; 3% do dano causado vira Vida. |
| 60 | Adaptacao | Ritmo Constante | Ataque automatico 12% mais rapido e 10% mais forte. |
| 60 | Convergencia | Eco de Grupo | Aliados proximos +8% de dano com gemas; areas 10% maiores. |
| 60 | Convergencia | Muro Compartilhado | Aliados proximos recebem 7% menos dano; cada gema concede 4 de barreira. |
| 70 | Essencia | Fundacao Larga | Uma Oportunidade adicional e +20 de raio. |
| 70 | Essencia | Escora Forte | Oportunidades concedem +15 de barreira. |
| 70 | Adaptacao | Escudo de Folego | Com Folego cheio, a recuperacao excedente vira barreira (ate 40). |
| 70 | Adaptacao | Angulo Morto | +5% de chance critica e +15% de dano critico. |
| 70 | Convergencia | Marca Comum | Acertos em inimigos lentos ou vulneraveis +20%; condicoes duram 15% mais. |
| 70 | Convergencia | Fileira Unida | 45% de toda barreira recebida tambem protege aliados proximos. |
| 80 | Essencia | Grande Obra | Obra maior causa +60. |
| 80 | Essencia | Demolicao Total | Oportunidades 50% mais fortes. |
| 80 | Adaptacao | Recarga de Batalha | Cada baixa reduz em 0,5 s todas as recargas. |
| 80 | Adaptacao | Muralha Interior | Barreiras recebidas +25%, curas +20% e +40 de Vida maxima. |
| 80 | Convergencia | Estilhaco Coletivo | Inimigos derrotados explodem: 25 de dano em raio 90. |
| 80 | Convergencia | Arsenal Aberto | Gemas de area e de projetil +12% de potencia. |
| 90 | Essencia | Engenharia Plena | Duas Oportunidades adicionais. |
| 90 | Essencia | Andaime Vivo | Oportunidades devolvem +12 de Folego e +10 de barreira. |
| 90 | Adaptacao | Marca do Sobrevivente | Abaixo de 35% de Vida, ganha 80 de barreira (a cada 25 s); 8% menos dano. |
| 90 | Adaptacao | Impulso Final | +8% de movimento, recargas 8% mais rapidas e +5% de potencia. |
| 90 | Convergencia | Vigilia Mutua | Aliado abaixo de 35% recebe 60 de barreira (a cada 15 s); aliados proximos 5% menos dano. |
| 90 | Convergencia | Convergencia Total | Aliados proximos +10% de dano com gemas; +6% de potencia propria. |
| 100 | Essencia | Cidade Viva | Oportunidades surgem a cada segundo acerto e duas bastam para a obra maior. |
| 100 | Essencia | Geometria Final | Cada Oportunidade usada ergue um Molde Vigilante por 8 s. |
| 100 | Adaptacao | Folego Transbordante | Excesso de Folego vira escudo (ate 90) e o Folego recupera 25% mais rapido. |
| 100 | Adaptacao | Impressao do Golpe | O ataque automatico copia lentidao, vulnerabilidade e roubo de vida da ultima gema e causa 20% mais dano. |
| 100 | Convergencia | Condicao Partilhada | Acertos em inimigos lentos ou vulneraveis +30%; toda gema deixa o alvo vulneravel (10%). |
| 100 | Convergencia | Eco Duplo | A cada terceira gema, ela se repete com 50% da potencia. |
