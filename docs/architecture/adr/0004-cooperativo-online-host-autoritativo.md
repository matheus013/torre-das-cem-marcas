# ADR 0004 — Cooperativo online com host autoritativo

## Estado

**Aceita em 1 de outubro de 2026. Substitui a ADR 0003.**

## Contexto

O jogo permite que uma pessoa crie um mundo e até três participantes entrem pela rede. Persistência extensa, economia, crime, inventário e consequências geracionais tornam um modelo sem autoridade única vulnerável a divergência e duplicação.

## Decisão

- Usar `ENetMultiplayerPeer` sobre a API de multiplayer de alto nível da Godot.
- Adotar servidor escutante: o processo do host também controla um personagem.
- Reservar o peer `1` para a autoridade do host.
- Clientes enviam intenção de movimento, habilidade, interação e voto.
- Host valida, simula e replica snapshots e eventos confirmados.
- Estado persistente é salvo apenas pelo host, com identificadores estáveis para participantes e personagens.
- O primeiro transporte comprovado é LAN/loopback e IP direto.
- Serviços de convite, descoberta, NAT traversal ou relay ficam atrás de uma futura camada de sessão.
- Não implementar migração de host no MVP. Saída do host encerra a sessão após gravação confirmada.
- Manter a simulação desacoplada da apresentação para permitir servidor dedicado posterior sem torná-lo requisito atual.

## Frequência inicial

- Simulação física: frequência fixa da engine.
- Snapshots de movimento da prova: 20 Hz.
- Intenção de destino: canal não confiável e ordenado.
- Habilidades, inventário, loot e transições: RPC confiável.
- Valores finais dependem de teste com latência, perda e quatro participantes.

## Segurança e consistência

- O cliente nunca determina dano, loot, moeda, morte ou escrita de salvamento.
- Toda RPC valida remetente, estado da sessão, alcance, recarga e permissão.
- Dados de rede não são usados como caminho de arquivo, código ou identificador confiável sem validação.
- Logs do host registram conexão, desconexão e eventos persistentes relevantes.

## Consequências

- Solo e host compartilham o mesmo caminho autoritativo.
- O host possui vantagem mínima de latência, aceita para o formato cooperativo.
- Queda do host encerra a sessão no MVP.
- Hospedagem pública por IP pode exigir configuração de rede até existir relay ou integração de plataforma.
- Testes precisam executar múltiplos processos e simular atraso, perda, reconexão e mensagens inválidas.

## Fontes oficiais

- [Godot — multiplayer de alto nível](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)
- [Godot — SceneMultiplayer](https://docs.godotengine.org/en/stable/classes/class_scenemultiplayer.html)
- [Godot — exportação para servidor dedicado](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html)
