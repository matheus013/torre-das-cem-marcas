# Assets de terceiros: efeitos, sons, ícones e itens

Curadoria de 2026-10-05 a partir dos pacotes brutos em `assets/new/` (6 GB,
fora do git e marcados com `.gdignore` para o Godot não importar nem exportar).
Entram no jogo 49 animações (13 de combate, 23 de elementos e 13 folhas de 9 cores), 41 sons, 83 ícones de gema e 84 ícones de item (43 deles das armas únicas).

## O que mudou no jogo

- **Som**: antes o jogo era mudo. `CombatAudio` (`src/presentation/audio/`) toca
  efeitos posicionais no bus `Effects`, cujo volume já está nas opções. Cada som
  tem intervalo mínimo e limite de vozes; o ataque automático dispara várias
  vezes por segundo e, sem isso, vira ruído contínuo. Variações alternadas e
  pitch aleatório evitam repetição audível. Clientes co-op ouvem o mesmo, porque
  o som segue os eventos `vfx` já replicados.
- **Animações**: `VfxLayer` toca tiras de `assets/sprites/vfx/anim/` (acerto,
  crítico, explosão de gema, elo elétrico, dano sofrido, morte de inimigo e de
  chefe, queda, cura, absorção, bloqueio, saque, nível e escada aberta). Sem a
  arte, cai nos traços procedurais de antes.
- **Novos eventos da simulação**: morte de inimigo, subida de nível e abertura
  da escada emitem `play`; rótulos (BLOQUEIO, CAIU, ESTABILIZADO...) levam o
  nome do efeito que os reforça.
- **Ícones de gema**: os 76 glifos provisórios de 28 px, vários quase iguais,
  foram trocados por ícones de 64 px escolhidos pela mecânica de cada gema
  (dardo para a agulha, vórtice para a prisão gravítica, bomba para a mina...).
  O teste de cobertura falha se duas gemas compartilharem ícone.
- **Ícones de item**: `assets/sprites/items/<id>.png`, mostrados na carga, no
  armazém, nos equipamentos disponíveis e equipados e no saque do chão. Anéis
  usam o metal do tier: incomum bronze, raro prata, épico ouro.
- **Animações por elemento**: cada gema pertence a um elemento (fogo, gelo, raio,
  ácido, trevas, sagrado, natureza, terra ou arcano) em `src/presentation/vfx/skill_themes.gd`.
  O elemento escolhe o projétil animado que voa até o alvo, o impacto, a explosão
  das novas e campos, o ataque do céu dos meteoros, o raio esticado entre alvos
  da corrente e o feixe. Campos e santuários giram um círculo mágico na cor do
  elemento. Gemas físicas mantêm o visual neutro. A simulação só envia o id da
  gema em cada evento visual (replicado no co-op).
- **Folhas de 9 cores** (`sh_*`): cada folha traz a mesma animação em nove cores,
  uma por linha (laranja, magenta, ciano, verde, marrom, branco, malva, vermelho,
  violeta). `SkillThemes.row` escolhe a linha pelo elemento da gema, e gemas
  físicas usam o ciano. Papéis: círculo de conjuração em toda gema lançada, espinhos
  nas novas, corte orientado nos cones, cometa caindo durante o aviso dos meteoros,
  faíscas nos acertos fortes, redemoinho de invocação, ondulação na chegada do dash,
  flechas da Saraivada, estrelas girando nas órbitas, núcleo pulsante das minas e
  runa nos pés durante a Saraivada.
- **Interface**: clique em qualquer botão (`UiSounds`, instalado pelo boot) e
  aviso sonoro de fôlego insuficiente.

**Sem arte nos pacotes:** armaduras, luvas, botas, calças e manoplas. Esses
itens aparecem sem ícone no menu e como losango colorido no chão.
`tools/art/make_skill_icons.gd` não sobrescreve ícones existentes (só com
`--force`), então não apaga os novos.

As chaves estáticas `vfx/impact`, `vfx/needle`, `vfx/stone`, `vfx/gravity` e
`vfx/sanctuary`, usadas como marcadores no chão, continuam sem arte.

## Reconstruir ou trocar

Edite `tools/art/third_party_assets.tsv` (tipo, destino, origem e filtro
ffmpeg opcional) e rode:

```sh
sh tools/art/import_third_party.sh
godot --headless --path . --import
```

O script lê direto dos zips e rars em `assets/new` (via `bsdtar`). Ícones de
magia voltam de 512 para os 64 px nativos sem interpolação; células 32×32 são
recortadas da folha FantasyInventory; anéis são reduzidos de 512 para 32 px.
Sons perdem o silêncio final e viram mono 16-bit 44,1 kHz.
`tests/combat_audio_test.gd`, `tests/vfx_layer_test.gd` e
`tests/sprite_coverage_test.gd` validam o resultado.

## Créditos e licenças

O repositório é privado porque várias licenças proíbem redistribuir os arquivos
fora do jogo. **Não torne o repositório público com estes assets.**

| Pacote | Uso | Licença |
| --- | --- | --- |
| Super Pixel Effects Gigapack (Free Version), Will Tice / unTied Games | `vfx/anim/` | comercial OK; **crédito obrigatório**; proibido redistribuir fora do jogo e usar para treino de IA |
| TTRPG Legacy Rings e Swords, Ddant1100 | anéis e as 36 armas únicas em `items/` | comercial OK; **crédito obrigatório**; proíbe uso em projetos ligados a NFT ou "IA Picture Generator" |
| Free Pixel Fantasy Weapon Pack, domin-dev | lança e bastão em `items/` | comercial OK; crédito opcional; proibido redistribuir ou subir em repositórios públicos |
| MAGE ICONS BIG PACK, Batareya | `icons/` | sem arquivo de licença no pacote; confirmar na página da autora |
| FantasyInventory | demais `items/` | sem arquivo de licença nem autor no pacote; identificar a origem |
| Pixel Combat, Helton Yan | `assets/audio/sfx/` | sem arquivo de licença no pacote; confirmar na loja de origem |
| Pixel Art Skill Animations - Lightning, Frostwindz | raio do céu e raio entre alvos (`el_thunder_strike`, `el_lightning_link`) | comercial OK; crédito opcional; proibido redistribuir fora do jogo e treinar IA |
| Free Pixel Magic Sprite Effects, craftpix | feixe de luz e círculo mágico (`el_light_beam`, `el_magic_circle`) | comercial OK; proibido redistribuir os arquivos (craftpix.net/file-licenses) |
| Séries Acid, Dark, Holy, Wood, Fire e Earth VFX | projéteis, impactos e explosões por elemento (`el_*`) | sem arquivo de licença nem autor no pacote; identificar a origem |
| Animation Pack | gelo e energia (`el_ice_*`, `el_energy_*`) | sem arquivo de licença nem autor no pacote; identificar a origem |
| RPG Effect All Free e Effect and FX Pixel All Free | folhas de 9 cores (`sh_*`) | sem arquivo de licença nem autor no pacote; identificar a origem |

Pendente para a Steam:

- uma tela de créditos no jogo com, no mínimo, "Super Pixel Effects Gigapack -
  Will Tice / unTied Games", "TTRPG Legacy - Ddant1100" e "Pixel Combat - Helton Yan";
- confirmar as licenças ausentes acima (Batareya, FantasyInventory, Helton Yan, séries de elementos, Animation Pack, RPG Effect e Effect and FX Pixel);
- avaliar a cláusula da Ddant1100 sobre "IA Picture Generator": o jogo usa arte
  de personagens gerada por IA. A leitura provável é que a cláusula vete usar
  os anéis em geradores de imagem, não em jogos, mas vale confirmar com o autor.

Pacotes avaliados e ainda não usados: Frostwindz Starcaller, Binbun (CC0, mas
são shaders 3D, inúteis aqui) e Magic Pack 9. RPG Effect e Effect and FX Pixel
têm centenas de folhas além das 13 em uso, boas candidatas para efeitos futuros.
O sopro de fogo (Fire Effect 1) ficou de fora: a folha tem células vazias no meio
da animação.
