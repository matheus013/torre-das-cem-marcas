# ADR 0013 — Ferramentas de conteúdo orientadas a dados

## Estado

Aceita em 1 de outubro de 2026.

## Contexto

Inimigos, itens, gemas, equipamentos e variações precisam crescer sem exigir alteração manual de código para cada entrada. IDs instáveis quebrariam loot, salvamentos e replicação online.

## Decisão

- Builds de desenvolvimento possuem uma Central de Conteúdo acessível pelo menu principal.
- A primeira versão oferece editores de inimigos e itens com formulário, busca, duplicação, exclusão, validação e resumo mecânico.
- Toda definição possui ID estável composto por letras minúsculas, números e sublinhado.
- Rascunhos ficam em `user://aresta_dev_content.json`.
- Exportação explícita grava `res://data/generated/dev_content.json`, permitindo versionamento e consumo pelo jogo.
- Dados exportados usam JSON versionado; validação de domínio continua no carregador de cada sistema.
- A ferramenta aparece apenas em builds de desenvolvimento.
- O protótipo do Pátio já consome definições exportadas de inimigos para Vida, velocidade, dano, intervalo de ataque e loot, com fallback interno quando o arquivo ainda não existe.
- Modificadores de inimigos são definições independentes de prefixo ou sufixo, possuem peso e multiplicadores de atributos e são sorteados deterministicamente pelo host.
- Um inimigo comum recebe no máximo um prefixo e um sufixo; IDs e atributos resultantes integram o salvamento e a replicação.
- Definições de inimigos referenciam uma raça e um grau por IDs validados. A raça fornece um traço persistente; o grau aplica multiplicadores e limita quantos afixos podem ser sorteados.
- O editor de inimigos expõe raça e grau como seleções fechadas para impedir referências inválidas durante a autoria do pacote beta.
- A Central também possui editor de summons com comportamento, seleção de alvo, política de limite, atributos de combate, duração e limite por proprietário.
- Encontros de boss e raid possuem editor próprio para inimigo central, fases, objetivos, escalonamento, Ruptura e enrage.

## Evolução

A mesma fundação já oferece editores de Gemas Ativas e Suportes com tags, valores, evoluções e modificadores em JSON validável. Loot, encontros, NPCs e tabelas econômicas são as próximas extensões. Visualização de sprites entra somente na etapa artística.
