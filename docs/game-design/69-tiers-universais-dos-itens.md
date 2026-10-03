# Tiers Universais dos Itens

## Estado

**Definido:** todo item possui exatamente um tier ordenado.

```text
Comum < Incomum < Raro < Épico < Lendário
```

O tier acompanha a instância física e integra loot, inventário, comércio, procedência, fabricação, roubo, banco, morte e herança.

## Significado

### Comum

Item cotidiano, material frequente ou equipamento com função direta. Possui baixo orçamento de modificadores, mas pode continuar útil por combinação, custo, peso ou disponibilidade.

### Incomum

Item menos frequente com combinação melhor, propriedade especializada ou condição simples. Começa a orientar decisões de build sem redefini-las.

### Raro

Item de obtenção relevante, combinação coerente e efeito capaz de sustentar uma direção de build. Pode conter propriedade condicional forte, mas não ocupa o papel transformador das Relíquias.

### Épico

Item excepcional, ligado a conteúdo difícil, descoberta importante ou fabricação avançada. Pode alterar uma interação mecânica e é o tier mínimo de uma Relíquia.

### Lendário

Item de enorme relevância e identidade autoral. Pode transformar mecânicas, possuir história própria e exigir condição especial de obtenção, manutenção ou uso. Lendário não significa automaticamente único entre todos os universos; Singularidade é uma classificação separada.

## Tier não é poder absoluto

- Tier superior oferece maior orçamento de impacto, não vitória automática sobre toda peça inferior.
- Requisitos, peso, custo, integridade, condição e sinergia podem tornar um item de tier menor mais adequado.
- A progressão evita que tiers altos sejam apenas a mesma propriedade com percentual maior.
- Itens Épicos e Lendários priorizam novas interações, combinações e contrapartidas.
- Tier não substitui nível, qualidade artesanal, procedência, unicidade ou importância narrativa.

## Fabricação e integridade

As três dimensões aparecem separadamente:

- **Tier:** Comum, Incomum, Raro, Épico ou Lendário; mede raridade e orçamento de impacto.
- **Fabricação:** Improvisada, Regular, Refinada ou Magistral; mede execução material.
- **Integridade:** valor atual entre destruído e íntegro; mede desgaste e dano.

Uma Relíquia Épica pode estar com fabricação Regular e baixa integridade. Um anel Comum pode possuir fabricação Magistral. Reparar integridade não altera tier.

## Aplicação por categoria

- Equipamentos usam tier para orçamento de atributos, condições e mecânicas.
- Gemas usam tier para raridade da forma mágica, suportes permitidos e particularidades, sem substituir seus níveis.
- Materiais usam tier para disponibilidade e potência de fabricação.
- Consumíveis usam tier para força, raridade e complexidade do efeito.
- Provas, mapas, chaves e objetos narrativos recebem tier conforme dificuldade de obtenção e impacto material, sem revelar automaticamente sua importância secreta.
- Moeda comum pode usar tier Comum; artefatos monetários ou cunhagens especiais recebem tier próprio.

## Relíquias

- Toda Relíquia é Épica ou Lendária.
- Além do tier mínimo, precisa possuir ao menos uma mudança mecânica.
- Um item Raro com efeito interessante continua sendo anel, amuleto ou outra categoria; não pode ocupar slot de Relíquia.
- Recompensas de Singularidade podem ser Lendárias e ocupar Relíquia, mas nem toda Relíquia Lendária é singular.

## Apresentação

- Nome, ícone, moldura e som podem comunicar tier, sempre com texto ou símbolo redundante à cor.
- Comparação mostra separadamente tier, fabricação, integridade e efeitos.
- Itens desconhecidos podem ocultar propriedades, mas não falsificam silenciosamente o tier já identificado.
- Identificação incompleta pode apresentar tier estimado até análise adequada.

## Implementação no protótipo

- A fabricação é guardada por instância (`quality`) e multiplica os bônus do equipamento: Improvisada 0,85, Regular 1, Refinada 1,15 e Magistral 1,3.
- Tier do item bônus e fabricação de equipamentos sobem com a dificuldade da baixa; Relíquias só aparecem como bônus de Boss e Raid (decisão 552).
- O inventário mostra tier e fabricação de cada peça; no chão, equipamentos com fabricação diferente de Regular exibem o nome dela.

## Balanceamento posterior

Taxa de queda, distribuição por região, orçamento de propriedades, progressão de fabricação e frequência de tiers ficam para playtest com o ciclo funcional. A ordem, os cinco nomes e o tier mínimo das Relíquias já são decisões vigentes.
