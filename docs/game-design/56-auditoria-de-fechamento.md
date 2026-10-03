# Auditoria de Fechamento do Game Design

## Estado

**Revisão concluída em 30 de setembro de 2026. A fase continua formalmente ativa até declaração do responsável.**

Esta auditoria congela a expansão conceitual e organiza o trabalho necessário para transformar a documentação existente em um game design pronto para orientar um recorte vertical.

## Resultado da auditoria estrutural

- A documentação possui índice central e registro cronológico de decisões.
- Os documentos temáticos estão ligados pelo `README.md`.
- A numeração das decisões está contínua.
- As regras recentes de roguelike geracional foram incorporadas aos documentos centrais de conceito, fracasso, personagens, famílias e progressão.
- Regras substituídas foram identificadas como históricas em vez de permanecerem concorrendo com as decisões atuais.
- Mistérios narrativos, conteúdo de produção e bloqueadores de design passaram a ocupar categorias distintas na matriz de fechamento.

## Diagnóstico

### Fundação macroscópica

Está madura. A identidade do jogo, a vila, a Torre, as famílias, o elenco inicial, a cosmologia, o multiverso opcional, as cidades internas, o pós-jogo e a campanha da Segunda Ascensão formam um conjunto coerente.

### Sistemas centrais

Estão conceitualmente definidos e possuem regras operacionais ou baseline para o recorte: combate, progressão, carga, economia, prova, reputação, recuperação, reencarnação e sucessão geracional.

### Conteúdo

O recorte vertical possui personagens, áreas da vila, expedição, inimigos, chefe, recompensas, itens, interface e consequências. Conteúdo das regiões posteriores permanece trabalho de produção, não lacuna de fundação.

### Prontidão estimada

- Design macroscópico do jogo: aproximadamente **90%**; os 10% restantes correspondem principalmente a conteúdo produzido durante o desenvolvimento e balanceamento por teste.
- Prontidão para especificar a arquitetura de um recorte vertical: **100% em termos de game design**.
- Conteúdo integral de todas as regiões e do pós-jogo: deliberadamente incompleto e não necessário para iniciar o primeiro recorte.

Esses percentuais são indicadores editoriais, não métricas matemáticas. Não significam que 90% dos mapas, inimigos, falas ou itens do jogo final já foram produzidos.

## Principais riscos de escopo

1. **Simulação geracional ampla:** simular todos os NPCs com a mesma profundidade multiplicaria escrita, estados e testes.
2. **Cem andares artesanais:** exigir conteúdo único para cada andar antes do primeiro protótipo atrasaria a validação do ciclo principal.
3. **Multiverso global:** Singularidades e história compartilhada são identidade de pós-jogo, não requisito para validar a primeira expedição.
4. **Posse e investigação universais:** inventário de todos os NPCs, procedência e provas precisam de camadas de importância para permanecer legíveis.
5. **Dez protagonistas simultâneos:** todos pertencem ao jogo, mas o primeiro recorte deve testar um subconjunto representativo.

## Controles aprovados para o fechamento

- Usar sucessores autorais ou semiautorais selecionados, em vez de geração irrestrita de protagonistas.
- Dividir NPCs em níveis de simulação: centrais, persistentes e incidentais.
- Projetar integralmente apenas os andares necessários ao recorte vertical; os demais permanecem em estrutura temática até sua produção.
- Manter Singularidades Globais, Terras Sagradas e viagens entre universos fora do recorte vertical.
- Aplicar procedência e investigação completas apenas a pessoas, itens e casos relevantes; elementos incidentais usam estados simplificados.
- Selecionar um grupo inicial menor que represente combate, cooperação, relação familiar e retorno à vila.

## Ondas de fechamento

As cinco ondas abaixo foram concluídas nesta revisão.

### Onda 1 — Consolidação

- Dez Testemunhos e roguelike geracional consolidados.
- Decisões registradas nos documentos temáticos.
- Aresta, Torre das Cem Marcas, Marca de Ordel e Chancelaria definidos.

### Onda 2 — Recorte vertical

- Eloa, Sena, Cira e Rui selecionados; Aresta e andares 1 a 4 delimitados.
- Ciclo do recorte e decisão de custódia definidos.
- Sistemas completos, simplificados e adiados classificados.

### Onda 3 — Regras testáveis

- Kits, inimigos, chefe, progressão e escalonamento definidos.
- Economia, carga, loot, ferimentos, morte e recuperação possuem baseline.
- Interface, câmera, risco, consequência e acessibilidade definidos.

### Onda 4 — Campanha e continuidade

- Dário Venn, confronto local e finais modulares definidos.
- Queda Total, sucessores curados e continuidade da campanha definidos.
- Expedição do Último Lastro recebeu verdade causal e mistérios pessoais preservados.

### Onda 5 — Verificação final

- Índice, links e sequência de decisões validados.
- Regras concorrentes e estados editoriais centrais revisados.
- Lacunas restantes classificadas como conteúdo de produção, mistério ou expansão opcional.
- Declaração formal do responsável ainda aguardada.

## O que não bloqueia a arquitetura futura

- Mapas e encontros de todos os cem andares.
- Lista completa de NPCs de todas as gerações.
- Balanceamento final de todos os itens e personagens.
- Minicampanhas dos dezesseis Primordiais.
- Identidade de todas as Singularidades Globais.
- Respostas definitivas para mistérios preservados pela narrativa.

## Próximo marco

O game design está em **candidato a encerramento**. O próximo marco é a revisão do responsável pelo projeto e, se estiver de acordo, a declaração formal registrada no `README.md`. Até essa declaração, arquitetura técnica e implementação continuam fora de escopo.
