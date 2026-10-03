# ADR 0010 — Equipamentos e modificadores

## Estado

**Aceita em 1 de outubro de 2026.**

## Decisão

- Modelar sete slots singulares, dez slots de anel e quatro slots de Relíquia.
- Tratar arma de duas mãos como incompatível com offhand ocupado.
- Exigir ao menos uma mudança mecânica em toda definição de Relíquia.
- Permitir incompatibilidades declarativas entre Relíquias.
- Somar atributos por um agregador único antes de `StatResolver`.
- Resolver mudanças mecânicas em pipeline ordenado e rastreável.
- Adicionar custo de capacidade às Gemas de Suporte sem remover o limite de dois encaixes.

## Implementação inicial

- `EquipmentItemDefinition` declara slot, atributos, tags, incompatibilidades e mecânicas.
- `EquipmentItemInstance` mantém identificador único, proprietário, qualidade, integridade e procedência.
- `ItemInventory` guarda instâncias pertencentes a uma entidade sem aceitar identificador duplicado.
- `EquipmentLoadout` valida os 21 espaços, arma de duas mãos, conflitos e agregação.
- `EquipmentTransaction` move instâncias entre inventário e loadout com rollback em caso de falha.
- `EquippedActiveGem` calcula capacidade de suporte como `2 + nível` e recusa excesso.
- Instâncias persistentes, qualidade, integridade e procedência serão ligadas ao inventário depois da prova estrutural.

## Pipeline

O resolvedor futuro recebe modificadores puros e comandos mecânicos separados. Modificadores numéricos podem ser agregados; alterações de comportamento precisam de identificador, fase, prioridade e condição. O pipeline recusa ciclos, dependências ausentes e mais de uma substituição exclusiva da mesma etapa.

## Autoridade

- Host valida posse, slot, requisitos, capacidade, conflitos e resultado.
- Equipar, retirar ou trocar itens é transação atômica.
- Cliente nunca aplica efeito de Relíquia ou suporte sem confirmação.
- Salvamento usa identificadores únicos de instância para impedir duplicação.

## Consequências

- Dez anéis e quatro Relíquias criam alta combinatória e exigem testes de propriedades, não apenas casos manuais.
- A interface precisa comparar resultado final, não despejar uma lista de percentuais.
- Relíquias devem ser raras também em produção de conteúdo para preservar impacto e legibilidade.
