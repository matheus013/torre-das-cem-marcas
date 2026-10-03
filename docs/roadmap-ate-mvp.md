# Roadmap até o MVP

## Estado

**Plano aprovado. Marco 1 em andamento: Aresta e a Torre já rodam online com host e três clientes (ADR 0018); falta medir latência real, reconexão e densidade de horda.**

Este documento organiza o caminho entre o game design aprovado e um MVP jogável. Engine e arquitetura inicial já foram escolhidas após a declaração formal de encerramento do game design.

## Definição do MVP

O MVP é a versão funcional do recorte **Renovação Antecipada**. Ele precisa provar o ciclo completo do jogo, não a escala final de cem andares.

### Experiência incluída

- jogo solo e cooperativo online para dois a quatro jogadores, com host autoritativo;
- Eloa, Sena, Cira e Rui, cada um viável em solo;
- área compacta e funcional de Aresta;
- preparação e formação da expedição;
- andares 1 a 4 das Galerias Refeitas;
- Raspador de Junta, Emboscado de Reboco, Molde de Ferramenta e Guardião de Enxerto;
- Cicatrização, rotas alternativas e uma separação cooperativa controlada;
- combate, técnicas, Fôlego, queda, estabilização e morte;
- inventário, carga, loot, equipamento, consumíveis e fabricação reduzida;
- layout de 21 equipamentos, capacidade de suportes e ao menos uma Relíquia mecânica de teste;
- progressão de personagem do nível 1 ao 10, primeiro marco de evolução e gemas do nível 1 ao 3, com estruturas validadas até seus limites;
- retirada, retorno, relatório e consequência em Aresta;
- decisão de custódia do objeto do andar 4;
- morte parcial com Testemunho de Retorno;
- Queda Total encerrando em uma vinheta da Virada;
- salvamento, carregamento, configurações e acessibilidade mínima.

### Fora do MVP

- sucessores jogáveis e simulação completa de uma nova geração;
- andares 5 a 100;
- cidades internas;
- dez personagens completos;
- Dário Venn e a traição do andar 100 em forma jogável;
- multiverso conectado em funcionamento;
- Singularidades Globais, deuses, Primordiais e Terras Sagradas;
- crime, julgamento e chantagem em profundidade total;
- romances, sucessões familiares e política regional completa;
- matchmaking público, relay próprio, servidor dedicado, migração de host e serviços globais entre mundos.

## Princípio de execução

Cada marco deve terminar em uma versão jogável. Sistemas isolados não contam como progresso de marco até participarem do ciclo real.

Prioridade:

1. risco técnico;
2. sensação de controle e combate;
3. ciclo de expedição;
4. persistência e consequência;
5. conteúdo;
6. apresentação e polimento.

## Marco 0 — Autorização e escopo travado

**Estado:** concluído em 1 de outubro de 2026. Plataforma detalhada, equipe e orçamento permanecem hipóteses explícitas até validação com o responsável.

### Objetivo

Encerrar formalmente o game design e transformar este roadmap no contrato de escopo do MVP.

### Entregas

- declaração formal de transição;
- lista P0, P1 e Fora do MVP aprovada;
- público-alvo e plataforma inicial definidos;
- composição e disponibilidade da equipe registradas;
- orçamento e restrições de prazo registrados;
- regra de mudança: qualquer inclusão exige retirar trabalho equivalente.

### Critério de saída

Nenhuma dúvida sobre o que significa “MVP pronto”.

## Marco 1 — Descoberta técnica e prova de viabilidade

### Objetivo

Escolher a fundação técnica por testes dos riscos específicos do jogo.

### Ataques prioritários

- host e três clientes entrando e saindo da sessão;
- intenção do cliente validada e simulada pelo host;
- movimento por mouse e câmera individual;
- ataque automático, `Q/W/E/R` e hordas replicadas;
- pixel art legível com quatro personagens, inimigos e efeitos simultâneos;
- salvamento de estado de mundo, personagens, inventários e decisões;
- troca segura entre solo e sessão online hospedada.

### Entregas

- comparação curta das engines candidatas;
- protótipo descartável de host-cliente com movimento e horda;
- escolha de plataforma e metas de desempenho;
- decisões técnicas registradas;
- estrutura do projeto, testes, builds e integração contínua mínimos.

### Critério de saída

Um host e três clientes conseguem mover personagens distintos, usar habilidades, enfrentar uma horda e salvar/carregar a sessão sem divergência, duplicação ou perda de identidade.

### Progresso

- [x] host autoritativo e até três clientes por IP direto no jogo principal (`WorldSimulation`, ADR 0018);
- [x] intenções do cliente validadas pelo host; snapshots a 20 Hz e eventos confiáveis;
- [x] personagens distintas por sessão, movimento por mouse e câmera individual;
- [x] ataque automático, `Q/W/E/R` com gemas resolvidas e hordas replicadas;
- [x] salvamento do host com personagens, equipamentos e gemas, verificado sem divergência por `tests/village_online_smoke.sh` (quatro processos);
- [x] troca entre solo e sessão hospedada pela tela de título e pelo menu dev;
- [x] reconexão com a mesma personagem (reserva de 60 s, verificada em processo separado);
- [x] meta de desempenho com hordas densas: até 160 inimigos abaixo de 3 ms por quadro no host e cerca de 600 kbit/s por cliente com snapshots comprimidos;
- [x] agentes jogando as quatro personagens em janelas locais (`tools/play_local_coop.sh`);
- [x] dificuldade escalando de um a quatro jogadores pela tabela do documento 58 (decisão 548);
- [x] progressão até o nível 100 com dez marcos executáveis por personagem (decisão 549) e saque físico no chão (decisão 550);
- [x] quantidade e qualidade do saque escalando com a dificuldade da baixa e do grupo (decisão 552);
- [x] cem andares em dez biomas, onze chefes com habilidades de área, patrulha, respawn acelerado e recordes por modo (decisões 553 a 559);
- [x] vila ampliada com trinta moradores, rotinas, conversa e modo padrão ou com IA (decisões 560 e 561); agente que cuida da própria build (decisão 562);
- [ ] medição com latência e perda de pacotes reais;
- [x] integração contínua mínima: `.github/workflows/tests.yml` roda `tests/run_all.sh` no GitHub Actions (decisão 568);
- [x] interface proporcional à tela (decisão 564);

## Marco 2 — Sandbox de combate

**Prova antecipada disponível:** os quatro personagens do beta são escolhíveis no Pátio com suas Passivas Autorais, HUD individual, ataque automático, quatro Gemas Ativas, efeitos visuais e retorno de inimigos. Números de dano e crítico provisório também estão ativos. Suportes, evoluções, níveis, cargas extras e estabilidade de gema participam do combate e são editados na aba Skills; atributos ativos seguem a decisão 531. As árvores de evolução do 10 ao 100 alteram o combate, o saque cai no chão e a Torre tem cem andares jogáveis com chefes por bioma. Queda e estabilização seguem o documento 58 (decisão 565) e a primeira calibragem por sonda está registrada na decisão 566.

### Objetivo

Provar que controlar cada personagem é claro e divertido antes de produzir mapas.

### Ordem recomendada

1. Sena, por testar movimento, mira, rotas e reposicionamento.
2. Eloa, por testar conexões entre alvos e leitura visual.
3. Cira, por testar condições, absorção e transformação.
4. Rui, por testar estruturas persistentes e alteração do cenário.

### Entregas

- movimento por destino, colisão, seleção automática de alvo, defesa e Fôlego;
- ataque automático, quatro slots de Gemas Ativas e dois suportes por slot;
- HUD individual e sinais de cooperação;
- alvo de treino, inimigo corpo a corpo e ameaça à distância temporários;
- queda, estabilização, morte e troca de personagem para teste (queda e estabilização ativas, decisão 565);
- escalonamento básico para um a quatro jogadores (orçamento, Vida de elite e chefe e recompensa já ativos; faltam ações de chefe por grupo).

### Critério de saída

Cada personagem vence o mesmo encontro em solo por estratégia própria, e grupos produzem combinações reconhecíveis sem composição obrigatória.

## Marco 3 — Microciclo jogável

**Prova antecipada disponível:** vila, interior, entrada do Pátio das Marcas, combate provisório, coleta, retirada e consequência visual já estão ligados em um único fluxo. Preparação, salvamento e conteúdo autoral ainda não integram essa prova.

### Objetivo

Construir a menor versão do ciclo Aresta, expedição e retorno.

### Conteúdo

- Praça do Retorno e Casa das Expedições em graybox;
- Mesa de Expedição simplificada;
- um trecho representativo do andar 1;
- Raspador de Junta e Emboscado de Reboco;
- coleta de Pedra Regenerativa e Musgo de Orientação;
- escolha entre avançar e recuar;
- relatório de retorno;
- uma melhoria simples aplicada em Aresta;
- salvamento antes e depois da expedição.

### Critério de saída

Uma pessoa que não leu os documentos consegue preparar-se, entrar, lutar, coletar, recuar, compreender o relatório e perceber uma mudança na vila.

## Marco 4 — Alpha do ciclo completo

### Objetivo

Ligar todos os sistemas obrigatórios ainda em conteúdo provisório.

### Entregas

- áreas funcionais de Aresta em graybox;
- andares 1 a 4 navegáveis;
- quatro personagens completos até nível 10, com primeiro marco funcional e capstone de nível 100 prototipada;
- quatro inimigos, incluindo o Guardião de Enxerto;
- Cicatrização funcional;
- inventário, carga, banco, partilha e procedência simplificada;
- moeda, compra, reparo, tratamento e fabricação inicial;
- relações e reputações reduzidas às instituições do recorte;
- personalidades, conhecimento limitado e decisões por utilidade para os NPCs centrais;
- morte parcial, Volta e indisponibilidade;
- decisão de custódia com consequência;
- início, conclusão e créditos provisórios do MVP.

### Critério de saída

O MVP pode ser concluído do começo ao fim em solo e com quatro jogadores, mesmo com arte e áudio provisórios.

## Marco 5 — Persistência, fracasso e replay

### Objetivo

Provar que derrota e repetição produzem história, não apenas reinício.

### Entregas

- recuperação de itens deixados na Torre;
- Testemunho de Retorno e duração da Volta;
- estados de ferimento e tratamento;
- Queda Total e vinheta navegável da Virada;
- Crônica registrando a Expedição Perdida;
- variação controlada de encontros e recursos;
- rotas e decisões que justificam segunda expedição;
- salvamentos migráveis entre versões internas do MVP.

### Critério de saída

Morte parcial, retirada e Queda Total são compreendidas antes de acontecer, não quebram o salvamento e geram resultados claramente diferentes.

## Marco 6 — Conteúdo completo do MVP

### Objetivo

Substituir lacunas e placeholders por conteúdo aprovado.

### Entregas

- mapas finais dos quatro andares;
- encontros e rotas alternativas revisados;
- diálogos essenciais de Alda, Nara e representantes dos serviços;
- arco do objeto do andar 78;
- resgate ou escolha do andar 3;
- quatro resultados de custódia;
- itens, receitas, recompensas e preços do pacote inicial;
- tutoriais contextuais integrados às situações;
- texto completo do relatório, Crônica e vinheta da Virada.

### Critério de saída

Não existe placeholder que impeça avaliar ritmo, compreensão, emoção ou consequência.

## Marco 7 — Apresentação e acessibilidade

### Objetivo

Alcançar leitura profissional sem esconder problemas de gameplay sob acabamento.

### Entregas

- pixel art final dos quatro personagens, inimigos e áreas do MVP;
- animações de combate e antecipações inimigas;
- efeitos distintos para perigo, aliado, interação e procedência;
- interface final dos fluxos essenciais;
- música e áudio de resposta essenciais;
- remapeamento, opções de clique/manter, escala de interface e legendas;
- redução de flashes, tremor e estímulos;
- símbolos redundantes às cores;
- revisão da interface individual nas resoluções suportadas.

### Critério de saída

Todas as informações críticas permanecem legíveis em solo e com quatro jogadores, incluindo para configurações de acessibilidade previstas.

## Marco 8 — Beta e balanceamento

### Objetivo

Remover bloqueios, ajustar números e provar a experiência com pessoas externas à equipe.

### Rodadas de teste

1. equipe: estabilidade e regras básicas;
2. convidados experientes: combate, builds e exploração;
3. jogadores sem contexto: compreensão do ciclo e narrativa;
4. grupos de dois, três e quatro: câmera, comunicação e escalonamento;
5. solo: viabilidade de todos os personagens;
6. acessibilidade: controles, sinais, texto e estímulos.

### Métricas de validação

- conclusão possível com cada personagem em solo;
- conclusão possível com dois, três e quatro jogadores;
- nenhuma composição obrigatória;
- expedição principal entre trinta e sessenta minutos;
- primeira conclusão total entre noventa minutos e duas horas e meia;
- jogadores entendem retirada, carga e risco antes da primeira perda grave;
- decisão de custódia produz consequência percebida na mesma sessão;
- nenhuma perda de salvamento ou bloqueio permanente de campanha;
- maioria dos testadores deseja iniciar outra expedição por estratégia ou história.

### Critério de saída

Problemas críticos e altos resolvidos, desempenho dentro da meta da plataforma e resultados de teste compatíveis com os critérios do recorte.

## Marco 9 — Candidato a MVP

**Preparação antecipada:** o jogo já separa modo dev e modo público; exportações release abrem sempre a tela pública, sem ferramentas internas.

### Objetivo

Produzir uma versão distribuível e auditável.

### Checklist de conclusão

- instalação e primeira execução funcionam em ambiente limpo;
- host, clientes e comandos são reconhecidos e recuperam-se de desconexão;
- todos os caminhos obrigatórios e de fracasso foram testados;
- salvamento, carregamento e atualização de versão foram testados;
- créditos, licenças, avisos e configurações estão presentes;
- logs e procedimento de reprodução de falhas estão disponíveis;
- nenhuma funcionalidade Fora do MVP entrou sem substituição formal de escopo;
- relatório final registra resultados, cortes e hipóteses para a próxima fase.

### Critério de saída

O MVP pode ser entregue a uma pessoa externa, jogado do início ao fim sem assistência da equipe e usado para decidir se o projeto completo deve avançar.

## Priorização de backlog

### P0 — Obrigatório

Tudo listado na definição do MVP e necessário para concluir, falhar, salvar e repetir o recorte.

### P1 — Importante, mas cortável

- variações adicionais de encontros;
- mais diálogos reativos;
- segunda melhoria de cada serviço;
- eventos de aventureiros NPC;
- mais de uma receita por combinação familiar;
- detalhes extras da Crônica;
- opções adicionais de aparência na vinheta da Virada.

### P2 — Depois do MVP

Qualquer elemento listado como Fora do MVP, além de polimento que não melhore compreensão, estabilidade ou identidade central.

## Ordem semanal de decisão

Durante a produção, cada ciclo deve responder:

1. Qual risco do marco atual ainda pode invalidar o projeto?
2. Qual versão jogável demonstra que ele foi reduzido?
3. Qual tarefa não contribui para o critério de saída e pode esperar?
4. O que foi medido em jogo, em vez de apenas discutido?
5. Alguma inclusão exige corte equivalente?

## Dependências críticas

### Estado técnico atual do combate

- números de dano normais, críticos e sofridos ativos;
- respawn seguro de comuns e elites ativo;
- atributos compostos por raca, grau e afixos ativos;
- tabelas deterministicas de multiplos drops integradas ao inventario da expedicao;
- escalada de 25 baixas para boss e dez bosses para raid integrada ao salvamento;
- Camara Refeita jogavel como sala exclusiva: portal fisico, isolamento do Guardiao, saida selada, restauracao do Pátio e cooldown persistente ativos.
- menu jogavel com abas de Inventario, Personagem e Skills ativo; carga, armazem, 21 slots, atributos, marcos e quatro gemas aparecem com estado real;
- EXP, niveis 1 a 20, barra no HUD, pontos de atributo e persistencia por personagem ativos;
- oito mecanicas-base de gema executam com evolucoes, suportes, niveis e modificadores por personagem; todos os modificadores do beta executam.
- Aresta e a Torre online para um a quatro jogadores com host autoritativo, personagens unicas, EXP compartilhada e salvamento do host;
- equipar e retirar pelos 21 slots, instancias de equipamento vindas de drops, bonus numericos e persistencia sem duplicacao ativos no jogo principal;

- Rede autoritativa, movimento e densidade de horda precedem produção extensa de arenas.
- Persistência precede economia, relações e consequências em escala.
- Ferramentas de conteúdo precedem os quatro andares finais.
- Kits funcionais precedem animação final.
- Ciclo completo em graybox precede arte ambiental final.
- Teste solo e com quatro jogadores acompanha todos os marcos, não apenas o beta.

## Planejamento de prazo

Datas só devem ser comprometidas depois do Marco 1, quando equipe, engine, plataforma, ferramentas e velocidade do primeiro protótipo forem conhecidos. Antes disso, estimativas seriam expectativa, não planejamento.

O primeiro cronograma deve usar os Marcos 2 a 4 para medir velocidade real e recalcular o restante com margem para integração, correções e produção de arte.
