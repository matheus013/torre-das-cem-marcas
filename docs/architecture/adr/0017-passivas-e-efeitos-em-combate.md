# ADR 0017 — Passivas, efeitos visuais e retorno de inimigos no combate

## Estado

Aceita em 2 de outubro de 2026. Implementa no Pátio das Marcas as ADRs 0009 (passivas autorais) e 0015/0013 (retorno de inimigos por definição estável).

## Contexto

O Pátio tinha uma única personagem sem passiva, efeitos desenhados como círculos genéricos e inimigos que não voltavam depois de derrotados. As passivas do beta, o `EnemyRespawnDirector` e a direção visual já estavam decididos, mas não participavam do jogo.

## Decisão

### Passivas

- `PassiveRuntime` (`src/gameplay/passives/passive_runtime.gd`) guarda o estado de combate da Passiva Autoral escolhida.
- A cena informa eventos: acerto em inimigo (com proximidade de obstáculo), uso de Gema Ativa, dano recebido e movimento.
- A passiva devolve multiplicadores da execução (potência e custo de Fôlego) e **pedidos** de efeito: `conduct`, `nova` e `barrier`. A cena é quem aplica dano, barreira e efeitos visuais.
- `markers()` expõe resíduos e oportunidades para desenho; `display()` alimenta o HUD.
- A escolha de personagem fica em `_character_id`, integra o salvamento e define sprite e passiva.

### Efeitos visuais

- `VfxLayer` (`src/presentation/vfx/vfx_layer.gd`) é um nó acima das entidades que desenha efeitos transitórios: trajeto com impacto, explosão, onda, corrente, imagens residuais e faíscas.
- Campos, santuários, marcadores de passiva e barreira orbital são desenhados pela própria cena, na camada do chão ou da personagem.
- Cada efeito procura o sprite em `assets/sprites/vfx/` e usa forma desenhada quando ele não existe. Efeitos nunca alteram regras.
- Limite de 96 efeitos simultâneos; o mais antigo é descartado.

### Retorno de inimigos

- A cena registra cada derrota não fragmentada no `EnemyRespawnDirector` com definição, classe de encontro e posição.
- A cada quadro na Torre, o diretor recebe a posição da personagem, os oito pontos de retorno e as posições ocupadas, e devolve pedidos de criação.
- `_create_enemy` aplica raça, grau e afixos tanto na onda inicial quanto nos retornos.
- O salvamento passou para a versão 3 e guarda a fila do diretor, a classe de encontro de cada inimigo e a personagem escolhida. Versões 1 e 2 continuam aceitas.

## Consequências

- Novas passivas exigem apenas novo ramo em `PassiveRuntime` e novos tipos de pedido quando necessário.
- No cooperativo online, os mesmos eventos e pedidos podem ser processados pelo host e replicados.
- Os números provisórios das passivas e do retorno estão nos documentos 71 e 70 e serão ajustados por playtest.
