# ADR 0011 — Tier universal de itens

## Estado

**Aceita em 1 de outubro de 2026.**

## Decisão

- Usar `ItemTier.Value` como enumeração compartilhada por todas as categorias de item.
- Manter ordem numérica estável: Comum, Incomum, Raro, Épico e Lendário.
- Persistir tier na instância do item.
- Separar tier de fabricação, integridade, procedência, definição e identificador.
- Exigir tier mínimo Épico para qualquer instância equipada como Relíquia.
- Não inferir unicidade, vínculo ou Singularidade apenas pelo tier.

## Migração e rede

- Tier é serializado por identificador textual ou versão explícita, nunca pela posição implícita do enum sem versão.
- Host valida requisitos de tier e orçamento de propriedades.
- Migrações não promovem ou rebaixam instâncias silenciosamente.
- Itens de conteúdo removido permanecem legíveis no salvamento e recebem tratamento explícito.

## Consequências

- Interface pode usar linguagem consistente para equipamento, gema, material e consumível.
- Geradores e tabelas de loot precisam respeitar orçamento por tier.
- Testes impedem inversão da ordem e entrada de Relíquias abaixo de Épico.
