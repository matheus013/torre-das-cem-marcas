# Bosses e Raids

## Estado

**Sistema-base definido e implementado.** Desde a decisão 554, cada bioma tem um chefe de andar com kit de habilidades de área, fases, fúria e combinações por tamanho de grupo (documento 75). Bosses e raids possuem definicoes autorais, fases, ruptura, enrage, escalonamento e snapshots. A Camara Refeita ja e uma arena exclusiva jogavel; a execucao completa das fases autorais e o balanceamento ficam para playtest.

## Classificacao

- Classe de encontro e independente de raca, grau e afixos.
- Inimigos podem ser Comum, Elite, Boss ou Raid.
- Bosses e inimigos centrais de raid usam grau Apice e nao recebem afixos aleatorios.
- Um boss ou raid nao e automaticamente Singularidade. Singularidades continuam seguindo as regras globais e podem usar este sistema quando enfrentadas.

## Boss

- Encontro autoral para um a quatro jogadores, normalmente ligado ao fim de uma area, missao ou cadeia narrativa.
- Possui duas ou mais fases determinadas por faixas de Vida.
- Cada fase declara mecanicas, telegráfos, composicao de adds e alteracoes da arena.
- Barra de Ruptura recompensa interrupcao, controle, impacto e uso do ambiente. Ao encher, produz uma janela curta de vulnerabilidade.
- Enrage limita estrategias indefinidamente defensivas, mas nunca substitui a escalada legivel das fases.
- Vida e dano escalam moderadamente com o grupo; quantidade de ameacas e pressao espacial continuam sendo os principais ajustes.

## Raid

- Encontro maior composto por boss central, fases e objetivos de arena.
- Objetivos podem bloquear dano ao nucleo ate serem concluidos, como romper ancoras, transportar cargas, ativar mecanismos ou conter adds.
- Em grupo, tarefas podem ocorrer em paralelo. No solo, a mesma logica torna-se sequencial e reduz pressao simultanea.
- Raids aceitam de um a quatro jogadores e nao exigem composicao, personagem ou funcao fixa.
- Falha segue as regras normais de morte parcial e Queda Total; raid nao cria uma excecao sem custo para o roguelike.
- Primeira conclusao pode conceder recompensa autoral garantida. Repeticoes usam materiais, variantes e objetivos opcionais sem duplicar recompensas unicas globais.

## Estado autoritativo

O host controla:

- Vida, fase atual e transicoes;
- barra de Ruptura e tempo de atordoamento;
- progresso de objetivos e janelas de vulnerabilidade;
- cronometro de enrage e multiplicadores finais;
- conclusao, falha, loot e snapshot do encontro.

Clientes enviam intencoes e recebem eventos confirmados. Reconexao restaura fase, objetivos, Vida, Ruptura e enrage sem reiniciar o confronto.

## Conteudo inicial

### Guardiao da Camara Refeita — Boss

1. **Vigilia Incorporadora:** puxa objetos e usa varreduras marcadas.
2. **Incorporacao da Camara:** faz paredes crescerem, imita equipamento capturado e chama adds.
3. **Renovacao Forcada:** colapsa partes da arena, expulsa intrusos e regenera estruturas rapidamente.

### Cerco do Nucleo de Renovacao — Raid de teste futuro

1. **Cerco Exterior:** ondas de inimigos e feixes giratorios.
2. **Ancoras da Renovacao:** o nucleo fica protegido ate tres ancoras serem rompidas.
3. **Carga Refeita:** quatro cargas precisam ser conduzidas enquanto o grupo sofre pressao dividida.
4. **Nucleo Exposto:** colapso final, adds continuos e piso instavel.

O Cerco existe no catalogo e nas ferramentas para validar o sistema, mas nao integra os andares 1 a 4 do primeiro recorte jogavel.

## Escalada por baixas

- Comuns e elites pertencem ao mesmo contador de ameaca normal.
- A cada 25 baixas normais, a Renovacao agenda um boss. O surgimento espera nao haver outro boss ou raid ativo.
- A cada dez bosses derrotados, uma raid e agendada.
- Raid pendente tem prioridade sobre boss pendente, sem apagar o boss da fila.
- Contadores e filas pertencem ao mundo do host, integram salvamento e nao sao reiniciados ao entrar novamente na area.
- Os valores 25 e dez sao parametros de beta e devem ser revistos depois dos primeiros testes de ritmo.

## Salas especiais

- Uma sala especial fecha as entradas e contem apenas seu boss; adds autorais ainda podem ser criados pela mecanica do proprio encontro.
- O boss da sala nao usa o retorno comum de inimigos nem a fila de escalada.
- A Camara Refeita usa recarga inicial de vinte minutos de tempo do mundo apos uma conclusao.
- Estado ativo, recarga e identidade do encontro sao persistentes e autoritativos no host.
- Sair sem concluir preserva o estado do confronto conforme as regras da expedicao; derrotar inicia a recarga longa.
- No prototipo, o portal da Camara Refeita fica no Pátio das Marcas. Os inimigos do Pátio sao suspensos sem perder Vida, afixos ou posicao e retornam quando o grupo deixa a Camara.
- A porta de retorno permanece selada enquanto o Guardiao vive. Queda da expedicao cancela a tentativa sem iniciar a recarga; somente a vitoria inicia os vinte minutos.
