# ADR 0008 — Evolução e atributos

## Estado

**Aceita e revisada em 1 de outubro de 2026.**

## Decisão

- Manter Gemas Ativas em `EvolutionTrack`, com dez níveis e uma escolha por nível.
- Fazer personagens evoluírem do nível 1 ao 100.
- Conceder cinco pontos livres nos noventa níveis que não são múltiplos de 10.
- Exigir uma escolha de marco nos dez múltiplos de 10, sem conceder pontos nesses níveis.
- Aceitar somente escolhas do tipo mecânica no nível 100 do personagem e no nível 10 da gema.
- Oferecer mais opções por marco ao personagem que por nível à gema.
- Usar seis atributos primários inspirados na organização de Dofus: Vitalidade, Força, Inteligência, Agilidade, Sorte e Sabedoria.
- Calcular estatísticas derivadas por funções centralizadas, com retornos decrescentes e limites documentados.
- Fazer cada gema declarar escalas em vez de inferi-las pelo nome ou matriz mágica.

## Implementação inicial

- `EvolutionChoice` distingue buff de mecânica e carrega modificadores declarativos.
- `EvolutionTrack` valida os dez níveis, escolhas e capstone das gemas.
- `CharacterBuild` controla cem níveis, pontos livres, dez marcos, passiva e derivados provisórios.
- `StatResolver` centraliza conversão decrescente e limites de atributos derivados.
- `SkillScalingProfile` limita cada gema a três atributos de escala declarados.
- `EquippedActiveGem` reutiliza o mesmo trilho de evolução.

## Autoridade e persistência

- O host confirma experiência, subida de nível, escolha, reespecialização e valores derivados.
- Salvamento registra nível, pontos livres, seis atributos, versão da definição e identificador escolhido em cada marco.
- Mudanças de balanceamento recalculam derivados; não reescrevem silenciosamente escolhas.
- Migração inválida oferece reespecialização gratuita e explícita, sem selecionar opção automaticamente.

## Consequências

- Interface, salvamento e ferramentas podem tratar evolução de gema e personagem de forma uniforme.
- Conteúdo final exige pelo menos dez conjuntos de escolhas por gema e personagem, tornando ferramentas e validação obrigatórias.
- Números provisórios de `CharacterBuild` servem apenas ao teste estrutural; curvas finais dependem do sandbox de combate.
- Fórmulas não ficam espalhadas em gemas, itens ou personagens; todos consultam o resolvedor versionado.
