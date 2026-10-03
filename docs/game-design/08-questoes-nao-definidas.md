# Matriz de Fechamento do Game Design

Este arquivo separa lacunas reais, conteúdo de produção, mistérios intencionais e expansões opcionais. Durante a revisão de fechamento, nenhuma nova frente de design deve ser aberta sem resolver ou reclassificar uma existente.

## Bloqueadores resolvidos

### Roguelike geracional

- Reencarnação, Queda Total, Virada, sucessores, herança, três camadas de NPCs e exceção do andar 100 estão definidos em `55-roguelike-geracional-e-reencarnacao.md`.

### Recorte vertical jogável

- Elenco, áreas de Aresta, andares 1 a 4, chefe, retorno, níveis de entrega e critérios estão definidos em `57-recorte-vertical.md`.

### Combate e progressão

- Kits dos quatro personagens estão definidos em `59-kits-iniciais-do-recorte.md`.
- Progressão, escalonamento, ferimentos, morte e recuperação possuem baseline em `58-parametros-iniciais-do-recorte.md`.
- Inimigos e Guardião de Enxerto estão definidos em `57-recorte-vertical.md`.

### Economia, itens e posse

- Moeda, preços, carga e custos seguem `58-parametros-iniciais-do-recorte.md`.
- Equipamentos, materiais, módulos, receitas e loot seguem `61-conteudo-inicial-de-itens.md`.
- Banco, armazenamento e herança seguem `20-inventario-carga-e-partilha.md`, `21-economia-pessoal-e-fundos.md` e `55-roguelike-geracional-e-reencarnacao.md`.

### Campanha principal

- Dário Venn, confronto local e finais modulares estão definidos em `38-traicao-do-andar-100-e-segunda-ascensao.md`.
- Continuidade entre gerações está definida em `55-roguelike-geracional-e-reencarnacao.md`.
- A verdade funcional da Expedição do Último Lastro está definida em `60-expedicao-do-ultimo-lastro.md`.

### Experiência e apresentação

- Fluxos, linguagem geracional, comunicação sistêmica, câmera e acessibilidade estão definidos em `62-experiencia-interface-e-camera.md`.

## Propostas consolidadas

- Conteúdo, autoria, localização e efeitos dos Dez Testemunhos foram consolidados em `52-dez-volumes-da-historia-velada.md`.
- Testemunho de Retorno, sucessores, herança e simulação geracional foram consolidados em `55-roguelike-geracional-e-reencarnacao.md`.

Não há proposta completa aguardando consolidação nesta revisão.

## Mistérios intencionais

Os itens abaixo não são lacunas de produção. Permanecer sem resposta faz parte da narrativa.

- Identidade, forma, esconderijo e objetivo final da Singularidade sacrificial original.
- Destino definitivo de Ilyra e de Avena.
- Natureza completa do Branco Estéril.
- Conteúdo das memórias perdidas de Mavra.
- Núcleo verdadeiro do Palimpsesto Vivo.
- Identidade da pessoa ausente ligada ao Portão Fechado.
- Versões públicas contraditórias sobre expedições perdidas.
- Existência de outros Herdeiros Divinos, Descendentes Puros e dragões ocultos além dos casos centrais.

Um mistério só deixa esta seção quando a campanha exigir uma resposta jogável.

## Conteúdo de produção

Estes itens precisam existir no jogo final, mas não precisam ser enumerados integralmente antes da arquitetura técnica.

- NPCs familiares além das lideranças centrais.
- Aparências finais, falas, vínculos e progressões completas dos dez personagens da primeira geração.
- Relações detalhadas entre todas as famílias secundárias.
- Inimigos, encontros, mapas, chefes e andares especiais das dez regiões.
- Missões, habitantes, lojas e recompensas completas das cinco cidades internas.
- Listas extensas de equipamentos, receitas, materiais, módulos, acessórios e loot.
- Variações de nomes, povos, itens e ambientação entre universos.
- Valores finais de balanceamento após testes.

## Pós-jogo e expansões opcionais

- Terras Sagradas e minicampanhas dos quinze Primordiais além de Edrava.
- Herdeiros Divinos adicionais e consequências de eras futuras.
- Descendentes Puros adicionais, genealogias dracônicas e ovos.
- Domínios Divinos exploráveis em escala ampla.
- Quantidade final de Singularidades Globais.
- Regiões adicionais do vazio entre universos.
- Novas rupturas, Confluências e campanhas multiversais.

Esses itens não podem bloquear o primeiro desenvolvimento jogável.

## Nomes editoriais consolidados

- A vila chama-se **Aresta**.
- A masmorra é oficialmente a **Torre das Cem Marcas** e localmente apenas a **Torre**.
- A região exterior é a **Marca de Ordel**.
- A autoridade exterior é a **Chancelaria da Marca**, dirigida por um Chanceler de mandato limitado.
- Documentos usam **reencarnação**, **Queda Total** e **Passagem de Geração**; habitantes costumam dizer **Volta**, **Queda** e **Virada**.

Os nomes próprios de ocupantes futuros dos cargos pertencem ao conteúdo de cada geração.

## Parâmetros de balanceamento

Os números abaixo possuem baseline em `58-parametros-iniciais-do-recorte.md` e exigem ajuste posterior por teste:

- Vida, dano, defesa, cura e quantidade de inimigos.
- Ritmo de experiência e limites de progressão.
- Capacidade de carga e penalidades.
- Preços, juros, salários, multas e recompensas.
- Recuperação de ferimentos e duração da reencarnação.
- Ganhos e perdas de reputação, relação e influência.
- Escalonamento para um a quatro jogadores.

O game design deve registrar faixas e intenções; o balanceamento final pertence à produção e aos testes.

## Fora de escopo nesta fase

- Engine.
- Arquitetura de software.
- Rede e persistência técnica.
- Banco de dados.
- APIs e infraestrutura.
- Classes, componentes ou estrutura de código.
- Implementação de qualquer tipo.

## Critério de encerramento

A fase de game design pode ser encerrada quando:

1. Todos os bloqueadores desta matriz estiverem definidos ou explicitamente adiados.
2. As propostas completas estiverem consolidadas nos documentos temáticos e no registro de decisões.
3. O recorte vertical tiver começo, ciclo de jogo, conclusão e critérios de validação claros.
4. Mistérios intencionais e conteúdo de produção estiverem corretamente classificados.
5. Não houver contradições vigentes entre documentos.
6. O responsável pelo projeto declarar a frase formal de transição registrada no `README.md`.
