# Personalidade e Decisão dos NPCs

## Estado

**Modelo sistêmico aprovado.** A primeira implementação usa decisão determinística por utilidade. Modelos generativos não controlam regras ou estado do mundo.

## Implementação no jogo (decisão 560)

- `VillageLife` simula onze moradores nomeados e dezenove comuns em Aresta, com trabalho, casa, pontos de encontro, ronda, rotina por período do dia, conversa com jogadores (tecla `E`) e lembranças dos feitos do quadro de expedição.
- **Modo padrão:** a Utility AI da NpcMind escolhe entre ações válidas e a fala é composta por intenção, ofício e fatos verdadeiros.
- **Modo com IA:** os moradores nomeados enviam ao modelo configurado personalidade, fatos verdadeiros e a lista fechada de ações; só ações da lista são aceitas e qualquer falha devolve a decisão ao modo padrão. A seção "Linguagem e modelos generativos" abaixo vale integralmente para tudo além de deslocamento e fala de moradores (ADR 0020).

## Objetivo

NPCs devem parecer pessoas coerentes, com interesses e limites próprios, sem conhecer automaticamente tudo que ocorreu no mundo. A mesma situação pode produzir decisões diferentes conforme personalidade, valores, necessidades, relações e memórias.

## Perfil persistente

Cada NPC relevante possui:

- **traços:** coragem, cautela, ambição, empatia, lealdade, ganância, religiosidade e impulsividade;
- **valores:** família, vila, dever, justiça, conhecimento, liberdade, poder e sobrevivência;
- **necessidades:** segurança, saúde, dinheiro, repouso, prestígio, pertencimento e proteção de pessoas próximas;
- **relações:** confiança, medo, respeito, afeto, dívida e ressentimento para cada alvo relevante;
- **memórias:** acontecimento, participantes conhecidos, impacto, idade e origem da informação;
- **objetivos:** resultados de curto, médio ou longo prazo que o NPC pretende alcançar;
- **conhecimento:** fatos, rumores, suspeitas e provas efetivamente acessíveis ao personagem.

Nem todo habitante precisa de todas as dimensões. Arquétipos oferecem valores iniciais, enquanto NPCs centrais recebem perfis autorais próprios.

## Seleção de ação

Uma situação produz ações candidatas definidas pelos sistemas do jogo. Cada ação possui pré-condições, benefícios, riscos, custo moral e pesos associados ao perfil.

```text
utilidade = base
          + traços relevantes
          + valores relevantes
          + necessidades atuais
          + relações com o alvo
          + memórias relacionadas
          + urgência
          - risco percebido
          - custo moral
```

A ação disponível com maior utilidade é escolhida. Empates usam regra estável, permitindo reproduzir erros e testar salvamentos. Aleatoriedade só pode entrar como variação pequena e baseada na semente do mundo, nunca como substituta da personalidade.

## Conhecimento limitado

- Um NPC só reage a fato conhecido, observado, contado ou inferido.
- Rumor, suspeita, testemunho e prova permanecem categorias diferentes.
- Memória registra o que o NPC acredita, que pode não corresponder à verdade do mundo.
- Informação pode ser esquecida, reinterpretada, desmentida ou reforçada.
- O host conserva a verdade do mundo separada das crenças individuais.
- Ações secretas não afetam reputação pública até existirem percepção e atribuição compatíveis.

## Três escalas de simulação

### Reação imediata

Executada diante de combate, ameaça, crime, diálogo, pedido ou oportunidade próxima. Usa poucas ações candidatas e precisa responder rapidamente.

### Rotina

Organiza trabalho, descanso, deslocamento, visitas, consumo e contatos sociais. É reavaliada em intervalos, mudanças de período ou interrupções relevantes.

### Planejamento

Escolhe objetivos como investigar alguém, proteger a família, disputar cargo, acumular dinheiro, mudar de serviço ou abandonar a vila. É atualizado em eventos e viradas de calendário, não a cada quadro.

## População e desempenho

- NPCs presentes e visíveis recebem simulação completa.
- NPCs relevantes fora da área usam atualização por eventos e intervalos maiores.
- População contextual é simulada por grupos e estatísticas até tornar-se individualmente relevante.
- Memórias possuem limite e saliência; acontecimentos importantes substituem lembranças triviais antigas.
- Decisões não visuais podem ser processadas em lotes distribuídos no tempo.

## Consequências e autonomia

- Persuasão, amizade, medo, autoridade e chantagem alteram utilidade; não assumem controle absoluto.
- Um NPC pode aceitar, negociar, recusar, mentir, denunciar, fugir ou preparar reação posterior.
- A decisão selecionada solicita efeitos aos sistemas responsáveis; a mente não cria itens, provas, dinheiro ou resultados diretamente.
- Mudanças fortes de personalidade exigem acontecimentos, passagem de tempo ou arco narrativo, evitando comportamento errático.

## Cooperativo online

- Somente o host executa decisões com consequência sistêmica.
- Clientes recebem ação escolhida, animação, fala e mudanças observáveis.
- Perfis, relações, crenças e memórias persistentes integram o salvamento do mundo do host.
- Diálogo iniciado por dois jogadores ao mesmo tempo usa prioridade, fila ou participação conjunta definida pela situação.

## Linguagem e modelos generativos

Um modelo de linguagem pode futuramente sugerir variações de fala baseadas numa decisão já tomada. Ele nunca pode:

- alterar inventário, relações, provas ou estado persistente diretamente;
- inventar conhecimento que o NPC não possui;
- decidir resultados de combate, economia, justiça ou política;
- substituir texto autoral em cenas críticas sem revisão e limites explícitos.

O MVP usa falas autorais, blocos condicionais e composição por intenção, personalidade e memória.
