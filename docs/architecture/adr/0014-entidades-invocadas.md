# ADR 0014 — Entidades invocadas

## Estado

Aceita em 1 de outubro de 2026.

## Contexto

Gemas, itens, Relíquias e efeitos futuros podem criar construtos, espíritos, cópias ou criaturas aliadas. Tratar uma invocação apenas como efeito de área impediria dano recebido, movimentação, limites por jogador, persistência e replicação online consistente.

## Decisão

- Separar a definição imutável da invocação de sua instância runtime.
- Toda instância possui ID estável, definição, proprietário, equipe, posição, Vida, duração restante, temporizador de ataque e ordem de criação.
- O host é a única autoridade para criar, substituir, mover, causar dano, expirar e remover invocações.
- Definições declaram comportamento inicial (`stationary`, `follow_owner` ou `chase_target`) e regra de alvo, sem acoplar IA a uma Gema específica.
- Cada definição possui limite por proprietário e política explícita ao excedê-lo: substituir a mais antiga ou rejeitar a criação.
- Duração zero representa entidade permanente; duração positiva representa entidade temporária.
- Colisão, possibilidade de receber dano e persistência entre áreas são propriedades independentes.
- Invocações não bloqueiam movimento por padrão, preservando legibilidade no combate de hordas.
- Snapshots usam apenas dados serializáveis e IDs estáveis. Clientes nunca escolhem IDs, alvos confirmados, dano ou expiração.
- Ao sair de uma área ou desconectar, instâncias não persistentes são removidas. Companheiros persistentes futuros usarão o mesmo contrato, mas dependerão de regras próprias de salvamento e vínculo.

## Implementação inicial

- `SummonDefinition` valida os atributos estruturais.
- `SummonInstance` representa estado runtime e produz snapshots.
- `SummonRoster` registra definições, aplica limites, substitui, expira, consulta por dono e restaura snapshots.
- O catálogo beta possui a definição `molde_vigilante`, referenciada pela Gema Ativa homônima.
- O protótipo já cria formas com proprietário, equipe, Vida, comportamento e ID, mantendo a apresentação em blockout.

## Consequências

- IA, animação e navegação podem evoluir sem alterar o contrato de propriedade e rede.
- Itens e suportes podem modificar quantidade e comportamento sem duplicar entidades especiais.
- Invocações permanentes exigirão orçamento de desempenho, regras de transição e salvamento antes de serem conteúdo disponível.
