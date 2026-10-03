# ADR 0006 — Mente sistêmica dos NPCs

## Estado

**Aceita em 1 de outubro de 2026.**

## Contexto

NPCs precisam gerir rotinas, reagir a crimes e relações, perseguir objetivos e preservar personalidades reconhecíveis. O sistema deve ser reproduzível, econômico e compatível com autoridade do host e salvamentos geracionais.

## Decisão

- Usar Utility AI determinística para selecionar ações disponíveis.
- Separar perfil persistente, contexto momentâneo e definição de ação.
- Representar traços, valores e necessidades em escala normalizada.
- Representar relações por alvo e dimensão.
- Armazenar memórias limitadas com etiqueta, alvo, impacto e idade.
- Exigir fatos conhecidos como pré-condição para ações dependentes de informação.
- Usar desempate estável pelo identificador da ação.
- Fazer a ação escolhida chamar o sistema proprietário do efeito, sem alterar diretamente estado externo.
- Executar decisões autoritativas apenas no host.

## Implementação inicial

- `NpcMind` mantém perfil, relações e memórias e calcula utilidade.
- `NpcDecisionContext` contém alvo, urgência e fatos conhecidos na situação.
- `NpcDecisionOption` declara disponibilidade, pesos, risco e custo moral.
- A primeira prova limita cada mente a 32 memórias; o número final depende de perfil de desempenho e importância narrativa.

## Atualização por nível de detalhe

- NPC em cena: reação conforme evento e atualização curta de rotina.
- NPC relevante fora da cena: processamento por eventos e pulsos espaçados.
- População contextual: agregados econômicos e sociais, sem uma mente completa por habitante.
- Promoção para NPC individual cria perfil consistente a partir do agregado e da semente do mundo.

## Determinismo

- Mesmos dados e contexto produzem a mesma escolha.
- Variação aleatória futura usa gerador e semente pertencentes ao estado autoritativo.
- Versão da fórmula e dos dados acompanha o salvamento para permitir migração.
- Ferramentas de depuração devem exibir ações candidatas, pontuação e fatores principais.

## Modelos de linguagem

**Atualizado pela ADR 0020:** no modo com IA, um modelo pode escolher deslocamento e fala de moradores entre ações já validadas pelo jogo; o restante desta seção continua valendo.

Modelos generativos ficam fora da tomada de decisão e da verdade do mundo. Uma integração posterior pode gerar variações de apresentação a partir de intenção e fatos já validados, com fallback autoral e sem acesso de escrita ao estado persistente.

## Consequências

- Designers podem explicar por que um NPC tomou uma decisão.
- Personalidades emergem de dados compartilháveis sem exigir uma árvore exclusiva para cada habitante.
- A qualidade depende de bons candidatos, pesos e memória; playtests precisam detectar oscilações e escolhas formalmente válidas, mas absurdas.
- Conteúdo crítico continua podendo impor ações autorais quando a narrativa exigir, registrando a exceção explicitamente.
