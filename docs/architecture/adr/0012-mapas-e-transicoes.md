# ADR 0012 — Mapas conectados e transições

## Estado

Aceita em 1 de outubro de 2026.

## Contexto

A exploração deve usar `Pokémon FireRed` como referência de leitura espacial: o jogador anda livremente por áreas externas, reconhece edifícios no próprio mapa e entra ou sai de locais preservando a sensação de um mundo conectado. O combate, a entrada por mouse e o cooperativo online continuam seguindo decisões próprias do projeto.

## Decisão

- A vila, regiões da Torre, interiores e locais especiais são mapas navegáveis conectados por passagens explícitas.
- Edifícios importantes aparecem no mapa exterior e possuem portas físicas, em vez de existirem apenas como opções de menu.
- Entrar em uma porta troca a área ativa; sair devolve o personagem a um ponto coerente junto à mesma entrada.
- Cada área preserva estado persistente relevante, incluindo NPCs, recipientes, provas, propriedade e consequências.
- Mapas podem ser maiores que a tela e usam câmera acompanhando o personagem.
- O controle aprovado permanece por destino do mouse, com teclado como alternativa de acessibilidade e desenvolvimento.
- No cooperativo, o host valida passagens, posição de retorno e estado da área. Participantes podem estar em áreas distintas quando a atividade não exigir reunião do grupo.
- Transições críticas de expedição podem exigir confirmação coletiva, mas portas comuns não interrompem o restante do grupo.

## MVP

A prova inicial contém uma área externa de Aresta, colisões, câmera, uma casa acessível e retorno ao exterior. Streaming, persistência completa e sincronização de áreas separadas entram nos marcos seguintes.

Durante a implementação dos sistemas, mapas e interfaces usam apenas formas geométricas e contraste funcional. Texturas, paleta definitiva, iluminação decorativa e acabamento visual serão trabalhados somente depois que o jogo estiver funcional e testável de ponta a ponta.
