# Pacote de Conteúdo do Beta

## Estado

**Primeira proposta implementada para discussão e playtest.** Nomes, valores, pesos e quantidade podem mudar depois dos testes. O arquivo validado que alimenta o protótipo está em `data/beta/beta_content.json`.

## Escopo

O pacote cobre Aresta e os andares 1 a 4 das Galerias Refeitas. Seu objetivo é testar liberdade de build, diferenças de encontro, loot, tiers, afixos e o ciclo de retorno sem antecipar conteúdo das outras nove regiões.

## Personagens

O beta oferece Eloa Ferral, Sena Rotavela, Cira Salvedra e Rui Pedralva. Cada personagem possui uma passiva autoral e duas escolhas de marco entre seis opções nos níveis 10 e 20. O limite individual do beta é 20; os demais personagens da primeira geração e níveis posteriores permanecem fora deste pacote.

## Gemas Ativas

| Gema | Primitiva | Papel possível |
|---|---|---|
| Agulha de Lastro | projétil | alvo único, perfuração ou múltiplos projéteis |
| Passo Vetorial | deslocamento | esquiva, mobilidade ofensiva ou barreira de chegada |
| Pulso de Cicatriz | nova | área, repulsão, lentidão ou proteção por acerto |
| Prisão Gravítica | campo | controle, dano periódico ou campo móvel |
| Muralha Refeita | barreira | proteção própria, coletiva ou explosão defensiva |
| Elo Residual | corrente | múltiplos alvos, debuff ou recuperação |
| Molde Vigilante | invocação | sentinela fixa, móvel ou múltipla |
| Semeadura Vital | santuário | cura, dano territorial ou barreira por excesso |

Cada ativa possui duas escolhas em cada nível de 1 a 3. O beta implementa essas escolhas primeiro; os níveis 4 a 10 permanecem trabalho posterior, mantendo a regra de transformação mecânica no nível 10.

O Molde Vigilante referencia uma definição própria de summon: sentinela temporária, vulnerável, estacionária por padrão e limitada a duas por jogador. Evoluções podem criar uma segunda forma ou fazê-la acompanhar o proprietário.

## Gemas de Suporte

- Projéteis Gêmeos, Perfuração Refeita e Ricochete de Junta alteram quantidade e trajetória.
- Área Expandida e Foco Concentrado trocam cobertura por potência.
- Eco Atrasado repete a execução com potência reduzida.
- Fluxo Rápido troca dano por cadência.
- Duração Estendida modifica campos, barreiras e invocações.
- Drenagem Vital converte parte do dano em recuperação.
- Impulso de Impacto acrescenta deslocamento.
- Busca Residual orienta projéteis com perda de velocidade.
- Sobrecarga Instável aumenta potência em troca de recarga e Fôlego.

Compatibilidade depende de tags. O resolvedor aplica multiplicadores, adições e mudanças mecânicas em ordem determinística.

## Inimigos

- **Larva de Junta:** enxame rápido e frágil.
- **Raspador de Junta:** perseguidor que pressiona cobertura e rotas.
- **Sentinela de Cal:** tiro à distância com trajetória visível.
- **Emboscado de Reboco:** permanece oculto até a aproximação.
- **Molde de Ferramenta:** imita loot até ser despertado.
- **Escora Hostil:** concede barreira a inimigos próximos.
- **Vigia Moldado:** marca e dispara contra o alvo.
- **Guardião de Enxerto:** chefe com pulso de incorporação e sem afixos aleatórios no beta.
- **Núcleo de Renovação:** inimigo central de raid usado para validar ferramentas e arquitetura; não aparece nos andares 1 a 4.

## Boss e raid

- O Guardião da Câmara Refeita possui três fases, Ruptura e enrage e encerra o recorte dos andares 1 a 4.
- O Cerco do Núcleo de Renovação possui quatro fases e dois objetivos de raid: romper três âncoras e conduzir quatro cargas.
- A raid está no catálogo para teste futuro, mas não faz parte do primeiro percurso jogável.

## Raças de monstros

| Raça | Traço de combate |
|---|---|
| Juntídeo | causa pressão adicional contra barreiras |
| Calcário | reduz parte do dano recebido |
| Rebocado | camufla-se enquanto está distante |
| Moldado | cria uma proteção após impactos sucessivos |
| Enxertado | recupera-se próximo de efeitos persistentes |

## Graus de evolução

| Grau | Papel | Afixos aleatórios |
|---|---|---|
| Nascente | criatura jovem ou incompleta | nenhum |
| Maduro | exemplar comum plenamente formado | zero ou um |
| Evoluído | variação adaptada e perigosa | um ou dois |
| Alfa | líder local de grande pressão | exatamente dois |
| Ápice | chefe ou existência excepcional | nenhum; mecânicas autorais |

O grau também multiplica atributos e recompensa e altera o porte visual no blockout. Raça e grau são eixos independentes, permitindo que uma mesma raça apareça em diferentes estágios sem exigir uma nova definição-base.

## Afixos

Prefixos: Robusto, Veloz, Brutal, Regenerado, Blindado e Duplicado.

Sufixos: da Cicatriz, do Eco, da Fome, do Lastro, do Reboco e da Ruptura.

Além de multiplicadores, o pacote inclui regeneração, escudo de primeiro impacto, divisão ao morrer, redução de Fôlego por contato, ataque ecoado, roubo de vida, atração gravitacional, ocultação distante e explosão ao morrer.

## Itens

O pacote possui 32 definições:

- quatro instrumentos iniciais;
- dois offhands;
- um amuleto;
- oito proteções distribuídas entre armadura, luvas, botas e calça;
- seis anéis;
- três Relíquias mecânicas;
- quatro consumíveis;
- quatro materiais das Galerias.

Os itens usam tiers de Comum a Lendário. Relíquias começam em Épico e sempre declaram mudança mecânica. Valores de poder são orçamento comparativo, não dano direto nem preço final.

## Implementação

- Catálogo JSON versionado e validado automaticamente.
- IDs únicos por coleção.
- Oito primitivas executáveis de Gema Ativa.
- Composição genérica de suportes e evoluções.
- Comportamentos-base de oito inimigos do recorte e um inimigo central de raid futura.
- Definições autorais de um boss e uma raid com fases, objetivos, Ruptura e enrage.
- Cinco raças com traços próprios e cinco graus de evolução.
- Definição inicial de summon ligada ao Molde Vigilante, com propriedade, duração e limite por jogador.
- Sorteio determinístico de prefixo e sufixo pelo host dentro dos limites do grau.
- Fallback do Pátio para o catálogo beta quando não existe conteúdo exportado pela Central.

## Retorno de inimigos

No Pátio das Marcas, inimigos comuns e de elite derrotados retornam pela Renovação (decisão 518):

- intervalo de 12 segundos com variação de 3;
- distância mínima de 220 unidades da personagem e de 48 de outro inimigo;
- no máximo seis inimigos vivos e um retorno por vez;
- oito pontos de retorno fixos, escolhidos pelo mais próximo do local da derrota;
- chefes, raids e fragmentos criados por `split_on_death` não retornam.

Cada retorno sorteia novamente os afixos dentro do grau, de forma determinística pela semente do encontro.

## Pontos para discussão após playtest

- se oito Gemas Ativas oferecem variedade suficiente sem diluir identidade;
- quais suportes produzem escolhas reais e quais são apenas aumentos obrigatórios;
- frequência ideal de inimigos com um ou dois afixos;
- se anéis devem aparecer cedo ou permanecer escassos;
- quais Relíquias representam melhor o potencial de transformação de build;
- quais inimigos exigem ajustes para solo e para quatro jogadores.
