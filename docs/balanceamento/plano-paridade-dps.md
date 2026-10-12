# Plano de Paridade de DPS

Data: 2026-10-12. Pedido: DPS medio proximo entre as magias de dano.
Escopo confirmado pelo responsavel: cura, protecao e mobilidade mantem seu
papel; nao precisam virar habilidades ofensivas.

Este documento define a ordem de trabalho. Nenhum multiplicador de combate
foi alterado nesta etapa. A rodada interrompida continua como referencia
historica, sem mudar o metodo enquanto ainda esta executando.

## Meta de Design

- Todas as magias de dano devem ser escolhas viaveis com investimento equivalente.
- Alvo inicial proposto: DPS medio normalizado entre 85% e 115% da referencia.
  E uma meta deste projeto, nao um padrao universal de balanceamento.
- Preservar identidade: alcance, elemento, projeteis, area, velocidade,
  invocacoes, ricochete, dano continuo e explosoes nao precisam ser iguais.
- Especialistas podem trocar dano em chefe por dano em horda, ou o inverso.
  A media nao deve esconder uma fraqueza extrema: sinalizar qualquer cenario
  abaixo de 65% da referencia ou acima de 150%, antes de aceitar a excecao.
- Controle, roubo de Vida, protecao e mobilidade sao medidos separadamente.
  Excecoes a faixa ofensiva exigem justificativa explicita; nao descontar
  dano silenciosamente so porque uma magia tambem tem utilidade.

## Ordem de Execucao

### 1. Fechar a referencia atual

- [ ] Consolidar os 50 assuntos: 46 gemas ativas e quatro autoataques.
- [ ] Preservar origem, precisao e configuracao de cada resultado.
- [ ] Separar utilitarias da comparacao ofensiva por comportamento real,
  revisando tags; nao classificar apenas pelo nome ou pela tag `damage`.

Evidencia e limitacoes: [retomada dos testes](retomada-2026-10-12.md).
Os vereditos atuais sao estimativas de arena, nao taxas de vitoria reais.

### 2. Tornar a medicao confiavel

- [ ] Corrigir a selecao de Paragon que atualmente conserva o ultimo preset,
  em vez de conservar a melhor distribuicao encontrada.
- [ ] Respeitar quantidade e faixa real de afixos por raridade. Separar
  equipamento comum de um teto teorico com todas as rolagens favoraveis.
- [ ] Reexecutar os dez estudos recuperados de logs: faltam equipamentos
  intermediarios e os valores de potencia foram arredondados.
- [ ] Acrescentar atribuicao de dano por origem na sonda: gema, invocacoes,
  efeitos continuos, autoataque, passivas de itens e efeitos dos suportes.
  Procs encadeados devem carregar a origem sem contar o mesmo dano duas vezes.
- [ ] Criar regressao para Paragon, afixos, atribuicao e dano percentual.

Medir a magia sem autoataque e sem passivas ofensivas nao relacionadas e,
depois, a build completa. Diferenca entre duas partidas com/sem magia nao
substitui atribuicao: a magia pode mudar os procs e o numero de abates.

### 3. Construir a matriz de comparacao

- [ ] Comparar primeiro gemas isoladas, sem suportes/evolucoes, com o mesmo
  orcamento de atributos e equipamento, respeitando os atributos de escala.
- [ ] Repetir com maestria e dois suportes de investimento equivalente;
  registrar separadamente a build otimizada com itens exclusivos/divinos.
- [ ] Cobrir inicio, nivel 100 e Paragon 50/100/175; repetir por personagem
  compativel para identificar influencia da arma e afinidade.
- [ ] Usar chefe unico e horda de seis inimigos com layout padronizado;
  acrescentar hordas moveis e densidades diferentes como testes de robustez.
- [ ] Medir pelo menos cinco sementes, janelas de 30 e 120 segundos e uma
  janela inicial de 5 segundos para separar explosao e dano sustentado.
- [ ] Manter custos, regeneracao, tempos de recarga e intervalos reais.
  Registrar tempo sem recursos, uptime, criticos, acertos e superdano perdido.
- [ ] Variar Vida e resistencias reais dos alvos por marco/dificuldade;
  efeitos percentuais nao podem ser calibrados apenas em bonecos de Vida enorme.
- [ ] Exercitar abates, propagacao, ricochete, preparacao e reposicionamento;
  documentar a politica do piloto para cada mecanica.

Para cada patamar, definir referencias separadas de chefe e horda a partir
da mediana corrigida das magias de dano e congelar esses valores na rodada.
Indice medio = 0,5 x (DPS chefe / referencia chefe) +
0,5 x (DPS horda / referencia horda). Nao tirar media de DPS brutos de um
alvo e de seis alvos, pois isso daria peso excessivo a area.

Publicar media, dispersao e piores casos, nao apenas o melhor resultado.
O indice e uma medida de comparacao, nao uma previsao de campanha.

### 4. Calibrar a escala global e depois cada magia

- [ ] Definir curva de poder da personagem versus Vida/dano dos inimigos
  nas cinco dificuldades. Nao transferir um deficit global para cada gema.
- [ ] Verificar como essa curva afeta dano fixo e percentual: evitar aplicar
  Ressonancia duas vezes ou multiplicar indevidamente uma fracao de Vida.
- [ ] Congelar a curva global e ajustar outliers de gemas em lotes pequenos,
  priorizando as mais fracas e mais fortes na matriz corrigida.
- [ ] Preferir ajustar coeficientes de dano antes de recarga/custo, quando
  isso preservar o ritmo. Problemas de alcance, acerto ou comportamento
  precisam de correcao mecanica, nao somente de multiplicadores maiores.
- [ ] Verificar suportes, evolucoes e itens exclusivos depois da base;
  impedir que um suporte obrigatorio seja a unica forma de tornar a gema viavel.
- [ ] Reexecutar comparacao e regressao a cada lote, com commit e relatorio
  de antes/depois. Nao calcular buffs definitivos a partir dos logs arredondados.

### 5. Validar no jogo

- [ ] Testar builds de perfuracao, controle, invocacao, dano continuo e area;
  pelo menos duas opcoes ofensivas viaveis por personagem (G3.2).
- [ ] Testar combinacoes reais de quatro gemas, autoataque e suportes, custos
  compartilhados, chefe, expedicao e retorno; arena isolada nao basta.
- [ ] Conferir controle Xbox/PlayStation e mouse, mira automatica ligada e
  desligada, solo e co-op; nao compensar um erro de mira com dano maior.
- [ ] Registrar tempo para matar/limpar, mortes, recursos e problemas de
  posicionamento; revisar se a proximidade de DPS tambem produz escolhas reais.
- [ ] Atualizar descricoes quando dano, custo, recarga ou comportamento mudar.
- [ ] Rodar suite, auditoria e compatibilidade de saves/rede antes de fechar lote.

## Criterio de Saida

Gemas de dano dentro da faixa de DPS medio nos patamares padronizados, ou
excecao explicita apoiada pelos dois cenarios e pelo playtest. Utilitarias
avaliadas por sua funcao. Nenhuma magia viavel apenas por um efeito externo
que mascara seu proprio dano. Suportes e itens sem outliers injustificados.

G8.11 permanece aberto: estas metas de paridade nao substituem as metas de
progressao/dificuldade nem os playtests previstos no roadmap de Gameplay.
