# Equipamentos, Relíquias e Modificadores

## Implementação no protótipo

- O menu principal apresenta e opera os sete slots fixos, dez anéis e quatro Relíquias.
- A mesma instância é movida atomicamente entre inventário e loadout; falha de encaixe não remove nem duplica o item.
- O protótipo começa com quatro peças, duas equipadas e duas disponíveis, permitindo testar imediatamente equipar e retirar.
- Equipamentos sorteados por tabelas de inimigos tornam-se instâncias únicas no inventário além do registro de saque da expedição.
- Bônus de Vida, Fôlego, movimento, velocidade de ataque, crítico, recarga e atributos primários já participam dos valores derivados.
- Localização, definição, tier, qualidade, integridade e sequência de IDs integram o save versão 6.
- Mudanças mecânicas de armas e Relíquias ainda dependem da integração completa do pipeline de skills.

## Estado

**Definido:** o personagem possui 21 espaços de equipamento. As variações de magia usam princípios de modificadores com capacidade, contrapartidas e transformações condicionais, inspirados por Warframe e Vampire Survivors sem reproduzir seus sistemas literalmente.

## Espaços de equipamento

| Categoria | Quantidade |
|---|---:|
| Arma | 1 |
| Offhand | 1 |
| Amuleto | 1 |
| Armadura | 1 |
| Luvas | 1 |
| Botas | 1 |
| Calça | 1 |
| Anéis | 10 |
| Relíquias | 4 |
| **Total** | **21** |

Armas de duas mãos ocupam funcionalmente arma e offhand. O jogador precisa liberar o offhand antes de equipá-las.

## Funções dos espaços

### Arma

Define a forma do ataque automático, alcance-base, ritmo e propriedades físicas. Não determina classe e não bloqueia famílias de gemas sem um requisito explícito do próprio item.

### Offhand

Inclui escudos, focos, grimórios, ferramentas, catalisadores e armas secundárias. Pode priorizar defesa, recurso, utilidade ou combinação ofensiva.

### Amuleto

Afeta relações entre atributos, gemas, condições e recursos. É o espaço comum mais apropriado para conversões moderadas de build.

### Armadura, luvas, botas e calça

- armadura concentra proteção e resistência;
- luvas afetam execução, ataque automático, aplicação e interação;
- botas afetam movimento, esquiva e efeitos de percurso;
- calça afeta estabilidade, Fôlego, carga e sustentação.

Essas tendências organizam loot, mas não proíbem propriedades incomuns justificadas por material e fabricação.

### Dez anéis

- Anéis são a camada granular da build.
- Dez é a capacidade máxima, não a quantidade comum esperada durante a campanha.
- O alvo inicial é que um jogador médio mantenha aproximadamente quatro anéis equipados.
- Slots vazios são um estado normal e não aplicam penalidade.
- Preencher os dez espaços representa progressão longa, coleção dedicada ou construção excepcional.
- Cada anel normalmente oferece poucos atributos, uma condição ou uma sinergia limitada.
- Dez anéis permitem especializar vários detalhes sem transformar cada peça em um pacote enorme.
- Efeitos idênticos podem sofrer retorno decrescente, limite compartilhado ou regra de unicidade.
- Um anel não deve sozinho reescrever completamente uma magia; esse espaço pertence às Relíquias.

### Quatro Relíquias

- Relíquias são extremamente raras e sempre possuem impacto mecânico.
- Toda Relíquia possui tier Épico ou Lendário.
- Uma Relíquia que oferece apenas atributos numéricos não é válida.
- Podem mudar funcionamento de ataque automático, passiva, Gema Ativa, suporte, recurso ou condição global da build.
- Podem converter alvo, trajetória, custo, gatilho, duração ou relacionamento entre magias.
- Relíquias podem possuir incompatibilidades explícitas para impedir combinações contraditórias ou ciclos infinitos.
- Quatro Relíquias equipadas devem criar identidade de fim de jogo sem apagar atributos, gemas e equipamentos comuns.

Exemplos de efeitos possíveis:

- a última magia usada passa a orbitar o personagem com potência reduzida;
- excesso de cura cria uma entidade temporária;
- projéteis que retornam podem carregar a propriedade da gema anterior;
- uma barreira deixa de ser fixa e acompanha o destino indicado pelo mouse;
- duas condições específicas se unem numa terceira reação;
- ataque automático consome cargas para copiar parte de uma Gema Ativa.

## Suportes inspirados por mods

- Gemas de Suporte possuem custo de capacidade além do limite físico de dois encaixes.
- A capacidade da Gema Ativa cresce com seu nível.
- Aumentar o grau de um suporte pode elevar efeito e custo.
- Modificadores simples aumentam uma propriedade com contrapartida pequena.
- Modificadores corrompidos concedem benefício forte e penalidade explícita.
- Aumentos mudam ou adicionam mecânicas, em vez de apenas elevar números.
- Suportes de conjunto podem reagir entre si, mas nunca modificar recursivamente outro suporte.
- Interface mostra capacidade usada, origem de cada efeito e valores antes e depois.

O baseline técnico concede capacidade `2 + nível da Gema Ativa`; custos finais dos suportes dependem de playtest.

## Evoluções inspiradas por combinações

O nível 10 sempre transforma a Gema Ativa, mas certas alternativas podem exigir uma condição conhecida da build, como:

- categoria de suporte equipada;
- atributo mínimo efetivo;
- propriedade da arma ou offhand;
- Relíquia descoberta;
- uso recorrente de uma interação durante a progressão da gema.

A condição abre uma alternativa; nunca altera silenciosamente uma escolha já feita. Uma evolução não consome equipamento ou Relíquia, salvo quando a descrição declarar uma transformação física deliberada.

## Ordem dos modificadores

1. comportamento-base da Gema Ativa ou ataque automático;
2. escolhas dos níveis 1 a 10 da gema;
3. duas Gemas de Suporte;
4. Passiva Autoral;
5. arma e offhand;
6. amuleto, armadura, luvas, botas, calça e anéis;
7. quatro Relíquias;
8. condições temporárias do personagem e do mundo;
9. limites de segurança e resultado autoritativo.

Cada etapa produz um relatório de modificadores para interface e depuração. Conversões cíclicas, valores não finitos e gatilhos sem limite são recusados.

## Loot, propriedade e raridade

- Todo equipamento é item físico com dono, procedência, qualidade, integridade e localização.
- Todo item possui tier universal conforme `69-tiers-universais-dos-itens.md`.
- Cada peça possui identificador de instância próprio; duas peças da mesma definição continuam sendo objetos diferentes.
- Equipar e retirar move a instância entre inventário e loadout como uma transação indivisível.
- Se qualquer validação falhar, o item permanece na origem e nenhum efeito parcial é aplicado.
- Anéis podem ser comuns ou raros; quantidade de slots não significa obtenção imediata de dez peças excelentes.
- Taxa de obtenção, curva de preenchimento e orçamento de poder dos anéis serão balanceados apenas quando o ciclo funcional permitir playtests representativos.
- Relíquias aparecem em chefes, cidades da Torre, volumes históricos, terras sagradas, entidades e acontecimentos excepcionais.
- Relíquias não precisam ser Singularidades Globais, mas algumas recompensas singulares podem ocupar esse espaço.
- Roubo, banco, morte parcial, espólio e Queda Total seguem as regras gerais de propriedade.

## Referências adaptadas

- Warframe usa slots, custo de capacidade, compatibilidade e modificadores capazes de trocar benefício por penalidade.
- Vampire Survivors usa progressão e condições complementares para transformar armas em novas formas.
- Aresta preserva quatro comandos ativos, decisão autoral por nível e itens físicos persistentes.

Fontes de referência:

- [Warframe — Mods Guide](https://www.warframe.com/en/news/guide-des-mods)
- [Warframe Support — Mod Guide](https://support.warframe.com/hc/en-us/articles/200500194-Mod-Guide-Use-Fusion-Transmutation-Sale)
- [Vampire Survivors Wiki — Weapons](https://vampire-survivors.fandom.com/wiki/Weapons)
