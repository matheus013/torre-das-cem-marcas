# Arquitetura Técnica

## Estado

Arquitetura iniciada após encerramento formal do game design em 1 de outubro de 2026.

## Objetivo atual

O Marco 1 reduz os riscos de cooperativo online, autoridade do host, entrada por mouse, combate de hordas e persistência antes da construção dos sistemas definitivos.

## Decisões

- [ADR 0001 — Engine e linguagem](adr/0001-engine-e-linguagem.md)
- [ADR 0002 — Plataforma e renderização do MVP](adr/0002-plataforma-e-renderizacao.md)
- [ADR 0003 — Cooperativo local e câmera (substituída)](adr/0003-cooperativo-local-e-camera.md)
- [ADR 0004 — Cooperativo online com host autoritativo](adr/0004-cooperativo-online-host-autoritativo.md)
- [ADR 0005 — Combate de hordas e entrada](adr/0005-combate-hordas-e-entrada.md)
- [ADR 0006 — Mente sistêmica dos NPCs](adr/0006-mente-sistemica-dos-npcs.md)
- [ADR 0007 — Gemas de habilidade](adr/0007-gemas-de-habilidade.md)
- [ADR 0008 — Evolução e atributos](adr/0008-evolucao-e-atributos.md)
- [ADR 0009 — Passivas autorais sem classes](adr/0009-passivas-autorais.md)
- [ADR 0010 — Equipamentos e modificadores](adr/0010-equipamentos-e-modificadores.md)
- [ADR 0011 — Tier universal de itens](adr/0011-tier-universal-de-itens.md)
- [ADR 0012 — Mapas conectados e transições](adr/0012-mapas-e-transicoes.md)
- [ADR 0013 — Ferramentas de conteúdo orientadas a dados](adr/0013-ferramentas-de-conteudo.md)
- [ADR 0014 — Entidades invocadas](adr/0014-entidades-invocadas.md)
- [ADR 0015 — Encontros de boss e raid](adr/0015-encontros-de-boss-e-raid.md)
- [ADR 0016 — Pipeline de arte com PixelForge](adr/0016-pipeline-de-arte-pixelforge.md)
- [ADR 0017 — Passivas, efeitos visuais e retorno de inimigos no combate](adr/0017-passivas-e-efeitos-em-combate.md)
- [ADR 0018 — Simulação do mundo e sessão online de Aresta](adr/0018-simulacao-do-mundo-e-sessao-online.md)
- [ADR 0019 — Andares, chefes, perigos e recordes da Torre](adr/0019-andares-chefes-e-recordes.md)
- [ADR 0020 — Moradores: modo padrão e modo com modelo de linguagem](adr/0020-moradores-com-modelo-de-linguagem.md)

## Prova de viabilidade

A primeira prova deve demonstrar:

1. host e até três clientes conectados por LAN ou IP direto;
2. servidor como autoridade de jogadores, hordas e habilidades;
3. movimento por botão direito e cursor;
4. ataque básico automático e quatro habilidades em `Q/W/E/R`;
5. desconexão sem divergência ou duplicação de estado;
6. execução estável no Mac M1 de desenvolvimento.

O código desta prova pode ser substituído. Sua função é revelar riscos e medir comportamento, não estabelecer abstrações definitivas.

## Laboratório de build

A interface jogável em `src/prototype/build_lab/` permite testar:

1. cem níveis, pontos de atributo e escolhas nos múltiplos de dez;
2. passiva única e atributos derivados;
3. quatro Gemas Ativas, evolução e capacidade de dois suportes;
4. sete slots fixos, dez anéis e quatro Relíquias;
5. tiers, inventário e transações de equipar ou retirar.

O laboratório usa os mesmos modelos testados pelo domínio, mas ainda trabalha com conteúdo e fórmulas provisórios.

## Interface e integração contínua

A interface escala pela menor razão da tela em relação a 1280×720 e se prende às bordas (decisão 564). `.github/workflows/tests.yml` roda `tests/run_all.sh` com Godot 4.6.3 headless no GitHub Actions (decisão 568).

## Exploração da vila

A prova em `src/prototype/village/` valida mapa maior que a tela, câmera acompanhando, colisões e entrada e saída de um interior com ponto de retorno preservado.

O mesmo fluxo agora inclui um microciclo provisório: portão físico para o Pátio das Marcas, ataque automático, quatro habilidades de teste, Vida, Fôlego, dano por contato, derrota, Pedra Regenerativa, retirada, relatório e uma mudança em Aresta. Salvamento versionado preserva área, posição, inimigos, recursos e consequência. A apresentação usa sprites provisórios gerados pelo PixelForge, iluminação 2D e ordenação por profundidade; veja a ADR 0016.

Desde a ADR 0018, as regras vivem em `WorldSimulation` (`src/gameplay/world/`), sem nós, e a cena é apenas apresentação e sessão. A mesma cena roda em solo, como host ENet de até quatro jogadores ou como cliente que envia intenções e desenha snapshots a 20 Hz. O sistema de gemas completo (troca por slot, suportes, evoluções, níveis e modificadores) executa na simulação e é editado pela aba Skills do menu do jogador. Testes: `world_simulation_test.gd`, `village_exploration_smoke_test.gd` e `village_online_smoke.sh` (host e três clientes em processos separados).

## Central de conteúdo

A cena em `src/prototype/dev_tools/` permite criar, buscar, duplicar, editar, excluir e exportar definições de inimigos e itens usando IDs estáveis. Ela é exibida somente em builds de desenvolvimento.

## Arte provisória

`art/manifest.json` descreve os assets gerados pelo PixelForge, `art/process.json` escolhe e processa as imagens brutas, e os sprites finais ficam em `assets/sprites/`.

## Retorno de inimigos

`EnemyRespawnDirector` agenda o retorno de inimigos comuns e de elite derrotados, respeitando intervalo, distância mínima dos jogadores, capacidade e snapshot. Está integrado ao Pátio e ao salvamento (ADR 0017).

## Modo dev e modo público

`src/app/boot.tscn` é a cena principal. `DevMode` (`src/core/app/dev_mode.gd`) decide o destino:

1. `--public` força o modo público e `--dev` força o modo dev (somente em builds de debug);
2. exportações release são sempre públicas;
3. a preferência local `user://aresta_settings.cfg` vale em seguida;
4. por fim, `aresta/dev_mode` no `project.godot` (padrão: ligado).

O menu dev tem o botão **Modo dev: LIGADO**, que desliga o modo e abre a tela pública; na tela pública, `F12` religa o modo dev em builds de debug. `--server` e `--client=` sempre abrem a sessão online. O `Esc` da vila volta à tela inicial do modo ativo.

## Personagens e passivas

A vila abre com a escolha entre Eloa, Sena, Cira e Rui. `PassiveRuntime` executa a Passiva Autoral escolhida no combate por eventos e pedidos de efeito (ADR 0017).

## Efeitos visuais

`VfxLayer` desenha efeitos transitórios de gemas, ataques, acertos, passivas e números de dano numa `CanvasLayer` que acompanha a câmera, sem ser escurecida pela luz ambiente, usando sprites de `assets/sprites/vfx/` quando existirem.
