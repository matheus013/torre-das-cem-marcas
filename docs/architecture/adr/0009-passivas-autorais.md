# ADR 0009 — Passivas autorais sem classes

## Estado

**Aceita em 1 de outubro de 2026.**

## Decisão

- Não representar classe, arquétipo ou papel no modelo de personagem.
- Permitir que todos usem o mesmo sistema de atributos, gemas, suportes e equipamentos.
- Exigir exatamente uma `SignaturePassiveDefinition` compatível para tornar um personagem jogável.
- Vincular a passiva ao identificador do personagem e impedir segunda atribuição ou transferência.
- Implementar passivas por eventos autoritativos de gameplay, como acerto, condição, deslocamento, interação e alteração de terreno.
- Fazer efeitos solicitarem mudanças aos sistemas proprietários, em vez de escrever estado arbitrário.
- Replicar cargas e sinais observáveis pelo host.

## Limites

- Uma passiva não concede acesso exclusivo a categorias de gema.
- Requisitos de atributo pertencem ao item ou gema e são iguais para todos.
- Evoluções podem modificar a passiva, mas não removê-la nem copiá-la.
- Conteúdo crítico precisa de teste com várias combinações de gemas para detectar uma build implicitamente obrigatória.

## Consequências

- Selecionar personagem continua significativo mesmo com builds livres.
- Cada nova pessoa jogável exige uma mecânica passiva própria e cobertura de eventos.
- Ferramentas devem rastrear ativação, cargas, origem e efeito para depuração de combinações.
