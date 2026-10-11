class_name WorldSimulation
extends RefCounted

## Mundo autoritativo de Aresta para um a quatro jogadores (ADR 0004 e 0018).
## Recebe intenções por jogador, simula vila, Pátio e Câmara Refeita e devolve
## eventos de apresentação e snapshots. Não conhece nós, câmera, rede nem entrada.

const SkillResolverScript := preload("res://src/gameplay/skills/skill_effect_resolver.gd")
const BetaCharacterFactoryScript := preload("res://src/gameplay/progression/beta_character_factory.gd")
const BetaItemFactoryScript := preload("res://src/gameplay/content/beta_item_factory.gd")
const EnemyRespawnDirectorScript := preload("res://src/gameplay/encounters/enemy_respawn_director.gd")
const ThreatEscalationDirectorScript := preload("res://src/gameplay/encounters/threat_escalation_director.gd")
const EnemyLootResolverScript := preload("res://src/gameplay/loot/enemy_loot_resolver.gd")
const TowerContentScript := preload("res://src/gameplay/world/tower_content.gd")
const FloorLayoutScript := preload("res://src/gameplay/world/floor_layout.gd")
const TelegraphScript := preload("res://src/gameplay/encounters/telegraph.gd")
const VillageLifeScript := preload("res://src/simulation/npc/village_life.gd")
const PassiveRuntimeScript := preload("res://src/gameplay/passives/passive_runtime.gd")
const LayoutScript := preload("res://src/gameplay/world/world_layout.gd")
const MilestoneEffectsScript := preload("res://src/gameplay/progression/milestone_effects.gd")
const SkillGeometryScript := preload("res://src/gameplay/skills/skill_geometry.gd")
const LootDifficultyScript := preload("res://src/gameplay/loot/loot_difficulty.gd")
const ItemPassivesScript := preload("res://src/gameplay/items/item_passives.gd")
const ItemAffixesScript := preload("res://src/gameplay/items/item_affixes.gd")

const MAX_PLAYERS := 4
const PLAYER_RADIUS := 14.0
const PLAYER_SPEED := 230.0
const AUTO_ATTACK_RANGE := 175.0
const AUTO_ATTACK_DAMAGE := 20.0
const AUTO_ATTACK_INTERVAL := 0.65
const PLAYER_MAX_HEALTH := 100.0
const PLAYER_MAX_BREATH := 100.0
const CRIT_CHANCE := 0.12
## Prata de Ordel (documento 58): bolsa inicial e preço de venda de equipamento por raridade,
## multiplicado pela fabricação. Filtro e autovenda usam a ordem das raridades.
const STARTING_SILVER := 120
const SELL_PRICES := {"common": 8, "uncommon": 20, "rare": 45, "epic": 90, "legendary": 180}
## Loja de equipamentos da Forja (decisão 594): estoque renovado a cada volta da Torre, até épico,
## melhor quanto mais fundo o grupo já foi; compra custa SHOP_MARKUP vezes o preço de venda.
const SHOP_NPC := "dalia_ferral"
const SHOP_SIZE := 8
const SHOP_MARKUP := 5
const SHOP_REROLL_PRICE := 25
const TIER_ORDER: Array[String] = ["common", "uncommon", "rare", "epic", "legendary"]
## Elementos alternados da Saraivada de Flechas, uma rajada de cada.
const VOLLEY_ELEMENTS := [
	{"id": "fire", "power_multiplier": 1.3},
	{"id": "ice", "slow": 0.3, "slow_duration": 1.5},
	{"id": "lightning", "vulnerable": 0.1, "vulnerable_duration": 2.0},
]
## Chance de arma única por baixa, sempre de uma gema que quem abateu está usando.
## Armas únicas são lendárias e decisivas (decisão 580): raras de verdade (decisão 585). Antes
## 1%/5%/100% faziam cair mais lendários que raros (1 a 2 por 100 abates).
const UNIQUE_WEAPON_CHANCE := {"common": 0.0005, "elite": 0.005, "boss": 0.1, "raid": 0.25}
## Gema de chefe (decisão 585): cada vitória dá uma gema do conjunto ou nenhuma; depois de uma
## vitória sem gema, a próxima garante uma.
const BOSS_GEM_CHANCE := 0.5
## Venenos (decisão 586): cada inimigo carrega um veneno de cada tipo. Esporo cresce a cada tick e
## se espalha quando o alvo morre; toxina vem da poça, escala com Inteligência e some logo depois
## que o inimigo sai dela. Dano de veneno não critica e não dispara passivas de acerto.
const POISON_TYPES := {
	"esporo": {"name": "Esporos", "color": "b4f05a"},
	"toxina": {"name": "Toxina", "color": "8fe05a"},
}
const SPORE_SPREAD_LIMIT := 12
## Ataque normal no clique: o pedido vale por este tempo (segurar o botão renova).
const ATTACK_REQUEST_WINDOW := 0.25
## Colônia de esporos (decisão 591): o tick é (base fixa + fração da Vida máxima do alvo) × acúmulo.
## A fração acompanha qualquer escala de Vida (andar, dificuldade); o acúmulo cresce a cada tick até
## um teto (Sabedoria o amplia); a Cepa guarda o maior acúmulo do andar e infecções novas herdam
## metade; cada salto ao espalhar muta +10%.
const SPORE_HEALTH_SHARE := {"common": 0.005, "elite": 0.0025, "boss": 0.0005}
const SPORE_STACK_CAP := 25.0
const SPORE_STRAIN_INHERIT := 0.5
const SPORE_MUTATION := 0.10
## Tetos de redução de recarga (60%) e de área (+100%): acima disso as gemas viram spam contínuo.
const COOLDOWN_RECOVERY_CAP := 2.5
const AREA_MULTIPLIER_CAP := 2.0
## Campos de tamanho de efeito que a Área amplia; alcance é distância, não área, e fica de fora.
const AREA_KEYS: Array[String] = ["radius", "impact_area", "collision_radius", "width", "arrival_area"]
const CRIT_MULTIPLIER := 1.75
const SAVE_VERSION := 13
const NarrativeProgress := preload("res://src/gameplay/world/narrative_progress.gd")
const CONTENT_PATH := "res://data/generated/dev_content.json"
const BETA_PATH := "res://data/beta/beta_content.json"
const CHARACTER_IDS: Array[StringName] = [&"eloa", &"sena", &"cira", &"rui"]
const STARTER_WEAPONS := {
	&"eloa": "filamentos_de_forja", &"sena": "lanca_de_duas_rotas",
	&"cira": "manoplas_de_placa_viva", &"rui": "bastao_modular_de_campo",
}
const STARTER_GEAR: Array[String] = ["protecao_de_trabalho", "botas_de_rota_antiga", "anel_de_folego"]
const EXPERIENCE_REWARDS := {"common": 12, "elite": 30, "boss": 120, "raid": 400}
const GEM_IDS: Array[String] = ["agulha_lastro", "passo_vetorial", "pulso_cicatriz", "prisao_gravitica"]
## Cada personagem começa só com o autoataque e esta gema em Q; as demais vêm dos chefes (`gem_set`).
const STARTER_GEMS := {
	&"eloa": "elo_residual", &"sena": "agulha_lastro", &"cira": "pulso_cicatriz", &"rui": "mina_de_lastro",
}
## EXP de gema vem do uso: cada lançamento e cada abate feito pela própria gema.
const GEM_CAST_EXPERIENCE := 6
## "tower" é sempre o andar ativo da Torre (`current_floor`); o grupo atravessa os andares junto.
const ARENA_ZONES: Array[StringName] = [&"tower"]
## Maestria das gemas (decisão 588): níveis 1 a 21; cada nível soma GEM_LEVEL_POWER_STEP aos
## números principais; nos níveis 5, 10, 15 e 20 escolhe-se 1 de 3 modificadores e no 21 1 de 2
## grandes modificadores. Requisitos de atributo crescem com o nível: sem cumpri-los, a gema age no
## maior nível cumprido. Levar uma gema ao 21 custa o esforço de levar a personagem ao 95.
const GEM_MAX_LEVEL_BETA := 21
const GEM_MASTERY_LEVELS: Array[int] = [5, 10, 15, 20, 21]
const GEM_LEVEL_POWER_STEP := 0.05
const GEM_PRIMARY_FIELDS: Array[String] = ["power", "barrier", "healing", "trail_damage", "arrival_damage", "arrival_barrier"]
## Requisito no nível 21: atributo principal 150, secundário 60% disso; curva (nível-1)/20 ^ 1,2.
const GEM_REQUIREMENT_MAX := 150.0
const GEM_REQUIREMENT_SECONDARY := 0.6
const GEM_REQUIREMENT_EXPONENT := 1.2
## Nível do jogador equivalente ao nível 21 da gema, e a parte da EXP do jogador que uma gema
## bem usada recebe (medida em tools/bench/gem_experience_probe.gd).
const GEM_PLAYER_LEVEL_EQUIVALENT := 95
const GEM_EXPERIENCE_SHARE := 0.85
const STABILITY_LIMIT := 0.6
const RECONNECT_GRACE := 60.0
## Escalonamento cooperativo do documento 58: orçamento do encontro, Vida de elite e Vida de chefe
## por número de jogadores na arena. Comuns não ganham Vida e o dano inimigo não muda.
const PARTY_SCALING := {
	1: {"budget": 1.0, "elite_health": 1.0, "boss_health": 1.0},
	2: {"budget": 1.65, "elite_health": 1.08, "boss_health": 1.55},
	3: {"budget": 2.25, "elite_health": 1.15, "boss_health": 2.05},
	4: {"budget": 2.8, "elite_health": 1.2, "boss_health": 2.5},
}
## Recompensa bruta acompanha 80% do crescimento do orçamento.
const REWARD_GROWTH_SHARE := 0.8
const BASE_PATIO_POPULATION := 4
const BASE_RESPAWN_CAPACITY := 6
const REINFORCEMENT_INTERVAL := 3.5
const BASE_KILLS_PER_BOSS := 25
## Monstros patrulham o território e só perseguem quem entra no raio de percepção.
const AGGRO_RADIUS := 520.0
const LEASH_RADIUS := 1100.0
const WANDER_RADIUS := 220.0
## Respawn acelera com o tempo no andar: intervalo = base / (1 + tempo / aceleração).
## Decisão 596: duas vezes mais rápido que antes (base 14 s e mínimo 2,5 s), mesma aceleração.
const RESPAWN_BASE_INTERVAL := 7.0
const RESPAWN_MIN_INTERVAL := 1.25
const RESPAWN_ACCELERATION := 120.0
const RESPAWN_MIN_DISTANCE := 480.0
## Decisão 596: nos andares comuns, a escada só se abre depois de o grupo sobreviver 10 minutos no
## andar (substitui a cota de abates, que segue contada para estatística).
const FLOOR_SURVIVAL_SECONDS := 600.0
## Decisão 596: todos os monstros (chefes inclusive) com 10x a Vida e 50% mais velocidade.
const ENEMY_HEALTH_MULT := 10.0
const ENEMY_SPEED_MULT := 1.5
## Chefe derrotado só volta depois da recarga (decisão 526); enquanto isso o andar é passagem.
## Alcance do golpe corpo a corpo dos chefes; o resto do dano vem das mecânicas anunciadas.
const BOSS_MELEE_RANGE := 75.0
const RECORD_MODES: Array[String] = ["solo", "duo", "trio", "squad"]
const RECORDS_PER_MODE := 5
## Queda e estabilização (documento 58, decisão 565): janelas por queda, tempo de estabilização,
## Vida ao voltar e Ferimento de Expedição (perda de Vida máxima até sair da Torre).
const DOWNED_WINDOWS: Array[float] = [20.0, 14.0, 8.0]
const STABILIZE_SECONDS := 3.0
const STABILIZE_RADIUS := 60.0
const STABILIZED_HEALTH := 0.25
const WOUND_PENALTY := 0.1
## Recuperação fora de combate (decisão 566): depois de 4 s sem dano, 1,5% da Vida máxima por segundo.
const OUT_OF_COMBAT_DELAY := 4.0
const OUT_OF_COMBAT_REGEN := 0.015
## Vida máxima ganha a cada nível de personagem.
const HEALTH_PER_LEVEL := 5.0
const AURA_RADIUS := 180.0
const AURA_LIMIT := 0.3
## Potência de combate cresce com o nível (3% por nível) e com os atributos de escala de cada gema
## (pesos 0,6 / 0,4 / 0,25 sobre o valor efetivo / 100), acompanhando a profundidade da Torre.
const POWER_PER_LEVEL := 0.03
const GEM_SCALING_WEIGHTS: Array[float] = [0.6, 0.4, 0.25]
## Saque físico (decisão 550): fica no chão até alguém passar por cima.
const PICKUP_RADIUS := 34.0
const MAX_GROUND_ITEM_VIEWS := 120
const AutoSupports := preload("res://src/gameplay/equipment/auto_attack_supports.gd")
const BestiaryScript := preload("res://src/gameplay/content/bestiary.gd")
const STACK_RADIUS := 18.0
const GEM_SLOT_KEYS: Array[String] = ["Q", "W", "E", "R"]

var encounter_seed := 7301
var players: Dictionary = {}
var enemies: Array[Dictionary] = []
var enemy_projectiles: Array[Dictionary] = []
var persistent_effects: Array[Dictionary] = []
## Gema cujo efeito está sendo resolvido; vai nos eventos visuais para a apresentação escolher o tema.
var _vfx_theme := ""
## Andares (decisão 553): andar ativo, layout, corrida atual, telegrafias, zonas de perigo,
## recargas de chefes derrotados, andar de partida, andar mais fundo e recordes de tempo.
var current_floor := 0
var floor_layout: Dictionary = {}
var floor_run: Dictionary = {}
var telegraphs: Array[Dictionary] = []
var hazard_zones: Array[Dictionary] = []
var tower_start_floor := 1
var deepest_floor := 1
var records: Dictionary = {}
var _hazard_timer := 6.0
var _floor_random := RandomNumberGenerator.new()
## Moradores de Aresta (decisão 560).
var village_life: RefCounted
var narrative := NarrativeProgress.new()
var banked_stone := 0
var banked_loot: Dictionary = {}
var village_progress := 0
var loot_kill_sequence := 0
var character_builds: Dictionary = {}
var character_experience: Dictionary = {}
var character_gear: Dictionary = {}
var character_gems: Dictionary = {}
## Bestiário por personagem: {personagem: {inimigo: {kills, min_health, max_health, drops, affixes}}}.
var character_bestiary: Dictionary = {}
## Loja: o estoque sai de (semente do mundo, rodada); vendidos guardam o índice da vaga.
var shop_sequence := 0
var shop_sold: Array[int] = []
var _shop_cache: Dictionary = {}
var equipment_instance_sequence := 1
var active_gems: Array[Dictionary] = []
var skill_max_cooldowns: Array[float] = [1.5, 3.0, 5.0, 8.0]
var respawn: RefCounted
var threat: RefCounted

var _loot_resolver: RefCounted = EnemyLootResolverScript.new()
var _crit_random := RandomNumberGenerator.new()
## Sorteio de afixos de equipamento (decisão 583), semeado pelo mundo para ser reproduzível.
var _affix_random := RandomNumberGenerator.new()
var _gem_random := RandomNumberGenerator.new()
var _next_summon_sequence := 1
var _events: Array[Dictionary] = []
var _collections: Dictionary = {}
var _scheduled: Array[Dictionary] = []
var _reinforcement_timer := REINFORCEMENT_INTERVAL
var _reinforcement_sequence := 0
var _milestone_cache: Dictionary = {}
## Passivas de itens (decisão 580): cache por jogador e acertos/abates enfileirados até o golpe
## atual terminar, para que ações como executar não mexam na lista de inimigos no meio do dano.
var _passive_cache: Dictionary = {}
var _passive_events: Array[Dictionary] = []
var _damage_depth := 0
var _mechanic_random := RandomNumberGenerator.new()
var _kill_burst_depth := 0
var ground_items: Array[Dictionary] = []
var _ground_sequence := 1


func setup(seed: int = 7301) -> void:
	encounter_seed = seed
	_affix_random.seed = seed * 92821 + 583
	_gem_random.seed = seed * 7727 + 585
	_configure_directors()
	_load_gems()
	village_life = VillageLifeScript.new()
	village_life.call("setup", seed + 41, LayoutScript.village_spots())


# ---------------------------------------------------------------- jogadores

func add_player(peer_id: int, character_id: StringName = &"", profile_id: String = "") -> bool:
	if players.has(peer_id) or players.size() >= MAX_PLAYERS:
		return false
	if not profile_id.is_empty() and not find_profile(profile_id).is_empty():
		profile_id = "%s#%d" % [profile_id, peer_id]
	var passive: RefCounted = PassiveRuntimeScript.new()
	players[peer_id] = {
		"peer": peer_id,
		"profile": profile_id,
		"connected": true,
		"reconnect_timer": 0.0,
		"character_id": &"",
		"character_name": "",
		"zone": &"village",
		"position": LayoutScript.WORLD_SPAWN + Vector2(float(players.size()) * 28.0, 0.0),
		"target": LayoutScript.WORLD_SPAWN + Vector2(float(players.size()) * 28.0, 0.0),
		"last_world_position": LayoutScript.WORLD_SPAWN,
		"transition_cooldown": 0.0,
		"health": PLAYER_MAX_HEALTH,
		"breath": PLAYER_MAX_BREATH,
		"cooldowns": [0.0, 0.0, 0.0, 0.0] as Array[float],
		"auto_attack": true,
		"attack_request": Vector2.ZERO,
		"attack_request_timer": 0.0,
		"recharge": [1.0, 1.0, 1.0, 1.0] as Array[float],
		"charges": [1, 1, 1, 1] as Array[int],
		"charge_caps": [1, 1, 1, 1] as Array[int],
		"barrier": 0.0,
		"invulnerable": 0.0,
		"damage_cooldown": 0.0,
		"attack_timer": 0.0,
		"quick_items": 2,
		"carried_stone": 0,
		"carried_loot": {},
		"passive": passive,
		"facing_left": false,
		"facing_direction": Vector2.DOWN,
		"moving": false,
		"hurt_flash": 0.0,
		"downed": false,
		"downed_timer": 0.0,
		"stabilize_progress": 0.0,
		"falls": 0,
		"wounds": 0,
	}
	var wanted := character_id if not character_id.is_empty() else first_free_character()
	if not wanted.is_empty():
		select_character(peer_id, wanted)
	return true


func remove_player(peer_id: int) -> void:
	if not players.has(peer_id):
		return
	var leaving := players[peer_id] as Dictionary
	for index in range(persistent_effects.size() - 1, -1, -1):
		if int(persistent_effects[index].get("owner_peer", -1)) == peer_id:
			persistent_effects.remove_at(index)
	players.erase(peer_id)
	_status(0, "%s deixou a sessao." % String(leaving["character_name"]))


## Desconexão reserva a personagem por RECONNECT_GRACE segundos quando o jogador tem perfil.
## Durante a reserva a personagem para, não recebe comandos, não é alvo e não sofre dano.
func disconnect_player(peer_id: int) -> void:
	var state := player(peer_id)
	if state.is_empty():
		return
	if String(state.get("profile", "")).is_empty():
		remove_player(peer_id)
		return
	state["connected"] = false
	state["reconnect_timer"] = RECONNECT_GRACE
	state["target"] = state["position"]
	state["moving"] = false
	_status(0, "%s perdeu a conexao. A personagem fica reservada por %d s." % [String(state["character_name"]), int(RECONNECT_GRACE)])


## Devolve ao novo peer a personagem reservada do mesmo perfil, com todo o estado intacto.
func reconnect_player(profile_id: String, new_peer: int) -> bool:
	if profile_id.is_empty() or players.has(new_peer):
		return false
	var old_peer := -1
	for peer_id: int in players:
		var candidate := players[peer_id] as Dictionary
		if String(candidate.get("profile", "")) == profile_id and not bool(candidate.get("connected", true)):
			old_peer = peer_id
	if old_peer < 0:
		return false
	var state := players[old_peer] as Dictionary
	players.erase(old_peer)
	state["peer"] = new_peer
	state["connected"] = true
	state["reconnect_timer"] = 0.0
	state["target"] = state["position"]
	players[new_peer] = state
	for effect in persistent_effects:
		if int(effect.get("owner_peer", -1)) == old_peer:
			effect["owner_peer"] = new_peer
			effect["owner_id"] = "peer_%d" % new_peer
	for entry in _scheduled:
		if int(entry.get("peer", -1)) == old_peer:
			entry["peer"] = new_peer
	_status(0, "%s voltou a sessao." % String(state["character_name"]))
	return true


func find_profile(profile_id: String) -> Dictionary:
	for state: Dictionary in players.values():
		if String(state.get("profile", "")) == profile_id:
			return state
	return {}


func is_connected_player(peer_id: int) -> bool:
	return bool(player(peer_id).get("connected", false))


## Reserva expirada: na arena a carga é abandonada na Torre, como numa retirada impossível.
func _expire_reservation(peer_id: int) -> void:
	var state := player(peer_id)
	if state["zone"] in ARENA_ZONES:
		_drop_carried(peer_id, state["zone"] as StringName, state["position"] as Vector2)
		_status(0, "%s nao voltou a tempo; a carga ficou no chao da Torre." % String(state["character_name"]))
	remove_player(peer_id)


func player(peer_id: int) -> Dictionary:
	return players.get(peer_id, {}) as Dictionary


func first_free_character() -> StringName:
	for character_id in CHARACTER_IDS:
		if not is_character_taken(character_id):
			return character_id
	return &""


func is_character_taken(character_id: StringName, except_peer: int = -1) -> bool:
	for peer_id: int in players:
		if peer_id != except_peer and (players[peer_id] as Dictionary)["character_id"] == character_id:
			return true
	return false


func select_character(peer_id: int, character_id: StringName) -> bool:
	var state := player(peer_id)
	if state.is_empty():
		return false
	if state["zone"] in ARENA_ZONES:
		_status(peer_id, "A troca de personagem so acontece fora da Torre.")
		return false
	if is_character_taken(character_id, peer_id):
		_status(peer_id, "Essa personagem ja esta na sessao.")
		return false
	var definition := _find(_collection("playable_characters"), String(character_id))
	if definition.is_empty():
		return false
	_ensure_character(character_id, definition)
	state["character_id"] = character_id
	state["character_name"] = String(definition.get("name", character_id))
	var passive := definition.get("passive", {}) as Dictionary
	(state["passive"] as RefCounted).call("setup", StringName(String(passive.get("id", ""))), String(passive.get("name", "")))
	_refresh_milestones(peer_id)
	_status(peer_id, "Expedicao com %s." % state["character_name"])
	return true


func _ensure_character(character_id: StringName, definition: Dictionary) -> void:
	var key := String(character_id)
	if not character_builds.has(key):
		var factory: RefCounted = BetaCharacterFactoryScript.new()
		character_builds[key] = factory.call("create_build", definition)
		character_experience[key] = 0
	if not character_gems.has(key):
		character_gems[key] = _new_gem_state(key)
	if not character_gear.has(key):
		character_gear[key] = _new_gear(key)
		var weapon := String(STARTER_WEAPONS.get(character_id, "filamentos_de_forja"))
		var weapon_id := _add_equipment_instance(character_id, weapon)
		var armor_id := _add_equipment_instance(character_id, STARTER_GEAR[0])
		for item_id in STARTER_GEAR.slice(1):
			_add_equipment_instance(character_id, item_id)
		_equip(character_id, weapon_id)
		_equip(character_id, armor_id)


# ---------------------------------------------------------------- gemas por personagem

## Gemas pertencem à personagem: até quatro ativas em Q/W/E/R (encaixe vazio é ""), suportes por
## encaixe e progresso só das gemas possuídas. Começa com a gema inicial da personagem em Q.
func _new_gem_state(character_id: String = "") -> Dictionary:
	var gems := {}
	var slots: Array = ["", "", "", ""]
	var starter := String(STARTER_GEMS.get(StringName(character_id), ""))
	if not gem_definition(starter).is_empty():
		gems[starter] = _new_gem_progress()
		slots[0] = starter
	return {"slots": slots, "supports": [[], [], [], []], "auto_supports": [], "gems": gems}


func _new_gem_progress() -> Dictionary:
	return {"level": 1, "experience": 0, "choices": {}}


func owns_gem(peer_id: int, gem_id: String) -> bool:
	return (_gem_state(peer_id).get("gems", {}) as Dictionary).has(gem_id)


## Entrega uma gema à personagem (queda de chefe, ferramentas e testes). Falso se já tinha.
func grant_gem(peer_id: int, gem_id: String) -> bool:
	var gems := _gem_state(peer_id)
	if gems.is_empty() or gem_definition(gem_id).is_empty() or (gems["gems"] as Dictionary).has(gem_id):
		return false
	(gems["gems"] as Dictionary)[gem_id] = _new_gem_progress()
	var slots := gems["slots"] as Array
	var empty := slots.find("")
	if empty >= 0:
		slots[empty] = gem_id
	return true


## Atalho de desenvolvimento (F8 no modo dev, ferramentas e testes): todas as gemas ativas.
## Com `legacy_loadout`, Q/W/E/R voltam à formação clássica de GEM_IDS.
func unlock_all_gems(peer_id: int, legacy_loadout: bool = false) -> void:
	var gems := _gem_state(peer_id)
	if gems.is_empty():
		return
	for definition in _collection("active_gems"):
		var gem_id := String(definition.get("id", ""))
		if not (gems["gems"] as Dictionary).has(gem_id):
			(gems["gems"] as Dictionary)[gem_id] = _new_gem_progress()
	if legacy_loadout:
		gems["slots"] = GEM_IDS.duplicate()
		gems["supports"] = [[], [], [], []]
	_status(peer_id, "Todas as gemas liberadas (desenvolvimento).")


## Conjunto de gemas que o chefe do andar entrega; vazio em andares sem chefe ou sem conjunto.
static func boss_gem_set(floor_number: int) -> Array[String]:
	var result: Array[String] = []
	for boss in TowerContentScript.collection("bosses"):
		if int(boss.get("floor", 0)) == floor_number:
			for gem_id: Variant in boss.get("gem_set", []) as Array:
				result.append(String(gem_id))
	return result


## Chefe vencido: cada jogador na arena sorteia no máximo uma gema do conjunto que ainda não tem
## (BOSS_GEM_CHANCE); quem saiu sem gema na vitória anterior sobre esse chefe ganha uma garantida.
func _grant_boss_gems(floor_number: int) -> void:
	var gem_set := boss_gem_set(floor_number)
	if gem_set.is_empty():
		return
	for member in _players_in_arena():
		var gems := _gem_state(member)
		var missing := gem_set.filter(func(gem_id: String) -> bool: return not owns_gem(member, gem_id))
		if gems.is_empty() or missing.is_empty():
			continue
		var misses := gems.get("boss_misses", {}) as Dictionary
		var key := str(floor_number)
		var state := player(member)
		if int(misses.get(key, 0)) == 0 and _gem_random.randf() >= BOSS_GEM_CHANCE:
			misses[key] = 1
			gems["boss_misses"] = misses
			_status(member, "O guardiao nao deixou gema desta vez. A proxima vitoria sobre ele garante uma.")
			continue
		misses.erase(key)
		gems["boss_misses"] = misses
		var gem_id := String(missing[_gem_random.randi_range(0, missing.size() - 1)])
		grant_gem(member, gem_id)
		var name := String(gem_definition(gem_id).get("name", gem_id))
		_vfx(state["zone"] as StringName, "label", [state["position"] as Vector2 + Vector2(0.0, -46.0), "NOVA GEMA: %s" % name.to_upper(), Color("f2d16a"), "levelup"])
		_status(member, "Nova gema: %s (%d de %d deste guardiao). Equipe em Aresta (SKILLS)." % [name, gem_set.size() - missing.size() + 1, gem_set.size()])


func _gem_state(peer_id: int) -> Dictionary:
	return character_gems.get(String(player(peer_id).get("character_id", "")), {}) as Dictionary


func gem_definition(gem_id: String) -> Dictionary:
	return _find(_collection("active_gems"), gem_id)


func support_definition(support_id: String) -> Dictionary:
	return _find(_collection("support_gems"), support_id)


## Capacidade de suporte: 3 no nível 1 e +1 a cada 5 níveis (7 no 20).
func gem_capacity(gem_level: int) -> int:
	return 3 + clampi(gem_level, 1, GEM_MAX_LEVEL_BETA) / 5


func _used_capacity(supports: Array) -> int:
	var total := 0
	for support_id: Variant in supports:
		total += int(support_definition(String(support_id)).get("drain", 0))
	return total


func _in_safe_area(peer_id: int, action: String) -> bool:
	if player(peer_id).get("zone") in ARENA_ZONES:
		_status(peer_id, "%s so pode ser feito em Aresta." % action)
		return false
	return true


func set_gem_slot(peer_id: int, slot: int, gem_id: String) -> bool:
	var gems := _gem_state(peer_id)
	if gems.is_empty() or slot < 0 or slot >= 4 or not (gem_id.is_empty() or (gems["gems"] as Dictionary).has(gem_id)):
		return false
	if not _in_safe_area(peer_id, "Trocar gemas"):
		return false
	var slots := gems["slots"] as Array
	if gem_id.is_empty():
		slots[slot] = ""
		(gems["supports"] as Array)[slot] = []
		_status(peer_id, "%s ficou vazio." % GEM_SLOT_KEYS[slot])
		return true
	var previous := String(slots[slot])
	var other := slots.find(gem_id)
	if other >= 0 and other != slot:
		slots[other] = previous
		var supports_list := gems["supports"] as Array
		var swap: Variant = supports_list[other]
		supports_list[other] = supports_list[slot]
		supports_list[slot] = swap
	slots[slot] = gem_id
	_validate_supports(gems)
	_status(peer_id, "%s equipada em %s." % [String(gem_definition(gem_id).get("name", gem_id)), GEM_SLOT_KEYS[slot]])
	return true


func attach_support(peer_id: int, slot: int, support_id: String) -> bool:
	if slot == AutoSupports.SLOT:
		return attach_auto_support(peer_id, support_id)
	var gems := _gem_state(peer_id)
	var support := support_definition(support_id)
	if gems.is_empty() or support.is_empty() or slot < 0 or slot >= 4:
		return false
	if not _in_safe_area(peer_id, "Ligar suportes"):
		return false
	var slots := gems["slots"] as Array
	var supports_list := gems["supports"] as Array
	var current := supports_list[slot] as Array
	var gem_id := String(slots[slot])
	if gem_id.is_empty():
		return false
	var level := int(((gems["gems"] as Dictionary)[gem_id] as Dictionary)["level"])
	var resolver: RefCounted = SkillResolverScript.new()
	var message := ""
	if current.size() >= 2:
		message = "Cada gema ativa aceita no maximo dois suportes."
	elif current.has(support_id):
		message = "Esse suporte ja esta ligado a esta gema."
	elif not bool(resolver.call("supports", gem_definition(gem_id), support)):
		message = "%s nao e compativel com %s." % [support.get("name", support_id), gem_definition(gem_id).get("name", gem_id)]
	elif _used_capacity(current) + int(support.get("drain", 0)) > gem_capacity(level):
		message = "Capacidade insuficiente: %d de %d." % [_used_capacity(current) + int(support.get("drain", 0)), gem_capacity(level)]
	if not message.is_empty():
		_status(peer_id, message)
		return false
	for index in range(supports_list.size()):
		(supports_list[index] as Array).erase(support_id)
	(gems["auto_supports"] as Array).erase(support_id)
	current.append(support_id)
	_status(peer_id, "%s ligado a %s." % [support.get("name", support_id), gem_definition(gem_id).get("name", gem_id)])
	return true


func detach_support(peer_id: int, slot: int, support_id: String) -> bool:
	var gems := _gem_state(peer_id)
	if gems.is_empty() or slot < 0 or slot > AutoSupports.SLOT or not _in_safe_area(peer_id, "Remover suportes"):
		return false
	var current := gems["auto_supports"] as Array if slot == AutoSupports.SLOT else (gems["supports"] as Array)[slot] as Array
	if not current.has(support_id):
		return false
	current.erase(support_id)
	_status(peer_id, "%s removido." % support_definition(support_id).get("name", support_id))
	return true


func attach_auto_support(peer_id: int, support_id: String) -> bool:
	var gems := _gem_state(peer_id)
	var support := support_definition(support_id)
	if gems.is_empty() or support.is_empty() or not _in_safe_area(peer_id, "Ligar suportes"):
		return false
	var current := gems["auto_supports"] as Array
	if current.size() >= 2 or current.has(support_id) or _used_capacity(current) + int(support.get("drain", 0)) > AutoSupports.CAPACITY or not AutoSupports.supports(_base_weapon_attack_model(peer_id), support):
		_status(peer_id, "Suporte incompativel ou capacidade do autoataque insuficiente.")
		return false
	for other: Array in gems["supports"]:
		other.erase(support_id)
	current.append(support_id)
	_status(peer_id, "%s ligado ao autoataque." % support.get("name", support_id))
	return true


func choose_gem_evolution(peer_id: int, gem_id: String, choice_id: String) -> bool:
	var gems := _gem_state(peer_id)
	if gems.is_empty() or not (gems["gems"] as Dictionary).has(gem_id):
		return false
	if not _in_safe_area(peer_id, "Escolher evolucoes"):
		return false
	var progress := (gems["gems"] as Dictionary)[gem_id] as Dictionary
	var mastery_level := pending_evolution_tier(progress)
	if mastery_level <= 0:
		return false
	for option: Dictionary in _evolution_options(gem_id, mastery_level):
		if String(option.get("id", "")) == choice_id:
			(progress["choices"] as Dictionary)[str(mastery_level)] = choice_id
			_status(peer_id, "%s: %s." % [gem_definition(gem_id).get("name", gem_id), option.get("name", choice_id)])
			return true
	return false


## Primeiro nível de maestria (5, 10, 15, 20, 21) já alcançado e ainda sem escolha; 0 se nenhum.
static func pending_evolution_tier(progress: Dictionary) -> int:
	for mastery_level in GEM_MASTERY_LEVELS:
		if mastery_level <= int(progress.get("level", 1)) and not (progress.get("choices", {}) as Dictionary).has(str(mastery_level)):
			return mastery_level
	return 0


## Requisitos de atributo da gema num nível: os atributos que ela escala (Esporos, que não escalam,
## pedem Sabedoria); o principal chega a 150 no nível 21 e o secundário a 60% disso.
func gem_requirements(gem_id: String, level: int) -> Dictionary:
	var stats := (gem_definition(gem_id).get("scaling", []) as Array).duplicate()
	if stats.is_empty():
		stats = ["wisdom"]
	var primary := roundf(GEM_REQUIREMENT_MAX * pow(float(clampi(level, 1, GEM_MAX_LEVEL_BETA) - 1) / float(GEM_MAX_LEVEL_BETA - 1), GEM_REQUIREMENT_EXPONENT))
	var result := {String(stats[0]): primary}
	if stats.size() > 1:
		result[String(stats[1])] = roundf(primary * GEM_REQUIREMENT_SECONDARY)
	return result


## Atributo bruto da personagem (pontos distribuídos, marcos e equipamento), comparado aos requisitos.
func raw_stat(peer_id: int, stat: String) -> float:
	var build := character_build(peer_id)
	if build == null:
		return 0.0
	var gear := _gear(peer_id)
	var modifiers: Dictionary = (gear["equipment"] as EquipmentLoadout).combined_stat_modifiers() if not gear.is_empty() else {}
	return float(build.base_stats.get(StringName(stat), 0.0)) + float(modifiers.get(StringName(stat), 0.0))


## Maior nível até o atual cujos requisitos a personagem cumpre: é nele que a gema age.
func gem_effective_level(peer_id: int, gem_id: String) -> int:
	var progress := (_gem_state(peer_id).get("gems", {}) as Dictionary).get(gem_id, {}) as Dictionary
	var level := int(progress.get("level", 1))
	while level > 1:
		var met := true
		var requirements := gem_requirements(gem_id, level)
		for stat: String in requirements:
			if raw_stat(peer_id, stat) < float(requirements[stat]):
				met = false
		if met:
			break
		level -= 1
	return level


func _evolution_options(gem_id: String, level: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var evolutions := gem_definition(gem_id).get("evolutions", {}) as Dictionary
	for option: Variant in evolutions.get(str(level), []) as Array:
		if option is Dictionary:
			result.append(option as Dictionary)
	return result


## EXP do nível N ao N+1: a parte (GEM_EXPERIENCE_SHARE) da EXP que o jogador gasta no bloco de níveis
## equivalente. Os 20 passos da gema cobrem os níveis 1 a 95 do jogador (~4,7 níveis por passo).
func gem_experience_required(level: int) -> int:
	var span := float(GEM_PLAYER_LEVEL_EQUIVALENT - 1) / float(GEM_MAX_LEVEL_BETA - 1)
	var first := int(floor(float(clampi(level, 1, GEM_MAX_LEVEL_BETA - 1) - 1) * span)) + 1
	var last := int(floor(float(clampi(level, 1, GEM_MAX_LEVEL_BETA - 1)) * span))
	var total := 0
	for player_level in range(first, last + 1):
		total += experience_required(player_level)
	return maxi(1, int(round(float(total) * GEM_EXPERIENCE_SHARE)))


## EXP de uso: só a gema que foi lançada ou que abateu o inimigo cresce.
func gain_gem_experience(peer_id: int, gem_id: String, amount: int) -> void:
	var gems := _gem_state(peer_id)
	if gems.is_empty() or amount <= 0 or not (gems["gems"] as Dictionary).has(gem_id):
		return
	var progress := (gems["gems"] as Dictionary)[gem_id] as Dictionary
	if int(progress["level"]) >= GEM_MAX_LEVEL_BETA:
		return
	progress["experience"] = int(progress["experience"]) + amount
	_advance_gem(peer_id, gem_id)


## Sobe de nível ao completar a EXP; cada nível libera a escolha de uma evolução em Aresta.
func _advance_gem(peer_id: int, gem_id: String) -> void:
	var progress := (_gem_state(peer_id)["gems"] as Dictionary)[gem_id] as Dictionary
	while int(progress["level"]) < GEM_MAX_LEVEL_BETA:
		var required := gem_experience_required(int(progress["level"]))
		if int(progress["experience"]) < required:
			break
		progress["experience"] = int(progress["experience"]) - required
		progress["level"] = int(progress["level"]) + 1
		if int(progress["level"]) >= GEM_MAX_LEVEL_BETA:
			progress["experience"] = 0
		var state := player(peer_id)
		var name := String(gem_definition(gem_id).get("name", gem_id))
		var milestone := int(progress["level"]) in GEM_MASTERY_LEVELS
		if not state.is_empty():
			_vfx(state["zone"] as StringName, "label", [state["position"] as Vector2 + Vector2(0.0, -30.0), "%s NV %d%s" % [name.to_upper(), progress["level"], " - MODIFICADOR!" if milestone else ""], Color("f2d16a") if milestone else Color("9fd8ff"), "levelup"])
		if milestone:
			_status(peer_id, "%s alcancou o nivel %d: escolha um modificador em Aresta (SKILLS)." % [name, progress["level"]])
		else:
			_status(peer_id, "%s alcancou o nivel %d." % [name, progress["level"]])


func _validate_supports(gems: Dictionary) -> void:
	var resolver: RefCounted = SkillResolverScript.new()
	for slot in range(4):
		var gem_id := String((gems["slots"] as Array)[slot])
		if not (gems["gems"] as Dictionary).has(gem_id):
			(gems["supports"] as Array)[slot] = []
			continue
		var level := int(((gems["gems"] as Dictionary)[gem_id] as Dictionary)["level"])
		var kept: Array = []
		for support_id: Variant in (gems["supports"] as Array)[slot]:
			var support := support_definition(String(support_id))
			if bool(resolver.call("supports", gem_definition(gem_id), support)) and _used_capacity(kept) + int(support.get("drain", 0)) <= gem_capacity(level):
				kept.append(support_id)
		(gems["supports"] as Array)[slot] = kept


## Gema-base, evoluções escolhidas em ordem de nível e suportes em ordem canônica de ID (ADR 0007).
func resolve_slot(peer_id: int, slot: int) -> Dictionary:
	var gems := _gem_state(peer_id)
	if gems.is_empty():
		return {}
	if slot < 0 or slot >= 4:
		return {}
	var gem_id := String((gems["slots"] as Array)[slot])
	if not (gems["gems"] as Dictionary).has(gem_id):
		return {}
	var definition := gem_definition(gem_id).duplicate(true)
	var progress := (gems["gems"] as Dictionary)[gem_id] as Dictionary
	# Nível efetivo (requisitos de atributo): números e modificadores só até ele.
	var effective := gem_effective_level(peer_id, gem_id)
	for field in GEM_PRIMARY_FIELDS:
		if definition.has(field):
			definition[field] = float(definition[field]) * (1.0 + GEM_LEVEL_POWER_STEP * float(effective - 1))
	var evolution_modifiers: Array[Dictionary] = []
	for level in GEM_MASTERY_LEVELS:
		if level > effective:
			break
		var choice_id := String((progress["choices"] as Dictionary).get(str(level), ""))
		for option in _evolution_options(gem_id, level):
			if String(option.get("id", "")) == choice_id:
				evolution_modifiers.append(option.get("modifiers", {}) as Dictionary)
	var support_ids: Array = ((gems["supports"] as Array)[slot] as Array).duplicate()
	support_ids.sort()
	var supports: Array[Dictionary] = []
	for support_id: Variant in support_ids:
		supports.append(support_definition(String(support_id)))
	var resolver: RefCounted = SkillResolverScript.new()
	var base: Dictionary = resolver.call("resolve", definition, [] as Array[Dictionary], evolution_modifiers)
	var resolved: Dictionary = resolver.call("resolve", base, supports)
	var unique := unique_weapon_for(peer_id, gem_id)
	if not unique.is_empty():
		var unique_modifiers: Array[Dictionary] = [unique["gem_modifiers"] as Dictionary]
		resolved = resolver.call("resolve", resolved, [] as Array[Dictionary], unique_modifiers)
		resolved["unique_weapon"] = String(unique["id"])
	resolved["gem_id"] = gem_id
	return resolved


## Arma única equipada que pertence a esta gema; vazio se a arma não for a dela.
func unique_weapon_for(peer_id: int, gem_id: String) -> Dictionary:
	var gear := _gear(peer_id)
	if gear.is_empty():
		return {}
	var weapon: EquipmentItemInstance = (gear["equipment"] as EquipmentLoadout).get_equipped(EquipmentItemDefinition.Slot.WEAPON, 0)
	if weapon == null:
		return {}
	var data := _find(_collection("items"), String(weapon.definition.id))
	return data if String(data.get("unique_gem", "")) == gem_id else {}


## Cargas por slot: `extra_charge` permite usos seguidos; a recarga devolve uma carga por vez.
func refresh_charges(peer_id: int) -> void:
	var state := player(peer_id)
	if state.is_empty() or _gem_state(peer_id).is_empty():
		return
	var charges := state["charges"] as Array[int]
	var caps := state["charge_caps"] as Array[int]
	var cooldowns := state["cooldowns"] as Array[float]
	for slot in range(4):
		caps[slot] = 1 + maxi(0, int(resolve_slot(peer_id, slot).get("extra_charge", 0)))
		charges[slot] = caps[slot]
		cooldowns[slot] = 0.0


# ---------------------------------------------------------------- intenções

func set_move_target(peer_id: int, target: Vector2) -> void:
	if is_milestone_paused():
		return
	var state := player(peer_id)
	if not state.is_empty() and not bool(state.get("downed", false)):
		state["target"] = target


func use_skill(peer_id: int, slot: int, target: Vector2) -> bool:
	if is_milestone_paused():
		return false
	var state := player(peer_id)
	if state.is_empty() or state["zone"] not in ARENA_ZONES or bool(state.get("downed", false)):
		return false
	var cooldowns := state["cooldowns"] as Array[float]
	var charges := state["charges"] as Array[int]
	if slot < 0 or slot >= cooldowns.size() or charges[slot] <= 0:
		return false
	var effect := resolve_slot(peer_id, slot)
	if effect.is_empty():
		return false
	var breath_cost := float(effect.get("breath_cost", 0.0)) * _mod(peer_id, "breath_cost_mult")
	if float(state["breath"]) < breath_cost:
		_status(peer_id, "Folego insuficiente.")
		return false
	var passive := state["passive"] as RefCounted
	var cast: Dictionary = passive.call("on_skill_used", slot)
	var free := bool(cast.get("free", false))
	breath_cost *= float(cast["breath_multiplier"])
	var power_multiplier := float(cast["power_multiplier"]) * _skill_power_multiplier(peer_id, effect)
	for key: String in ["power", "barrier", "healing", "trail_damage", "arrival_damage", "expire_damage"]:
		if effect.has(key):
			effect[key] = float(effect[key]) * power_multiplier
	var area := float(derived_stats(peer_id).get("area_multiplier", 1.0))
	for key in AREA_KEYS:
		if effect.has(key):
			effect[key] = float(effect[key]) * area
	if effect.has("duration"):
		effect["duration"] = float(effect["duration"]) * _mod(peer_id, "duration_mult")
	if not free:
		state["breath"] = float(state["breath"]) - breath_cost
		charges[slot] -= 1
		if cooldowns[slot] <= 0.0:
			var recharge := float(effect.get("cooldown", 1.0)) / float(derived_stats(peer_id).get("cooldown_recovery_multiplier", 1.0))
			(state["recharge"] as Array[float])[slot] = recharge
			cooldowns[slot] = recharge
	_apply_passive_requests(peer_id, cast["requests"] as Array)
	_add_barrier(peer_id, _mod(peer_id, "barrier_on_skill_add"), 4.0)
	state["last_hit"] = _hit_context(effect)
	execute_gem_effect(peer_id, effect, target)
	_after_skill(peer_id, effect, target, float(cast.get("echo", 0.0)))
	gain_gem_experience(peer_id, String(effect.get("gem_id", "")), GEM_CAST_EXPERIENCE)
	ItemPassivesScript.on_cast(self, peer_id, effect, target, slot)
	return true


## Potência de gema vinda dos marcos: global, por tag e pela aura de aliados próximos.
func _skill_power_multiplier(peer_id: int, effect: Dictionary) -> float:
	# Gemas de potência fixa (Esporos) não escalam com atributos, nível nem bônus de personagem.
	if bool(gem_definition(String(effect.get("gem_id", ""))).get("fixed_power", false)):
		return 1.0
	var multiplier := _mod(peer_id, "power_mult") * (1.0 + _ally_aura(peer_id, "ally_power_add")) * level_power(peer_id)
	var effective := (derived_stats(peer_id).get("effective_primaries", {}) as Dictionary)
	var scaling := 1.0
	var gem := gem_definition(String(effect.get("gem_id", "")))
	var stats := gem.get("scaling", []) as Array
	for index in range(mini(stats.size(), GEM_SCALING_WEIGHTS.size())):
		scaling += float(effective.get(StringName(String(stats[index])), 0.0)) / 100.0 * GEM_SCALING_WEIGHTS[index]
	multiplier *= scaling
	for tag: Variant in effect.get("tags", []) as Array:
		multiplier *= _mod(peer_id, "power_%s_mult" % String(tag))
	var element := String(gem.get("element", ""))
	if not element.is_empty():
		multiplier *= _mod(peer_id, "power_%s_mult" % element)
	return multiplier


## Atributos que fortalecem a gema, com o ganho por ponto efetivo e os pontos atuais.
func gem_scaling_view(peer_id: int, gem_id: String) -> Array[Dictionary]:
	var effective := derived_stats(peer_id).get("effective_primaries", {}) as Dictionary
	var stats := gem_definition(gem_id).get("scaling", []) as Array
	var result: Array[Dictionary] = []
	for index in range(mini(stats.size(), GEM_SCALING_WEIGHTS.size())):
		var stat := String(stats[index])
		result.append({"stat": stat, "per_point": GEM_SCALING_WEIGHTS[index] / 100.0, "points": float(effective.get(StringName(stat), 0.0))})
	return result


## Eco (passiva ou `skill_echo`) e onda de chegada do dash (`dash_nova`) depois de uma gema.
func _after_skill(peer_id: int, effect: Dictionary, target: Vector2, echo: float) -> void:
	var state := player(peer_id)
	state["cast_count"] = int(state.get("cast_count", 0)) + 1
	for mechanic in _mechanics(peer_id, "skill_echo"):
		if int(state["cast_count"]) % maxi(1, int(mechanic.get("every", 3))) == 0:
			echo = maxf(echo, float(mechanic.get("ratio", 0.5)))
	if echo > 0.0:
		var copy := effect.duplicate(true)
		for key: String in ["power", "barrier", "healing", "trail_damage", "arrival_damage", "expire_damage"]:
			if copy.has(key):
				copy[key] = float(copy[key]) * echo
		copy.erase("repeat_count")
		_scheduled.append({"time": 0.3, "peer": peer_id, "effect": copy, "target": target, "zone": state["zone"], "floor": current_floor})
	if String(effect.get("mechanic", "")) == "dash":
		for mechanic in _mechanics(peer_id, "dash_nova"):
			var radius := float(mechanic.get("radius", 80.0))
			_vfx(state["zone"], "ring", [state["position"], radius])
			damage_enemies(peer_id, state["position"] as Vector2, radius, float(mechanic.get("damage", 20.0)))


func use_quick_item(peer_id: int) -> void:
	if is_milestone_paused():
		return
	var state := player(peer_id)
	if state.is_empty() or bool(state.get("downed", false)):
		return
	if int(state["quick_items"]) <= 0:
		_status(peer_id, "Nenhum consumivel rapido restante.")
	elif float(state["health"]) >= max_health(peer_id):
		_status(peer_id, "Vida ja esta completa.")
	else:
		state["quick_items"] = int(state["quick_items"]) - 1
		state["health"] = minf(max_health(peer_id), float(state["health"]) + 35.0)
		_status(peer_id, "Consumivel usado. Vida: %d" % int(state["health"]))


func allocate_stat(peer_id: int, stat: StringName) -> void:
	var build := character_build(peer_id)
	if build != null and build.allocate_stat(stat, 1):
		var state := player(peer_id)
		state["health"] = minf(float(state["health"]), max_health(peer_id))
		_status(peer_id, "Ponto atribuido a %s." % String(stat).replace("_", " ").capitalize())


## Reset de atributos: todos os pontos distribuídos voltam a ficar livres (evoluções ficam).
func reset_stats(peer_id: int) -> bool:
	var build := character_build(peer_id)
	if build == null:
		return false
	var points := build.reset_stats()
	_milestone_cache.erase(String(player(peer_id).get("character_id", "")))
	var state := player(peer_id)
	state["health"] = minf(float(state["health"]), max_health(peer_id))
	_status(peer_id, "Atributos resetados: %d pontos livres para distribuir." % points)
	return true


func choose_milestone(peer_id: int, choice_id: StringName) -> void:
	var build := character_build(peer_id)
	if build != null and build.choose_milestone(choice_id):
		_status(peer_id, "Evolucao escolhida: %s." % String(choice_id).replace("_", " ").capitalize())
		_refresh_milestones(peer_id)
		_process_level_ups(peer_id)


func equip_item(peer_id: int, instance_id: StringName) -> void:
	var state := player(peer_id)
	if state.is_empty():
		return
	var message := _equip(state["character_id"] as StringName, instance_id)
	if not message.is_empty():
		_status(peer_id, message)


func unequip_item(peer_id: int, slot: int, index: int) -> void:
	var gear := _gear(peer_id)
	if gear.is_empty():
		return
	if EquipmentTransaction.unequip_to_inventory(gear["inventory"] as ItemInventory, gear["equipment"] as EquipmentLoadout, slot as EquipmentItemDefinition.Slot, index):
		_status(peer_id, "Equipamento devolvido ao inventario.")


# ---------------------------------------------------------------- passo

## Derived from connected players, so disconnect/reload cannot leave a stale pause flag.
func pending_milestone_peers() -> Array[int]:
	var result: Array[int] = []
	for peer_id: int in players:
		var build := character_build(peer_id)
		if is_connected_player(peer_id) and build != null and build.has_pending_milestone() and not build.milestone_choices.get(build.level, []).is_empty():
			result.append(peer_id)
	result.sort()
	return result


func is_milestone_paused() -> bool:
	return not pending_milestone_peers().is_empty()


func step(delta: float) -> void:
	if is_milestone_paused():
		return
	for peer_id: int in players.keys():
		if not players.has(peer_id):
			continue
		_step_player(peer_id, delta)
		if is_milestone_paused():
			return
	for enemy in enemies:
		enemy["flash"] = maxf(0.0, float(enemy.get("flash", 0.0)) - delta)
		enemy["slow_timer"] = maxf(0.0, float(enemy.get("slow_timer", 0.0)) - delta)
		enemy["vulnerable_timer"] = maxf(0.0, float(enemy.get("vulnerable_timer", 0.0)) - delta)
	_run_scheduled(delta)
	if is_milestone_paused():
		return
	village_life.call("step", delta, _village_context())
	if not _players_in_arena().is_empty():
		_step_floor(delta)
		_apply_party_scaling()
		_update_enemy_projectiles(delta)
		_update_enemies(delta)
		if is_milestone_paused():
			return
		_update_persistent_effects(delta)
		ItemPassivesScript.step_burns(self, delta)
		_step_poisons(delta)
		if is_explore_floor():
			tick_respawns(delta)
			_update_reinforcements(delta)
		_update_threat_spawn()
	_step_narrative_rescue(delta)


func _run_scheduled(delta: float) -> void:
	for index in range(_scheduled.size() - 1, -1, -1):
		var entry := _scheduled[index]
		entry["time"] = float(entry["time"]) - delta
		if float(entry["time"]) > 0.0:
			continue
		_scheduled.remove_at(index)
		var peer_id := int(entry["peer"])
		if players.has(peer_id) and player(peer_id)["zone"] in ARENA_ZONES:
			if int(entry.get("floor", current_floor)) != current_floor or entry.get("zone", player(peer_id)["zone"]) != player(peer_id)["zone"]:
				continue
			execute_gem_effect(peer_id, entry["effect"] as Dictionary, entry["target"] as Vector2)
			if is_milestone_paused():
				return


func _step_barrier(peer_id: int, delta: float) -> void:
	var state := player(peer_id)
	if float(state.get("barrier_timer", 0.0)) <= 0.0:
		return
	state["barrier_timer"] = float(state["barrier_timer"]) - delta
	if float(state.get("barrier_contact_damage", 0.0)) > 0.0:
		state["barrier_contact_tick"] = float(state.get("barrier_contact_tick", 0.0)) - delta
		if float(state["barrier_contact_tick"]) <= 0.0:
			state["barrier_contact_tick"] = 0.5
			damage_enemies(peer_id, state["position"] as Vector2, 40.0, float(state["barrier_contact_damage"]))
	if float(state["barrier_timer"]) <= 0.0:
		state["barrier"] = 0.0
		state["barrier_contact_damage"] = 0.0
		var burst := float(state.get("barrier_expire_damage", 0.0))
		state["barrier_expire_damage"] = 0.0
		if burst > 0.0 and state["zone"] in ARENA_ZONES:
			var radius := float(state.get("barrier_radius", 90.0))
			_vfx(state["zone"], "ring", [state["position"], radius])
			damage_enemies(peer_id, state["position"] as Vector2, radius, burst)


func _step_player(peer_id: int, delta: float) -> void:
	var state := players[peer_id] as Dictionary
	state["breath_hit_budget"] = minf(8.0, float(state.get("breath_hit_budget", 8.0)) + delta * 8.0)
	if bool(state.get("downed", false)):
		_step_downed(peer_id, delta)
		return
	if not bool(state.get("connected", true)):
		state["reconnect_timer"] = float(state["reconnect_timer"]) - delta
		if float(state["reconnect_timer"]) <= 0.0:
			_expire_reservation(peer_id)
		return
	state["transition_cooldown"] = maxf(0.0, float(state["transition_cooldown"]) - delta)
	state["damage_cooldown"] = maxf(0.0, float(state["damage_cooldown"]) - delta)
	state["invulnerable"] = maxf(0.0, float(state["invulnerable"]) - delta)
	state["hurt_flash"] = maxf(0.0, float(state["hurt_flash"]) - delta)
	state["since_damage"] = float(state.get("since_damage", 0.0)) + delta
	if float(state["since_damage"]) >= OUT_OF_COMBAT_DELAY and state["zone"] in ARENA_ZONES:
		state["health"] = minf(max_health(peer_id), float(state["health"]) + max_health(peer_id) * OUT_OF_COMBAT_REGEN * delta)
	var regen := 18.0 * delta * _mod(peer_id, "breath_regen_mult")
	# Canalizar a Saraivada segura o fôlego: sem regenerar, o custo por segundo vale de verdade.
	if persistent_effects.any(func(effect: Dictionary) -> bool: return effect["mechanic"] == "volley" and int(effect["owner_peer"]) == peer_id):
		regen = 0.0
	var overflow := float(state["breath"]) + regen - max_breath(peer_id)
	state["breath"] = minf(max_breath(peer_id), float(state["breath"]) + regen)
	if overflow > 0.0 and state["zone"] in ARENA_ZONES:
		for mechanic in _mechanics(peer_id, "breath_shield"):
			var cap := float(mechanic.get("cap", 40.0))
			if float(state["barrier"]) < cap:
				state["barrier"] = minf(cap, float(state["barrier"]) + overflow)
				state["barrier_timer"] = maxf(float(state.get("barrier_timer", 0.0)), 2.0)
	var timers := state.get("mechanic_timers", {}) as Dictionary
	for key: Variant in timers:
		timers[key] = maxf(0.0, float(timers[key]) - delta)
	var cooldowns := state["cooldowns"] as Array[float]
	var charges := state["charges"] as Array[int]
	var caps := state["charge_caps"] as Array[int]
	for index in range(cooldowns.size()):
		if cooldowns[index] <= 0.0:
			continue
		cooldowns[index] = maxf(0.0, cooldowns[index] - delta)
		if cooldowns[index] <= 0.0:
			charges[index] = mini(caps[index], charges[index] + 1)
			if charges[index] < caps[index]:
				cooldowns[index] = (state["recharge"] as Array[float])[index]
	var previous := state["position"] as Vector2
	var offset := (state["target"] as Vector2) - previous
	if offset.length() > 2.0:
		var speed := PLAYER_SPEED * float(derived_stats(peer_id).get("movement_speed_multiplier", 1.0)) * float((state["passive"] as RefCounted).call("move_speed_multiplier"))
		if state["zone"] == &"tower":
			speed *= 1.0 - _zone_slow(state["position"] as Vector2)
		move_player(peer_id, offset.normalized() * minf(speed * delta, offset.length()))
	var moved := (state["position"] as Vector2) - previous
	state["moving"] = moved.length() > 0.1
	if bool(state["moving"]):
		state["facing_direction"] = moved.normalized()
	if absf(moved.x) > 0.1:
		state["facing_left"] = moved.x < 0.0
	_check_transition(peer_id)
	if not players.has(peer_id) or state["zone"] not in ARENA_ZONES:
		return
	_step_barrier(peer_id, delta)
	ItemPassivesScript.tick(self, peer_id, delta)
	if is_milestone_paused() or not players.has(peer_id) or state["zone"] not in ARENA_ZONES:
		return
	_collect_ground_items(peer_id)
	var passive := state["passive"] as RefCounted
	passive.call("tick", delta)
	_apply_passive_requests(peer_id, passive.call("on_player_moved", state["position"]) as Array)
	state["attack_timer"] = float(state["attack_timer"]) - delta
	state["attack_request_timer"] = maxf(0.0, float(state.get("attack_request_timer", 0.0)) - delta)
	if float(state["attack_timer"]) <= 0.0:
		var weapon := weapon_attack_model(peer_id)
		# Ataque normal: no clique (ou tecla), mirando o ponto pedido, ou automático no inimigo mais
		# próximo quando a personagem deixa o ataque automático ligado.
		var manual := float(state["attack_request_timer"]) > 0.0
		var nearest := -1
		var aim := Vector2.ZERO
		if manual:
			aim = state["attack_request"] as Vector2
			nearest = _enemy_near_aim(state["position"] as Vector2, aim, float(weapon["range"]))
		elif bool(state.get("auto_attack", true)):
			nearest = nearest_enemy_to(state["position"] as Vector2, float(weapon["range"]))
		if (nearest >= 0 or manual) and float(state["breath"]) >= float(weapon.get("breath_cost", 0.0)):
			state["breath"] = float(state["breath"]) - float(weapon.get("breath_cost", 0.0))
			# Sem inimigo ao alcance, o golpe manual sai na direção mirada até o alcance da arma.
			var first := (state["position"] as Vector2) + (state.get("facing_direction", Vector2.RIGHT) as Vector2) * float(weapon["range"])
			if nearest >= 0:
				first = enemies[nearest]["position"] as Vector2
			elif aim.distance_to(state["position"] as Vector2) >= 1.0:
				first = (state["position"] as Vector2) + (state["position"] as Vector2).direction_to(aim) * float(weapon["range"])
			_vfx(state["zone"], "travel", ["vfx/bolt", (state["position"] as Vector2) - Vector2(0.0, 14.0), first, 0.07, 9.0])
			var damage := float(weapon["damage"])
			var imprint := {"crit_add": weapon["crit_add"], "damage_type": weapon["damage_type"], "knockback": weapon.get("knockback", 0.0), "vulnerable": weapon.get("vulnerable", 0.0), "vulnerable_duration": weapon.get("vulnerable_duration", 0.0)}
			for key in ["life_steal", "breath_per_hit", "barrier_per_hit"]:
				imprint[key] = weapon.get(key, 0.0)
			for mechanic in _mechanics(peer_id, "auto_imprint"):
				var last := state.get("last_hit", {}) as Dictionary
				for key: String in ["slow", "slow_duration", "vulnerable", "vulnerable_duration", "life_steal"]:
					if last.has(key):
						imprint[key] = float(last[key]) * (float(mechanic.get("ratio", 1.0)) if key in ["slow", "vulnerable", "life_steal"] else 1.0)
			var extra_targets: Array[Vector2] = []
			for mechanic in _mechanics(peer_id, "auto_chain"):
				for enemy in enemies:
					var spot := enemy["position"] as Vector2
					if spot != first and spot.distance_to(first) <= 150.0 and extra_targets.size() < int(mechanic.get("targets", 1)):
						extra_targets.append(spot)
			var origin := state["position"] as Vector2
			var direction := origin.direction_to(first)
			match String(weapon["pattern"]):
				"line":
					var end := origin + direction * float(weapon["range"])
					_vfx(state["zone"], "chain", [[origin, end] as Array[Vector2]])
					_damage_segment(peer_id, origin, end, float(weapon["width"]), damage, int(weapon["targets"]), imprint)
				"cone":
					_vfx(state["zone"], "cone", [origin, direction, float(weapon["range"]), float(weapon["angle"])])
					for index in range(enemies.size() - 1, -1, -1):
						if index < enemies.size() and SkillGeometryScript.in_cone(enemies[index]["position"] as Vector2, origin, direction, float(weapon["range"]), float(weapon["angle"])):
							damage_enemy(peer_id, index, damage, imprint)
				_:
					if int(weapon.get("projectile_count", 0)) > 0 or int(weapon.get("pierce", 0)) > 0 or int(weapon.get("ricochet", 0)) > 0 or bool(weapon.get("return_projectile", false)) or int(weapon.get("fork_count", 0)) > 0 or float(weapon.get("impact_area", 0.0)) > 0.0:
						_cast_projectiles(peer_id, weapon, first, imprint)
					elif nearest >= 0:
						damage_enemy(peer_id, nearest, damage, imprint)
			for spot in extra_targets:
				var chained := nearest_enemy_to(spot, 4.0)
				if chained >= 0:
					_vfx(state["zone"], "chain", [[first, spot] as Array[Vector2]])
					damage_enemy(peer_id, chained, damage * float(_mechanics(peer_id, "auto_chain")[0].get("ratio", 0.5)), imprint)
			state["attack_timer"] = float(weapon["interval"])


## Liga ou desliga o ataque normal automático da personagem (preferência de cada jogador).
func set_auto_attack(peer_id: int, enabled: bool) -> void:
	var state := player(peer_id)
	if not state.is_empty():
		state["auto_attack"] = enabled


## Pede um ataque normal mirando um ponto (clique ou tecla). Segurar renova o pedido; o golpe sai
## quando a cadência da arma permite.
func request_attack(peer_id: int, aim: Vector2) -> void:
	var state := player(peer_id)
	if state.is_empty() or not aim.is_finite():
		return
	state["attack_request"] = aim
	state["attack_request_timer"] = ATTACK_REQUEST_WINDOW


## Inimigo ao alcance da arma mais próximo do ponto mirado (-1 se nenhum).
func _enemy_near_aim(origin: Vector2, aim: Vector2, reach: float) -> int:
	var result := -1
	var best := INF
	for index in range(enemies.size()):
		var spot := enemies[index]["position"] as Vector2
		if origin.distance_to(spot) > reach:
			continue
		var distance := aim.distance_squared_to(spot)
		if distance < best:
			best = distance
			result = index
	return result


# ---------------------------------------------------------------- movimento e zonas

func move_player(peer_id: int, motion: Vector2) -> void:
	var state := player(peer_id)
	var position := state["position"] as Vector2
	var zone := state["zone"] as StringName
	var candidate_x := position + Vector2(motion.x, 0.0)
	if can_stand(zone, candidate_x):
		position.x = candidate_x.x
	var candidate_y := position + Vector2(0.0, motion.y)
	if can_stand(zone, candidate_y):
		position.y = candidate_y.y
	state["position"] = position


func can_stand(zone: StringName, position: Vector2) -> bool:
	if zone == &"tower":
		return not floor_layout.is_empty() and FloorLayoutScript.can_stand(floor_layout, position, PLAYER_RADIUS)
	var bounds := Rect2(Vector2(PLAYER_RADIUS, PLAYER_RADIUS), LayoutScript.map_size(zone) - Vector2.ONE * PLAYER_RADIUS * 2.0)
	if not bounds.has_point(position):
		return false
	for obstacle in LayoutScript.obstacles(zone, village_progress):
		if obstacle.grow(PLAYER_RADIUS).has_point(position):
			return false
	return true


## Ponto livre mais próximo em espiral: chegada dentro de colisão (mapa mudou, save antigo)
## prenderia a personagem, já que todo movimento a partir dali é recusado.
func nearest_standable(zone: StringName, position: Vector2) -> Vector2:
	if can_stand(zone, position):
		return position
	for ring in range(1, 16):
		for step in range(ring * 8):
			var candidate := position + Vector2.RIGHT.rotated(TAU * float(step) / float(ring * 8)) * float(ring) * 12.0
			if can_stand(zone, candidate):
				return candidate
	return position


func _zone_size(zone: StringName) -> Vector2:
	if zone == &"tower" and not floor_layout.is_empty():
		return floor_layout["size"] as Vector2
	return LayoutScript.map_size(zone)


func _place(peer_id: int, zone: StringName, position: Vector2, cooldown: float = 0.5) -> void:
	var state := player(peer_id)
	if zone != &"tower":
		position = nearest_standable(zone, position)
	state["zone"] = zone
	state["position"] = position
	state["target"] = position
	state["transition_cooldown"] = cooldown


func _check_transition(peer_id: int) -> void:
	var state := player(peer_id)
	if float(state["transition_cooldown"]) > 0.0:
		return
	var position := state["position"] as Vector2
	match state["zone"]:
		&"village":
			if LayoutScript.HOUSE_DOOR.grow(PLAYER_RADIUS).has_point(position):
				enter_house(peer_id)
			elif LayoutScript.TOWER_DOOR.grow(PLAYER_RADIUS).has_point(position):
				enter_tower(peer_id)
		&"house":
			if LayoutScript.INTERIOR_EXIT.has_point(position):
				leave_house(peer_id)
		&"tower":
			if (floor_layout["return_portal"] as Rect2).grow(PLAYER_RADIUS).has_point(position):
				if boss_alive():
					_status(peer_id, "A arena permanece selada enquanto o chefe estiver de pe.")
					state["transition_cooldown"] = 0.8
				else:
					leave_tower(peer_id)
			elif bool(floor_run.get("stairs_open", false)) and (floor_layout["stairs"] as Rect2).grow(PLAYER_RADIUS).has_point(position):
				descend(peer_id)


func enter_house(peer_id: int) -> void:
	player(peer_id)["last_world_position"] = LayoutScript.HOUSE_RETURN
	_place(peer_id, &"house", Vector2(640.0, 570.0))
	_status(peer_id, "Interior carregado. O estado da vila permanece preservado.")


func leave_house(peer_id: int) -> void:
	_place(peer_id, &"village", player(peer_id)["last_world_position"] as Vector2)
	_status(peer_id, "Voce voltou ao mesmo ponto de Aresta.")


func enter_tower(peer_id: int) -> void:
	var state := player(peer_id)
	state["health"] = max_health(peer_id)
	state["breath"] = max_breath(peer_id)
	refresh_charges(peer_id)
	if _players_in_arena().is_empty():
		start_floor(clampi(tower_start_floor, 1, deepest_floor))
	var offset := float(_players_in_arena().size()) * 26.0
	_place(peer_id, &"tower", (floor_layout["entry"] as Vector2) + Vector2(offset - 30.0, 0.0), 0.8)
	_note_party_peak()
	_status(peer_id, "Andar %d: %s." % [current_floor, String(floor_def().get("name", ""))])


func leave_tower(peer_id: int) -> void:
	var state := player(peer_id)
	if state.get("zone", &"") == &"tower":
		narrative.record_return("retreat")
	state["falls"] = 0
	state["wounds"] = 0
	state["downed"] = false
	_place(peer_id, &"village", LayoutScript.TOWER_RETURN)
	var delivered := int(state["carried_stone"])
	banked_stone += delivered
	_merge_loot(banked_loot, state["carried_loot"] as Dictionary)
	(state["carried_loot"] as Dictionary).clear()
	state["carried_stone"] = 0
	var sale := _auto_sell(peer_id)
	_clear_owned_effects(peer_id)
	if _players_in_arena().is_empty():
		enemy_projectiles.clear()
	_event({"type": "clear_vfx", "peer": peer_id})
	if _players_in_arena().is_empty():
		village_life.call("advance_period")
		_restock_shop()
	village_life.call("remember_event", "retorno", "%s voltou da Torre trazendo %d pedras; o grupo chegou ao andar %d" % [String(state["character_name"]), delivered, deepest_floor], 0.4, String(state["character_id"]))
	if banked_stone >= 3 and village_progress == 0:
		village_progress = 1
		village_life.call("remember_event", "reforco", "um reforco foi erguido em Aresta com a pedra trazida da Torre", 0.6)
		_status(peer_id, "Relatorio: %d pedras entregues. Um reforco foi construido.%s" % [delivered, sale])
	else:
		_status(peer_id, "Relatorio: %d pedras entregues. Total armazenado: %d.%s" % [delivered, banked_stone, sale])


## Fatos verdadeiros e jogadores visíveis entregues aos moradores.
func narrative_marker() -> Vector2:
	return (FloorLayoutScript.generate(1)["route"] as Array)[1] as Vector2


func narrative_action(peer_id: int, action: String) -> bool:
	var state := player(peer_id)
	if state.is_empty() or not bool(state.get("connected", false)) or bool(state.get("downed", false)):
		return false
	if action == "rescue_worker":
		if narrative.stage == "available" or narrative.rescue_state != "waiting" or state["zone"] != &"tower" or current_floor != 1:
			return false
		if (state["position"] as Vector2).distance_to(narrative_worker_position()) > 90:
			return false
		narrative.rescue_state = "escorting"
		_status(peer_id, "Acompanhe o trabalhador ate o portal. Afaste os inimigos; ele espera se voce se afastar.")
		return true
	if action == "inspect":
		if state["zone"] != &"tower" or current_floor != 1 or (state["position"] as Vector2).distance_to(narrative_marker()) > 90.0:
			return false
		if not narrative.inspect():
			return false
		_status(peer_id, "Observacao registrada no diario. Retorne a Aresta.")
		return true
	var npc_id := "alda_serrin" if action == "acknowledge_crisis" else "nara_quiral"
	var npc: Dictionary = village_life.call("find", npc_id)
	if state["zone"] != &"village" or npc.is_empty() or (state["position"] as Vector2).distance_to(npc["position"] as Vector2) > 110.0:
		return false
	if action == "acknowledge_crisis" and narrative.acknowledge_crisis():
		_status(peer_id, "Pedido de Alda registrado. Nara recebe o grupo na Casa das Expedicoes.")
		return true
	if action == "prepare_first_floor" and narrative.stage == "active":
		return set_start_floor(peer_id, 1)
	if action == "accept" and narrative.accept():
		_status(peer_id, "Pedido aceito: registro da primeira rota, andar 1.")
		return true
	if action == "report" and narrative.report():
		var reward: Dictionary = narrative.catalog()["reward"]
		var item_id := String(reward["item_id"])
		banked_loot[item_id] = int(banked_loot.get(item_id, 0)) + int(reward["quantity"])
		_status(peer_id, "Relato entregue. Musgo de Orientacao armazenado.")
		return true
	return false


func narrative_view() -> Dictionary:
	var model := narrative.view()
	if narrative.stage == "active" and current_floor == 1:
		model["marker_position"] = narrative_marker()
	if narrative.stage != "available" and current_floor == 1 and narrative.rescue_state != "rescued":
		var position := narrative_worker_position()
		model["field_worker"] = {"id": "ra_socorro", "name": "Trabalhador", "title": "Retirada pela rota registrada", "sprite": "npcs/comum_trabalhador", "position": position, "named": true, "moving": _narrative_rescue_can_move(position), "facing_direction": (_narrative_rescue_destination() - position).normalized(), "rescue_state": narrative.rescue_state}
		model["field_objective"] = "Trabalhador pede ajuda perto da primeira marca. Acompanhar a retirada e opcional." if narrative.rescue_state == "waiting" else "Acompanhe o trabalhador ate o portal. Ele espera sem companhia ou com inimigos por perto."
	return model


func _narrative_rescue_destination() -> Vector2:
	return (FloorLayoutScript.generate(1)["return_portal"] as Rect2).get_center()


func _narrative_rescue_start() -> Vector2:
	return narrative_marker() + Vector2(0, -80)


func narrative_worker_position() -> Vector2:
	var layout := FloorLayoutScript.generate(1)
	var entry: Vector2 = layout["entry"]
	var start := _narrative_rescue_start()
	var destination := _narrative_rescue_destination()
	var first_length := start.distance_to(entry)
	var distance := narrative.rescue_progress * (first_length + entry.distance_to(destination))
	return start.move_toward(entry, distance) if distance <= first_length else entry.move_toward(destination, distance - first_length)


func _narrative_rescue_can_move(position: Vector2) -> bool:
	if current_floor != 1 or narrative.rescue_state != "escorting":
		return false
	var accompanied := false
	for state: Dictionary in players.values():
		if state.get("connected", false) and not state.get("downed", false) and state["zone"] == &"tower" and (state["position"] as Vector2).distance_to(position) <= 160:
			accompanied = true
	if not accompanied:
		return false
	for enemy: Dictionary in enemies:
		if float(enemy.get("health", 0)) > 0 and (enemy["position"] as Vector2).distance_to(position) < 180:
			return false
	return true


func _step_narrative_rescue(delta: float) -> void:
	if not is_finite(delta) or delta <= 0 or not _narrative_rescue_can_move(narrative_worker_position()):
		return
	var layout := FloorLayoutScript.generate(1)
	var distance := _narrative_rescue_start().distance_to(layout["entry"]) + (layout["entry"] as Vector2).distance_to(_narrative_rescue_destination())
	# Follow the protected route using host time, never a client-provided position.
	narrative.rescue_progress = minf(1, narrative.rescue_progress + minf(delta, 0.25) * 85 / maxf(1, distance))
	if narrative.rescue_progress >= 1 or (layout["return_portal"] as Rect2).grow(PLAYER_RADIUS).has_point(narrative_worker_position()):
		narrative.rescue_progress = 1
		narrative.rescue_state = "rescued"
		village_life.call("remember_event", "socorro_primeira_rota", "um trabalhador alcancou o portal acompanhado pelo grupo", 0.5)
		for peer_id: int in players:
			_status(peer_id, "Resgate confirmado: o trabalhador alcancou o portal. Registro preservado no diario.")


func expedition_preparation(peer_id: int) -> Array[String]:
	var state := player(peer_id)
	if state.is_empty():
		return []
	var integrity := 1.0
	var gear := _gear(peer_id)
	for spec: Array in LayoutScript.equipment_slot_specs():
		var item := (gear["equipment"] as EquipmentLoadout).get_equipped(spec[1], int(spec[2]))
		if item != null:
			integrity = minf(integrity, item.integrity)
	var preparation: Array[String] = [
		"Condicao: Vida %d/%d; Folego %d/%d; ferimentos %d. Enfermaria: Maura." % [int(state["health"]), int(max_health(peer_id)), int(state["breath"]), int(max_breath(peer_id)), int(state.get("wounds", 0))],
		"Suprimentos de cura: %d/9. Comercio: Cassio; alquimia: Sira." % int(state["quick_items"]),
		"Menor integridade equipada: %d%%. Oficina: Dalia." % int(round(integrity * 100.0)),
		"Proxima entrada: andar %d. Portao junto ao posto da guarda." % tower_start_floor,
	]
	if not _players_in_arena().is_empty():
		preparation.append("Grupo na Torre: andar %d. O andar escolhido vale quando a Torre estiver vazia; entrar agora acompanha o grupo." % current_floor)
	return preparation


func _village_context() -> Dictionary:
	var visible := {}
	for peer_id: int in players:
		var state := players[peer_id] as Dictionary
		if state["zone"] == &"village" and bool(state.get("connected", true)):
			visible[peer_id] = {"name": String(state["character_name"]), "position": state["position"]}
	return {"players": visible, "world": {"deepest_floor": deepest_floor, "banked_stone": banked_stone, "village_progress": village_progress}}


## Conversa iniciada por um jogador perto de um morador.
func talk_to_npc(peer_id: int, npc_id: String) -> bool:
	return bool(village_life.call("talk", npc_id, peer_id, _village_context()))


func use_village_service(peer_id: int, npc_id: String, offer_id: String) -> bool:
	var state := player(peer_id)
	var npc := village_life.call("find", npc_id) as Dictionary
	var offer := preload("res://src/gameplay/world/village_services.gd").offer(npc_id, offer_id)
	if state.is_empty() or npc.is_empty() or offer.is_empty() or not is_connected_player(peer_id):
		return false
	if state["zone"] != &"village" or bool(state.get("downed", false)) or (state["position"] as Vector2).distance_to(npc["position"] as Vector2) > 110.0:
		return false
	var gear := _gear(peer_id)
	var stock: Dictionary = village_life.economy.stock
	var materials := offer["materials"] as Dictionary
	if int(gear["silver"]) < int(offer["price"]):
		_status(peer_id, "Prata insuficiente.")
		return false
	for resource: String in materials:
		if int(stock.get(resource, 0)) < int(materials[resource]):
			_status(peer_id, "O armazem precisa de mais %s." % resource)
			return false
	var effect := String(offer["effect"])
	var repair_items: Array[EquipmentItemInstance] = []
	if effect == "supply" and int(state["quick_items"]) + int(offer["quantity"]) > 9:
		_status(peer_id, "A bolsa comporta ate 9 suprimentos.")
		return false
	if effect == "heal" and float(state["health"]) >= max_health(peer_id) and float(state["breath"]) >= max_breath(peer_id) and int(state.get("wounds", 0)) == 0:
		_status(peer_id, "Voce ja esta recuperado.")
		return false
	if effect == "repair":
		for item: EquipmentItemInstance in (gear["inventory"] as ItemInventory).items.values():
			if item.integrity < 1.0:
				repair_items.append(item)
		for spec in LayoutScript.equipment_slot_specs():
			var item := (gear["equipment"] as EquipmentLoadout).get_equipped(spec[1], int(spec[2]))
			if item != null and item.integrity < 1.0:
				repair_items.append(item)
		if repair_items.is_empty():
			_status(peer_id, "Seu equipamento nao precisa de reparos.")
			return false
	# Validate the entire transaction before spending shared reserves or personal silver.
	gear["silver"] = int(gear["silver"]) - int(offer["price"])
	for resource: String in materials:
		stock[resource] = int(stock[resource]) - int(materials[resource])
	match effect:
		"supply":
			state["quick_items"] = int(state["quick_items"]) + int(offer["quantity"])
		"heal":
			state["wounds"] = 0
			state["health"] = max_health(peer_id)
			state["breath"] = max_breath(peer_id)
		"repair":
			for item in repair_items:
				item.integrity = 1.0
	_status(peer_id, "%s: %s." % [String(npc["name"]), String(offer["name"])])
	return true


func resolve_npc_request(request_id: int, action_id: String, speech: String) -> bool:
	return bool(village_life.call("resolve_request", request_id, action_id, speech, _village_context()))


func arena_zone() -> StringName:
	return &"tower"


func floor_def() -> Dictionary:
	return TowerContentScript.floor_def(maxi(1, current_floor))


func is_explore_floor() -> bool:
	return current_floor > 0 and String(floor_def().get("kind", "explore")) == "explore"


func boss_alive() -> bool:
	for enemy in enemies:
		if bool(enemy.get("floor_boss", false)):
			return true
	return false


# ---------------------------------------------------------------- andares

## Prepara um andar: layout determinístico, população inicial, chefe e cronômetro da corrida.
func start_floor(number: int) -> void:
	current_floor = clampi(number, 1, TowerContentScript.MAX_FLOOR)
	deepest_floor = maxi(deepest_floor, current_floor)
	floor_layout = FloorLayoutScript.generate(current_floor)
	_floor_random.seed = hash([encounter_seed, current_floor, loot_kill_sequence])
	enemies.clear()
	enemy_projectiles.clear()
	persistent_effects.clear()
	telegraphs.clear()
	hazard_zones.clear()
	respawn.call("clear")
	_hazard_timer = 6.0
	var definition := floor_def()
	floor_run = {
		"floor": current_floor, "time": 0.0, "kills": 0, "party_peak": 1,
		"quota": int(definition.get("kill_quota", 0)), "quota_base": int(definition.get("kill_quota", 0)), "stairs_open": false, "recorded": false,
		"boss_fight": false,
	}
	if is_explore_floor():
		_spawn_floor_population()
	else:
		# Sem recarga (decisão 587): o guardião volta sempre que o grupo entra no andar.
		_spawn_floor_boss()
		floor_run["boss_fight"] = true


func _spawn_floor_population() -> void:
	var points := floor_layout.get("spawn_points", []) as Array
	if points.is_empty():
		return
	var packs := int(floor_def().get("packs", 20))
	for pack in range(packs):
		var center := points[_floor_random.randi_range(0, points.size() - 1)] as Vector2
		for member in range(_floor_random.randi_range(2, 4)):
			var spot := center + Vector2.RIGHT.rotated(_floor_random.randf() * TAU) * _floor_random.randf_range(10.0, 70.0)
			if FloorLayoutScript.can_stand(floor_layout, spot, 16.0):
				enemies.append(_spawn_floor_enemy(_pick_floor_enemy(member == 0), spot, pack * 7 + member))
	floor_run["population"] = enemies.size()


## Definições do bioma do andar; o primeiro de cada matilha pode ser elite.
func _pick_floor_enemy(allow_elite: bool) -> Dictionary:
	var biome := TowerContentScript.biome(String(floor_def().get("biome", "galerias")))
	var commons: Array[Dictionary] = []
	var elites: Array[Dictionary] = []
	for enemy_id: Variant in biome.get("enemies", []) as Array:
		var definition := _find(_collection("enemies"), String(enemy_id))
		if definition.is_empty():
			continue
		if String(definition.get("encounter_class", "common")) == "elite":
			elites.append(definition)
		elif String(definition.get("encounter_class", "common")) == "common":
			commons.append(definition)
	var elite_chance := 0.12 + 0.002 * float(current_floor)
	if allow_elite and not elites.is_empty() and _floor_random.randf() < elite_chance:
		return elites[_floor_random.randi_range(0, elites.size() - 1)]
	if commons.is_empty():
		return _enemy_definitions()[0]
	return commons[_floor_random.randi_range(0, commons.size() - 1)]


## Cria o inimigo com a escala de profundidade do andar e um território para patrulhar.
func _spawn_floor_enemy(definition: Dictionary, position: Vector2, roll_index: int) -> Dictionary:
	var enemy := create_enemy(definition, position, roll_index + current_floor * 1000)
	var floor_info := floor_def()
	if String(definition.get("mechanic", "")) != "boss_kit" and String(definition.get("encounter_class", "")) != "boss":
		enemy["health"] = float(enemy["health"]) * float(floor_info.get("health_multiplier", 1.0))
		enemy["max_health"] = float(enemy["max_health"]) * float(floor_info.get("health_multiplier", 1.0))
		enemy["damage"] = float(enemy["damage"]) * float(floor_info.get("damage_multiplier", 1.0))
	enemy["home"] = position
	enemy["wander_target"] = position
	enemy["wander_timer"] = _floor_random.randf_range(0.0, 2.5)
	enemy["roamer"] = _floor_random.randf() < 0.3
	return enemy


func _spawn_floor_boss() -> void:
	var boss_kit := {}
	for entry in TowerContentScript.collection("bosses"):
		if int(entry.get("floor", 0)) == current_floor:
			boss_kit = entry
	if boss_kit.is_empty():
		return
	var definition := _find(_collection("enemies"), String(boss_kit["id"])).duplicate(true)
	definition["health"] = float(boss_kit.get("health", definition.get("health", 900.0)))
	definition["damage"] = float(boss_kit.get("damage", definition.get("damage", 24.0)))
	definition["speed"] = float(boss_kit.get("speed", definition.get("speed", 36.0)))
	var boss := _spawn_floor_enemy(definition, floor_layout["boss_spawn"] as Vector2, 9000)
	boss["base_mechanic"] = "boss_kit"
	boss["floor_boss"] = true
	boss["kit"] = boss_kit.get("abilities", []).duplicate(true)
	boss["phases"] = boss_kit.get("phases", [0.5]).duplicate()
	boss["enrage"] = float(boss_kit.get("enrage", 200.0))
	boss["fight_time"] = 0.0
	boss["phase"] = 0
	boss["cast_lock"] = 2.0
	boss["kit_timers"] = {}
	enemies.append(boss)
	_status(0, "%s desperta. A arena selou a saida." % String(boss_kit.get("name", "O guardiao")))


func _step_floor(delta: float) -> void:
	if floor_run.is_empty():
		return
	if not bool(floor_run.get("recorded", false)):
		floor_run["time"] = float(floor_run["time"]) + delta
	if is_explore_floor() and not bool(floor_run.get("stairs_open", false)) and survival_left() <= 0.0:
		floor_run["stairs_open"] = true
		_announce_stairs()
		_status(0, "Voces sobreviveram %d minutos. A escada para o andar %d se abriu." % [int(FLOOR_SURVIVAL_SECONDS / 60.0), mini(current_floor + 1, TowerContentScript.MAX_FLOOR)])
	_note_party_peak()
	_update_telegraphs(delta)
	_update_hazard_zones(delta)
	if is_explore_floor():
		_hazard_timer -= delta
		if _hazard_timer <= 0.0:
			var hazard := TowerContentScript.biome(String(floor_def().get("biome", ""))).get("hazard", {}) as Dictionary
			_hazard_timer = float(hazard.get("interval", 7.0)) * _floor_random.randf_range(0.8, 1.25)
			_cast_hazard(hazard)


func _note_party_peak() -> void:
	if floor_run.is_empty():
		return
	var connected := 0
	for peer_id in _players_in_arena():
		if is_connected_player(peer_id):
			connected += 1
	floor_run["party_peak"] = clampi(maxi(int(floor_run.get("party_peak", 1)), connected), 1, MAX_PLAYERS)


## Abate contado para a cota do andar; ao completar, a escada para baixo se abre.
func _register_floor_kill(enemy: Dictionary) -> void:
	if floor_run.is_empty():
		return
	if bool(enemy.get("floor_boss", false)):
		_grant_boss_gems(current_floor)
		_finish_floor_run()
		floor_run["stairs_open"] = true
		_announce_stairs()
		_status(0, "Guardiao vencido em %s. A passagem se abriu." % format_time(float(floor_run["time"])))
		return
	floor_run["kills"] = int(floor_run["kills"]) + 1


## Segundos que faltam para a escada de um andar comum se abrir (0 quando já pode).
func survival_left() -> float:
	return maxf(0.0, FLOOR_SURVIVAL_SECONDS - float(floor_run.get("time", 0.0)))


## Desce com todo o grupo do andar. O tempo dos andares comuns vai até a descida.
func descend(peer_id: int) -> void:
	if is_explore_floor():
		_finish_floor_run()
	if current_floor >= TowerContentScript.MAX_FLOOR:
		for member in _players_in_arena():
			leave_tower(member)
		_status(0, "A Sala Sem Numero ficou para tras. O grupo retorna a Aresta.")
		return
	var members := _players_in_arena()
	start_floor(current_floor + 1)
	var offset := 0.0
	for member in members:
		_place(member, &"tower", (floor_layout["entry"] as Vector2) + Vector2(offset - 30.0, 0.0), 0.8)
		_event({"type": "clear_vfx", "peer": member})
		offset += 26.0
	_note_party_peak()
	_status(0, "Andar %d: %s." % [current_floor, String(floor_def().get("name", ""))])


## Registra o tempo da corrida nos recordes do modo (solo, duo, trio ou squad) e avisa recordes novos.
func _finish_floor_run() -> void:
	if bool(floor_run.get("recorded", false)) or (not is_explore_floor() and not bool(floor_run.get("boss_fight", false))):
		return
	floor_run["recorded"] = true
	var mode := RECORD_MODES[clampi(int(floor_run.get("party_peak", 1)), 1, MAX_PLAYERS) - 1]
	var time := float(floor_run["time"])
	var characters: Array[String] = []
	for member in _players_in_arena():
		characters.append(String(player(member).get("character_name", "")))
	var entry := {"time": snappedf(time, 0.01), "characters": characters, "date": Time.get_date_string_from_system()}
	var floor_key := str(current_floor)
	var by_floor := records.get(floor_key, {}) as Dictionary
	var list := (by_floor.get(mode, []) as Array).duplicate()
	var previous_best := float((list[0] as Dictionary)["time"]) if not list.is_empty() else INF
	list.append(entry)
	list.sort_custom(func(left: Variant, right: Variant) -> bool: return float((left as Dictionary)["time"]) < float((right as Dictionary)["time"]))
	by_floor[mode] = list.slice(0, RECORDS_PER_MODE)
	records[floor_key] = by_floor
	var best := time < previous_best
	_event({"type": "record", "floor": current_floor, "mode": mode, "time": time, "best": best})
	if best:
		_status(0, "NOVO RECORDE %s no andar %d: %s." % [mode.to_upper(), current_floor, format_time(time)])
		village_life.call("remember_event", "recorde", "o grupo bateu o recorde %s do andar %d" % [mode, current_floor], 0.5)


static func format_time(seconds: float) -> String:
	return "%d:%05.2f" % [int(seconds) / 60, fmod(seconds, 60.0)]


func best_time(floor_number: int, mode: String) -> float:
	var list := (records.get(str(floor_number), {}) as Dictionary).get(mode, []) as Array
	return float((list[0] as Dictionary)["time"]) if not list.is_empty() else -1.0


func record_mode() -> String:
	return RECORD_MODES[clampi(int(floor_run.get("party_peak", 1)), 1, MAX_PLAYERS) - 1]


## Andar de partida escolhido em Aresta (até o mais fundo já alcançado).
func set_start_floor(peer_id: int, number: int) -> bool:
	if player(peer_id).get("zone") == &"tower" or number < 1 or number > deepest_floor:
		return false
	tower_start_floor = number
	_status(0, "Proxima entrada na Torre: andar %d." % number)
	return true


func _players_in_zone(zone: StringName) -> Array[int]:
	var result: Array[int] = []
	for peer_id: int in players:
		if (players[peer_id] as Dictionary)["zone"] == zone:
			result.append(peer_id)
	return result


func _players_in_arena() -> Array[int]:
	return _players_in_zone(arena_zone())


# ---------------------------------------------------------------- inimigos

func create_enemy(definition: Dictionary, position: Vector2, roll_index: int) -> Dictionary:
	var race := _find(_collection("monster_races"), String(definition.get("race_id", "juntideo")))
	var rank := _find(_collection("enemy_ranks"), String(definition.get("rank_id", "maduro")))
	var maximum_health := maxf(1.0, float(definition.get("health", 60.0)) * ENEMY_HEALTH_MULT)
	var enemy := {
		"definition_id": String(definition.get("id", "raspador_padrao")),
		"display_name": String(definition.get("name", "Raspador")),
		"encounter_class": String(definition.get("encounter_class", "common")),
		"race_id": String(definition.get("race_id", "juntideo")),
		"rank_id": String(definition.get("rank_id", "maduro")),
		"race_trait": String(race.get("trait", "")),
		"kind": String(definition.get("kind", "melee")),
		"base_mechanic": String(definition.get("mechanic", "swarm")),
		"position": position,
		"health": maximum_health,
		"max_health": maximum_health,
		"speed": maxf(0.0, float(definition.get("speed", 42.0)) * ENEMY_SPEED_MULT),
		"damage": maxf(0.0, float(definition.get("damage", 12.0))),
		"attack_interval": maxf(0.05, float(definition.get("attack_interval", 0.8))),
		"loot_value": maxi(0, int(definition.get("loot_value", 1))),
		"loot_table_id": String(definition.get("loot_table_id", "")),
		"allow_affixes": bool(definition.get("allow_affixes", true)),
		"prefix_id": "",
		"suffix_id": "",
		"modifier_mechanics": [],
		"shield_hits": 0,
		"action_timer": float(definition.get("attack_interval", 0.8)),
		"awakened": false,
		"hits_received": 0,
		"minimum_affixes": int(rank.get("minimum_affixes", 0)),
		"maximum_affixes": int(rank.get("maximum_affixes", 1)),
	}
	_apply_race_profile(enemy, race)
	_apply_rank(enemy, rank)
	_roll_modifiers(enemy, _enemy_modifiers(), roll_index)
	return enemy


func _apply_rank(enemy: Dictionary, rank: Dictionary) -> void:
	enemy["max_health"] = maxf(1.0, float(enemy["max_health"]) * maxf(0.05, float(rank.get("health_multiplier", 1.0))))
	enemy["health"] = enemy["max_health"]
	enemy["damage"] = maxf(0.0, float(enemy["damage"]) * maxf(0.05, float(rank.get("damage_multiplier", 1.0))))
	enemy["speed"] = maxf(0.0, float(enemy["speed"]) * maxf(0.05, float(rank.get("speed_multiplier", 1.0))))
	enemy["loot_value"] = maxi(0, int(ceil(float(enemy["loot_value"]) * maxf(0.0, float(rank.get("loot_multiplier", 1.0))))))


func _apply_race_profile(enemy: Dictionary, race: Dictionary) -> void:
	var profile := race.get("stat_profile", {}) as Dictionary
	enemy["max_health"] = maxf(1.0, float(enemy["max_health"]) * maxf(0.05, float(profile.get("health", 1.0))))
	enemy["health"] = enemy["max_health"]
	enemy["damage"] = maxf(0.0, float(enemy["damage"]) * maxf(0.05, float(profile.get("damage", 1.0))))
	enemy["speed"] = maxf(0.0, float(enemy["speed"]) * maxf(0.05, float(profile.get("speed", 1.0))))
	enemy["attack_interval"] = maxf(0.05, float(enemy["attack_interval"]) * maxf(0.05, float(profile.get("attack_interval", 1.0))))
	enemy["action_timer"] = enemy["attack_interval"]


func _roll_modifiers(enemy: Dictionary, modifiers: Array[Dictionary], spawn_index: int) -> void:
	if modifiers.is_empty() or not bool(enemy.get("allow_affixes", true)):
		return
	var random := RandomNumberGenerator.new()
	random.seed = encounter_seed + spawn_index * 101
	var prefixes: Array[Dictionary] = []
	var suffixes: Array[Dictionary] = []
	for modifier in modifiers:
		if String(modifier.get("position", "prefix")) == "suffix":
			suffixes.append(modifier)
		else:
			prefixes.append(modifier)
	var minimum_affixes := clampi(int(enemy.get("minimum_affixes", 0)), 0, 2)
	var maximum_affixes := clampi(int(enemy.get("maximum_affixes", 1)), minimum_affixes, 2)
	var affix_count := random.randi_range(minimum_affixes, maximum_affixes)
	if affix_count == 1:
		if (random.randf() < 0.5 or suffixes.is_empty()) and not prefixes.is_empty():
			apply_enemy_modifier(enemy, _choose_weighted(prefixes, random))
		elif not suffixes.is_empty():
			apply_enemy_modifier(enemy, _choose_weighted(suffixes, random))
	elif affix_count >= 2:
		if not prefixes.is_empty():
			apply_enemy_modifier(enemy, _choose_weighted(prefixes, random))
		if not suffixes.is_empty():
			apply_enemy_modifier(enemy, _choose_weighted(suffixes, random))


func _choose_weighted(pool: Array[Dictionary], random: RandomNumberGenerator) -> Dictionary:
	var total_weight := 0.0
	for modifier in pool:
		total_weight += maxf(0.0, float(modifier.get("weight", 1.0)))
	if total_weight <= 0.0:
		return pool[0]
	var roll := random.randf_range(0.0, total_weight)
	for modifier in pool:
		roll -= maxf(0.0, float(modifier.get("weight", 1.0)))
		if roll <= 0.0:
			return modifier
	return pool.back()


func apply_enemy_modifier(enemy: Dictionary, modifier: Dictionary) -> void:
	var modifier_name := String(modifier.get("name", modifier.get("id", "")))
	if String(modifier.get("position", "prefix")) == "suffix":
		enemy["suffix_id"] = String(modifier.get("id", ""))
		enemy["display_name"] = "%s %s" % [enemy.get("display_name", "Inimigo"), modifier_name]
	else:
		enemy["prefix_id"] = String(modifier.get("id", ""))
		enemy["display_name"] = "%s %s" % [modifier_name, enemy.get("display_name", "Inimigo")]
	enemy["max_health"] = maxf(1.0, float(enemy.get("max_health", 1.0)) * maxf(0.05, float(modifier.get("health_multiplier", 1.0))))
	enemy["health"] = enemy["max_health"]
	enemy["speed"] = maxf(0.0, float(enemy.get("speed", 0.0)) * maxf(0.05, float(modifier.get("speed_multiplier", 1.0))))
	enemy["damage"] = maxf(0.0, float(enemy.get("damage", 0.0)) * maxf(0.05, float(modifier.get("damage_multiplier", 1.0))))
	enemy["attack_interval"] = maxf(0.05, float(enemy.get("attack_interval", 0.8)) * maxf(0.05, float(modifier.get("attack_interval_multiplier", 1.0))))
	enemy["loot_value"] = maxi(0, int(round(float(enemy.get("loot_value", 1)) * maxf(0.0, float(modifier.get("loot_multiplier", 1.0))))))
	var mechanic_id := String(modifier.get("mechanic_id", ""))
	if not mechanic_id.is_empty():
		var mechanics: Array = enemy.get("modifier_mechanics", []) as Array
		if mechanic_id not in mechanics:
			mechanics.append(mechanic_id)
		enemy["modifier_mechanics"] = mechanics
		if mechanic_id == "first_hit_shield":
			enemy["shield_hits"] = int(enemy.get("shield_hits", 0)) + 1


func _configure_directors() -> void:
	_crit_random.seed = encounter_seed + 17
	_mechanic_random.seed = encounter_seed + 29
	respawn = EnemyRespawnDirectorScript.new()
	respawn.call("configure", {
		"interval": RESPAWN_BASE_INTERVAL, "variance": 1.5, "maximum_alive": 6, "batch_size": 1,
		"minimum_player_distance": 220.0, "minimum_enemy_distance": 48.0,
		"eligible_classes": ["common", "elite"], "seed": encounter_seed,
	})
	threat = ThreatEscalationDirectorScript.new()
	threat.call("configure", {"normal_kills_per_boss": BASE_KILLS_PER_BOSS, "boss_kills_per_raid": 10})


## Respawn pelos pontos de patrulha do andar, longe do grupo. O intervalo cai com o tempo no andar.
func tick_respawns(delta: float) -> void:
	respawn.set("interval", respawn_interval())
	respawn.set("minimum_player_distance", RESPAWN_MIN_DISTANCE)
	var player_positions: Array[Vector2] = []
	for peer_id in _players_in_zone(&"tower"):
		player_positions.append(player(peer_id)["position"] as Vector2)
	var occupied: Array[Vector2] = []
	for enemy in enemies:
		occupied.append(enemy["position"] as Vector2)
	var points: Array[Vector2] = []
	for point: Vector2 in floor_layout.get("spawn_points", []) as Array:
		points.append(point)
	var requests: Array = respawn.call("tick", delta, enemies.size(), player_positions, points, occupied)
	for request: Dictionary in requests:
		var definition := _find(_collection("enemies"), String(request.get("definition_id", "")))
		if definition.is_empty():
			continue
		var position := request["position"] as Vector2
		enemies.append(_spawn_floor_enemy(definition, position, 1000 + int(request.get("spawn_sequence", 0))))


## Intervalo atual de respawn, exibido no HUD do andar.
func respawn_interval() -> float:
	return maxf(RESPAWN_MIN_INTERVAL, RESPAWN_BASE_INTERVAL / (1.0 + float(floor_run.get("time", 0.0)) / RESPAWN_ACCELERATION))


## Escalada de ameaça nos andares comuns: um campeão do bioma surge perto do grupo.
func _update_threat_spawn() -> void:
	for enemy in enemies:
		if String(enemy.get("encounter_class", "")) in ["boss", "raid"]:
			return
	var encounter_class: StringName = threat.call("consume_next_spawn")
	if encounter_class.is_empty():
		return
	var members := _players_in_arena()
	if members.is_empty():
		return
	var anchor := player(members[0])["position"] as Vector2
	var spot := anchor + Vector2.RIGHT.rotated(_floor_random.randf() * TAU) * 380.0
	if not FloorLayoutScript.can_stand(floor_layout, spot, 30.0):
		spot = anchor + Vector2(0.0, -300.0)
	var champion := _spawn_floor_enemy(_pick_floor_enemy(true), spot, 5000 + loot_kill_sequence)
	var factor := 4.0 if encounter_class == &"boss" else 9.0
	champion["health"] = float(champion["health"]) * factor
	champion["max_health"] = float(champion["max_health"]) * factor
	champion["damage"] = float(champion["damage"]) * 1.4
	champion["encounter_class"] = String(encounter_class)
	champion["display_name"] = "Campeao %s" % String(champion.get("display_name", ""))
	champion["champion"] = true
	enemies.append(champion)
	_vfx(&"tower", "ring", [spot, 90.0 if encounter_class == &"boss" else 130.0])
	_status(0, "A Renovacao respondeu: %s surgiu." % String(champion["display_name"]))


# ---------------------------------------------------------------- escalonamento cooperativo

## Jogadores conectados na arena ativa (1 a 4). Personagens reservadas não contam.
func party_size() -> int:
	var count := 0
	for peer_id in _players_in_arena():
		if is_connected_player(peer_id):
			count += 1
	return clampi(count, 1, MAX_PLAYERS)


func party_scaling() -> Dictionary:
	return PARTY_SCALING[party_size()] as Dictionary


## Fração de baixas que gera saque: o total cresce 80% do que o orçamento cresce.
func reward_share() -> float:
	var budget := float(party_scaling()["budget"])
	return (1.0 + REWARD_GROWTH_SHARE * (budget - 1.0)) / budget


## Ajusta Vida máxima de elites e chefes ao grupo atual, preservando a fração de Vida.
## A base fica no inimigo, então entradas, saídas e salvamentos não acumulam multiplicadores.
func _apply_party_scaling() -> void:
	var scaling := party_scaling()
	respawn.set("maximum_alive", maxi(BASE_RESPAWN_CAPACITY, int(ceil(float(floor_run.get("population", BASE_RESPAWN_CAPACITY)) * float(scaling["budget"])))))
	threat.set("normal_kills_per_boss", int(round(BASE_KILLS_PER_BOSS * float(scaling["budget"]))))
	# Cota cresce com o grupo para que o andar continue pedindo exploração (decisão 566).
	if floor_run.has("quota_base") and not bool(floor_run.get("stairs_open", false)):
		floor_run["quota"] = maxi(int(floor_run.get("quota", 0)), int(round(float(floor_run["quota_base"]) * pow(float(scaling["budget"]), 0.6))))
	for enemy in enemies:
		var encounter_class := String(enemy.get("encounter_class", "common"))
		var factor := 1.0
		if encounter_class == "elite":
			factor = float(scaling["elite_health"])
		elif encounter_class in ["boss", "raid"]:
			factor = float(scaling["boss_health"])
		if not enemy.has("base_max_health"):
			enemy["base_max_health"] = float(enemy["max_health"])
		var target := float(enemy["base_max_health"]) * factor
		var current := float(enemy["max_health"])
		if absf(target - current) > 0.01:
			enemy["health"] = float(enemy["health"]) * target / current
			enemy["max_health"] = target


## Orçamento extra do grupo vira reforços que entram pelo ponto de patrulha mais distante do grupo.
func _update_reinforcements(delta: float) -> void:
	var target := int(round(float(floor_run.get("population", 0)) * float(party_scaling()["budget"])))
	var alive := 0
	for enemy in enemies:
		if String(enemy.get("encounter_class", "common")) in ["common", "elite"]:
			alive += 1
	if alive + int(respawn.call("pending_count")) >= target:
		_reinforcement_timer = REINFORCEMENT_INTERVAL
		return
	_reinforcement_timer -= delta
	if _reinforcement_timer > 0.0:
		return
	_reinforcement_timer = REINFORCEMENT_INTERVAL
	var members := _players_in_zone(&"tower")
	var best := Vector2.ZERO
	var best_distance := -1.0
	for point: Vector2 in floor_layout.get("spawn_points", []) as Array:
		var nearest_player := INF
		for peer_id in members:
			nearest_player = minf(nearest_player, point.distance_to(player(peer_id)["position"] as Vector2))
		if nearest_player < RESPAWN_MIN_DISTANCE or nearest_player > 1600.0:
			continue
		if nearest_player > best_distance:
			best_distance = nearest_player
			best = point
	if best_distance < 0.0:
		return
	enemies.append(_spawn_floor_enemy(_pick_floor_enemy(true), best, 3000 + _reinforcement_sequence))
	_reinforcement_sequence += 1


func _nearest_player(position: Vector2) -> int:
	var result := -1
	var best := INF
	for peer_id in _players_in_arena():
		if not is_connected_player(peer_id) or is_downed(peer_id):
			continue
		var distance := position.distance_to(player(peer_id)["position"] as Vector2)
		if distance < best:
			best = distance
			result = peer_id
	return result


func _update_enemies(delta: float) -> void:
	for enemy_index in range(enemies.size() - 1, -1, -1):
		if enemy_index >= enemies.size():
			continue
		var enemy := enemies[enemy_index]
		enemy["moving"] = false
		if bool(enemy.get("floor_boss", false)):
			_step_boss(enemy, delta)
			continue
		enemy["provoked"] = maxf(0.0, float(enemy.get("provoked", 0.0)) - delta)
		var target_peer := _nearest_player(enemy["position"] as Vector2)
		var distance := INF if target_peer < 0 else (enemy["position"] as Vector2).distance_to(player(target_peer)["position"] as Vector2)
		var far_from_home := (enemy["position"] as Vector2).distance_to(enemy.get("home", enemy["position"]) as Vector2) > LEASH_RADIUS
		var chasing := bool(enemy.get("chasing", false))
		if distance <= AGGRO_RADIUS or float(enemy["provoked"]) > 0.0:
			chasing = true
		elif chasing and (distance > AGGRO_RADIUS * 1.6 or far_from_home):
			chasing = false
		enemy["chasing"] = chasing
		if not chasing or target_peer < 0:
			_wander(enemy, delta)
			continue
		var target := player(target_peer)
		var enemy_position := enemy["position"] as Vector2
		var offset := (target["position"] as Vector2) - enemy_position
		enemy["action_timer"] = float(enemy.get("action_timer", 0.0)) - delta
		var mechanics: Array = enemy.get("modifier_mechanics", []) as Array
		var base_mechanic := String(enemy.get("base_mechanic", "swarm"))
		var race_trait := String(enemy.get("race_trait", ""))
		if "regeneration" in mechanics:
			enemy["health"] = minf(float(enemy.get("max_health", 1.0)), float(enemy["health"]) + float(enemy.get("max_health", 1.0)) * 0.015 * delta)
		if "gravity_pull" in mechanics and offset.length() < 190.0 and offset.length() > 40.0:
			move_player(target_peer, -offset.normalized() * 28.0 * delta)
		if race_trait == "effect_feeder" and not persistent_effects.is_empty():
			enemy["health"] = minf(float(enemy.get("max_health", 1.0)), float(enemy["health"]) + float(enemy.get("max_health", 1.0)) * 0.01 * delta)
		var hidden_by_wall := ("wall_hide" in mechanics or base_mechanic == "wall_ambush" or race_trait == "wall_camouflage") and offset.length() > 170.0
		if base_mechanic == "loot_mimic" and not bool(enemy.get("awakened", false)):
			if offset.length() <= 180.0:
				enemy["awakened"] = true
			else:
				continue
		if base_mechanic in ["telegraphed_shot", "mark_target"]:
			if offset.length() > 300.0:
				_move_enemy(enemy, offset.normalized() * float(enemy.get("speed", 30.0)) * delta)
			elif float(enemy["action_timer"]) <= 0.0:
				_fire_enemy_projectile(enemy_position, target["position"] as Vector2, float(enemy.get("damage", 10.0)), base_mechanic == "mark_target")
				enemy["action_timer"] = float(enemy.get("attack_interval", 1.5))
			continue
		if base_mechanic == "enemy_barrier" and float(enemy["action_timer"]) <= 0.0:
			for ally in enemies:
				if enemy_position.distance_to(ally["position"] as Vector2) <= 190.0:
					ally["shield_hits"] = mini(2, int(ally.get("shield_hits", 0)) + 1)
			enemy["action_timer"] = 4.0
		if base_mechanic == "incorporate_objects" and float(enemy["action_timer"]) <= 0.0:
			for peer_id in _players_in_arena():
				if enemy_position.distance_to(player(peer_id)["position"] as Vector2) <= 180.0:
					take_damage(peer_id, float(enemy.get("damage", 20.0)))
			_vfx(arena_zone(), "ring", [enemy_position, 180.0])
			enemy["action_timer"] = 3.5
		if offset.length() > 30.0:
			if not hidden_by_wall:
				var movement_speed := float(enemy.get("speed", 42.0))
				if float(enemy.get("slow_timer", 0.0)) > 0.0:
					movement_speed *= 1.0 - float(enemy.get("slow_amount", 0.0))
				if base_mechanic == "erode_cover":
					movement_speed *= 1.15
				_move_enemy(enemy, offset.normalized() * movement_speed * delta)
		elif float(target["damage_cooldown"]) <= 0.0:
			var contact_damage := float(enemy.get("damage", 12.0))
			if race_trait == "barrier_breaker" and float(target["barrier"]) > 0.0:
				contact_damage *= 1.35
			if "echo_attack" in mechanics:
				contact_damage *= 1.35
			take_damage(target_peer, contact_damage)
			if "life_leech" in mechanics:
				enemy["health"] = minf(float(enemy.get("max_health", 1.0)), float(enemy["health"]) + contact_damage * 0.5)
			if "slowing_contact" in mechanics and players.has(target_peer):
				target["breath"] = maxf(0.0, float(target["breath"]) - 12.0)
			target["damage_cooldown"] = float(enemy.get("attack_interval", 0.8))


## Monstros fora de combate patrulham: andam pelo território (ou entre pontos de patrulha, os
## errantes), param um pouco e seguem para outro ponto. Nunca ficam parados esperando o jogador.
func _wander(enemy: Dictionary, delta: float) -> void:
	var position := enemy["position"] as Vector2
	var target := enemy.get("wander_target", position) as Vector2
	enemy["wander_timer"] = float(enemy.get("wander_timer", 0.0)) - delta
	if position.distance_to(target) > 6.0:
		var speed := float(enemy.get("speed", 40.0)) * 0.45
		if not _move_enemy(enemy, (target - position).normalized() * speed * delta):
			enemy["wander_timer"] = 0.0
			enemy["wander_target"] = position
		return
	if float(enemy["wander_timer"]) > 0.0:
		return
	var home := enemy.get("home", position) as Vector2
	var next := home + Vector2.RIGHT.rotated(_floor_random.randf() * TAU) * _floor_random.randf_range(40.0, WANDER_RADIUS)
	var points := floor_layout.get("spawn_points", []) as Array
	if bool(enemy.get("roamer", false)) and not points.is_empty():
		var candidate := points[_floor_random.randi_range(0, points.size() - 1)] as Vector2
		if candidate.distance_to(position) < 900.0:
			next = candidate
			enemy["home"] = candidate
	if FloorLayoutScript.can_stand(floor_layout, next, 14.0):
		enemy["wander_target"] = next
	enemy["wander_timer"] = _floor_random.randf_range(1.2, 4.0)


## Move o inimigo deslizando pelos obstáculos; devolve falso quando fica bloqueado.
func _move_enemy(enemy: Dictionary, motion: Vector2) -> bool:
	var position := enemy["position"] as Vector2
	if floor_layout.is_empty() or FloorLayoutScript.can_stand(floor_layout, position + motion, 12.0):
		enemy["position"] = position + motion
		if not motion.is_zero_approx():
			enemy["facing_direction"] = motion.normalized()
			enemy["moving"] = true
		return true
	if FloorLayoutScript.can_stand(floor_layout, position + Vector2(motion.x, 0.0), 12.0):
		enemy["position"] = position + Vector2(motion.x, 0.0)
		if not is_zero_approx(motion.x):
			enemy["facing_direction"] = Vector2(signf(motion.x), 0.0)
			enemy["moving"] = true
		return true
	if FloorLayoutScript.can_stand(floor_layout, position + Vector2(0.0, motion.y), 12.0):
		enemy["position"] = position + Vector2(0.0, motion.y)
		if not is_zero_approx(motion.y):
			enemy["facing_direction"] = Vector2(0.0, signf(motion.y))
			enemy["moving"] = true
		return true
	return false


# ---------------------------------------------------------------- chefes, telegrafias e perigos

## Chefe de andar: fases por Vida, enrage por tempo, habilidades em área com aviso no chão e
## combinações extras conforme o tamanho do grupo (documento 58).
func _step_boss(boss: Dictionary, delta: float) -> void:
	boss["fight_time"] = float(boss.get("fight_time", 0.0)) + delta
	var ratio := float(boss["health"]) / maxf(1.0, float(boss["max_health"]))
	var phase := 0
	for threshold: Variant in boss.get("phases", []) as Array:
		if ratio <= float(threshold):
			phase += 1
	var position := boss["position"] as Vector2
	if phase > int(boss.get("phase", 0)):
		boss["phase"] = phase
		boss["cast_lock"] = 1.2
		_vfx(&"tower", "ring", [position, 160.0])
		_status(0, "%s muda de forma: fase %d." % [String(boss.get("display_name", "Chefe")), phase + 1])
	var enraged := float(boss["fight_time"]) >= float(boss.get("enrage", 200.0))
	if enraged and not bool(boss.get("enraged", false)):
		boss["enraged"] = true
		_status(0, "%s entrou em furia." % String(boss.get("display_name", "Chefe")))
	var timers := boss.get("kit_timers", {}) as Dictionary
	for key: Variant in timers:
		timers[key] = float(timers[key]) - delta
	boss["cast_lock"] = float(boss.get("cast_lock", 0.0)) - delta
	var target_peer := _nearest_player(position)
	if target_peer < 0:
		return
	var target_position := player(target_peer)["position"] as Vector2
	if float(boss["cast_lock"]) <= 0.0:
		var kit := (boss.get("kit", []) as Array).duplicate()
		for extra in TowerContentScript.party_abilities(party_size()):
			extra["damage"] = float(boss["damage"]) * float(extra.get("damage_ratio", 1.0))
			kit.append(extra)
		var start := int(boss.get("next_ability", 0))
		for step in range(kit.size()):
			var index := (start + step) % kit.size()
			var ability := kit[index] as Dictionary
			if int(ability.get("phase", 1)) - 1 > phase or float(timers.get(str(index), 0.0)) > 0.0:
				continue
			var cooldown := float(ability.get("cooldown", 6.0)) * pow(0.85, float(phase)) * (0.6 if enraged else 1.0)
			timers[str(index)] = cooldown
			boss["next_ability"] = index + 1
			boss["cast_lock"] = maxf(0.9, _cast_ability(boss, ability, 1.5 if enraged else 1.0))
			break
		boss["kit_timers"] = timers
	if float(boss["cast_lock"]) > 0.0 or float(boss.get("speed", 0.0)) <= 0.0:
		return
	var offset := target_position - position
	if offset.length() > BOSS_MELEE_RANGE:
		var speed := float(boss["speed"]) * (1.0 + 0.12 * float(phase)) * (1.25 if enraged else 1.0)
		_move_enemy(boss, offset.normalized() * speed * delta)
	elif float(player(target_peer)["damage_cooldown"]) <= 0.0:
		take_damage(target_peer, float(boss["damage"]) * (1.5 if enraged else 1.0))
		player(target_peer)["damage_cooldown"] = 1.0


## Executa uma habilidade de chefe; devolve por quanto tempo o chefe fica concentrado.
func _cast_ability(caster: Dictionary, ability: Dictionary, damage_scale: float) -> float:
	var targets: Array = []
	for peer_id in _players_in_arena():
		if is_connected_player(peer_id):
			targets.append(player(peer_id)["position"])
	var context := {
		"origin": caster["position"], "targets": targets, "random": _floor_random,
		"center": floor_layout.get("arena_center", caster["position"]),
	}
	var result := TelegraphScript.from_ability(ability, context, damage_scale)
	for telegraph: Dictionary in result["telegraphs"]:
		telegraph["source"] = "boss"
		telegraphs.append(telegraph)
	for action: Dictionary in result["actions"]:
		match String(action["type"]):
			"barrage":
				var count := int(action["count"])
				var turn := _floor_random.randf() * TAU
				for index in range(count):
					var direction := Vector2.RIGHT.rotated(turn + TAU * float(index) / float(count))
					enemy_projectiles.append({"position": caster["position"], "velocity": direction * float(action["speed"]), "damage": float(action["damage"]), "lifetime": 4.0})
				_vfx(&"tower", "ring", [caster["position"], 60.0])
			"summon":
				for index in range(int(action["count"])):
					if enemies.size() >= 40:
						break
					var spot := (caster["position"] as Vector2) + Vector2.RIGHT.rotated(TAU * float(index) / float(maxi(1, int(action["count"])))) * 110.0
					if FloorLayoutScript.can_stand(floor_layout, spot, 14.0):
						var add := _spawn_floor_enemy(_pick_floor_enemy(false), spot, 7000 + index)
						add["chasing"] = true
						add["summoned"] = true
						enemies.append(add)
				_vfx(&"tower", "ring", [caster["position"], 120.0])
	return float(result.get("lock", 0.0))


## Resolve as telegrafias vencidas: dano, empurrão, investida e zonas persistentes. Puxões agem durante o aviso.
func _update_telegraphs(delta: float) -> void:
	for index in range(telegraphs.size() - 1, -1, -1):
		if index >= telegraphs.size():
			continue
		var telegraph := telegraphs[index]
		telegraph["remaining"] = float(telegraph["remaining"]) - delta
		var effect := telegraph.get("effect", {}) as Dictionary
		var origin := telegraph["position"] as Vector2
		if effect.has("pull_radius"):
			for peer_id in _players_in_arena():
				var spot := player(peer_id)["position"] as Vector2
				if spot.distance_to(origin) <= float(effect["pull_radius"]) and spot.distance_to(origin) > 20.0:
					move_player(peer_id, (origin - spot).normalized() * float(effect["pull_strength"]) * delta)
		if float(telegraph["remaining"]) > 0.0:
			continue
		telegraphs.remove_at(index)
		for peer_id in _players_in_arena():
			var state := player(peer_id)
			if not is_connected_player(peer_id) or not TelegraphScript.contains(telegraph, state["position"] as Vector2, PLAYER_RADIUS * 0.5):
				continue
			take_damage(peer_id, float(telegraph["damage"]))
			if not players.has(peer_id) or state["zone"] != &"tower":
				continue
			if float(effect.get("push", 0.0)) > 0.0:
				move_player(peer_id, Vector2.RIGHT.rotated(float(telegraph.get("angle", 0.0))) * float(effect["push"]))
		if effect.has("zone"):
			var zone := effect["zone"] as Dictionary
			hazard_zones.append({"position": origin, "radius": float(zone["radius"]), "damage": float(zone["damage"]), "slow": float(zone.get("slow", 0.0)), "remaining": float(zone["duration"]), "tick": 0.0})
		if effect.has("charge_to"):
			for enemy in enemies:
				if bool(enemy.get("floor_boss", false)):
					var destination := effect["charge_to"] as Vector2
					if FloorLayoutScript.can_stand(floor_layout, destination, 30.0):
						enemy["position"] = destination
		if String(telegraph["shape"]) == "rect":
			var end := origin + Vector2.RIGHT.rotated(float(telegraph["angle"])) * float(telegraph["length"])
			_vfx(&"tower", "chain", [[origin, end]])
		else:
			_vfx(&"tower", "ring", [origin, float(telegraph["radius"])])


func _update_hazard_zones(delta: float) -> void:
	for index in range(hazard_zones.size() - 1, -1, -1):
		var zone := hazard_zones[index]
		zone["remaining"] = float(zone["remaining"]) - delta
		zone["tick"] = float(zone["tick"]) - delta
		if float(zone["tick"]) <= 0.0:
			zone["tick"] = 0.5
			for peer_id in _players_in_arena():
				if is_connected_player(peer_id) and (player(peer_id)["position"] as Vector2).distance_to(zone["position"] as Vector2) <= float(zone["radius"]):
					take_damage(peer_id, float(zone["damage"]) * 0.5)
		if float(zone["remaining"]) <= 0.0:
			hazard_zones.remove_at(index)


func _zone_slow(position: Vector2) -> float:
	var slow := 0.0
	for zone in hazard_zones:
		if position.distance_to(zone["position"] as Vector2) <= float(zone["radius"]):
			slow = maxf(slow, float(zone.get("slow", 0.0)))
	return slow


## Perigo ambiental do bioma (documentos 28 a 37) perto de um jogador do andar.
func _cast_hazard(hazard: Dictionary) -> void:
	var members: Array[int] = []
	for peer_id in _players_in_arena():
		if is_connected_player(peer_id):
			members.append(peer_id)
	if members.is_empty() or hazard.is_empty():
		return
	var ability := hazard.duplicate(true)
	if String(ability.get("type", "")) == "mixed":
		var options := ["slam", "gust", "zone", "line", "meteor", "pull", "donut"]
		ability = {"type": options[_floor_random.randi_range(0, options.size() - 1)], "radius": 90.0, "inner": 80.0, "length": 560.0, "width": 80.0, "count": 4, "spread": 300.0, "delay": 1.2, "damage": float(hazard.get("damage", 20.0)), "push": 140.0, "strength": 180.0, "duration": 4.0}
		if String(ability["type"]) in ["donut", "pull"]:
			ability["radius"] = 220.0
	var target := player(members[_floor_random.randi_range(0, members.size() - 1)])["position"] as Vector2
	var origin := target + Vector2.RIGHT.rotated(_floor_random.randf() * TAU) * _floor_random.randf_range(0.0, 90.0)
	if String(ability.get("type", "")) == "line":
		origin = target - Vector2.RIGHT.rotated(_floor_random.randf() * TAU) * 300.0
	var result := TelegraphScript.from_ability(ability, {"origin": origin, "targets": [target], "random": _floor_random, "center": target}, float(floor_def().get("hazard_multiplier", 1.0)))
	for telegraph: Dictionary in result["telegraphs"]:
		telegraph["source"] = "hazard"
		telegraph["label"] = String(hazard.get("label", ""))
		telegraphs.append(telegraph)


func _fire_enemy_projectile(origin: Vector2, target: Vector2, damage: float, marked: bool) -> void:
	enemy_projectiles.append({
		"position": origin,
		"velocity": (target - origin).normalized() * (250.0 if marked else 205.0),
		"damage": damage * (1.2 if marked else 1.0),
		"lifetime": 3.0,
	})


func _update_enemy_projectiles(delta: float) -> void:
	for index in range(enemy_projectiles.size() - 1, -1, -1):
		if index >= enemy_projectiles.size():
			continue
		var projectile := enemy_projectiles[index]
		projectile["position"] = (projectile["position"] as Vector2) + (projectile["velocity"] as Vector2) * delta
		projectile["lifetime"] = float(projectile["lifetime"]) - delta
		var position := projectile["position"] as Vector2
		var hit_peer := -1
		for peer_id in _players_in_arena():
			if position.distance_to(player(peer_id)["position"] as Vector2) <= PLAYER_RADIUS + 6.0:
				hit_peer = peer_id
				break
		if hit_peer >= 0:
			enemy_projectiles.remove_at(index)
			take_damage(hit_peer, float(projectile["damage"]))
		elif float(projectile["lifetime"]) <= 0.0 or not Rect2(Vector2.ZERO, _zone_size(&"tower")).has_point(position):
			enemy_projectiles.remove_at(index)


func nearest_enemy_to(origin: Vector2, max_range: float) -> int:
	var result := -1
	var nearest_distance := max_range
	for index in range(enemies.size()):
		var distance := origin.distance_to(enemies[index]["position"] as Vector2)
		if distance < nearest_distance:
			nearest_distance = distance
			result = index
	return result


# ---------------------------------------------------------------- dano

func damage_enemies(peer_id: int, center: Vector2, radius: float, damage: float, hit: Dictionary = {}) -> void:
	if damage <= 0.0:
		return
	for index in range(enemies.size() - 1, -1, -1):
		if index < enemies.size() and center.distance_to(enemies[index]["position"] as Vector2) <= radius:
			damage_enemy(peer_id, index, damage, hit)


func damage_enemy(peer_id: int, index: int, damage: float, hit: Dictionary = {}) -> void:
	_damage_depth += 1
	_damage_enemy(peer_id, index, damage, hit)
	_damage_depth -= 1
	while _damage_depth == 0 and not _passive_events.is_empty():
		var event: Dictionary = _passive_events.pop_front()
		if not players.has(int(event["peer"])):
			continue
		if String(event["kind"]) == "kill":
			ItemPassivesScript.on_kill(self, int(event["peer"]), event["enemy"] as Dictionary, float(event["damage"]), event["hit"] as Dictionary)
		else:
			ItemPassivesScript.on_hit(self, int(event["peer"]), event["enemy"] as Dictionary, float(event["damage"]), event["hit"] as Dictionary, bool(event["critical"]))


func _damage_enemy(peer_id: int, index: int, damage: float, hit: Dictionary) -> void:
	if index < 0 or index >= enemies.size():
		return
	var zone := arena_zone()
	var enemy := enemies[index]
	var enemy_position := enemy["position"] as Vector2
	var dot := bool(hit.get("dot", false))
	# Dano contínuo (veneno, queimadura) não é bloqueável nem esquivável: ignora escudos e não
	# consome cargas de bloqueio (regressão de 2026-10-07).
	if not dot and int(enemy.get("shield_hits", 0)) > 0:
		enemy["shield_hits"] = int(enemy["shield_hits"]) - 1
		_vfx(zone, "label", [enemy_position, "BLOQUEIO", Color("c9d4d6"), "block"])
		return
	var derived := derived_stats(peer_id)
	var conditioned := float(enemy.get("vulnerable_timer", 0.0)) > 0.0 or float(enemy.get("slow_timer", 0.0)) > 0.0
	if float(enemy.get("vulnerable_timer", 0.0)) > 0.0:
		damage *= 1.0 + float(enemy.get("vulnerable_amount", 0.0))
	var apply_vulnerable := 0.0
	for mechanic in _mechanics(peer_id, "shared_condition"):
		if conditioned:
			damage *= 1.0 + float(mechanic.get("bonus", 0.0))
		if bool(hit.get("gem", false)):
			apply_vulnerable = maxf(apply_vulnerable, float(mechanic.get("apply_vulnerable", 0.0)))
	if apply_vulnerable > 0.0 and float(hit.get("vulnerable", 0.0)) < apply_vulnerable:
		hit = hit.duplicate()
		hit["vulnerable"] = apply_vulnerable
		hit["vulnerable_duration"] = 3.0
	var critical := not bool(hit.get("dot", false)) and _crit_random.randf() < minf(0.5, minf(0.35, float(derived.get("critical_chance", CRIT_CHANCE))) + float(hit.get("crit_add", 0.0)))
	if critical:
		damage *= minf(2.0, CRIT_MULTIPLIER + maxf(0.0, float(derived.get("critical_damage_multiplier", 1.5)) - 1.5) + float(derived.get("critical_damage_bonus", 0.0)))
	var race_trait := String(enemy.get("race_trait", ""))
	if race_trait == "stone_skin" and String(hit.get("damage_type", "physical")) == "physical":
		damage *= 0.85
	if dot:
		_vfx(zone, "number", [enemy_position, damage, false, "poison" if hit.has("poison") else "burn"])
	else:
		_vfx(zone, "number", [enemy_position, damage, critical])
		_vfx(zone, "spark", [enemy_position])
	enemy["health"] = float(enemy["health"]) - damage
	if not bool(hit.get("passive", false)) and not bool(hit.get("dot", false)) and players.has(peer_id):
		_passive_events.append({"kind": "hit", "peer": peer_id, "enemy": enemy, "damage": damage, "hit": hit, "critical": critical})
	enemy["flash"] = 0.12
	if float(enemy.get("provoked", 0.0)) <= 0.0:
		for neighbor in enemies:
			if (neighbor["position"] as Vector2).distance_to(enemy_position) <= 240.0:
				neighbor["provoked"] = maxf(float(neighbor.get("provoked", 0.0)), 3.0)
	enemy["provoked"] = 6.0
	var attacker := player(peer_id)
	if not attacker.is_empty():
		var near_obstacle := _is_near_obstacle(enemy_position)
		_apply_passive_requests(peer_id, (attacker["passive"] as RefCounted).call("on_enemy_hit", enemy_position, near_obstacle) as Array)
		for other in _players_in_arena():
			if other != peer_id and is_connected_player(other) and not _mechanics(other, "ally_feed").is_empty():
				_apply_passive_requests(other, (player(other)["passive"] as RefCounted).call("on_enemy_hit", enemy_position, near_obstacle) as Array)
		var steal := float(hit.get("life_steal", 0.0)) + _mod(peer_id, "life_steal_add")
		if steal > 0.0:
			heal_player(peer_id, damage * steal)
		if float(hit.get("barrier_per_hit", 0.0)) > 0.0:
			_add_barrier(peer_id, float(hit["barrier_per_hit"]), 3.0)
		if float(hit.get("breath_per_hit", 0.0)) > 0.0:
			var budget := float(attacker.get("breath_hit_budget", 8.0))
			var gained := minf(budget, float(hit["breath_per_hit"]))
			attacker["breath_hit_budget"] = budget - gained
			attacker["breath"] = minf(max_breath(peer_id), float(attacker["breath"]) + gained)
		if float(hit.get("knockback", 0.0)) > 0.0:
			var away := (enemy_position - (attacker["position"] as Vector2)).normalized()
			if not bool(enemy.get("floor_boss", false)):
				enemy["position"] = (enemy_position + away * float(hit["knockback"])).clamp(Vector2(20.0, 20.0), _zone_size(&"tower") - Vector2(20.0, 20.0))
	if float(hit.get("slow", 0.0)) > 0.0:
		enemy["slow_amount"] = maxf(float(enemy.get("slow_amount", 0.0)) if float(enemy.get("slow_timer", 0.0)) > 0.0 else 0.0, float(hit["slow"]))
		enemy["slow_timer"] = maxf(float(enemy.get("slow_timer", 0.0)), float(hit.get("slow_duration", 1.5)))
	if float(hit.get("vulnerable", 0.0)) > 0.0:
		enemy["vulnerable_amount"] = float(hit["vulnerable"])
		enemy["vulnerable_timer"] = maxf(float(enemy.get("vulnerable_timer", 0.0)), float(hit.get("vulnerable_duration", 3.0)))
	# Ticks de dano contínuo não contam como golpes: a Casca Adaptável não cria escudo com eles.
	if not dot:
		enemy["hits_received"] = int(enemy.get("hits_received", 0)) + 1
	if not dot and race_trait == "adaptive_shell" and int(enemy["hits_received"]) % 3 == 0:
		enemy["shield_hits"] = int(enemy.get("shield_hits", 0)) + 1
	if float(enemy["health"]) > 0.0:
		return
	var defeated := enemy.duplicate(true) as Dictionary
	var mechanics: Array = defeated.get("modifier_mechanics", []) as Array
	enemies.remove_at(index)
	_spread_poisons(defeated)
	var major := bool(defeated.get("floor_boss", false)) or String(defeated.get("encounter_class", "")) in ["boss", "raid"]
	_vfx(zone, "play", ["explosion" if major else "poof", enemy_position])
	if not bool(defeated.get("fragment", false)):
		var encounter_class := StringName(String(defeated.get("encounter_class", "common")))
		respawn.call("register_defeat", StringName(String(defeated.get("definition_id", ""))), encounter_class, enemy_position)
		threat.call("register_defeat", encounter_class)
		_record_bestiary_kill(defeated)
		_grant_loot(peer_id, defeated)
		for member in _players_in_arena():
			_grant_experience(member, defeated)
		_on_kill(peer_id, enemy_position)
		if not bool(hit.get("passive", false)) and players.has(peer_id):
			_passive_events.append({"kind": "kill", "peer": peer_id, "enemy": defeated, "damage": damage, "hit": hit, "critical": false})
		if not String(hit.get("gem_id", "")).is_empty() and players.has(peer_id):
			gain_gem_experience(peer_id, String(hit["gem_id"]), int(EXPERIENCE_REWARDS.get(String(defeated.get("encounter_class", "common")), 12)))
		if float(hit.get("breath_on_kill", 0.0)) > 0.0 and players.has(peer_id):
			player(peer_id)["breath"] = minf(max_breath(peer_id), float(player(peer_id)["breath"]) + float(hit["breath_on_kill"]))
		_register_floor_kill(defeated)
	if "death_burst" in mechanics:
		for member in _players_in_arena():
			if (player(member)["position"] as Vector2).distance_to(enemy_position) <= 110.0:
				take_damage(member, 18.0)
	if "split_on_death" in mechanics and enemies.size() < 18:
		for direction in [-1.0, 1.0]:
			var fragment := defeated.duplicate(true) as Dictionary
			fragment["position"] = enemy_position + Vector2(24.0 * direction, 0.0)
			fragment["max_health"] = maxf(1.0, float(defeated["max_health"]) * 0.35)
			fragment["health"] = fragment["max_health"]
			fragment["damage"] = float(defeated["damage"]) * 0.6
			fragment["loot_value"] = 0
			fragment["modifier_mechanics"] = []
			fragment["prefix_id"] = ""
			fragment["suffix_id"] = ""
			fragment["fragment"] = true
			enemies.append(fragment)
	if players.has(peer_id) and not bool(defeated.get("floor_boss", false)):
		_status(peer_id, "Saque recolhido. Pedra Regenerativa: %d" % int(player(peer_id)["carried_stone"]))


func take_damage(peer_id: int, amount: float) -> void:
	var state := player(peer_id)
	if state.is_empty() or state["zone"] not in ARENA_ZONES or float(state["invulnerable"]) > 0.0 or not bool(state.get("connected", true)) or bool(state.get("downed", false)):
		return
	var zone := state["zone"] as StringName
	var position := state["position"] as Vector2
	if float(state["barrier"]) > 0.0:
		var absorbed := minf(float(state["barrier"]), amount)
		state["barrier"] = float(state["barrier"]) - absorbed
		amount -= absorbed
		_vfx(zone, "label", [position, "ABSORVIDO", Color("7fd6e0"), "shield"])
		if amount <= 0.0:
			_status(peer_id, "Barreira absorveu o impacto.")
			return
	var stability := stability_at(zone, position)
	if stability > 0.0:
		amount *= 1.0 - stability
	amount *= _mod(peer_id, "damage_taken_mult") * (1.0 - _ally_aura(peer_id, "ally_damage_reduction_add"))
	# Guarda da arma: quem luta colado (manoplas, bastão) recebe menos dano para compensar o risco.
	amount *= 1.0 - clampf(float(weapon_attack_model(peer_id).get("guard", 0.0)), 0.0, 0.5)
	amount *= 1.0 - float(derived_stats(peer_id).get("damage_reduction", 0.0))
	var reaction: Dictionary = (state["passive"] as RefCounted).call("on_damage_taken", amount, float(state["health"]) / max_health(peer_id))
	amount = float(reaction["amount"])
	_vfx(zone, "number", [position, amount, false, "player"])
	state["health"] = maxf(0.0, float(state["health"]) - amount)
	state["hurt_flash"] = 0.15
	state["since_damage"] = 0.0
	_status(peer_id, "Dano recebido. Vida restante: %d" % int(state["health"]))
	if float(state["health"]) <= 0.0 and ItemPassivesScript.on_lethal(self, peer_id):
		return
	if float(state["health"]) <= 0.0:
		_fall(peer_id)
	else:
		ItemPassivesScript.on_hurt(self, peer_id, amount)
		_apply_passive_requests(peer_id, reaction["requests"] as Array)
		_check_low_health(peer_id)


## Vida a zero: com aliado de pé, a personagem cai e espera estabilização; na quarta queda, sem
## aliados de pé ou em solo, a expedição dela termina.
func _fall(peer_id: int) -> void:
	var state := player(peer_id)
	var falls := int(state.get("falls", 0))
	if falls >= DOWNED_WINDOWS.size() or _standing_allies(peer_id).is_empty():
		_handle_defeat(peer_id)
		_check_party_collapse()
		return
	state["downed"] = true
	state["falls"] = falls + 1
	state["downed_timer"] = DOWNED_WINDOWS[falls]
	state["stabilize_progress"] = 0.0
	state["barrier"] = 0.0
	state["target"] = state["position"]
	state["moving"] = false
	_vfx(state["zone"], "label", [state["position"], "CAIU", Color("e87a6a"), "downed"])
	_status(0, "%s caiu! Fique ao lado por %d s para estabilizar (%d s restantes)." % [String(state["character_name"]), int(STABILIZE_SECONDS), int(DOWNED_WINDOWS[falls])])
	_check_party_collapse()


func _standing_allies(peer_id: int) -> Array[int]:
	var result: Array[int] = []
	for other in _players_in_arena():
		if other != peer_id and is_connected_player(other) and not bool(player(other).get("downed", false)):
			result.append(other)
	return result


## Se ninguém do andar continua de pé, todos os caídos perdem a expedição.
func _check_party_collapse() -> void:
	var standing := 0
	var downed: Array[int] = []
	for peer_id in _players_in_arena():
		if bool(player(peer_id).get("downed", false)):
			downed.append(peer_id)
		elif is_connected_player(peer_id):
			standing += 1
	if standing == 0:
		for peer_id in downed:
			player(peer_id)["downed"] = false
			_handle_defeat(peer_id)


func is_downed(peer_id: int) -> bool:
	return bool(player(peer_id).get("downed", false))


func _step_downed(peer_id: int, delta: float) -> void:
	var state := player(peer_id)
	state["downed_timer"] = float(state["downed_timer"]) - delta
	var helping := false
	for ally in _standing_allies(peer_id):
		if (player(ally)["position"] as Vector2).distance_to(state["position"] as Vector2) <= STABILIZE_RADIUS:
			helping = true
	state["stabilize_progress"] = maxf(0.0, float(state["stabilize_progress"]) + (delta if helping else -delta * 0.5))
	if float(state["stabilize_progress"]) >= STABILIZE_SECONDS:
		state["downed"] = false
		state["wounds"] = int(state.get("wounds", 0)) + 1
		state["health"] = max_health(peer_id) * STABILIZED_HEALTH
		state["invulnerable"] = 1.5
		state["stabilize_progress"] = 0.0
		_vfx(state["zone"], "label", [state["position"], "ESTABILIZADO", Color("93c25a"), "heal"])
		_status(0, "%s foi estabilizado com um Ferimento de Expedicao." % String(state["character_name"]))
	elif float(state["downed_timer"]) <= 0.0:
		state["downed"] = false
		_handle_defeat(peer_id)
		_check_party_collapse()


## Maior redução de dano entre santuários estáveis que contêm a posição (Raiz Estável).
func stability_at(zone: StringName, position: Vector2) -> float:
	if zone != arena_zone():
		return 0.0
	var best := 0.0
	for effect in persistent_effects:
		if String(effect.get("mechanic", "")) == "sanctuary" and (effect["position"] as Vector2).distance_to(position) <= float(effect["radius"]):
			best = maxf(best, float(effect.get("stability", 0.0)))
	return best


func _handle_defeat(peer_id: int) -> void:
	var state := player(peer_id)
	if state.get("zone", &"") == &"tower":
		narrative.record_return("defeat")
	state["downed"] = false
	state["falls"] = 0
	state["wounds"] = 0
	var lost_stone := int(state["carried_stone"])
	_drop_carried(peer_id, state["zone"] as StringName, state["position"] as Vector2)
	state["health"] = max_health(peer_id)
	state["breath"] = max_breath(peer_id)
	state["barrier"] = 0.0
	_clear_owned_effects(peer_id)
	_place(peer_id, &"village", LayoutScript.TOWER_RETURN, 0.8)
	_event({"type": "clear_vfx", "peer": peer_id})
	if _players_in_arena().is_empty():
		enemy_projectiles.clear()
	_status(peer_id, "Expedicao perdida. %d pedras ficaram no chao da Torre para serem recuperadas." % lost_stone)
	village_life.call("remember_event", "queda", "%s caiu na Torre e voltou ferido para Aresta" % String(state["character_name"]), -0.4, String(state["character_id"]))


func _is_near_obstacle(position: Vector2) -> bool:
	for obstacle in LayoutScript.obstacles(arena_zone(), village_progress):
		if obstacle.grow(60.0).has_point(position):
			return true
	return false


func _clear_owned_effects(peer_id: int) -> void:
	for index in range(persistent_effects.size() - 1, -1, -1):
		if int(persistent_effects[index].get("owner_peer", -1)) == peer_id:
			persistent_effects.remove_at(index)


# ---------------------------------------------------------------- gemas e efeitos

func execute_gem_effect(peer_id: int, effect: Dictionary, target: Vector2) -> void:
	var previous_theme := _vfx_theme
	_vfx_theme = String(effect.get("gem_id", ""))
	var caster := player(peer_id)
	if not caster.is_empty() and String(effect.get("mechanic", "")) != "impact":
		_vfx(caster["zone"], "cast", [caster["position"]])
	_execute_gem_effect(peer_id, effect, target)
	_vfx_theme = previous_theme


func _execute_gem_effect(peer_id: int, effect: Dictionary, target: Vector2) -> void:
	var state := player(peer_id)
	if state.is_empty():
		return
	var zone := state["zone"] as StringName
	var position := state["position"] as Vector2
	var mechanic := String(effect.get("mechanic", ""))
	var radius := float(effect.get("radius", 48.0))
	var power := float(effect.get("power", 0.0))
	var hit := _hit_context(effect)
	match mechanic:
		"projectile", "boomerang":
			_cast_projectiles(peer_id, effect, target, hit)
		"volley":
			_toggle_volley(peer_id, effect, hit)
		"cone":
			var direction := (target - position).normalized()
			if direction == Vector2.ZERO:
				direction = Vector2.RIGHT
			var angle := clampf(float(effect.get("angle", 1.2)), 0.1, TAU)
			_vfx(zone, "cone", [position, direction, radius, angle])
			for index in range(enemies.size() - 1, -1, -1):
				if index < enemies.size() and SkillGeometryScript.in_cone(enemies[index]["position"], position, direction, radius, angle):
					damage_enemy(peer_id, index, power, hit)
		"beam":
			var direction := (target - position).normalized()
			if direction == Vector2.ZERO:
				direction = Vector2.RIGHT
			var end := position + direction * float(effect.get("range", 450.0))
			_vfx(zone, "beam", [position, end, float(effect.get("width", 18.0))])
			_damage_segment(peer_id, position, end, float(effect.get("width", 18.0)), power, enemies.size(), hit)
		"meteor":
			var center := _ranged_skill_target(peer_id, target, effect)
			var count := clampi(int(effect.get("meteor_count", 1)), 1, 8)
			for index in range(count):
				var spread := Vector2.ZERO if count == 1 else Vector2.RIGHT.rotated(TAU * index / float(count)) * float(effect.get("spread", 80.0))
				var landing := (center + spread).clamp(Vector2(20, 20), _zone_size(zone) - Vector2(20, 20))
				var delay := maxf(0.1, float(effect.get("delay", 0.8))) + index * 0.12
				_vfx(zone, "target_ring", [landing, radius, delay])
				var impact := effect.duplicate(true)
				impact["mechanic"] = "impact"
				impact["repeat_count"] = 0
				_scheduled.append({"time": delay, "peer": peer_id, "effect": impact, "target": landing, "zone": zone, "floor": current_floor})
		"impact":
			_vfx(zone, "strike", [target, radius])
			damage_enemies(peer_id, target, radius, power, hit)
		"dash":
			var direction := (target - position).normalized()
			if direction == Vector2.ZERO:
				direction = Vector2.LEFT if bool(state["facing_left"]) else Vector2.RIGHT
			move_player(peer_id, direction * float(effect.get("distance", 100.0)))
			var arrival := state["position"] as Vector2
			state["invulnerable"] = maxf(float(state["invulnerable"]), float(effect.get("invulnerability", 0.0)))
			if absf(direction.x) > 0.1:
				state["facing_left"] = direction.x < 0.0
			_vfx(zone, "ghosts", ["characters/" + String(state["character_id"]), position + Vector2(0.0, 12.0), arrival + Vector2(0.0, 12.0), state["facing_left"]])
			if float(effect.get("trail_damage", 0.0)) > 0.0:
				_damage_segment(peer_id, position, arrival, 26.0, float(effect["trail_damage"]), 99, hit)
			if float(effect.get("arrival_area", 0.0)) > 0.0:
				_vfx(zone, "ring", [arrival, float(effect["arrival_area"])])
				damage_enemies(peer_id, arrival, float(effect["arrival_area"]), float(effect.get("arrival_damage", 15.0)), hit)
			if float(effect.get("arrival_barrier", 0.0)) > 0.0:
				_add_barrier(peer_id, float(effect["arrival_barrier"]), 3.0)
		"nova":
			var center := _ranged_skill_target(peer_id, target, effect) if bool(effect.get("remote_nova", false)) else position
			var inner := maxf(0.0, float(effect.get("inner_radius", 0.0)))
			_vfx(zone, "ring", [center, radius])
			if inner > 0.0:
				_vfx(zone, "ring", [center, inner])
			for index in range(enemies.size() - 1, -1, -1):
				if index < enemies.size():
					var distance := center.distance_to(enemies[index]["position"])
					if distance >= inner and distance <= radius:
						damage_enemy(peer_id, index, power, hit)
		"spores":
			var spore_target := nearest_enemy_to(_ranged_skill_target(peer_id, target, effect), float(effect.get("radius", 60.0)) + 60.0)
			if spore_target < 0:
				spore_target = nearest_enemy_to(target, float(effect.get("range", 420.0)))
			if spore_target >= 0:
				var victim := enemies[spore_target]
				_vfx(zone, "travel", ["vfx/bolt", position - Vector2(0.0, 14.0), victim["position"], 0.18, 10.0])
				_vfx(zone, "strike", [victim["position"], 40.0])
				apply_poison(peer_id, victim, "esporo", {
					"damage": power, "growth": float(effect.get("poison_growth", 0.2)), "interval": float(effect.get("tick_interval", 1.0)),
					"remaining": -1.0, "spread_radius": float(effect.get("spread_radius", 130.0)), "gem_id": String(effect.get("gem_id", "")),
					"share": spore_health_share(victim), "stack": maxf(1.0, spore_strain(peer_id) * SPORE_STRAIN_INHERIT),
					"cap": spore_stack_cap(peer_id),
				})
		"field", "sanctuary", "orbit", "mine", "poison_pool":
			var effect_position := position if mechanic == "sanctuary" else target
			if mechanic == "orbit":
				effect_position = position
			elif mechanic != "sanctuary":
				effect_position = _ranged_skill_target(peer_id, target, effect)
			_limit_skill_deployments(peer_id, String(effect.get("gem_id", effect.get("id", ""))))
			persistent_effects.append({
				"mechanic": mechanic,
				"gem_id": String(effect.get("gem_id", effect.get("id", ""))),
				"owner_peer": peer_id,
				"position": effect_position,
				"radius": radius,
				"power": power + float(effect.get("enemy_damage_per_tick", 0.0)),
				"healing": float(effect.get("healing", 0.0)),
				"range": float(effect.get("range", radius)),
				"duration": float(effect.get("duration", 5.0)),
				"tick_interval": float(effect.get("tick_interval", effect.get("attack_interval", 1.0))),
				"tick_timer": 0.0,
				"pull": float(effect.get("pull_strength", 0.0)),
				"expire_damage": float(effect.get("expire_damage", 0.0)),
				"follows": mechanic == "orbit" or bool(effect.get("field_follows_player", false)),
				"orbit_count": clampi(int(effect.get("orbit_count", 3)), 1, 8),
				"phase": 0.0,
				"angular_speed": float(effect.get("angular_speed", 2.5)),
				"collision_radius": float(effect.get("collision_radius", 20.0)),
				"arm_timer": maxf(0.0, float(effect.get("arm_delay", 1.0))),
				"trigger_radius": float(effect.get("trigger_radius", 70.0)),
				"overheal_barrier": bool(effect.get("overheal_barrier", false)),
				"stability": clampf(float(effect.get("stability", 0.0)), 0.0, STABILITY_LIMIT),
				"hit": hit,
				"poison_linger": float(effect.get("poison_linger", 2.0)),
			})
			_vfx(zone, "burst", [effect_position, radius * 0.6])
		"summon":
			_spawn_summons(peer_id, effect, target)
			_vfx(zone, "summon", [target])
		"barrier":
			var amount := float(effect.get("barrier", 0.0))
			_add_barrier(peer_id, amount, float(effect.get("duration", 3.5)))
			state["barrier_contact_damage"] = float(effect.get("contact_damage", 0.0))
			state["barrier_expire_damage"] = float(effect.get("expire_nova_damage", 0.0))
			state["barrier_radius"] = radius
			var shared := float(effect.get("allies_receive_barrier", 0.0)) if typeof(effect.get("allies_receive_barrier")) != TYPE_BOOL else (1.0 if bool(effect["allies_receive_barrier"]) else 0.0)
			if shared > 0.0:
				for member in _players_in_zone(zone):
					if member != peer_id and (player(member)["position"] as Vector2).distance_to(position) <= radius:
						_add_barrier(member, amount * minf(1.0, shared), float(effect.get("duration", 3.5)))
			_vfx(zone, "ring", [position, radius])
		"chain":
			_damage_chain(peer_id, effect, hit)
	var repeats := clampi(int(effect.get("repeat_count", 0)), 0, 4)
	if repeats > 0:
		var echo := effect.duplicate(true)
		echo["repeat_count"] = 0
		for index in range(repeats):
			_scheduled.append({"time": maxf(0.05, float(effect.get("repeat_delay", 0.6))) * float(index + 1), "peer": peer_id, "effect": echo, "target": target, "zone": zone, "floor": current_floor})


func _ranged_skill_target(peer_id: int, target: Vector2, effect: Dictionary) -> Vector2:
	var origin: Vector2 = player(peer_id)["position"]
	var offset := target - origin
	var reach := maxf(1.0, float(effect.get("range", 420.0)))
	return (origin + offset.limit_length(reach)).clamp(Vector2(20, 20), _zone_size(player(peer_id)["zone"]) - Vector2(20, 20))


func _limit_skill_deployments(peer_id: int, gem_id: String) -> void:
	var owned: Array[Dictionary] = []
	for current in persistent_effects:
		if int(current.get("owner_peer", -1)) == peer_id and String(current.get("gem_id", "")) == gem_id and String(current.get("mechanic", "")) != "summon":
			owned.append(current)
	if owned.size() >= 8:
		persistent_effects.erase(owned[0])


func _hit_context(effect: Dictionary) -> Dictionary:
	return {
		"damage_type": "arcane" if "magic" in (effect.get("tags", []) as Array) else "physical",
		"crit_add": float(effect.get("critical_chance", 0.0)),
		"life_steal": float(effect.get("life_steal", 0.0)),
		"knockback": float(effect.get("knockback", 0.0)),
		"slow": clampf(float(effect.get("slow", 0.0)), 0.0, 0.8),
		"slow_duration": maxf(1.0, float(effect.get("status_duration", effect.get("duration", 1.5)))) if effect.has("slow") else 0.0,
		"vulnerable": float(effect.get("damage_taken", 0.0)),
		"vulnerable_duration": float(effect.get("status_duration", effect.get("duration", 3.0))),
		"barrier_per_hit": float(effect.get("barrier_per_hit", 0.0)),
		"breath_per_hit": float(effect.get("breath_per_hit", 0.0)),
		"breath_on_kill": float(effect.get("breath_on_kill", 0.0)),
		"gem": true,
		"gem_id": String(effect.get("gem_id", "")),
		"passive": bool(effect.get("passive_cast", false)),
	}


func _add_barrier(peer_id: int, amount: float, duration: float, linked: bool = true) -> void:
	var state := player(peer_id)
	if state.is_empty() or amount <= 0.0:
		return
	amount *= _mod(peer_id, "barrier_mult")
	state["barrier"] = float(state["barrier"]) + amount
	state["barrier_timer"] = maxf(float(state.get("barrier_timer", 0.0)), duration)
	if not linked:
		return
	for mechanic in _mechanics(peer_id, "ally_link"):
		for other in _players_in_arena():
			if other != peer_id and (player(other)["position"] as Vector2).distance_to(state["position"] as Vector2) <= AURA_RADIUS:
				_add_barrier(other, amount * float(mechanic.get("ratio", 0.3)), duration, false)


func heal_player(peer_id: int, amount: float) -> void:
	var state := player(peer_id)
	if state.is_empty() or amount <= 0.0:
		return
	state["health"] = minf(max_health(peer_id), float(state["health"]) + amount * _mod(peer_id, "healing_mult"))


## Gatilhos de baixa dos marcos: cura, Fôlego, estilhaço, recarga e invocação.
func _on_kill(peer_id: int, position: Vector2) -> void:
	var state := player(peer_id)
	if state.is_empty():
		return
	heal_player(peer_id, _mod(peer_id, "heal_on_kill_add"))
	state["breath"] = minf(max_breath(peer_id), float(state["breath"]) + _mod(peer_id, "breath_on_kill_add"))
	for mechanic in _mechanics(peer_id, "cooldown_refund"):
		var cooldowns := state["cooldowns"] as Array[float]
		for slot in range(cooldowns.size()):
			cooldowns[slot] = maxf(0.0, cooldowns[slot] - float(mechanic.get("seconds", 0.5)))
	for mechanic in _mechanics(peer_id, "summon_on_kill"):
		if _mechanic_random.randf() < float(mechanic.get("chance", 0.1)):
			_spawn_summons(peer_id, {"summon_definition_id": "molde_vigilante", "summon_count": 1, "duration": float(mechanic.get("duration", 8.0))}, position)
	if _kill_burst_depth > 0:
		return
	_kill_burst_depth += 1
	for mechanic in _mechanics(peer_id, "kill_burst"):
		_vfx(arena_zone(), "ring", [position, float(mechanic.get("radius", 90.0))])
		damage_enemies(peer_id, position, float(mechanic.get("radius", 90.0)), float(mechanic.get("damage", 20.0)))
	_kill_burst_depth -= 1


## Último recurso próprio (`last_stand`) e socorro a aliados (`rescue`), cada um com recarga.
func _check_low_health(peer_id: int) -> void:
	var state := player(peer_id)
	var ratio := float(state["health"]) / max_health(peer_id)
	var timers := state.get("mechanic_timers", {}) as Dictionary
	state["mechanic_timers"] = timers
	for mechanic in _mechanics(peer_id, "last_stand"):
		var key := "last_stand_%s" % str(mechanic.get("threshold", 0.3))
		if ratio < float(mechanic.get("threshold", 0.3)) and float(timers.get(key, 0.0)) <= 0.0:
			timers[key] = float(mechanic.get("cooldown", 30.0))
			_add_barrier(peer_id, float(mechanic.get("barrier", 40.0)), 6.0)
			_vfx(state["zone"], "label", [state["position"], "SEGUNDO FOLEGO", Color("7fd6e0"), "heal"])
	for helper in _players_in_arena():
		if helper == peer_id or not is_connected_player(helper):
			continue
		var helper_state := player(helper)
		if (helper_state["position"] as Vector2).distance_to(state["position"] as Vector2) > 260.0:
			continue
		var helper_timers := helper_state.get("mechanic_timers", {}) as Dictionary
		helper_state["mechanic_timers"] = helper_timers
		for mechanic in _mechanics(helper, "rescue"):
			var key := "rescue_%s" % str(mechanic.get("threshold", 0.3))
			if ratio < float(mechanic.get("threshold", 0.3)) and float(helper_timers.get(key, 0.0)) <= 0.0:
				helper_timers[key] = float(mechanic.get("cooldown", 20.0))
				_add_barrier(peer_id, float(mechanic.get("barrier", 35.0)), 6.0)
				_vfx(state["zone"], "chain", [[helper_state["position"], state["position"]] as Array[Vector2]])


func _cast_projectiles(peer_id: int, effect: Dictionary, target: Vector2, hit: Dictionary) -> void:
	var state := player(peer_id)
	var zone := state["zone"] as StringName
	var origin := (state["position"] as Vector2) - Vector2(0.0, 14.0)
	var max_range := float(effect.get("range", 520.0))
	if bool(effect.get("homing", false)):
		var homing_target := nearest_enemy_to(target, 200.0)
		if homing_target >= 0:
			target = enemies[homing_target]["position"] as Vector2
	var aim := target - origin
	var distance := minf(aim.length(), max_range)
	var direction := aim.normalized() if aim.length() > 0.1 else Vector2.RIGHT
	var count := clampi(1 + int(effect.get("projectile_count", 0)), 1, 8)
	var radius := float(effect.get("radius", 42.0)) + float(effect.get("impact_area", 0.0))
	var power := float(effect.get("power", 0.0))
	var pierce := int(effect.get("pierce", 0))
	var ricochets := int(effect.get("ricochet", 0))
	var travel_time := 0.12 / maxf(0.2, float(effect.get("speed", 1.0)))
	for index in range(count):
		var offset := (float(index) - float(count - 1) * 0.5) * 0.2
		var end := origin + direction.rotated(offset) * distance
		_vfx(zone, "travel", ["vfx/needle", origin, end, travel_time, radius])
		var struck: Array[Dictionary] = []
		for enemy in enemies:
			var spot := enemy["position"] as Vector2
			if spot.distance_to(end) <= radius:
				struck.append(enemy)
		if pierce > 0:
			_damage_segment(peer_id, origin, end, 22.0, power * 0.8, pierce, hit)
		damage_enemies(peer_id, end, radius, power, hit)
		var last := end
		for _bounce in range(ricochets):
			var next := -1
			var best := 180.0
			for candidate in range(enemies.size()):
				var candidate_position := enemies[candidate]["position"] as Vector2
				var candidate_distance := candidate_position.distance_to(last)
				if candidate_distance < best and candidate_distance > 8.0 and not struck.has(enemies[candidate]):
					best = candidate_distance
					next = candidate
			if next < 0:
				break
			var bounce_position := enemies[next]["position"] as Vector2
			_vfx(zone, "chain", [[last, bounce_position]])
			struck.append(enemies[next])
			damage_enemy(peer_id, next, power * 0.7, hit)
			last = bounce_position
		if bool(effect.get("return_projectile", false)):
			_vfx(zone, "travel", ["vfx/needle", end, origin, travel_time * 1.5, 16.0])
			_damage_segment(peer_id, end, origin, 22.0, power * 0.6, 99, hit)
		for branch in range(clampi(int(effect.get("fork_count", 0)), 0, 4)):
			var branch_angle := (float(branch) - float(clampi(int(effect.get("fork_count", 0)), 0, 4) - 1) * 0.5) * 0.75
			var branch_end := end + direction.rotated(branch_angle) * max_range * 0.4
			_vfx(zone, "travel", ["vfx/needle", end, branch_end, travel_time, 16.0])
			_damage_segment(peer_id, end, branch_end, 20.0, power * 0.65, 99, hit)


## Dano ao longo de uma linha, do ponto inicial para o final, limitado a "limit" alvos.
func _damage_segment(peer_id: int, from: Vector2, to: Vector2, width: float, damage: float, limit: int, hit: Dictionary) -> void:
	var targets: Array[Dictionary] = []
	for index in range(enemies.size()):
		var position := enemies[index]["position"] as Vector2
		var closest := Geometry2D.get_closest_point_to_segment(position, from, to)
		if closest.distance_to(position) <= width:
			targets.append({"index": index, "along": from.distance_to(closest)})
	targets.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left["along"]) < float(right["along"]))
	var selected: Array[int] = []
	for entry in targets.slice(0, mini(limit, targets.size())):
		selected.append(int(entry["index"]))
	selected.sort()
	selected.reverse()
	for index in selected:
		damage_enemy(peer_id, index, damage, hit)


func _update_persistent_effects(delta: float) -> void:
	for index in range(persistent_effects.size() - 1, -1, -1):
		if index >= persistent_effects.size():
			continue
		var effect := persistent_effects[index]
		var owner_peer := int(effect.get("owner_peer", -1))
		var mechanic := String(effect["mechanic"])
		if bool(effect.get("timed", true)):
			effect["duration"] = float(effect["duration"]) - delta
		if mechanic != "summon" and bool(effect.get("follows", false)) and players.has(owner_peer):
			effect["position"] = player(owner_peer)["position"]
		if mechanic == "orbit":
			effect["phase"] = fmod(float(effect.get("phase", 0.0)) + float(effect["angular_speed"]) * delta, TAU)
		if mechanic == "volley":
			var archer := player(owner_peer)
			var cost := float(effect["breath_per_second"]) * _mod(owner_peer, "breath_cost_mult") * delta
			# Sem limite de tempo: só acaba ao lançar de novo, sem Fôlego, caída ou fora da arena.
			if archer.is_empty() or archer["zone"] not in ARENA_ZONES or bool(archer.get("downed", false)) or float(archer["breath"]) < cost:
				if not archer.is_empty() and float(archer.get("breath", 0.0)) < cost:
					_status(owner_peer, "Folego esgotado: Saraivada encerrada.")
				persistent_effects.erase(effect)
				continue
			archer["breath"] = float(archer["breath"]) - cost
			effect["elapsed"] = float(effect.get("elapsed", 0.0)) + delta
			effect["tick_timer"] = float(effect["tick_timer"]) - delta
			var shot_interval := maxf(0.001, float(effect["tick_interval"]) / float(effect["arrow_count"]))
			while float(effect["tick_timer"]) <= 0.0:
				effect["tick_timer"] = float(effect["tick_timer"]) + shot_interval
				_fire_volley(effect)
			continue
		if mechanic == "mine":
			effect["arm_timer"] = maxf(0.0, float(effect["arm_timer"]) - delta)
			if float(effect["duration"]) <= 0.0 or (float(effect["arm_timer"]) <= 0.0 and nearest_enemy_to(effect["position"], float(effect["trigger_radius"])) >= 0):
				_vfx(arena_zone(), "burst", [effect["position"], float(effect["radius"])])
				damage_enemies(owner_peer, effect["position"], float(effect["radius"]), float(effect["power"]), effect.get("hit", {}) as Dictionary)
				persistent_effects.erase(effect)
			continue
		if float(effect.get("pull", 0.0)) > 0.0:
			for enemy in enemies:
				var to_center := (effect["position"] as Vector2) - (enemy["position"] as Vector2)
				if to_center.length() <= float(effect["radius"]) and to_center.length() > 8.0:
					enemy["position"] = (enemy["position"] as Vector2) + to_center.normalized() * minf(to_center.length(), float(effect["pull"]) * delta)
		if mechanic == "summon" and String(effect.get("behavior", "stationary")) == "follow_owner" and players.has(owner_peer):
			var summon_position := effect["position"] as Vector2
			var owner_offset := (player(owner_peer)["position"] as Vector2) - summon_position
			if owner_offset.length() > 42.0:
				effect["position"] = summon_position + owner_offset.normalized() * minf(float(effect.get("movement_speed", 120.0)) * delta, owner_offset.length() - 42.0)
		elif mechanic == "summon" and String(effect.get("behavior", "")) == "chase_target":
			var nearest := _summon_target(effect)
			if nearest >= 0:
				var offset := (enemies[nearest]["position"] as Vector2) - (effect["position"] as Vector2)
				if offset.length() > float(effect["range"]) * 0.7:
					effect["position"] = (effect["position"] as Vector2) + offset.normalized() * minf(float(effect["movement_speed"]) * delta, offset.length())
		effect["tick_timer"] = float(effect["tick_timer"]) - delta
		if float(effect["tick_timer"]) <= 0.0:
			effect["tick_timer"] = float(effect["tick_interval"])
			if mechanic == "summon":
				var nearest := _summon_target(effect)
				if nearest >= 0 and (enemies[nearest]["position"] as Vector2).distance_to(effect["position"]) <= float(effect["range"]):
					damage_enemy(owner_peer, nearest, float(effect["power"]), effect.get("hit", {}) as Dictionary)
			elif mechanic == "poison_pool":
				# Toxina por segundo = potência da poça; dura um pouco depois de sair dela.
				for enemy in enemies:
					if (enemy["position"] as Vector2).distance_to(effect["position"] as Vector2) <= float(effect["radius"]):
						apply_poison(owner_peer, enemy, "toxina", {"damage": float(effect["power"]) * 0.5, "interval": 0.5,
							"remaining": float(effect.get("poison_linger", 2.0)), "gem_id": String(effect.get("gem_id", ""))})
			elif mechanic == "orbit":
				for point in SkillGeometryScript.orbit_points(effect["position"], float(effect["radius"]), float(effect["phase"]), int(effect["orbit_count"])):
					damage_enemies(owner_peer, point, float(effect["collision_radius"]), float(effect["power"]), effect.get("hit", {}) as Dictionary)
			else:
				damage_enemies(owner_peer, effect["position"] as Vector2, float(effect["radius"]), float(effect["power"]), effect.get("hit", {}) as Dictionary)
				if mechanic == "sanctuary":
					for member in _players_in_arena():
						if (player(member)["position"] as Vector2).distance_to(effect["position"] as Vector2) <= float(effect["radius"]):
							var member_state := player(member)
							var healed := float(member_state["health"]) + float(effect["healing"])
							if bool(effect.get("overheal_barrier", false)) and healed > max_health(member):
								_add_barrier(member, healed - max_health(member), 3.0)
							member_state["health"] = minf(max_health(member), healed)
		if bool(effect.get("timed", true)) and float(effect["duration"]) <= 0.0:
			var expire := float(effect.get("expire_damage", 0.0))
			if expire > 0.0:
				var expire_radius := float(effect.get("expire_radius", effect.get("radius", 80.0)))
				_vfx(arena_zone(), "ring", [effect["position"], expire_radius])
				damage_enemies(owner_peer, effect["position"] as Vector2, expire_radius, expire, effect.get("hit", {}) as Dictionary)
			persistent_effects.erase(effect)


## Aplica ou renova um veneno. Mesmo tipo não acumula: fica o maior dano por tick e a maior
## duração (esporos nunca expiram; só a morte do alvo os espalha).
func apply_poison(peer_id: int, enemy: Dictionary, poison_type: String, data: Dictionary) -> void:
	var poisons := enemy.get_or_add("poisons", {}) as Dictionary
	var current := poisons.get(poison_type, {}) as Dictionary
	var entry := {
		"type": poison_type, "peer": peer_id, "gem_id": String(data.get("gem_id", "")),
		"damage": maxf(float(data.get("damage", 0.0)), float(current.get("damage", 0.0))),
		"growth": float(data.get("growth", current.get("growth", 0.0))),
		"interval": maxf(0.1, float(data.get("interval", 1.0))),
		"timer": float(current.get("timer", data.get("interval", 1.0))),
		"lasting": float(data.get("remaining", 1.0)) < 0.0,
		"remaining": maxf(float(data.get("remaining", 1.0)), float(current.get("remaining", 0.0))),
		"spread_radius": float(data.get("spread_radius", current.get("spread_radius", 0.0))),
		"share": maxf(float(data.get("share", 0.0)), float(current.get("share", 0.0))),
		"stack": maxf(float(data.get("stack", 1.0)), float(current.get("stack", 1.0))),
		"cap": maxf(float(data.get("cap", 1.0)), float(current.get("cap", 1.0))),
	}
	poisons[poison_type] = entry


## Dano do próximo tick de um veneno neste inimigo: (base + fração da Vida máxima) × acúmulo.
func poison_tick_damage(enemy: Dictionary, entry: Dictionary) -> float:
	return (float(entry["damage"]) + float(entry.get("share", 0.0)) * float(enemy.get("max_health", 0.0))) * float(entry.get("stack", 1.0))


## Fração da Vida máxima por tick de esporo, menor em elites e chefes.
func spore_health_share(enemy: Dictionary) -> float:
	var encounter := String(enemy.get("encounter_class", "common"))
	if bool(enemy.get("floor_boss", false)) or encounter in ["boss", "raid"]:
		return float(SPORE_HEALTH_SHARE["boss"])
	return float(SPORE_HEALTH_SHARE["elite" if encounter == "elite" else "common"])


## Teto do acúmulo dos esporos: x25, ampliado pela Sabedoria (até x40).
func spore_stack_cap(peer_id: int) -> float:
	return SPORE_STACK_CAP * float(derived_stats(peer_id).get("spore_cap_multiplier", 1.0))


## Cepa: maior acúmulo de esporo que a personagem alcançou neste andar (0 em outro andar).
func spore_strain(peer_id: int) -> float:
	var strain := player(peer_id).get("spore_strain", {}) as Dictionary
	return float(strain.get("stack", 0.0)) if int(strain.get("floor", -1)) == current_floor else 0.0


func _record_spore_strain(peer_id: int, stack: float) -> void:
	if players.has(peer_id) and stack > spore_strain(peer_id):
		player(peer_id)["spore_strain"] = {"floor": current_floor, "stack": stack}


func is_poisoned(enemy: Dictionary) -> bool:
	return not (enemy.get("poisons", {}) as Dictionary).is_empty()


func poison_view(enemy: Dictionary) -> Array:
	var result := []
	for entry: Dictionary in (enemy.get("poisons", {}) as Dictionary).values():
		result.append({"type": entry["type"], "damage": poison_tick_damage(enemy, entry) / float(entry["interval"])})
	return result


## Ticks de veneno. A lista é copiada: um tick pode matar e espalhar para outros inimigos.
func _step_poisons(delta: float) -> void:
	for enemy in enemies.duplicate():
		var poisons := enemy.get("poisons", {}) as Dictionary
		for poison_type: String in poisons.keys():
			var entry := poisons[poison_type] as Dictionary
			entry["timer"] = float(entry["timer"]) - delta
			if not bool(entry.get("lasting", false)):
				entry["remaining"] = float(entry["remaining"]) - delta
			if float(entry["timer"]) <= 0.0:
				entry["timer"] = float(entry["timer"]) + float(entry["interval"])
				var index := enemies.find(enemy)
				if index >= 0 and players.has(int(entry["peer"])):
					damage_enemy(int(entry["peer"]), index, poison_tick_damage(enemy, entry), {"gem": true, "gem_id": entry["gem_id"], "dot": true, "damage_type": "arcane", "poison": poison_type})
				entry["stack"] = minf(float(entry.get("cap", 1.0)), float(entry.get("stack", 1.0)) * (1.0 + float(entry["growth"])))
				if poison_type == "esporo":
					_record_spore_strain(int(entry["peer"]), float(entry["stack"]))
			if not bool(entry.get("lasting", false)) and float(entry["remaining"]) <= 0.0:
				poisons.erase(poison_type)
		if poisons.is_empty():
			enemy.erase("poisons")


## Esporos de um inimigo que morreu passam, com o dano atual, para os vizinhos no raio.
func _spread_poisons(defeated: Dictionary) -> void:
	var spore := (defeated.get("poisons", {}) as Dictionary).get("esporo", {}) as Dictionary
	if spore.is_empty() or float(spore.get("spread_radius", 0.0)) <= 0.0:
		return
	var origin := defeated["position"] as Vector2
	var spread := 0
	# Alcance de proliferação (afixo da Presa da Serpente) e Inteligência de quem aplicou ampliam o raio.
	var radius := float(spore["spread_radius"]) * (spore_spread_multiplier(int(spore["peer"])) if players.has(int(spore["peer"])) else 1.0)
	_vfx(arena_zone(), "ring", [origin, radius])
	for enemy in enemies:
		if spread >= SPORE_SPREAD_LIMIT:
			break
		if (enemy["position"] as Vector2).distance_to(origin) <= radius:
			# A fração da Vida é do novo alvo; o acúmulo segue e muta +10% a cada salto.
			var copy := spore.duplicate()
			copy["timer"] = float(spore["interval"])
			copy["share"] = spore_health_share(enemy)
			copy["stack"] = minf(float(spore.get("cap", 1.0)), float(spore.get("stack", 1.0)) * (1.0 + SPORE_MUTATION))
			var poisons := enemy.get_or_add("poisons", {}) as Dictionary
			if float(copy["stack"]) >= float((poisons.get("esporo", {}) as Dictionary).get("stack", 0.0)):
				poisons["esporo"] = copy
				_record_spore_strain(int(spore["peer"]), float(copy["stack"]))
			spread += 1


## Multiplicador do raio da explosão de esporos: Inteligência (StatResolver) vezes afixos e passivas.
func spore_spread_multiplier(peer_id: int) -> float:
	return float(derived_stats(peer_id).get("spore_spread_multiplier", 1.0)) * _mod(peer_id, "poison_spread_mult")


## Saraivada: usar de novo encerra; senão acompanha a portadora disparando em círculo.
func _toggle_volley(peer_id: int, effect: Dictionary, hit: Dictionary) -> void:
	var gem_id := String(effect.get("gem_id", ""))
	for existing in persistent_effects:
		if String(existing["mechanic"]) == "volley" and int(existing["owner_peer"]) == peer_id:
			persistent_effects.erase(existing)
			_status(peer_id, "Saraivada encerrada.")
			return
	persistent_effects.append({
		"mechanic": "volley", "gem_id": gem_id, "owner_peer": peer_id, "position": player(peer_id)["position"],
		"follows": true, "timed": false, "duration": 0.0, "radius": float(effect.get("range", 300.0)),
		"arrow_width": float(effect.get("radius", 16.0)),
		"power": float(effect.get("power", 0.0)), "range": float(effect.get("range", 300.0)),
		"tick_interval": float(effect.get("tick_interval", 0.4)), "tick_timer": 0.0,
		"arrow_count": clampi(int(effect.get("arrow_count", 24)), 1, 48),
		"breath_per_second": float(effect.get("breath_per_second", 9.0)), "volley_index": 0, "hit": hit,
		"elapsed": 0.0, "start_angle": (player(peer_id).get("facing_direction", Vector2.DOWN) as Vector2).angle(),
		"pierce": clampi(int(effect.get("pierce", 0)), 0, 6),
	})


## Um disparo por passo angular: uma volta conserva a quantidade e o tempo da antiga
## rajada. O acumulador preserva a cadencia mesmo quando cabem varias flechas num frame.
func _fire_volley(effect: Dictionary) -> void:
	var peer_id := int(effect["owner_peer"])
	var state := player(peer_id)
	var origin := (state["position"] as Vector2) - Vector2(0.0, 12.0)
	var count := int(effect["arrow_count"])
	var index := int(effect["volley_index"])
	effect["volley_index"] = index + 1
	if (index + 1) % count == 0:
		ItemPassivesScript.on_volley_turn(self, peer_id, effect)
	var element := VOLLEY_ELEMENTS[(index / count) % VOLLEY_ELEMENTS.size()] as Dictionary
	var hit := (effect["hit"] as Dictionary).duplicate()
	for key: String in element:
		if key != "id" and key != "power_multiplier":
			hit[key] = maxf(float(hit.get(key, 0.0)), float(element[key]))
	var previous_theme := _vfx_theme
	_vfx_theme = "element:" + String(element["id"])
	var direction := Vector2.RIGHT.rotated(float(effect.get("start_angle", 0.0)) + TAU * float(index % count) / float(count))
	var end := origin + direction * float(effect["range"])
	_vfx(state["zone"], "travel", ["vfx/arrow", origin + direction * 18.0, end, 0.22, 14.0])
	_damage_segment(peer_id, origin, end, float(effect.get("arrow_width", 16.0)), float(effect["power"]) * float(element.get("power_multiplier", 1.0)), 1 + int(effect.get("pierce", 0)), hit)
	_vfx_theme = previous_theme


func _volley_spin(peer_id: int) -> Dictionary:
	for effect in persistent_effects:
		if effect["mechanic"] == "volley" and int(effect["owner_peer"]) == peer_id:
			var elapsed := float(effect.get("elapsed", 0.0))
			var speed := TAU / maxf(0.001, float(effect["tick_interval"]))
			return {"phase": fposmod(float(effect.get("start_angle", 0.0)) + elapsed * speed, TAU), "elapsed": elapsed}
	return {}


func _summon_target(effect: Dictionary) -> int:
	var chosen := -1
	var best := INF
	var center: Vector2 = effect["position"]
	if String(effect.get("targeting", "")) == "owner_target":
		center = effect.get("owner_target", center)
	for index in range(enemies.size()):
		var distance := center.distance_to(enemies[index]["position"])
		var reach := 600.0 if String(effect.get("behavior", "")) == "chase_target" else float(effect["range"])
		if distance > reach:
			continue
		var score := float(enemies[index]["health"]) if String(effect.get("targeting", "")) == "lowest_health_hostile" else distance
		if score < best:
			best = score
			chosen = index
	return chosen


func _spawn_summons(peer_id: int, effect: Dictionary, target: Vector2) -> void:
	var definition_id := String(effect.get("summon_definition_id", ""))
	var definition := _find(_collection("summons"), definition_id)
	if definition.is_empty():
		return
	var owner_limit := maxi(1, int(definition.get("owner_limit", 1)))
	var summon_count := clampi(int(effect.get("summon_count", 1)), 1, 8)
	for summon_index in range(summon_count):
		var owned: Array[int] = []
		for index in range(persistent_effects.size()):
			var current := persistent_effects[index]
			if String(current.get("mechanic", "")) == "summon" and int(current.get("owner_peer", -1)) == peer_id and String(current.get("summon_definition_id", "")) == definition_id:
				owned.append(index)
		if owned.size() >= owner_limit:
			if String(definition.get("replacement_policy", "oldest")) == "reject":
				break
			persistent_effects.remove_at(owned[0])
		var spread := Vector2.RIGHT.rotated(TAU * float(summon_index) / float(maxi(1, summon_count))) * 22.0
		var summon_duration := float(effect.get("duration", definition.get("duration", 0.0)))
		persistent_effects.append({
			"mechanic": "summon",
			"instance_id": "summon_%d_%d" % [peer_id, _next_summon_sequence],
			"summon_definition_id": definition_id,
			"owner_peer": peer_id,
			"owner_id": "peer_%d" % peer_id,
			"team_id": "heroes",
			"position": target + spread,
			"radius": float(effect.get("radius", definition.get("collision_radius", 12.0))),
			"collision_radius": float(definition.get("collision_radius", 12.0)),
			"power": float(effect.get("power", definition.get("power", 0.0))),
			"health": float(definition.get("health", 1.0)),
			"max_health": float(definition.get("health", 1.0)),
			"range": float(effect.get("range", definition.get("range", 100.0))),
			"duration": summon_duration,
			"timed": summon_duration > 0.0,
			"tick_interval": float(effect.get("attack_interval", definition.get("attack_interval", 1.0))),
			"tick_timer": 0.0,
			"behavior": "follow_owner" if bool(effect.get("summon_follows_player", false)) else String(definition.get("behavior", "stationary")),
			"movement_speed": float(definition.get("movement_speed", 0.0)),
			"targeting": String(definition.get("targeting", "nearest_hostile")),
			"can_be_damaged": bool(definition.get("can_be_damaged", true)),
			"expire_damage": float(effect.get("expire_damage", 0.0)),
			"expire_radius": float(effect.get("expire_radius", 80.0)),
			"hit": _hit_context(effect),
			"owner_target": target,
		})
		_next_summon_sequence += 1


## Corrente real: do portador ao alvo mais próximo e, dali, saltos dentro de "chain_range".
func _damage_chain(peer_id: int, effect: Dictionary, hit: Dictionary) -> void:
	var state := player(peer_id)
	var origin := (state["position"] as Vector2) - Vector2(0.0, 14.0)
	var count := int(effect.get("chain_count", 3))
	var jump := float(effect.get("chain_range", 150.0))
	var power := float(effect.get("power", 0.0))
	var points: Array[Vector2] = [origin]
	var chosen: Array[int] = []
	var from := origin
	var search := float(effect.get("range", 400.0))
	for _link in range(count):
		var next := -1
		var best := search
		for index in range(enemies.size()):
			if chosen.has(index):
				continue
			var distance := from.distance_to(enemies[index]["position"] as Vector2)
			if distance < best:
				best = distance
				next = index
		if next < 0:
			break
		chosen.append(next)
		from = enemies[next]["position"] as Vector2
		points.append(from)
		search = jump
	if chosen.is_empty():
		return
	_vfx(arena_zone(), "chain", [points])
	var heal := float(effect.get("heal_per_chain", 0.0)) * float(chosen.size())
	if heal > 0.0:
		state["health"] = minf(max_health(peer_id), float(state["health"]) + heal)
	var hits: Array[Dictionary] = []
	for index: int in chosen:
		hits.append(enemies[index])
	if bool(effect.get("repeat_last_target", false)):
		hits.append(hits[-1])
	for enemy in hits:
		var index := enemies.find(enemy)
		if index >= 0:
			damage_enemy(peer_id, index, power, hit)


func _apply_passive_requests(peer_id: int, requests: Array) -> void:
	var state := player(peer_id)
	if state.is_empty() or state["zone"] not in ARENA_ZONES:
		return
	for request: Dictionary in requests:
		match String(request.get("type", "")):
			"nova":
				var center := request.get("position", state["position"]) as Vector2
				_vfx(state["zone"], "ring", [center, float(request["radius"])])
				damage_enemies(peer_id, center, float(request["radius"]), float(request["amount"]))
			"barrier":
				_add_barrier(peer_id, float(request["amount"]), 6.0)
			"breath":
				state["breath"] = minf(max_breath(peer_id), float(state["breath"]) + float(request["amount"]))
			"ally_barrier":
				for other in _players_in_arena():
					if other != peer_id and (player(other)["position"] as Vector2).distance_to(state["position"] as Vector2) <= float(request.get("radius", 180.0)):
						_add_barrier(other, float(request["amount"]), 4.0, false)
			"summon":
				_spawn_summons(peer_id, {"summon_definition_id": "molde_vigilante", "summon_count": 1, "duration": float(request.get("duration", 8.0))}, request.get("position", state["position"]) as Vector2)
			"conduct":
				for origin: Vector2 in request["origins"]:
					var target_index := nearest_enemy_to(origin, float(request.get("range", 200.0)))
					if target_index < 0:
						continue
					var link: Array[Vector2] = [origin, enemies[target_index]["position"] as Vector2]
					_vfx(state["zone"], "chain", [link])
					damage_enemy(peer_id, target_index, float(request["amount"]))


# ---------------------------------------------------------------- saque, EXP e atributos

func _grant_loot(peer_id: int, enemy: Dictionary) -> void:
	loot_kill_sequence += 1
	var state := player(peer_id)
	if state.is_empty():
		return
	var share := reward_share()
	if share < 1.0:
		var reward_random := RandomNumberGenerator.new()
		reward_random.seed = hash([encounter_seed, loot_kill_sequence, "reward"])
		if reward_random.randf() >= share:
			return
	var loot_table := _find(_collection("loot_tables"), String(enemy.get("loot_table_id", "")))
	var difficulty := LootDifficultyScript.score(enemy, float(party_scaling()["budget"]))
	var drops: Array = _loot_resolver.call("resolve", loot_table, encounter_seed, loot_kill_sequence,
		LootDifficultyScript.chance_multiplier(difficulty), LootDifficultyScript.quantity_multiplier(difficulty))
	var quality_random := RandomNumberGenerator.new()
	quality_random.seed = hash([encounter_seed, loot_kill_sequence, "quality"])
	if drops.is_empty() and loot_table.is_empty():
		drops.append({"item_id": "pedra_regenerativa", "quantity": LootDifficultyScript.scaled_quantity(maxi(0, int(enemy.get("loot_value", 1))), difficulty, quality_random)})
	if quality_random.randf() < LootDifficultyScript.bonus_chance(difficulty):
		var allow_relics := String(enemy.get("encounter_class", "common")) in ["boss", "raid"]
		var bonus := LootDifficultyScript.pick_bonus_item(_collection("items"), difficulty, allow_relics, quality_random)
		if not bonus.is_empty():
			drops.append({"item_id": bonus, "quantity": 1})
	if quality_random.randf() < float(UNIQUE_WEAPON_CHANCE.get(String(enemy.get("encounter_class", "common")), 0.0)):
		var unique := _pick_unique_weapon(peer_id, quality_random)
		if not unique.is_empty():
			drops.append({"item_id": unique, "quantity": 1})
	_record_bestiary_drops(enemy, drops)
	var origin := enemy.get("position", state["position"]) as Vector2
	for drop_index in range(drops.size()):
		var drop := drops[drop_index] as Dictionary
		var item_id := String(drop.get("item_id", ""))
		var quantity := maxi(0, int(drop.get("quantity", 0)))
		if item_id.is_empty() or quantity <= 0:
			continue
		var scatter := Vector2.RIGHT.rotated(TAU * float(drop_index) / float(maxi(1, drops.size())) + float(loot_kill_sequence)) * (10.0 + 8.0 * float(drop_index))
		var quality := ""
		if _is_equipment(item_id):
			quality = LootDifficultyScript.pick_weighted(LootDifficultyScript.fabrication_weights(difficulty), quality_random)
		drop_item(arena_zone(), origin + scatter, item_id, quantity, quality)


## Arma única de uma das gemas ativas de quem abateu; vazio se nenhuma tiver arma.
func _pick_unique_weapon(peer_id: int, random: RandomNumberGenerator) -> String:
	var gems := _gem_state(peer_id)
	if gems.is_empty():
		return ""
	var candidates: Array[String] = []
	for gem_id: Variant in gems["slots"] as Array:
		if String(gem_id).is_empty():
			continue
		var unique_id := "unica_" + String(gem_id)
		if not _find(_collection("items"), unique_id).is_empty():
			candidates.append(unique_id)
	return candidates[random.randi_range(0, candidates.size() - 1)] if not candidates.is_empty() else ""


## Coloca saque no chão. Itens empilháveis iguais muito próximos se juntam numa pilha.
func drop_item(zone: StringName, position: Vector2, item_id: String, quantity: int, quality: String = "") -> void:
	if quantity <= 0:
		return
	position = position.clamp(Vector2(24.0, 24.0), _zone_size(&"tower") - Vector2(24.0, 24.0))
	var equipment := _is_equipment(item_id)
	if not equipment:
		for item in ground_items:
			if item["zone"] == zone and int(item.get("floor", 0)) == current_floor and String(item["item_id"]) == item_id and (item["position"] as Vector2).distance_to(position) <= STACK_RADIUS:
				item["quantity"] = int(item["quantity"]) + quantity
				return
	var definition := _find(_collection("items"), item_id)
	if equipment and quality.is_empty():
		quality = "regular"
	var display := item_display_name(item_id)
	if equipment and quality != "regular":
		display += " " + String(LootDifficultyScript.FABRICATION_LABELS.get(quality, ""))
	ground_items.append({
		"id": _ground_sequence, "zone": zone, "floor": current_floor, "position": position, "item_id": item_id,
		"quantity": quantity, "tier": String(definition.get("tier", "common")),
		"name": display, "equipment": equipment, "quality": quality,
	})
	_ground_sequence += 1


func _is_equipment(item_id: String) -> bool:
	return String(_find(_collection("items"), item_id).get("slot", "none")) != "none"


## Coleta ao passar por cima: sem menu, durante o combate (documento 20).
func _collect_ground_items(peer_id: int) -> void:
	var state := player(peer_id)
	var reach := PICKUP_RADIUS + _mod(peer_id, "pickup_radius_add")
	for index in range(ground_items.size() - 1, -1, -1):
		var item := ground_items[index]
		if item["zone"] != state["zone"] or int(item.get("floor", 0)) != current_floor or (item["position"] as Vector2).distance_to(state["position"] as Vector2) > reach:
			continue
		if _filtered_out(peer_id, String(item["item_id"]), String(item.get("tier", "common"))):
			continue
		ground_items.remove_at(index)
		_receive_item(peer_id, String(item["item_id"]), int(item["quantity"]), String(item.get("quality", "")))
		_vfx(state["zone"], "label", [item["position"], "+%d %s" % [int(item["quantity"]), String(item["name"])] if int(item["quantity"]) > 1 else "+" + String(item["name"]), Color("e8b84a"), "coins"])


func _receive_item(peer_id: int, item_id: String, quantity: int, quality: String = "") -> void:
	var state := player(peer_id)
	# Equipamento vira peça na mochila e não entra na carga (antes também entrava e chegava ao
	# armazém como cópia fantasma; regressão de 2026-10-08).
	if not _is_equipment(item_id):
		var carried := state["carried_loot"] as Dictionary
		carried[item_id] = int(carried.get(item_id, 0)) + quantity
	if item_id == "pedra_regenerativa":
		state["carried_stone"] = int(state["carried_stone"]) + quantity
	if _is_equipment(item_id):
		for _copy in range(quantity):
			_add_equipment_instance(state["character_id"] as StringName, item_id, quality, maxi(1, current_floor))
		_status(peer_id, "%s recolhido." % item_display_name(item_id))
	else:
		_status(peer_id, "Saque recolhido. Pedra Regenerativa: %d" % int(state["carried_stone"]))


## A carga de quem cai ou some fica no local (documento 20). Equipamento já é da personagem.
func _drop_carried(peer_id: int, zone: StringName, position: Vector2) -> int:
	var state := player(peer_id)
	var carried := state["carried_loot"] as Dictionary
	var dropped := 0
	var index := 0
	for raw_id: Variant in carried.keys():
		var item_id := String(raw_id)
		if _is_equipment(item_id):
			continue
		var quantity := int(carried[raw_id])
		drop_item(zone, position + Vector2.RIGHT.rotated(float(index) * 1.7) * 14.0, item_id, quantity)
		dropped += quantity
		index += 1
	carried.clear()
	state["carried_stone"] = 0
	return dropped


func _merge_loot(destination: Dictionary, source: Dictionary) -> void:
	for item_id: String in source:
		if not _is_equipment(item_id):
			destination[item_id] = int(destination.get(item_id, 0)) + maxi(0, int(source[item_id]))


## Saves antigos guardavam cópias de equipamentos na carga e no armazém; as peças reais já estão
## na mochila, então os contadores são descartados ao carregar.
func _without_equipment(loot: Dictionary) -> Dictionary:
	var clean := {}
	for item_id: Variant in loot:
		if not _is_equipment(String(item_id)):
			clean[String(item_id)] = loot[item_id]
	return clean


func _grant_experience(peer_id: int, enemy: Dictionary) -> void:
	var key := String(player(peer_id).get("character_id", ""))
	if key.is_empty():
		return
	var reward := int(EXPERIENCE_REWARDS.get(String(enemy.get("encounter_class", "common")), 12))
	character_experience[key] = int(character_experience.get(key, 0)) + reward
	_process_level_ups(peer_id)


## EXP direta (atalho de desenvolvimento): o mesmo caminho de níveis, marcos e gemas.
func add_experience(peer_id: int, amount: int) -> void:
	var key := String(player(peer_id).get("character_id", ""))
	if key.is_empty() or amount <= 0:
		return
	character_experience[key] = int(character_experience.get(key, 0)) + amount
	_process_level_ups(peer_id)
	for gem_id: Variant in _gem_state(peer_id).get("slots", []) as Array:
		gain_gem_experience(peer_id, String(gem_id), amount)


func _process_level_ups(peer_id: int) -> void:
	var build := character_build(peer_id)
	if build == null:
		return
	var key := String(player(peer_id)["character_id"])
	while build.level < build.max_level and not build.has_pending_milestone():
		var required := experience_required(build.level)
		if int(character_experience.get(key, 0)) < required:
			break
		character_experience[key] = int(character_experience[key]) - required
		if not build.level_up():
			break
		player(peer_id)["health"] = minf(max_health(peer_id), float(player(peer_id)["health"]) + HEALTH_PER_LEVEL)
		_status(peer_id, "%s alcancou o nivel %d." % [player(peer_id)["character_name"], build.level])
		_vfx(player(peer_id)["zone"], "play", ["levelup", player(peer_id)["position"]])
	if build.has_pending_milestone():
		_status(peer_id, "Nivel %d: uma evolucao precisa ser escolhida." % build.level)


func experience_required(level: int) -> int:
	return 60 + maxi(0, level - 1) * 35


# ---------------------------------------------------------------- efeitos dos marcos

## Efeitos agregados das escolhas de marco da personagem do jogador (cache invalidado ao escolher).
func milestone_effects(peer_id: int) -> Dictionary:
	var key := String(player(peer_id).get("character_id", ""))
	if key.is_empty():
		return {}
	if not _milestone_cache.has(key):
		var build := character_builds.get(key) as CharacterBuild
		var selected: Dictionary = build.selected_milestones if build != null else {}
		_milestone_cache[key] = MilestoneEffectsScript.resolve(_find(_collection("playable_characters"), key), selected)
	return _milestone_cache[key] as Dictionary


## Marcos de evolução combinados com passivas de itens: `_mult` multiplica, o resto soma.
func _mod(peer_id: int, key: String) -> float:
	var milestone := MilestoneEffectsScript.modifier(milestone_effects(peer_id), key)
	var item := ItemPassivesScript.modifier(self, peer_id, key)
	return milestone * item if key.ends_with("_mult") else milestone + item


## Linha do catálogo de itens (vazia se o id não existir).
func item_data(item_id: String) -> Dictionary:
	return _find(_collection("items"), item_id)


func _mechanics(peer_id: int, mechanic_id: String) -> Array[Dictionary]:
	return MilestoneEffectsScript.mechanics(milestone_effects(peer_id), mechanic_id)


## Recalcula efeitos e reconfigura a passiva depois de escolha, troca de personagem ou carga.
func _refresh_milestones(peer_id: int) -> void:
	_milestone_cache.erase(String(player(peer_id).get("character_id", "")))
	var state := player(peer_id)
	if state.is_empty():
		return
	(state["passive"] as RefCounted).call("configure", milestone_effects(peer_id).get("passive", {}))
	state["health"] = minf(float(state["health"]), max_health(peer_id))


## Soma das auras de aliados próximos (`ally_power_add` ou `ally_damage_reduction_add`), limitada.
func level_power(peer_id: int) -> float:
	var build := character_build(peer_id)
	return 1.0 + POWER_PER_LEVEL * float((build.level if build != null else 1) - 1)


func _ally_aura(peer_id: int, key: String) -> float:
	var state := player(peer_id)
	var total := 0.0
	for other in _players_in_arena():
		if other == peer_id or not is_connected_player(other):
			continue
		if (player(other)["position"] as Vector2).distance_to(state["position"] as Vector2) <= AURA_RADIUS:
			total += _mod(other, key)
	return minf(AURA_LIMIT, total)


func character_build(peer_id: int) -> CharacterBuild:
	return character_builds.get(String(player(peer_id).get("character_id", ""))) as CharacterBuild


func _gear(peer_id: int) -> Dictionary:
	return character_gear.get(String(player(peer_id).get("character_id", "")), {}) as Dictionary


func derived_stats(peer_id: int) -> Dictionary:
	var build := character_build(peer_id)
	if build == null:
		return {"max_health": PLAYER_MAX_HEALTH, "max_breath": PLAYER_MAX_BREATH, "critical_chance": CRIT_CHANCE}
	var gear := _gear(peer_id)
	var raw_stats := build.base_stats.duplicate(true) as Dictionary
	var modifiers: Dictionary = (gear["equipment"] as EquipmentLoadout).combined_stat_modifiers() if not gear.is_empty() else {}
	for stat in CharacterBuild.PRIMARY_STATS:
		raw_stats[stat] = float(raw_stats.get(stat, 0.0)) + float(modifiers.get(stat, 0.0))
	var resolved := StatResolver.resolve(raw_stats)
	resolved["max_health"] = float(resolved["max_health"]) + float(modifiers.get(&"health", 0.0))
	resolved["max_breath"] = PLAYER_MAX_BREATH + float(modifiers.get(&"breath", 0.0))
	resolved["movement_speed_multiplier"] = float(resolved["movement_speed_multiplier"]) + float(modifiers.get(&"movement_speed", 0.0)) / 100.0
	resolved["automatic_attack_rate_multiplier"] = float(resolved["automatic_attack_rate_multiplier"]) + float(modifiers.get(&"attack_speed", 0.0)) / 100.0
	resolved["critical_chance"] = minf(0.35, CRIT_CHANCE + maxf(0.0, float(resolved["critical_chance"]) - 0.05) + float(modifiers.get(&"critical_chance", 0.0)) / 100.0)
	resolved["cooldown_recovery_multiplier"] = float(resolved["cooldown_recovery_multiplier"]) + float(modifiers.get(&"cooldown_recovery", 0.0)) / 100.0
	# Nível e marcos de evolução (documento 66 e decisão 549).
	resolved["max_health"] = float(resolved["max_health"]) + HEALTH_PER_LEVEL * float(build.level - 1) + _mod(peer_id, "max_health_add")
	resolved["max_breath"] = float(resolved["max_breath"]) + _mod(peer_id, "max_breath_add")
	resolved["critical_chance"] = minf(0.35, float(resolved["critical_chance"]) + _mod(peer_id, "crit_chance_add"))
	resolved["critical_damage_bonus"] = _mod(peer_id, "crit_damage_add")
	resolved["movement_speed_multiplier"] = float(resolved["movement_speed_multiplier"]) * _mod(peer_id, "move_speed_mult")
	resolved["automatic_attack_rate_multiplier"] = float(resolved["automatic_attack_rate_multiplier"]) * _mod(peer_id, "auto_rate_mult")
	resolved["cooldown_recovery_multiplier"] = minf(COOLDOWN_RECOVERY_CAP, float(resolved["cooldown_recovery_multiplier"]) / maxf(0.5, _mod(peer_id, "cooldown_mult")))
	resolved["cooldown_reduction"] = 1.0 - 1.0 / float(resolved["cooldown_recovery_multiplier"])
	resolved["area_multiplier"] = minf(AREA_MULTIPLIER_CAP, (1.0 + float(modifiers.get(&"area", 0.0)) / 100.0) * _mod(peer_id, "radius_mult"))
	# Defesa do equipamento com retorno decrescente: 100 de defesa reduz metade, nunca mais que 50%.
	var defense := maxf(0.0, float(modifiers.get(&"defense", 0.0)))
	resolved["damage_reduction"] = minf(0.5, defense / (defense + 100.0))
	return resolved


func max_health(peer_id: int) -> float:
	var wounds := int(player(peer_id).get("wounds", 0))
	return maxf(1.0, float(derived_stats(peer_id).get("max_health", PLAYER_MAX_HEALTH)) * maxf(0.5, 1.0 - WOUND_PENALTY * float(wounds)))


func max_breath(peer_id: int) -> float:
	return maxf(1.0, float(derived_stats(peer_id).get("max_breath", PLAYER_MAX_BREATH)))


# ---------------------------------------------------------------- equipamento

func _add_equipment_instance(character_id: StringName, item_id: String, quality: String = "", item_level: int = 1) -> StringName:
	var gear := character_gear.get(String(character_id), {}) as Dictionary
	var definition := _find(_collection("items"), item_id)
	if gear.is_empty() or definition.is_empty() or String(definition.get("slot", "none")) == "none":
		return &""
	var factory: RefCounted = BetaItemFactoryScript.new()
	var instance_id := StringName("%s_%d" % [item_id, equipment_instance_sequence])
	equipment_instance_sequence += 1
	var item: EquipmentItemInstance = factory.call("instance_from_data", definition, instance_id, character_id)
	if item != null and not quality.is_empty():
		item.quality = StringName(quality)
	if item != null:
		item.item_level = clampi(item_level, 1, ItemAffixesScript.MAX_ITEM_LEVEL)
		item.affixes = _roll_item_affixes(definition, item)
	if item == null or not (gear["inventory"] as ItemInventory).add(item):
		return &""
	return instance_id


## Afixos fixos do item (ex.: proliferação da Presa da Serpente) seguidos dos sorteados pela raridade.
func _roll_item_affixes(definition: Dictionary, item: EquipmentItemInstance) -> Array[Dictionary]:
	var result := ItemAffixesScript.roll_fixed(definition.get("fixed_affixes", []) as Array, _affix_random)
	result.append_array(ItemAffixesScript.roll(ItemTier.key(item.tier), _affix_random, item.item_level))
	return result


## Equipa uma peça do inventário; se o encaixe estiver ocupado, troca pela peça atual (a de menor
## valor, em anéis e relíquias). A troca é desfeita se qualquer passo falhar.
func _equip(character_id: StringName, instance_id: StringName) -> String:
	var gear := character_gear.get(String(character_id), {}) as Dictionary
	if gear.is_empty():
		return ""
	var inventory := gear["inventory"] as ItemInventory
	var equipment := gear["equipment"] as EquipmentLoadout
	var item := inventory.get_item(instance_id)
	if item == null:
		return ""
	var slot := item.definition.slot
	var index := 0
	if slot == EquipmentItemDefinition.Slot.RING:
		index = _first_empty_index(equipment, slot, EquipmentLoadout.RING_SLOT_COUNT)
		if index < 0:
			index = _weakest_index(equipment, slot, EquipmentLoadout.RING_SLOT_COUNT)
	elif slot == EquipmentItemDefinition.Slot.RELIC:
		index = _first_empty_index(equipment, slot, EquipmentLoadout.RELIC_SLOT_COUNT)
		if index < 0:
			index = _weakest_index(equipment, slot, EquipmentLoadout.RELIC_SLOT_COUNT)
	var previous := equipment.get_equipped(slot, index)
	if previous != null and not EquipmentTransaction.unequip_to_inventory(inventory, equipment, slot, index):
		return "Nao foi possivel liberar o encaixe."
	if not EquipmentTransaction.equip_from_inventory(inventory, equipment, instance_id, index):
		if previous != null:
			EquipmentTransaction.equip_from_inventory(inventory, equipment, previous.instance_id, index)
		return "Nao ha encaixe compativel para esse equipamento."
	return "%s equipado." % item_display_name(String(item.definition.id))


func _weakest_index(equipment: EquipmentLoadout, slot: EquipmentItemDefinition.Slot, count: int) -> int:
	var weakest := 0
	var weakest_score := INF
	for index in range(count):
		var current := equipment.get_equipped(slot, index)
		if current != null and _item_score(current) < weakest_score:
			weakest_score = _item_score(current)
			weakest = index
	return weakest


func _first_empty_index(equipment: EquipmentLoadout, slot: EquipmentItemDefinition.Slot, count: int) -> int:
	for index in range(count):
		if equipment.get_equipped(slot, index) == null:
			return index
	return -1


func item_display_name(item_id: String) -> String:
	var definition := _find(_collection("items"), item_id)
	return String(definition.get("name", item_id.replace("_", " ").capitalize()))


# ---------------------------------------------------------------- eventos e snapshots

func drain_events() -> Array[Dictionary]:
	var result := _events
	_events = []
	return result


func _event(event: Dictionary) -> void:
	_events.append(event)


func _announce_stairs() -> void:
	if floor_layout.has("stairs"):
		_vfx(arena_zone(), "play", ["stairs", (floor_layout["stairs"] as Rect2).get_center()])


func _vfx(zone: StringName, call_name: String, args: Array) -> void:
	var event := {"type": "vfx", "zone": String(zone), "call": call_name, "args": args}
	if not _vfx_theme.is_empty():
		event["theme"] = _vfx_theme
	_event(event)


func _status(peer_id: int, text: String) -> void:
	_event({"type": "status", "peer": peer_id, "text": text})


## Estado observável usado pela apresentação local e pela replicação para clientes.
func view_snapshot() -> Dictionary:
	var player_views := {}
	for peer_id: int in players:
		var state := players[peer_id] as Dictionary
		var build := character_build(peer_id)
		var level := build.level if build != null else 1
		var passive := state["passive"] as RefCounted
		player_views[peer_id] = {
			"peer": peer_id,
			"loot_filter": String(_gear(peer_id).get("loot_filter", "common")),
			"character_id": String(state["character_id"]),
			"character_name": state["character_name"],
			"connected": bool(state.get("connected", true)),
			"reconnect_timer": float(state.get("reconnect_timer", 0.0)),
			"zone": String(state["zone"]),
			"position": state["position"],
			"facing_left": state["facing_left"],
			"facing_direction": state.get("facing_direction", Vector2.DOWN),
			"volley_spin": _volley_spin(peer_id),
			"moving": state["moving"],
			"health": state["health"],
			"max_health": max_health(peer_id),
			"breath": state["breath"],
			"max_breath": max_breath(peer_id),
			"barrier": state["barrier"],
			"barrier_timer": maxf(0.0, float(state.get("barrier_timer", 0.0))),
			"status_effects": player_status_effects(peer_id),
			"invulnerable": float(state["invulnerable"]) > 0.0,
			"downed": bool(state.get("downed", false)),
			"downed_timer": float(state.get("downed_timer", 0.0)),
			"stabilize_progress": float(state.get("stabilize_progress", 0.0)) / STABILIZE_SECONDS,
			"wounds": int(state.get("wounds", 0)),
			"hurt_flash": state["hurt_flash"],
			"cooldowns": _ready_cooldowns(state),
			"charges": (state["charges"] as Array[int]).duplicate(),
			"charge_caps": (state["charge_caps"] as Array[int]).duplicate(),
			"max_cooldowns": _slot_cooldowns(peer_id),
			"gem_ids": (_gem_state(peer_id).get("slots", GEM_IDS) as Array).duplicate(),
			"skill_tooltips": skill_tooltips(peer_id),
			"skill_costs": skill_costs(peer_id),
			"quick_items": state["quick_items"],
			"expedition_preparation": expedition_preparation(peer_id) if state["zone"] == &"village" else [],
			"silver": int(_gear(peer_id).get("silver", 0)),
			"carried_stone": state["carried_stone"],
			"level": level,
			"experience": int(character_experience.get(String(state["character_id"]), 0)),
			"experience_required": experience_required(level),
			"pending_milestone": build.has_pending_milestone() if build != null else false,
			"milestone_choices": _milestone_choices(peer_id),
			"passive_display": passive.call("display"),
			"passive_markers": passive.call("markers"),
		}
	var enemy_views: Array[Dictionary] = []
	for enemy in enemies:
		enemy_views.append({
			"definition_id": enemy["definition_id"], "position": enemy["position"],
			"facing_direction": enemy.get("facing_direction", Vector2.DOWN),
			"health": enemy["health"], "max_health": enemy["max_health"],
			"prefix_id": enemy["prefix_id"], "suffix_id": enemy["suffix_id"],
			"shield_hits": enemy["shield_hits"], "flash": enemy.get("flash", 0.0),
			"awakened": enemy["awakened"], "base_mechanic": enemy["base_mechanic"],
			"race_trait": enemy["race_trait"], "race_id": enemy["race_id"], "rank_id": enemy["rank_id"],
			"slow": float(enemy.get("slow_amount", 0.0)), "slow_timer": float(enemy.get("slow_timer", 0.0)),
			"vulnerable": float(enemy.get("vulnerable_amount", 0.0)), "vulnerable_timer": float(enemy.get("vulnerable_timer", 0.0)),
			"poisons": poison_view(enemy),
			"boss": bool(enemy.get("floor_boss", false)) or bool(enemy.get("champion", false)),
			"name": String(enemy.get("display_name", "")), "chasing": bool(enemy.get("chasing", false)),
			"moving": bool(enemy.get("moving", false)),
		})
	var projectile_views: Array[Dictionary] = []
	for projectile in enemy_projectiles:
		projectile_views.append({"position": projectile["position"], "velocity": projectile["velocity"]})
	var effect_views: Array[Dictionary] = []
	for effect in persistent_effects:
		effect_views.append({
			"mechanic": effect["mechanic"], "gem_id": String(effect.get("gem_id", "")), "position": effect["position"], "radius": effect.get("radius", 40.0),
			"duration": effect.get("duration", 1.0), "collision_radius": effect.get("collision_radius", 12.0),
			"points": SkillGeometryScript.orbit_points(effect["position"], float(effect["radius"]), float(effect.get("phase", 0.0)), int(effect.get("orbit_count", 1))) if String(effect["mechanic"]) == "orbit" else [],
			"armed": float(effect.get("arm_timer", 0.0)) <= 0.0,
		})
	return {
		"players": player_views,
		"milestone_peers": pending_milestone_peers(),
		"narrative": narrative_view(),
		"arena_zone": String(arena_zone()),
		"party_size": party_size(),
		"party_budget": float(party_scaling()["budget"]),
		"enemies": enemy_views,
		"drops": _drop_views(),
		"projectiles": projectile_views,
		"effects": effect_views,
		"floor": _floor_view(),
		"npcs": village_life.call("view"),
		"village_period": String(village_life.call("period")),
		"warehouse": village_life.economy.view(),
		"village_log": (village_life.get("log") as Array).duplicate(true),
		"npc_mode": String(village_life.get("mode")),
		"telegraphs": _telegraph_views(),
		"hazard_zones": _hazard_views(),
		"tower_start_floor": tower_start_floor,
		"deepest_floor": deepest_floor,
		"banked_stone": banked_stone,
		"village_progress": village_progress,
		"max_cooldowns": skill_max_cooldowns.duplicate(),
		"gem_ids": GEM_IDS.duplicate(),
	}


## Slots com carga disponível aparecem prontos no HUD mesmo enquanto outra carga recarrega.
func _floor_view() -> Dictionary:
	if current_floor <= 0 or floor_run.is_empty():
		return {}
	var definition := floor_def()
	var boss_ratio := -1.0
	var boss_name := ""
	for enemy in enemies:
		if bool(enemy.get("floor_boss", false)):
			boss_ratio = float(enemy["health"]) / maxf(1.0, float(enemy["max_health"]))
			boss_name = String(enemy.get("display_name", ""))
	var mode := record_mode()
	return {
		"number": current_floor, "name": String(definition.get("name", "")), "biome": String(definition.get("biome", "")),
		"kind": String(definition.get("kind", "explore")), "time": float(floor_run.get("time", 0.0)),
		"kills": int(floor_run.get("kills", 0)), "quota": int(floor_run.get("quota", 0)),
		"stairs_open": bool(floor_run.get("stairs_open", false)), "mode": mode, "best": best_time(current_floor, mode),
		"survival_left": survival_left() if is_explore_floor() else 0.0,
		"respawn_interval": respawn_interval(), "boss_ratio": boss_ratio, "boss_name": boss_name,
		"recorded": bool(floor_run.get("recorded", false)),
	}


func _telegraph_views() -> Array:
	var result: Array = []
	for telegraph in telegraphs:
		var view := telegraph.duplicate()
		view.erase("effect")
		view["progress"] = 1.0 - float(telegraph["remaining"]) / maxf(0.01, float(telegraph["delay"]))
		result.append(view)
	return result


func _hazard_views() -> Array:
	var result: Array = []
	for zone in hazard_zones:
		result.append({"position": zone["position"], "radius": zone["radius"], "remaining": zone["remaining"], "slow": zone.get("slow", 0.0)})
	return result


func _drop_views() -> Array:
	var result: Array = []
	for item in _visible_ground_items():
		result.append({
			"zone": String(item["zone"]), "position": item["position"], "item_id": item["item_id"],
			"quantity": item["quantity"], "tier": item["tier"], "name": item["name"], "equipment": item["equipment"],
		})
	return result


func _visible_ground_items() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for item in ground_items:
		if int(item.get("floor", 0)) == current_floor:
			candidates.append(item)
	if candidates.size() <= MAX_GROUND_ITEM_VIEWS:
		return candidates
	# Round-robin nearest drops: one busy ally cannot consume the entire snapshot.
	var rankings: Array = []
	var peers := players.keys()
	peers.sort()
	for peer: int in peers:
		var state := player(peer)
		if not bool(state.get("connected", false)) or state["zone"] not in [&"tower", &"boss_room"]:
			continue
		var nearby: Array[Dictionary] = []
		for item in candidates:
			if item["zone"] == state["zone"]:
				nearby.append(item)
		var origin := state["position"] as Vector2
		nearby.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var da := (a["position"] as Vector2).distance_squared_to(origin)
			var db := (b["position"] as Vector2).distance_squared_to(origin)
			return int(a["id"]) < int(b["id"]) if da == db else da < db)
		rankings.append({"items": nearby, "index": 0})
	if rankings.is_empty():
		candidates.resize(MAX_GROUND_ITEM_VIEWS)
		return candidates
	var selected: Array[Dictionary] = []
	var seen := {}
	while selected.size() < MAX_GROUND_ITEM_VIEWS:
		var added := false
		for ranking: Dictionary in rankings:
			var items := ranking["items"] as Array
			var index := int(ranking["index"])
			while index < items.size() and seen.has(items[index]["id"]):
				index += 1
			if index < items.size():
				selected.append(items[index])
				seen[items[index]["id"]] = true
				added = true
				index += 1
			ranking["index"] = index
			if selected.size() == MAX_GROUND_ITEM_VIEWS:
				break
		if not added:
			break
	return selected


## Lista dos andares já alcançados para o mapa da Torre: nome, bioma, tipo e recarga de chefe.
func _tower_map_model() -> Array:
	var result: Array = []
	for number in range(1, deepest_floor + 1):
		var definition := TowerContentScript.floor_def(number)
		result.append({
			"number": number, "name": String(definition.get("name", "")), "kind": String(definition.get("kind", "explore")),
			"biome": String(TowerContentScript.biome(String(definition.get("biome", ""))).get("name", "")),
		})
	return result


func _ready_cooldowns(state: Dictionary) -> Array:
	var result: Array = []
	var cooldowns := state["cooldowns"] as Array[float]
	var charges := state["charges"] as Array[int]
	for slot in range(cooldowns.size()):
		result.append(0.0 if charges[slot] > 0 else cooldowns[slot])
	return result


func _slot_cooldowns(peer_id: int) -> Array:
	var result: Array = []
	for slot in range(4):
		var effect := resolve_slot(peer_id, slot)
		result.append(float(effect.get("cooldown", 1.0)) / float(derived_stats(peer_id).get("cooldown_recovery_multiplier", 1.0)))
	return result


func _skills_model(peer_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var gems := _gem_state(peer_id)
	if gems.is_empty():
		return result
	var resolver: RefCounted = SkillResolverScript.new()
	for slot in range(4):
		var gem_id := String((gems["slots"] as Array)[slot])
		if not (gems["gems"] as Dictionary).has(gem_id):
			result.append({"slot": slot, "key": GEM_SLOT_KEYS[slot], "id": "", "empty": true, "name": "Encaixe vazio"})
			continue
		var definition := gem_definition(gem_id)
		var progress := (gems["gems"] as Dictionary)[gem_id] as Dictionary
		var level := int(progress["level"])
		var current := resolve_slot(peer_id, slot)
		var attached: Array[Dictionary] = []
		for support_id: Variant in (gems["supports"] as Array)[slot]:
			var support := support_definition(String(support_id))
			attached.append({"id": String(support_id), "name": String(support.get("name", support_id)), "drain": int(support.get("drain", 0)), "category": support.get("category", "buff"), "description": support.get("description", "")})
		var available: Array[Dictionary] = []
		for support in _collection("support_gems"):
			var support_id := String(support.get("id", ""))
			var in_use := (gems.get("auto_supports", []) as Array).has(support_id)
			for other: Variant in gems["supports"]:
				if (other as Array).has(support_id):
					in_use = true
			if not in_use and bool(resolver.call("supports", definition, support)):
				var with_support: Dictionary = resolver.call("resolve", current, [support] as Array[Dictionary])
				available.append({"id": support_id, "name": String(support.get("name", support_id)), "drain": int(support.get("drain", 0)), "category": support.get("category", "buff"), "description": support.get("description", ""),
					"preview": skill_change_preview(peer_id, current, with_support)})
		var pending: Array[Dictionary] = []
		var pending_tier := pending_evolution_tier(progress)
		for option in _evolution_options(gem_id, pending_tier):
			var with_option: Dictionary = resolver.call("resolve", current, [] as Array[Dictionary], [option.get("modifiers", {}) as Dictionary] as Array[Dictionary])
			pending.append({"id": String(option.get("id", "")), "name": String(option.get("name", "")), "modifiers": option.get("modifiers", {}),
				"preview": skill_change_preview(peer_id, current, with_option)})
		var chosen: Array[String] = []
		for chosen_level in GEM_MASTERY_LEVELS:
			var choice_id := String((progress["choices"] as Dictionary).get(str(chosen_level), ""))
			for option in _evolution_options(gem_id, chosen_level):
				if String(option.get("id", "")) == choice_id:
					chosen.append("Nv %d: %s" % [chosen_level, String(option.get("name", choice_id))])
		var effective := gem_effective_level(peer_id, gem_id)
		var requirements: Array[Dictionary] = []
		var next_requirements := gem_requirements(gem_id, mini(level + 1, GEM_MAX_LEVEL_BETA))
		var current_requirements := gem_requirements(gem_id, level)
		for stat: String in current_requirements:
			requirements.append({"stat": stat, "value": float(current_requirements[stat]), "next": float(next_requirements.get(stat, 0.0)),
				"have": raw_stat(peer_id, stat), "met": raw_stat(peer_id, stat) >= float(current_requirements[stat])})
		var resolved := resolve_slot(peer_id, slot)
		var scale := _skill_power_multiplier(peer_id, resolved)
		available.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return String(left["name"]).naturalnocasecmp_to(String(right["name"])) < 0)
		result.append({
			"slot": slot, "key": GEM_SLOT_KEYS[slot], "id": gem_id, "name": String(definition.get("name", gem_id)),
			"mechanic": String(definition.get("mechanic", "")), "tags": definition.get("tags", []),
			"description": definition.get("description", ""),
			"level": level, "max_level": GEM_MAX_LEVEL_BETA,
			"experience": int(progress["experience"]), "experience_required": gem_experience_required(level) if level < GEM_MAX_LEVEL_BETA else 0,
			"pending_tier": pending_tier, "effective_level": effective, "requirements": requirements,
			"next_mastery": GEM_MASTERY_LEVELS.filter(func(mastery: int) -> bool: return mastery > level).front() if level < GEM_MAX_LEVEL_BETA else 0,
			"capacity_used": _used_capacity((gems["supports"] as Array)[slot] as Array), "capacity": gem_capacity(level),
			"supports": attached, "available_supports": available, "support_count": attached.size(),
			"pending_choices": pending, "chosen": chosen,
			"power": float(resolved.get("power", 0.0)) * scale, "barrier": float(resolved.get("barrier", 0.0)) * scale, "healing": float(resolved.get("healing", 0.0)) * scale,
			"base_power": float(resolved.get("power", 0.0)), "power_multiplier": scale, "scaling": gem_scaling_view(peer_id, gem_id),
			"unique_weapon": String(unique_weapon_for(peer_id, gem_id).get("description", "")),
			"breath_cost": float(resolved.get("breath_cost", 0.0)) * _mod(peer_id, "breath_cost_mult"), "charges": 1 + maxi(0, int(resolved.get("extra_charge", 0))),
			"cooldown": float(resolved.get("cooldown", 0.0)) / maxf(0.01, float(derived_stats(peer_id).get("cooldown_recovery_multiplier", 1.0))),
		})
	return result


## Status detalhados no estilo de Dofus (decisão 589): cada atributo separado em base (pontos e
## marcos), equipamento, total e efetivo (depois dos redutores acima de 100); números de combate;
## e bônus de dano por tipo e elemento, somando marcos, passivas de itens e afixos.
const DAMAGE_BONUS_ROWS: Array[Array] = [
	["power_mult", "Potencia geral"], ["auto_damage_mult", "Autoataque"], ["power_physical_mult", "Dano fisico"],
	["power_magic_mult", "Dano magico"], ["power_fire_mult", "Fogo"], ["power_ice_mult", "Gelo"], ["power_lightning_mult", "Raio"],
	["power_acid_mult", "Acido"], ["power_nature_mult", "Natureza"], ["power_dark_mult", "Trevas"], ["power_holy_mult", "Sagrado"],
	["power_earth_mult", "Terra"], ["power_arcane_mult", "Arcano"], ["power_summon_mult", "Invocacoes"],
]


func detailed_stats(peer_id: int) -> Dictionary:
	var build := character_build(peer_id)
	if build == null:
		return {}
	var derived := derived_stats(peer_id)
	var effective := derived.get("effective_primaries", {}) as Dictionary
	var attributes: Array[Dictionary] = []
	for stat in CharacterBuild.PRIMARY_STATS:
		var base := float(build.base_stats.get(stat, 0.0))
		var total := raw_stat(peer_id, String(stat))
		attributes.append({"stat": String(stat), "base": base, "equipment": total - base, "total": total, "effective": float(effective.get(stat, total))})
	var weapon := weapon_attack_model(peer_id)
	var combat: Array[Array] = [
		["Vida maxima", "%d" % roundi(max_health(peer_id))],
		["Folego maximo", "%d" % roundi(max_breath(peer_id))],
		["Regeneracao de Folego", "%d/s" % roundi(18.0 * _mod(peer_id, "breath_regen_mult"))],
		["Potencia do nivel", "x%.2f" % level_power(peer_id)],
		["Dano do autoataque", "%.1f a cada %.2f s" % [float(weapon.get("damage", 0.0)), float(weapon.get("interval", 1.0))]],
		["Chance critica", "%.1f%%" % (float(derived.get("critical_chance", CRIT_CHANCE)) * 100.0)],
		["Dano critico", "x%.2f" % minf(2.0, CRIT_MULTIPLIER + float(derived.get("critical_damage_bonus", 0.0)))],
		["Reducao de recarga", "%.0f%% (teto %.0f%%)" % [float(derived.get("cooldown_reduction", 0.0)) * 100.0, (1.0 - 1.0 / COOLDOWN_RECOVERY_CAP) * 100.0]],
		["Area", "+%.0f%% (teto +%.0f%%)" % [(float(derived.get("area_multiplier", 1.0)) - 1.0) * 100.0, (AREA_MULTIPLIER_CAP - 1.0) * 100.0]],
		["Velocidade de movimento", "%.0f%%" % (float(derived.get("movement_speed_multiplier", 1.0)) * 100.0)],
		["Cadencia de ataque", "%.0f%%" % (float(derived.get("automatic_attack_rate_multiplier", 1.0)) * 100.0)],
		["Defesa (reducao de dano)", "%.1f%% (teto 50%%)" % (float(derived.get("damage_reduction", 0.0)) * 100.0)],
		["Guarda da arma", "%.0f%%" % (float(weapon.get("guard", 0.0)) * 100.0)],
		["Dano recebido (marcos e itens)", "x%.2f" % _mod(peer_id, "damage_taken_mult")],
		["Roubo de Vida", "%.1f%%" % (_mod(peer_id, "life_steal_add") * 100.0)],
		["Alcance de proliferacao de veneno", "+%.0f%%" % ((_mod(peer_id, "poison_spread_mult") - 1.0) * 100.0)],
		["Teto do acumulo de esporos (Sabedoria)", "x%.1f" % spore_stack_cap(peer_id)],
		["Raio da explosao de esporos (Inteligencia)", "+%.0f%% (teto +%.0f%%)" % [(float(derived.get("spore_spread_multiplier", 1.0)) - 1.0) * 100.0, StatResolver.SPORE_SPREAD_CAP * 100.0]],
	]
	var damage: Array[Array] = []
	for row in DAMAGE_BONUS_ROWS:
		var value := _mod(peer_id, String(row[0]))
		damage.append([String(row[1]), "%s%.0f%%" % ["+" if value >= 1.0 else "", (value - 1.0) * 100.0]])
	return {"attributes": attributes, "combat": combat, "damage": damage}


## Números de uma gema como o jogador os sente (decisão 589): dano, barreira e cura já com atributos,
## nível e bônus; recarga com a Sabedoria; cargas; e os campos que mudam o comportamento.
const PREVIEW_METRICS: Array[Array] = [
	["power", "Dano", "scaled"], ["barrier", "Barreira", "scaled"], ["healing", "Cura", "scaled"],
	["trail_damage", "Dano do rastro", "scaled"], ["arrival_damage", "Dano na chegada", "scaled"], ["arrival_barrier", "Barreira na chegada", "scaled"],
	["cooldown", "Recarga", "seconds"], ["extra_charge", "Cargas", "charges"], ["breath_cost", "Folego", "number"],
	["radius", "Raio", "number"], ["range", "Alcance", "number"], ["width", "Largura", "number"], ["angle", "Abertura", "angle"],
	["duration", "Duracao", "seconds"], ["tick_interval", "Intervalo", "seconds"],
	["projectile_count", "Projeteis", "plus_one"], ["pierce", "Perfuracao", "number"], ["ricochet", "Ricochetes", "number"],
	["fork_count", "Bifurcacoes", "number"], ["chain_count", "Saltos", "number"], ["meteor_count", "Impactos", "number"],
	["orbit_count", "Orbitas", "number"], ["arrow_count", "Flechas", "number"], ["summon_count", "Invocacoes", "number"],
	["repeat_count", "Repeticoes", "number"], ["critical_chance", "Critico", "percent"], ["slow", "Lentidao", "percent"],
	["damage_taken", "Vulnerabilidade", "percent"], ["life_steal", "Roubo de Vida", "percent"], ["poison_growth", "Crescimento do veneno", "percent"],
	["spread_radius", "Espalhamento", "number"], ["impact_area", "Area do impacto", "number"], ["knockback", "Repulsao", "number"],
	["expire_damage", "Dano ao expirar", "scaled"], ["contact_damage", "Dano de contato", "scaled"], ["stability", "Estabilidade", "percent"],
	["expire_nova_damage", "Explosao ao expirar", "scaled"], ["chain_range", "Alcance do salto", "number"], ["heal_per_chain", "Cura por salto", "number"],
	["angular_speed", "Rotacao", "number"], ["collision_radius", "Largura das laminas", "number"], ["arm_delay", "Tempo de armar", "seconds"],
	["trigger_radius", "Gatilho", "number"], ["delay", "Atraso do impacto", "seconds"], ["poison_linger", "Toxina apos sair", "seconds"],
	["breath_per_second", "Folego por segundo", "number"], ["breath_on_kill", "Folego por abate", "number"], ["breath_per_hit", "Folego por acerto", "number"],
	["invulnerability", "Invulnerabilidade", "seconds"], ["distance", "Distancia", "number"], ["attack_interval", "Intervalo de ataque", "seconds"],
	["pull_strength", "Atracao", "number"], ["inner_radius", "Centro vazio", "number"], ["allies_receive_barrier", "Barreira em aliados", "percent"],
	["arrival_area", "Area na chegada", "number"], ["speed", "Velocidade", "number"], ["spread", "Espalhamento", "number"],
]
const PREVIEW_FLAGS := {
	"homing": "teleguiado", "return_projectile": "retorna", "remote_nova": "pulso na mira", "field_follows_player": "segue o portador",
	"summon_follows_player": "invocacao segue", "repeat_last_target": "repete no ultimo alvo", "overheal_barrier": "excesso vira barreira",
}


## Campos ausentes que o resolvedor trata como 1 quando um modificador os multiplica.
const PREVIEW_DEFAULTS := {"speed": 1.0}


func _preview_value(peer_id: int, effect: Dictionary, field: String, kind: String) -> float:
	var value := float(effect.get(field, PREVIEW_DEFAULTS.get(field, 0.0)))
	match kind:
		"scaled":
			return value * _skill_power_multiplier(peer_id, effect)
		"seconds":
			return value / maxf(0.01, float(derived_stats(peer_id).get("cooldown_recovery_multiplier", 1.0))) if field == "cooldown" else value
		"charges":
			return 1.0 + maxf(0.0, value)
		"plus_one":
			return 1.0 + value
	return value


## O que muda numa gema entre dois estados (modificador ou suporte): "Dano 120 -> 144 (+20%)".
func skill_change_preview(peer_id: int, before: Dictionary, after: Dictionary) -> String:
	var parts := PackedStringArray()
	for metric in PREVIEW_METRICS:
		var field := String(metric[0])
		var kind := String(metric[2])
		if not before.has(field) and not after.has(field):
			continue
		var old := _preview_value(peer_id, before, field, kind)
		var new := _preview_value(peer_id, after, field, kind)
		if is_equal_approx(old, new):
			continue
		var change := " (%s%d%%)" % ["+" if new > old else "", roundi((new / old - 1.0) * 100.0)] if absf(old) > 0.0001 and kind in ["scaled", "number", "seconds"] else ""
		parts.append("%s %s -> %s%s" % [String(metric[1]), _preview_text(old, kind), _preview_text(new, kind), change])
	for flag: String in PREVIEW_FLAGS:
		if bool(after.get(flag, false)) and not bool(before.get(flag, false)):
			parts.append("ganha: " + String(PREVIEW_FLAGS[flag]))
	return ", ".join(parts) if not parts.is_empty() else "sem mudanca nos numeros principais"


func _preview_text(value: float, kind: String) -> String:
	match kind:
		"seconds":
			return "%.1f s" % value
		"percent":
			return "%d%%" % roundi(value * 100.0)
		"angle":
			return "%d graus" % roundi(rad_to_deg(value))
	return str(roundi(value)) if absf(value - roundf(value)) < 0.05 or absf(value) >= 10.0 else "%.1f" % value


func player_status_effects(peer_id: int) -> Array[Dictionary]:
	var state := player(peer_id)
	var result: Array[Dictionary] = []
	if float(state.get("barrier", 0.0)) > 0.0:
		result.append({"id":"barrier", "name":"Barreira", "icon":"muralha_refeita", "remaining":float(state.get("barrier_timer", 0.0)), "value":float(state["barrier"]), "description":"Absorve dano antes da Vida."})
	if float(state.get("invulnerable", 0.0)) > 0.0:
		result.append({"id":"invulnerable", "name":"Invulneravel", "icon":"passo_vetorial", "remaining":float(state["invulnerable"]), "description":"Protecao temporaria contra dano."})
	if state.get("zone") == arena_zone():
		var position := state["position"] as Vector2
		for spec in [["healing", "healing", "Cultivo", "semeadura_vital"], ["stability", "stability", "Estabilidade", "abrigo_de_escora"]]:
			var best := 0.0
			var remaining := 0.0
			for effect in persistent_effects:
				if String(effect.get("mechanic", "")) == "sanctuary" and float(effect.get("duration", 0.0)) > 0.0 and position.distance_to(effect["position"] as Vector2) <= float(effect["radius"]):
					var value := float(effect.get(spec[1], 0.0))
					if value > best:
						best = value
						remaining = float(effect["duration"])
			if best > 0.0:
				result.append({"id":spec[0], "name":spec[2], "icon":spec[3], "remaining":remaining, "value":best, "description":"Cura enquanto estiver no circulo." if spec[0] == "healing" else "Reduz dano recebido em %.0f%% dentro do circulo." % (best * 100.0)})
		var slow := 0.0
		var slow_time := 0.0
		for hazard in hazard_zones:
			if state["zone"] == &"tower" and position.distance_to(hazard["position"] as Vector2) <= float(hazard["radius"]) and float(hazard.get("remaining", 0.0)) > 0.0 and float(hazard.get("slow", 0.0)) > slow:
				slow = float(hazard["slow"])
				slow_time = float(hazard["remaining"])
		if slow > 0.0:
			result.append({"id":"slow", "kind":"debuff", "name":"Lentidao", "icon":"anel_de_geada", "remaining":slow_time, "description":"Movimento reduzido em %.0f%% enquanto estiver na zona." % (slow * 100.0)})
	for effect in persistent_effects:
		if String(effect.get("mechanic", "")) == "volley" and int(effect.get("owner_peer", 0)) == peer_id:
			# Sem duração: o ícone mostra quanto Fôlego ainda sustenta a Saraivada.
			var per_second := maxf(0.001, float(effect.get("breath_per_second", 9.0)) * _mod(peer_id, "breath_cost_mult"))
			result.append({"id":"volley", "kind":"buff", "name":"Saraivada", "icon":"saraivada_de_flechas", "remaining":float(player(peer_id).get("breath", 0.0)) / per_second, "duration":max_breath(peer_id) / per_second, "description":"Disparando flechas enquanto houver Folego. Lance de novo para encerrar."})
	result.append_array(ItemPassivesScript.status_effects(self, peer_id))
	var wounds := int(state.get("wounds", 0))
	if wounds > 0:
		result.append({"id":"wound", "kind":"debuff", "name":"Ferimento x%d" % wounds, "icon":"drenagem_vital", "remaining":-1.0, "stacks":wounds, "description":"Vida maxima reduzida em %.0f%% ate retornar a vila." % (minf(0.5, wounds * WOUND_PENALTY) * 100.0)})
	return result


func skill_costs(peer_id: int) -> Array[float]:
	var result: Array[float] = []
	for slot in range(4):
		result.append(float(resolve_slot(peer_id, slot).get("breath_cost", 0.0)) * _mod(peer_id, "breath_cost_mult"))
	return result


func skill_tooltips(peer_id: int) -> Array[String]:
	var result: Array[String] = []
	var slots := _gem_state(peer_id).get("slots", []) as Array
	var recovery := maxf(0.01, float(derived_stats(peer_id).get("cooldown_recovery_multiplier", 1.0)))
	for slot in range(slots.size()):
		var definition := gem_definition(String(slots[slot]))
		var model := resolve_slot(peer_id, slot).duplicate()
		if model.is_empty():
			result.append("Encaixe vazio. Equipe uma gema em Aresta (SKILLS).")
			continue
		var scale := _skill_power_multiplier(peer_id, model)
		for key in ["power", "barrier", "healing"]:
			if model.has(key):
				model[key] = float(model[key]) * scale
		model["scaling"] = gem_scaling_view(peer_id, String(slots[slot]))
		model["name"] = definition.get("name", "")
		model["description"] = definition.get("description", "")
		model["cooldown"] = float(model.get("cooldown", 0.0)) / recovery
		model["charges"] = 1 + maxi(0, int(model.get("extra_charge", 0)))
		var supports: Array[Dictionary] = []
		for support_id: Variant in (_gem_state(peer_id)["supports"] as Array)[slot] as Array:
			supports.append(support_definition(String(support_id)))
		model["supports"] = supports
		result.append(ContentDescriptions.skill(model))
	return result


## Gemas possuídas, com nível, para trocar de encaixe.
func _gem_options(peer_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var gems := _gem_state(peer_id)
	var owned := gems.get("gems", {}) as Dictionary
	for definition in _collection("active_gems"):
		var gem_id := String(definition.get("id", ""))
		if owned.has(gem_id):
			result.append({"id": gem_id, "name": String(definition.get("name", gem_id)), "description": definition.get("description", ""),
				"equipped": (gems.get("slots", []) as Array).has(gem_id), "level": int((owned[gem_id] as Dictionary)["level"])})
	result.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return String(left["name"]).naturalnocasecmp_to(String(right["name"])) < 0)
	return result


## Gemas que a personagem ainda não tem, agrupadas pelo chefe que as entrega.
func _locked_gem_sets(peer_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var owned := _gem_state(peer_id).get("gems", {}) as Dictionary
	for boss in TowerContentScript.collection("bosses"):
		var names: Array[String] = []
		for gem_id: Variant in boss.get("gem_set", []) as Array:
			if not owned.has(String(gem_id)):
				names.append(String(gem_definition(String(gem_id)).get("name", gem_id)))
		if not names.is_empty():
			result.append({"floor": int(boss.get("floor", 0)), "boss": String(boss.get("name", "")), "gems": names})
	return result


func _milestone_choices(peer_id: int) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var build := character_build(peer_id)
	if build != null and build.has_pending_milestone():
		for value: Variant in build.milestone_choices.get(build.level, []):
			var choice := value as EvolutionChoice
			choices.append({"id": String(choice.id), "name": choice.display_name, "description": choice.description, "branch": String(choice.branch)})
	return choices


func _base_weapon_attack_model(peer_id: int) -> Dictionary:
	var state := player(peer_id)
	var equipment: EquipmentLoadout = _gear(peer_id).get("equipment") as EquipmentLoadout
	var type_id := "unarmed"
	var fabrication := 1.0
	if equipment != null and equipment.weapon != null:
		type_id = weapon_type_for(peer_id, equipment.weapon)
		fabrication = LootDifficultyScript.fabrication_factor(String(equipment.weapon.quality))
	var derived := derived_stats(peer_id)
	var result := WeaponCombat.resolve(type_id, String(state.get("character_id", "")), derived.get("effective_primaries", {}) as Dictionary, fabrication)
	result["weapon_type"] = type_id
	result["damage"] = float(result["damage"]) * _mod(peer_id, "auto_damage_mult") * level_power(peer_id)
	result["interval"] = float(result["interval"]) / maxf(0.01, float(derived.get("automatic_attack_rate_multiplier", 1.0)))
	result["critical_chance"] = clampf(float(derived.get("critical_chance", CRIT_CHANCE)) + float(result["crit_add"]), 0.0, 0.5)
	result["item_name"] = item_display_name(String(equipment.weapon.definition.id)) if equipment != null and equipment.weapon != null else "Desarmado"
	return result


func weapon_attack_model(peer_id: int) -> Dictionary:
	var attached: Array[Dictionary] = []
	var ids := (_gem_state(peer_id).get("auto_supports", []) as Array).duplicate()
	ids.sort()
	for id: String in ids:
		attached.append(support_definition(id))
	var result := AutoSupports.resolve(_base_weapon_attack_model(peer_id), attached)
	result["critical_chance"] = clampf(float(derived_stats(peer_id).get("critical_chance", CRIT_CHANCE)) + float(result["crit_add"]), 0.0, 0.5)
	return result


func _auto_support_model(peer_id: int) -> Dictionary:
	var weapon := _base_weapon_attack_model(peer_id)
	var gems := _gem_state(peer_id)
	var attached: Array[Dictionary] = []
	for id: String in gems.get("auto_supports", []):
		var support := support_definition(id).duplicate(true)
		support["active"] = AutoSupports.supports(weapon, support)
		if not bool(support["active"]):
			support["description"] = "Inativo com esta arma. " + String(support.get("description", ""))
		attached.append(support)
	var available: Array[Dictionary] = []
	for support in _collection("support_gems"):
		var used := (gems["auto_supports"] as Array).has(support["id"])
		for other: Array in gems["supports"]:
			used = used or other.has(support["id"])
		if not used and AutoSupports.supports(weapon, support):
			available.append(support)
	available.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["name"]).naturalnocasecmp_to(String(b["name"])) < 0)
	var resolved := weapon_attack_model(peer_id)
	return {"slot": AutoSupports.SLOT, "supports": attached, "available_supports": available, "capacity": AutoSupports.CAPACITY, "capacity_used": _used_capacity(gems["auto_supports"] as Array), "damage": resolved["damage"], "interval": resolved["interval"], "breath_cost": resolved.get("breath_cost", 0.0), "weapon_name": resolved["item_name"]}


func menu_model(peer_id: int) -> Dictionary:
	var state := player(peer_id)
	var build := character_build(peer_id)
	var stats: Dictionary = {}
	var stat_bonus: Dictionary = {}
	var milestone_choices := _milestone_choices(peer_id)
	if build != null:
		for stat in CharacterBuild.PRIMARY_STATS:
			stats[String(stat)] = int(build.base_stats.get(stat, 0))
			# Bônus de equipamento e afixos, mostrado entre parênteses ao lado dos pontos.
			stat_bonus[String(stat)] = int(round(raw_stat(peer_id, String(stat)) - float(build.base_stats.get(stat, 0))))
	var skills := _skills_model(peer_id)
	var definition := _find(_collection("playable_characters"), String(state.get("character_id", "")))
	var chosen: Array[Dictionary] = []
	if build != null:
		var levels := build.selected_milestones.keys()
		levels.sort()
		for level: Variant in levels:
			for raw_choice: Variant in (definition.get("milestones", {}) as Dictionary).get(str(level), []) as Array:
				var entry := raw_choice as Dictionary
				if String(entry.get("id", "")) == String(build.selected_milestones[level]):
					chosen.append({"level": int(level), "name": entry.get("name", ""), "branch": entry.get("branch", ""), "description": entry.get("description", "")})
	var passive := definition.get("passive", {}) as Dictionary
	var gear := _gear(peer_id)
	var equipment: EquipmentLoadout = gear.get("equipment") as EquipmentLoadout
	return {
		"character_name": state.get("character_name", ""), "character_id": String(state.get("character_id", "")),
		"weapon_attack": weapon_attack_model(peer_id),
		"auto_attack_supports": _auto_support_model(peer_id),
		"level": build.level if build != null else 1,
		"max_level": build.max_level if build != null else CharacterBuild.MAX_LEVEL,
		"records": records.duplicate(true),
		"deepest_floor": deepest_floor,
		"tower_start_floor": tower_start_floor,
		"floors": _tower_map_model(),
		"chosen_milestones": chosen,
		"experience": int(character_experience.get(String(state.get("character_id", "")), 0)),
		"experience_required": experience_required(build.level if build != null else 1),
		"unspent_stat_points": build.unspent_stat_points if build != null else 0,
		"stats": stats, "stat_bonus": stat_bonus, "detailed_stats": detailed_stats(peer_id),
		"milestone_choices": milestone_choices,
		"carried_loot": (state.get("carried_loot", {}) as Dictionary).duplicate(),
		"banked_loot": banked_loot.duplicate(),
		"inventory_equipment": _inventory_model(gear, peer_id),
		"sell_all": sell_all_preview(peer_id),
		"shop": shop_model(peer_id),
		"bestiary": bestiary_model(peer_id),
		"silver": int(gear.get("silver", 0)), "loot_filter": String(gear.get("loot_filter", "common")), "auto_sell": String(gear.get("auto_sell", "")),
		"equipped_count": equipment.equipped_count() if equipment != null else 0,
		"equipment_slots": _slots_model(equipment, peer_id),
		"item_tooltips": _item_tooltips(),
		"item_tiers": _item_tiers(),
		"derived_stats": derived_stats(peer_id),
		"skills": skills,
		"gem_options": _gem_options(peer_id),
		"locked_gem_sets": _locked_gem_sets(peer_id),
		"in_safe_area": state.get("zone", &"village") not in ARENA_ZONES,
		"passive_name": String(passive.get("name", "")),
		"passive_description": String(passive.get("description", "")),
	}


func _item_tiers() -> Dictionary:
	var result := {}
	for definition in _collection("items"):
		result[String(definition["id"])] = String(definition.get("tier", "common"))
	return result


func _item_tooltips() -> Dictionary:
	var result := {}
	for definition in _collection("items"):
		result[String(definition["id"])] = ContentDescriptions.item(definition, String(definition.get("tier", "")))
	return result


## Tipo de ataque da arma. Arma única assume a forma da arma inicial de quem a empunha
## (decisão 580): manoplas continuam manoplas, então qualquer personagem aproveita a peça.
func weapon_type_for(peer_id: int, weapon: EquipmentItemInstance) -> String:
	if String(item_data(String(weapon.definition.id)).get("unique_gem", "")).is_empty():
		return String(weapon.definition.weapon_type)
	var starter := item_data(String(STARTER_WEAPONS.get(StringName(String(player(peer_id).get("character_id", ""))), "")))
	return String(starter.get("weapon_type", weapon.definition.weapon_type))


func _equipment_tooltip(item: EquipmentItemInstance, peer_id: int) -> String:
	var weapon := {}
	if item.definition.slot == EquipmentItemDefinition.Slot.WEAPON:
		weapon = WeaponCombat.resolve(weapon_type_for(peer_id, item), String(player(peer_id).get("character_id", "")), derived_stats(peer_id).get("effective_primaries", {}) as Dictionary, LootDifficultyScript.fabrication_factor(String(item.quality)))
	return ContentDescriptions.item(_find(_collection("items"), String(item.definition.id)), ItemTier.label(item.tier), String(LootDifficultyScript.FABRICATION_LABELS.get(String(item.quality), "Regular")), weapon, item.affixes, item.item_level, _stat_factor(item))


## Fator real dos atributos-base da peça: fabricação x nível do item.
func _stat_factor(item: EquipmentItemInstance) -> float:
	return LootDifficultyScript.fabrication_factor(String(item.quality)) * ItemAffixesScript.level_factor(item.item_level)


## Dica colorida do inventário (decisão 584), com a ação do clique.
func _equipment_rich_tooltip(item: EquipmentItemInstance, peer_id: int, hint: String) -> String:
	var weapon := {}
	if item.definition.slot == EquipmentItemDefinition.Slot.WEAPON:
		weapon = WeaponCombat.resolve(weapon_type_for(peer_id, item), String(player(peer_id).get("character_id", "")), derived_stats(peer_id).get("effective_primaries", {}) as Dictionary, LootDifficultyScript.fabrication_factor(String(item.quality)))
	return ContentDescriptions.item_rich(item_data(String(item.definition.id)), ItemTier.key(item.tier), LayoutScript.slot_label(item.definition.slot),
		String(LootDifficultyScript.FABRICATION_LABELS.get(String(item.quality), "Regular")), weapon, item.affixes, hint, item.item_level, _stat_factor(item))


func _inventory_model(gear: Dictionary, peer_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if gear.is_empty():
		return result
	var inventory := gear["inventory"] as ItemInventory
	for instance_id: StringName in inventory.items:
		var item: EquipmentItemInstance = inventory.items[instance_id] as EquipmentItemInstance
		result.append({
			"instance_id": String(instance_id), "item_id": String(item.definition.id), "name": item_display_name(String(item.definition.id)),
			"tier": ItemTier.label(item.tier), "tier_id": ItemTier.key(item.tier), "slot": LayoutScript.slot_label(item.definition.slot),
			"sell_price": item_sell_price(item),
			"fabrication": String(LootDifficultyScript.FABRICATION_LABELS.get(String(item.quality), "Regular")),
			"slot_id": int(item.definition.slot), "score": _item_score(item),
			"tooltip": _equipment_tooltip(item, peer_id), "affix_count": item.affixes.size(),
			"rich_tooltip": _equipment_rich_tooltip(item, peer_id, "Clique: equipar  |  Botao direito: vender por %d P" % item_sell_price(item)),
		})
	result.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return String(left["name"]) < String(right["name"]))
	return result


## Valor comparável de uma peça: tier define o patamar e a fabricação desempata.
func _item_score(item: EquipmentItemInstance) -> float:
	return float(int(item.tier)) * 10.0 + LootDifficultyScript.fabrication_factor(String(item.quality)) * 4.0


func _slots_model(equipment: EquipmentLoadout, peer_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for spec: Array in LayoutScript.equipment_slot_specs():
		var slot := spec[1] as EquipmentItemDefinition.Slot
		var index := int(spec[2])
		var item: EquipmentItemInstance = equipment.get_equipped(slot, index) if equipment != null else null
		result.append({
			"slot": spec[0], "item": item_display_name(String(item.definition.id)) if item != null else "VAZIO",
			"item_id": String(item.definition.id) if item != null else "",
			"tier_id": ItemTier.key(item.tier) if item != null else "",
			"occupied": item != null, "slot_id": int(slot), "index": index, "score": _item_score(item) if item != null else -1.0,
			"tooltip": _equipment_tooltip(item, peer_id) if item != null else "",
			"rich_tooltip": _equipment_rich_tooltip(item, peer_id, "Clique: desequipar") if item != null else "",
		})
	return result


# ---------------------------------------------------------------- bestiário

func _bestiary_entry(peer_id: int, enemy_id: String) -> Dictionary:
	var book := character_bestiary.get_or_add(String(player(peer_id).get("character_id", "")), {}) as Dictionary
	return book.get_or_add(enemy_id, {"kills": 0, "min_health": 0.0, "max_health": 0.0, "drops": {}, "affixes": {}}) as Dictionary


## Todo abate conta para quem está na arena (o grupo inteiro aprende com a luta).
func _record_bestiary_kill(enemy: Dictionary) -> void:
	var enemy_id := String(enemy.get("definition_id", ""))
	if enemy_id.is_empty():
		return
	for member in _players_in_arena():
		if not is_connected_player(member):
			continue
		var entry := _bestiary_entry(member, enemy_id)
		entry["kills"] = int(entry["kills"]) + 1
		var health := float(enemy.get("max_health", 0.0))
		entry["min_health"] = health if float(entry["min_health"]) <= 0.0 else minf(float(entry["min_health"]), health)
		entry["max_health"] = maxf(float(entry["max_health"]), health)
		for key: String in ["prefix_id", "suffix_id"]:
			var affix := String(enemy.get(key, ""))
			if not affix.is_empty():
				var affixes := entry["affixes"] as Dictionary
				affixes[affix] = int(affixes.get(affix, 0)) + 1


## Cada item que caiu conta uma vez por abate (taxa observada = vezes / abates).
func _record_bestiary_drops(enemy: Dictionary, drops: Array) -> void:
	var enemy_id := String(enemy.get("definition_id", ""))
	if enemy_id.is_empty():
		return
	var seen := {}
	for drop: Dictionary in drops:
		seen[String(drop.get("item_id", ""))] = true
	seen.erase("")
	for member in _players_in_arena():
		if not is_connected_player(member):
			continue
		var counted := _bestiary_entry(member, enemy_id)["drops"] as Dictionary
		for item_id: String in seen:
			counted[item_id] = int(counted.get(item_id, 0)) + 1


func _restore_bestiary(raw: Variant) -> void:
	character_bestiary = {}
	if not raw is Dictionary:
		return
	for character: Variant in raw:
		if not raw[character] is Dictionary:
			continue
		var book := {}
		for enemy_id: Variant in raw[character]:
			var saved: Variant = raw[character][enemy_id]
			if not saved is Dictionary:
				continue
			var entry := {"kills": maxi(0, int(saved.get("kills", 0))), "min_health": maxf(0.0, float(saved.get("min_health", 0.0))),
				"max_health": maxf(0.0, float(saved.get("max_health", 0.0))), "drops": {}, "affixes": {}}
			for key: String in ["drops", "affixes"]:
				var counts: Variant = saved.get(key, {})
				if counts is Dictionary:
					for item: Variant in counts:
						if (counts[item] is int or counts[item] is float) and int(counts[item]) > 0:
							(entry[key] as Dictionary)[String(item)] = int(counts[item])
			book[String(enemy_id)] = entry
		character_bestiary[String(character)] = book


## Monstros do bestiário em ordem de bioma: comuns, elites e o guardião de cada bioma.
func _bestiary_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var biomes := TowerContentScript.collection("biomes")
	biomes.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return int((left["floors"] as Array)[0]) < int((right["floors"] as Array)[0]))
	var listed := {}
	for biome in biomes:
		var group: Array[Dictionary] = []
		for enemy_id: Variant in biome.get("enemies", []) as Array:
			var definition := _find(_collection("enemies"), String(enemy_id))
			if not definition.is_empty() and not listed.has(String(enemy_id)):
				group.append({"definition": definition, "biome": biome, "boss": {}})
				listed[String(enemy_id)] = true
		group.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return String((left["definition"] as Dictionary).get("encounter_class", "")) == "common" and String((right["definition"] as Dictionary).get("encounter_class", "")) != "common")
		for boss in TowerContentScript.collection("bosses"):
			if String(boss.get("biome", "")) == String(biome.get("id", "")) and not listed.has(String(boss["id"])):
				var definition := _find(_collection("enemies"), String(boss["id"])).duplicate(true)
				definition["id"] = String(boss["id"])
				definition["name"] = String(boss.get("name", definition.get("name", "")))
				definition["encounter_class"] = "boss"
				definition["health"] = float(boss.get("health", definition.get("health", 900.0)))
				definition["damage"] = float(boss.get("damage", definition.get("damage", 24.0)))
				definition["speed"] = float(boss.get("speed", definition.get("speed", 36.0)))
				group.append({"definition": definition, "biome": biome, "boss": boss})
				listed[String(boss["id"])] = true
		result.append_array(group)
	return result


static func _times(count: int) -> String:
	return "%d %s" % [count, "vez" if count == 1 else "vezes"]


func bestiary_model(peer_id: int) -> Dictionary:
	var book := character_bestiary.get(String(player(peer_id).get("character_id", "")), {}) as Dictionary
	var entries: Array = []
	var discovered := 0
	for record in _bestiary_catalog():
		var definition := record["definition"] as Dictionary
		var enemy_id := String(definition.get("id", ""))
		var encounter := String(definition.get("encounter_class", "common"))
		var known := book.get(enemy_id, {}) as Dictionary
		var kills := int(known.get("kills", 0))
		var level := BestiaryScript.level(kills, encounter)
		if level > 0:
			discovered += 1
		var biome := record["biome"] as Dictionary
		entries.append({
			"id": enemy_id, "name": String(definition.get("name", enemy_id)) if level > 0 else "???",
			"class": encounter, "class_name": String(BestiaryScript.CLASS_NAMES.get(encounter, "Comum")),
			"biome": String(biome.get("name", "")), "floors": biome.get("floors", [0, 0]),
			"kills": kills, "level": level, "level_name": BestiaryScript.LEVEL_NAMES[level],
			"next": BestiaryScript.next_threshold(kills, encounter),
			"next_section": BestiaryScript.SECTION_NAMES[mini(level + 1, 5)] if level < 5 else "",
			"portrait": enemy_id if level > 0 else "",
			"sections": _bestiary_sections(definition, record["boss"] as Dictionary, biome, known, level),
		})
	return {"entries": entries, "discovered": discovered, "total": entries.size()}


func _bestiary_sections(definition: Dictionary, boss: Dictionary, biome: Dictionary, known: Dictionary, level: int) -> Array:
	var sections: Array = []
	if level <= 0:
		return sections
	var encounter := String(definition.get("encounter_class", "common"))
	var race := _find(_collection("monster_races"), String(definition.get("race_id", "")))
	var rank := _find(_collection("enemy_ranks"), String(definition.get("rank_id", "")))
	var floors := biome.get("floors", [0, 0]) as Array
	sections.append({"title": BestiaryScript.SECTION_NAMES[1], "rows": [
		["Raca", "%s. %s" % [String(race.get("name", "?")), String(race.get("description", ""))]],
		["Patente", String(rank.get("name", "-"))],
		["Classe", String(BestiaryScript.CLASS_NAMES.get(encounter, "Comum"))],
		["Habitat", "%s (andares %d a %d)" % [String(biome.get("name", "")), int(floors[0]), int(floors[1])] if boss.is_empty() else "%s (andar %d)" % [String(biome.get("name", "")), int(boss.get("floor", 0))]],
		["Abates", str(int(known.get("kills", 0)))],
	]})
	if not String(definition.get("lore", "")).is_empty():
		(sections[0]["rows"] as Array).append(["Registro", String(definition["lore"])])
	if level < 2:
		return sections
	var profile := race.get("stat_profile", {}) as Dictionary
	var rank_factor := func(key: String) -> float: return maxf(0.05, float(rank.get(key, 1.0))) if boss.is_empty() else 1.0
	var base_health := float(definition.get("health", 60.0)) * ENEMY_HEALTH_MULT * float(profile.get("health", 1.0)) * float(rank_factor.call("health_multiplier"))
	var base_damage := float(definition.get("damage", 12.0)) * float(profile.get("damage", 1.0)) * float(rank_factor.call("damage_multiplier"))
	var stats := [
		["Vida base", "%d (cresce com o andar)" % roundi(base_health)],
		["Vida observada", "%d a %d" % [roundi(float(known.get("min_health", 0.0))), roundi(float(known.get("max_health", 0.0)))]],
		["Dano base", "%d" % roundi(base_damage)],
		["Velocidade", "%d" % roundi(float(definition.get("speed", 42.0)) * ENEMY_SPEED_MULT * float(profile.get("speed", 1.0)) * float(rank_factor.call("speed_multiplier")))],
		["Intervalo de ataque", "%.2f s" % (float(definition.get("attack_interval", 0.8)) * float(profile.get("attack_interval", 1.0)))],
		["EXP de gema por abate", str(int(EXPERIENCE_REWARDS.get(encounter, 12)))],
	]
	if not boss.is_empty():
		stats.append(["Furia", "apos %d s de luta" % int(boss.get("enrage", 200))])
	sections.append({"title": BestiaryScript.SECTION_NAMES[2], "rows": stats})
	if level < 3:
		return sections
	var trait_id := String(race.get("trait", ""))
	var resistances := PackedStringArray()
	var trait_resistances := BestiaryScript.TRAIT_RESISTANCES.get(trait_id, {}) as Dictionary
	for kind: String in trait_resistances:
		resistances.append("%s %s" % [kind, BestiaryScript.percent(float(trait_resistances[kind]))])
	var behaviour := [
		["Mecanica", String(BestiaryScript.MECHANICS.get(String(definition.get("mechanic", "swarm")) if boss.is_empty() else "boss_kit", "Ataca corpo a corpo."))],
		["Traco da raca", String(BestiaryScript.TRAITS.get(trait_id, "Nenhum traco especial."))],
		["Resistencias", ", ".join(resistances) if not resistances.is_empty() else "Nenhuma"],
		["Afixos", "%d a %d por exemplar" % [int(rank.get("minimum_affixes", 0)), int(rank.get("maximum_affixes", 0))] if bool(definition.get("allow_affixes", true)) and boss.is_empty() else "Nao recebe afixos"],
	]
	for ability: Dictionary in boss.get("abilities", []) as Array:
		var detail := PackedStringArray()
		if ability.has("damage"):
			detail.append("dano %d" % int(ability["damage"]))
		if ability.has("radius"):
			detail.append("raio %d" % int(ability["radius"]))
		if ability.has("count"):
			detail.append("%d invocacoes" % int(ability["count"]))
		if ability.has("cooldown"):
			detail.append("a cada %.1f s" % float(ability["cooldown"]))
		if int(ability.get("phase", 1)) > 1:
			detail.append("a partir da fase %d" % int(ability["phase"]))
		behaviour.append(["Habilidade", "%s: %s" % [String(BestiaryScript.ABILITIES.get(String(ability.get("type", "")), String(ability.get("type", "")))), ", ".join(detail)]])
	if not boss.is_empty():
		var phases := PackedStringArray()
		for threshold: Variant in boss.get("phases", []) as Array:
			phases.append("%d%%" % roundi(float(threshold) * 100.0))
		behaviour.append(["Fases", "muda de fase com %s da Vida" % ", ".join(phases) if not phases.is_empty() else "fase unica"])
	sections.append({"title": BestiaryScript.SECTION_NAMES[3], "rows": behaviour})
	if level < 4:
		return sections
	var difficulty := LootDifficultyScript.score({"encounter_class": encounter, "rank_id": String(definition.get("rank_id", "maduro"))})
	var loot := [] as Array
	var table := _find(_collection("loot_tables"), String(boss.get("loot_table_id", definition.get("loot_table_id", ""))))
	for drop: Dictionary in table.get("entries", []) as Array:
		var chance := minf(1.0, float(drop.get("chance", 0.0)) * LootDifficultyScript.chance_multiplier(difficulty))
		var amount := "%d" % int(drop.get("minimum", 1)) if int(drop.get("minimum", 1)) == int(drop.get("maximum", 1)) else "%d a %d" % [int(drop.get("minimum", 1)), int(drop.get("maximum", 1))]
		loot.append([item_display_name(String(drop.get("item_id", ""))), "%s (x%s)" % [BestiaryScript.percent(chance), amount]])
	loot.append(["Equipamento bonus", BestiaryScript.percent(LootDifficultyScript.bonus_chance(difficulty)) + (" (pode ser Reliquia)" if encounter in ["boss", "raid"] else "")])
	loot.append(["Arma unica (de uma gema equipada)", BestiaryScript.percent(float(UNIQUE_WEAPON_CHANCE.get(encounter, 0.0)))])
	loot.append(["Observacao", "Afixos no monstro aumentam as chances e as quantidades."])
	sections.append({"title": BestiaryScript.SECTION_NAMES[4], "rows": loot})
	if level < 5:
		return sections
	var kills := maxi(1, int(known.get("kills", 0)))
	var field := [] as Array
	var drops := known.get("drops", {}) as Dictionary
	var drop_ids := drops.keys()
	drop_ids.sort_custom(func(left: Variant, right: Variant) -> bool: return int(drops[left]) > int(drops[right]))
	# Materiais um a um; equipamentos somados (cada peça é sorteada de uma lista grande).
	var equipment := 0
	for item_id: Variant in drop_ids:
		if _is_equipment(String(item_id)):
			equipment += int(drops[item_id])
			continue
		field.append(["Caiu: %s" % item_display_name(String(item_id)), "%s (%s dos abates)" % [_times(int(drops[item_id])), BestiaryScript.percent(float(drops[item_id]) / float(kills))]])
	if equipment > 0:
		field.append(["Caiu: equipamentos", "%d %s (%.2f por abate)" % [equipment, "peca" if equipment == 1 else "pecas", float(equipment) / float(kills)]])
	var affixes := known.get("affixes", {}) as Dictionary
	for affix_id: Variant in affixes:
		var modifier := _find(_enemy_modifiers(), String(affix_id))
		field.append(["Afixo visto: %s" % String(modifier.get("name", affix_id)), _times(int(affixes[affix_id]))])
	if field.is_empty():
		field.append(["Registro", "Nenhum saque observado ainda."])
	sections.append({"title": BestiaryScript.SECTION_NAMES[5], "rows": field})
	return sections


# ---------------------------------------------------------------- salvamento

## Mundo do host. Somente o estado da jogadora local (host) é guardado como posição e carga.
func save_data(host_peer: int) -> Dictionary:
	var progress: Dictionary = {}
	for key: String in character_builds:
		progress[key] = {"build": (character_builds[key] as CharacterBuild).snapshot(), "experience": int(character_experience.get(key, 0))}
	var gear_data: Dictionary = {}
	for key: String in character_gear:
		gear_data[key] = _gear_snapshot(character_gear[key] as Dictionary)
	var host := player(host_peer)
	return {
		"version": SAVE_VERSION,
		"narrative": narrative.snapshot(),
		"zone": String(host.get("zone", "village")),
		"player_position": _vector_array(host.get("position", LayoutScript.WORLD_SPAWN) as Vector2),
		"target_position": _vector_array(host.get("target", LayoutScript.WORLD_SPAWN) as Vector2),
		"last_world_position": _vector_array(host.get("last_world_position", LayoutScript.WORLD_SPAWN) as Vector2),
		"player_health": host.get("health", PLAYER_MAX_HEALTH),
		"player_breath": host.get("breath", PLAYER_MAX_BREATH),
		"quick_items": host.get("quick_items", 2),
		"carried_stone": host.get("carried_stone", 0),
		"carried_loot": host.get("carried_loot", {}),
		"character_id": String(host.get("character_id", "eloa")),
		"enemies": _serialize_enemies(enemies),
		"ground_items": _serialize_ground_items(),
		"current_floor": current_floor,
		"floor_run": floor_run.duplicate(true),
		"village_life": village_life.call("snapshot"),
		"tower_start_floor": tower_start_floor,
		"deepest_floor": deepest_floor,
		"banked_stone": banked_stone,
		"banked_loot": banked_loot,
		"loot_kill_sequence": loot_kill_sequence,
		"village_progress": village_progress,
		"encounter_seed": encounter_seed,
		"respawn": respawn.call("snapshot"),
		"threat": threat.call("snapshot"),
		"character_progress": progress,
		"character_gear": gear_data,
		"character_gems": character_gems.duplicate(true),
		"character_bestiary": character_bestiary.duplicate(true),
		"shop_sequence": shop_sequence,
		"shop_sold": shop_sold.duplicate(),
		"equipment_instance_sequence": equipment_instance_sequence,
	}


static func validate_save(data: Dictionary) -> Error:
	var schema_error: Error = preload("res://src/core/persistence/world_save_schema.gd").validate(data, SAVE_VERSION)
	if schema_error != OK:
		return schema_error
	if int(data["version"]) >= 10 and (not data.has("narrative") or (data["narrative"] is Dictionary and data["narrative"].is_empty())):
		return ERR_FILE_CORRUPT
	if int(data["version"]) >= 11 and (not data["narrative"] is Dictionary or not data["narrative"].has("opening_known")):
		return ERR_FILE_CORRUPT
	if int(data["version"]) >= 13 and (not data["narrative"] is Dictionary or not data["narrative"].has("rescue_state") or not data["narrative"].has("rescue_progress")):
		return ERR_FILE_CORRUPT
	if not NarrativeProgress.valid(data.get("narrative", {})):
		return ERR_FILE_CORRUPT
	return OK


func load_data(data: Dictionary, host_peer: int) -> bool:
	if validate_save(data) != OK:
		return false
	var version := int(data.get("version", 0))
	if version < 1 or version > SAVE_VERSION:
		return false
	var zone := StringName(String(data.get("zone", "village")))
	if zone not in [&"village", &"house", &"tower", &"boss_room"]:
		return false
	encounter_seed = int(data.get("encounter_seed", 7301))
	narrative.restore(data.get("narrative", {}))
	_configure_directors()
	var respawn_data: Variant = data.get("respawn", {})
	if respawn_data is Dictionary:
		respawn.call("restore", respawn_data)
	var threat_data: Variant = data.get("threat", {})
	if threat_data is Dictionary:
		threat.call("restore", threat_data)
	deepest_floor = clampi(int(data.get("deepest_floor", 1)), 1, TowerContentScript.MAX_FLOOR)
	var saved_life: Variant = data.get("village_life", {})
	if saved_life is Dictionary:
		village_life.call("restore", saved_life)
	tower_start_floor = clampi(int(data.get("tower_start_floor", 1)), 1, deepest_floor)
	# Saves antigos podem trazer "boss_cooldowns": ignorado, chefes não têm mais recarga.
	current_floor = clampi(int(data.get("current_floor", 0)), 0, TowerContentScript.MAX_FLOOR)
	floor_layout = FloorLayoutScript.generate(current_floor) if current_floor > 0 else {}
	floor_run = (data.get("floor_run", {}) as Dictionary).duplicate(true) if current_floor > 0 else {}
	telegraphs.clear()
	hazard_zones.clear()
	enemies = _deserialize_enemies(data.get("enemies", []))
	_restore_ground_items(data.get("ground_items", []))
	enemy_projectiles.clear()
	persistent_effects.clear()
	banked_stone = maxi(0, int(data.get("banked_stone", 0)))
	banked_loot = _without_equipment((data.get("banked_loot", {}) as Dictionary).duplicate(true))
	if banked_loot.is_empty() and banked_stone > 0:
		banked_loot["pedra_regenerativa"] = banked_stone
	loot_kill_sequence = maxi(0, int(data.get("loot_kill_sequence", 0)))
	village_progress = clampi(int(data.get("village_progress", 0)), 0, 1)
	_restore_progress(data.get("character_progress", {}))
	_restore_gear(data, StringName(String(data.get("character_id", "eloa"))))
	_restore_gems(data.get("character_gems", {}), version)
	_restore_bestiary(data.get("character_bestiary", {}))
	shop_sequence = maxi(0, int(data.get("shop_sequence", 0)))
	shop_sold.clear()
	for index: Variant in data.get("shop_sold", []) as Array:
		if (index is int or index is float) and int(index) >= 0 and int(index) < SHOP_SIZE and int(index) not in shop_sold:
			shop_sold.append(int(index))
	_shop_cache.clear()
	var host := player(host_peer)
	_milestone_cache.clear()
	for peer_id: int in players:
		_refresh_milestones(peer_id)
	if host.is_empty():
		return true
	var saved_character := StringName(String(data.get("character_id", "eloa")))
	host["zone"] = &"village"
	if CHARACTER_IDS.has(saved_character):
		select_character(host_peer, saved_character)
	if zone == &"boss_room" or (zone == &"tower" and current_floor <= 0):
		zone = &"village"
	host["zone"] = zone
	host["position"] = _array_vector(data.get("player_position", []), LayoutScript.WORLD_SPAWN)
	host["target"] = _array_vector(data.get("target_position", []), host["position"] as Vector2)
	host["last_world_position"] = _array_vector(data.get("last_world_position", []), LayoutScript.WORLD_SPAWN)
	host["health"] = maxf(1.0, float(data.get("player_health", PLAYER_MAX_HEALTH)))
	host["breath"] = maxf(0.0, float(data.get("player_breath", PLAYER_MAX_BREATH)))
	host["quick_items"] = clampi(int(data.get("quick_items", 2)), 0, 9)
	host["carried_stone"] = maxi(0, int(data.get("carried_stone", 0)))
	host["carried_loot"] = _without_equipment((data.get("carried_loot", {}) as Dictionary).duplicate(true))
	if (host["carried_loot"] as Dictionary).is_empty() and int(host["carried_stone"]) > 0:
		(host["carried_loot"] as Dictionary)["pedra_regenerativa"] = host["carried_stone"]
	host["transition_cooldown"] = 0.5
	_status(host_peer, "Mundo carregado.")
	return true


## Saves até a versão 7 guardavam todas as gemas, e a evolução do nível N era escolhida no
## próprio nível N. Na migração ficam a gema inicial, as gemas com progresso e os conjuntos dos
## chefes já ultrapassados; o nível sobe um quando a evolução do nível atual já fora escolhida.
func _restore_gems(raw: Variant, version: int = SAVE_VERSION) -> void:
	if not raw is Dictionary:
		return
	for key: Variant in raw:
		var saved := raw[key] as Dictionary
		var state := _new_gem_state(String(key))
		var owned := state["gems"] as Dictionary
		var saved_gems: Variant = saved.get("gems", {})
		if saved_gems is Dictionary:
			for gem_id: Variant in saved_gems:
				if gem_definition(String(gem_id)).is_empty() or not saved_gems[gem_id] is Dictionary:
					continue
				var entry := saved_gems[gem_id] as Dictionary
				var level := int(entry.get("level", 1))
				var choices := (entry.get("choices", {}) as Dictionary).duplicate()
				if version < 8:
					if level <= 1 and int(entry.get("experience", 0)) <= 0 and choices.is_empty():
						continue
					level += 1 if choices.has(str(level)) else 0
				var experience := maxi(0, int(entry.get("experience", 0)))
				if version < 12:
					# Maestria (decisão 588): a EXP da curva antiga (150 x nível, até o 4) vira nível na
					# curva nova; as escolhas antigas não existem mais e são refeitas nos níveis 5 a 21.
					var total := experience
					for old_level in range(1, clampi(level, 1, 4)):
						total += 150 * old_level
					level = 1
					while level < GEM_MAX_LEVEL_BETA and total >= gem_experience_required(level):
						total -= gem_experience_required(level)
						level += 1
					experience = total
					choices = {}
				owned[String(gem_id)] = {
					"level": clampi(level, 1, GEM_MAX_LEVEL_BETA),
					"experience": experience,
					"choices": choices,
				}
		if version < 8:
			for boss in TowerContentScript.collection("bosses"):
				if int(boss.get("floor", 0)) < deepest_floor:
					for gem_id: Variant in boss.get("gem_set", []) as Array:
						if not owned.has(String(gem_id)) and not gem_definition(String(gem_id)).is_empty():
							owned[String(gem_id)] = _new_gem_progress()
		var slots: Variant = saved.get("slots", [])
		if slots is Array and (slots as Array).size() == 4:
			for index in range(4):
				(state["slots"] as Array)[index] = String(slots[index]) if owned.has(String(slots[index])) and not (state["slots"] as Array).slice(0, index).has(String(slots[index])) else ""
		var saved_supports: Variant = saved.get("supports", [])
		if saved_supports is Array and (saved_supports as Array).size() == 4:
			state["supports"] = (saved_supports as Array).duplicate(true)
		_validate_supports(state)
		var auto_ids: Variant = saved.get("auto_supports", [])
		if auto_ids is Array:
			for id: Variant in auto_ids:
				var support := support_definition(String(id))
				var used := false
				for other: Array in state["supports"]:
					used = used or other.has(id)
				var current := state["auto_supports"] as Array
				if not support.is_empty() and not used and not current.has(id) and current.size() < 2 and _used_capacity(current) + int(support.get("drain", 0)) <= AutoSupports.CAPACITY:
					current.append(String(id))
		var saved_misses: Variant = saved.get("boss_misses", {})
		if saved_misses is Dictionary:
			for floor_key: Variant in saved_misses:
				if int(saved_misses[floor_key]) > 0:
					(state.get_or_add("boss_misses", {}) as Dictionary)[str(int(String(floor_key)))] = 1
		character_gems[String(key)] = state


func _restore_progress(raw_progress: Variant) -> void:
	if not raw_progress is Dictionary:
		return
	for key: Variant in raw_progress:
		var definition := _find(_collection("playable_characters"), String(key))
		var saved := raw_progress[key] as Dictionary
		if definition.is_empty() or saved.is_empty():
			continue
		var factory: RefCounted = BetaCharacterFactoryScript.new()
		var build: CharacterBuild = factory.call("create_build", definition)
		var build_data: Variant = saved.get("build", {})
		if build_data is Dictionary:
			build.restore(build_data)
		character_builds[String(key)] = build
		character_experience[String(key)] = maxi(0, int(saved.get("experience", 0)))


func _restore_gear(data: Dictionary, saved_character: StringName) -> void:
	var per_character: Dictionary = {}
	if data.get("character_gear") is Dictionary:
		per_character = data["character_gear"] as Dictionary
		equipment_instance_sequence = maxi(1, int(data.get("equipment_instance_sequence", 1)))
	elif data.get("equipment") is Dictionary and not (data["equipment"] as Dictionary).is_empty():
		# Salvamentos até a versão 6 tinham um único inventário: ele passa para a personagem salva.
		per_character[String(saved_character)] = data["equipment"]
		equipment_instance_sequence = maxi(1, int((data["equipment"] as Dictionary).get("instance_sequence", 1)))
	for key: String in per_character:
		var saved := per_character[key] as Dictionary
		var gear := _new_gear(key)
		gear["silver"] = maxi(0, int(saved.get("silver", STARTING_SILVER)))
		gear["loot_filter"] = String(saved.get("loot_filter", "common")) if String(saved.get("loot_filter", "common")) in TIER_ORDER else "common"
		gear["auto_sell"] = String(saved.get("auto_sell", "")) if String(saved.get("auto_sell", "")) in TIER_ORDER else ""
		var factory: RefCounted = BetaItemFactoryScript.new()
		for raw_item: Variant in saved.get("items", []) as Array:
			if not raw_item is Dictionary:
				continue
			var entry := raw_item as Dictionary
			var definition := _find(_collection("items"), String(entry.get("definition_id", "")))
			if definition.is_empty():
				continue
			var item: EquipmentItemInstance = factory.call("instance_from_data", definition, StringName(String(entry.get("instance_id", ""))), StringName(key))
			if item == null:
				continue
			item.tier = int(entry.get("tier", int(item.tier))) as ItemTier.Value
			item.quality = StringName(String(entry.get("quality", "common")))
			item.integrity = clampf(float(entry.get("integrity", 1.0)), 0.0, 1.0)
			item.item_level = clampi(int(entry.get("item_level", 1)), 1, ItemAffixesScript.MAX_ITEM_LEVEL)
			# Peças de saves anteriores aos afixos (decisão 583) sorteiam os seus ao carregar.
			item.affixes = ItemAffixesScript.sanitize(entry["affixes"]) if entry.has("affixes") else _roll_item_affixes(definition, item)
			if not (gear["inventory"] as ItemInventory).add(item):
				continue
			if String(entry.get("location", "inventory")) == "equipped":
				EquipmentTransaction.equip_from_inventory(gear["inventory"] as ItemInventory, gear["equipment"] as EquipmentLoadout, item.instance_id, int(entry.get("index", 0)))
		character_gear[key] = gear


func _gear_snapshot(gear: Dictionary) -> Dictionary:
	var items: Array[Dictionary] = []
	var inventory := gear["inventory"] as ItemInventory
	var equipment := gear["equipment"] as EquipmentLoadout
	for instance_id: StringName in inventory.items:
		items.append(_item_snapshot(inventory.items[instance_id] as EquipmentItemInstance, "inventory", -1, 0))
	for spec: Array in LayoutScript.equipment_slot_specs():
		var item := equipment.get_equipped(spec[1] as EquipmentItemDefinition.Slot, int(spec[2]))
		if item != null:
			items.append(_item_snapshot(item, "equipped", int(spec[1]), int(spec[2])))
	return {"items": items, "silver": int(gear.get("silver", STARTING_SILVER)), "loot_filter": String(gear.get("loot_filter", "common")), "auto_sell": String(gear.get("auto_sell", ""))}


func _new_gear(key: String) -> Dictionary:
	return {"inventory": ItemInventory.new(StringName(key)), "equipment": EquipmentLoadout.new(), "silver": STARTING_SILVER, "loot_filter": "common", "auto_sell": ""}


## Valor em prata de uma peça: raridade vezes fabricação.
func item_sell_price(item: EquipmentItemInstance) -> int:
	return maxi(1, int(round(float(SELL_PRICES.get(ItemTier.key(item.tier), 8)) * LootDifficultyScript.fabrication_factor(String(item.quality)))))


## Vende uma peça do inventário (nunca uma equipada). Devolve a prata recebida, 0 se não vendeu.
func sell_item(peer_id: int, instance_id: StringName) -> int:
	var gear := _gear(peer_id)
	if gear.is_empty():
		return 0
	var inventory := gear["inventory"] as ItemInventory
	var item := inventory.get_item(instance_id)
	if item == null or _is_equipped(gear, item):
		return 0
	var price := item_sell_price(item)
	inventory.remove(instance_id)
	gear["silver"] = int(gear["silver"]) + price
	_status(peer_id, "%s vendido por %d P." % [item_display_name(String(item.definition.id)), price])
	return price


# ---------------------------------------------------------------- loja

## Estoque atual (instâncias sem dono, só para exibir e vender). Mesma rodada, mesmo estoque.
func shop_stock() -> Array[EquipmentItemInstance]:
	var key := "%d:%d:%d" % [encounter_seed, shop_sequence, deepest_floor]
	if _shop_cache.has(key):
		return _shop_cache[key] as Array[EquipmentItemInstance]
	var random := RandomNumberGenerator.new()
	random.seed = hash([encounter_seed, shop_sequence, "shop"])
	var difficulty := 1.0 + float(deepest_floor) / 12.0
	var level := maxi(1, deepest_floor)
	var factory: RefCounted = BetaItemFactoryScript.new()
	var stock: Array[EquipmentItemInstance] = []
	var catalog: Array[Dictionary] = []
	for entry in _collection("items"):
		if String(entry.get("tier", "common")) != "legendary":
			catalog.append(entry)
	for index in range(SHOP_SIZE):
		var item_id := LootDifficultyScript.pick_bonus_item(catalog, difficulty, false, random)
		var definition := _find(_collection("items"), item_id)
		var item: EquipmentItemInstance = factory.call("instance_from_data", definition, StringName("loja_%d" % index)) if not definition.is_empty() else null
		if item == null:
			continue
		item.quality = StringName(LootDifficultyScript.pick_weighted(LootDifficultyScript.fabrication_weights(difficulty), random))
		item.item_level = clampi(level, 1, ItemAffixesScript.MAX_ITEM_LEVEL)
		item.affixes = ItemAffixesScript.roll_fixed(definition.get("fixed_affixes", []) as Array, random)
		item.affixes.append_array(ItemAffixesScript.roll(ItemTier.key(item.tier), random, item.item_level))
		item.set_meta("shop_index", index)
		stock.append(item)
	_shop_cache.clear()
	_shop_cache[key] = stock
	return stock


func shop_price(item: EquipmentItemInstance) -> int:
	return item_sell_price(item) * SHOP_MARKUP


func _near_shop(peer_id: int) -> bool:
	var state := player(peer_id)
	var npc := village_life.call("find", SHOP_NPC) as Dictionary
	return not state.is_empty() and not npc.is_empty() and state["zone"] == &"village" and (state["position"] as Vector2).distance_to(npc["position"] as Vector2) <= 110.0


func shop_model(peer_id: int) -> Dictionary:
	var items: Array = []
	var silver := int(_gear(peer_id).get("silver", 0))
	for item in shop_stock():
		var index := int(item.get_meta("shop_index"))
		var price := shop_price(item)
		items.append({
			"index": index, "item_id": String(item.definition.id), "name": item_display_name(String(item.definition.id)),
			"tier": ItemTier.label(item.tier), "tier_id": ItemTier.key(item.tier), "price": price,
			"sold": index in shop_sold, "affordable": silver >= price, "affix_count": item.affixes.size(),
			"rich_tooltip": _equipment_rich_tooltip(item, peer_id, "Comprar por %d P" % price),
		})
	return {"items": items, "silver": silver, "reroll_price": SHOP_REROLL_PRICE, "npc": SHOP_NPC}


## Compra a peça da vaga `index`: vira uma peça nova, igual à da vitrine, na mochila de quem comprou.
func buy_shop_item(peer_id: int, index: int) -> bool:
	var gear := _gear(peer_id)
	if gear.is_empty() or not _near_shop(peer_id) or index in shop_sold:
		return false
	var offer: EquipmentItemInstance = null
	for item in shop_stock():
		if int(item.get_meta("shop_index")) == index:
			offer = item
	if offer == null:
		return false
	var price := shop_price(offer)
	if int(gear["silver"]) < price:
		_status(peer_id, "Prata insuficiente: %s custa %d P." % [item_display_name(String(offer.definition.id)), price])
		return false
	var factory: RefCounted = BetaItemFactoryScript.new()
	var player_id := player(peer_id)["character_id"] as StringName
	var instance_id := StringName("%s_%d" % [String(offer.definition.id), equipment_instance_sequence])
	var bought: EquipmentItemInstance = factory.call("instance_from_data", _find(_collection("items"), String(offer.definition.id)), instance_id, player_id)
	if bought == null:
		return false
	bought.quality = offer.quality
	bought.item_level = offer.item_level
	bought.affixes = offer.affixes.duplicate(true)
	if not (gear["inventory"] as ItemInventory).add(bought):
		return false
	equipment_instance_sequence += 1
	gear["silver"] = int(gear["silver"]) - price
	shop_sold.append(index)
	_status(peer_id, "Comprado: %s por %d P." % [item_display_name(String(offer.definition.id)), price])
	return true


## Renova a vitrine na hora, pagando prata.
func reroll_shop(peer_id: int) -> bool:
	var gear := _gear(peer_id)
	if gear.is_empty() or not _near_shop(peer_id):
		return false
	if int(gear["silver"]) < SHOP_REROLL_PRICE:
		_status(peer_id, "Prata insuficiente para renovar o estoque (%d P)." % SHOP_REROLL_PRICE)
		return false
	gear["silver"] = int(gear["silver"]) - SHOP_REROLL_PRICE
	_restock_shop()
	_status(peer_id, "Dalia trouxe pecas novas da forja.")
	return true


func _restock_shop() -> void:
	shop_sequence += 1
	shop_sold.clear()


## Peças que "Vender tudo" vende: todo o inventário fora o equipado, lendários e armas únicas.
func _sellable_items(peer_id: int) -> Array[EquipmentItemInstance]:
	var result: Array[EquipmentItemInstance] = []
	var gear := _gear(peer_id)
	if gear.is_empty():
		return result
	var legendary := TIER_ORDER.find("legendary")
	for item: EquipmentItemInstance in (gear["inventory"] as ItemInventory).items.values():
		if int(item.tier) >= legendary or _is_equipped(gear, item) or _find(_collection("items"), String(item.definition.id)).has("unique_gem"):
			continue
		result.append(item)
	return result


func sell_all_preview(peer_id: int) -> Dictionary:
	var price := 0
	var items := _sellable_items(peer_id)
	for item in items:
		price += item_sell_price(item)
	return {"count": items.size(), "price": price}


## Vende de uma vez tudo o que sell_all_preview conta. Devolve a prata recebida.
func sell_all(peer_id: int) -> int:
	var gear := _gear(peer_id)
	var items := _sellable_items(peer_id)
	if items.is_empty():
		_status(peer_id, "Nada para vender: pecas equipadas, lendarias e armas unicas ficam.")
		return 0
	var earned := 0
	for item in items:
		earned += item_sell_price(item)
		(gear["inventory"] as ItemInventory).remove(item.instance_id)
	gear["silver"] = int(gear["silver"]) + earned
	_status(peer_id, "Vendidas %d %s por %d P." % [items.size(), "peca" if items.size() == 1 else "pecas", earned])
	return earned


## Filtro de saque: equipamentos abaixo desta raridade ficam no chão. "common" recolhe tudo.
func set_loot_filter(peer_id: int, tier: String) -> bool:
	var gear := _gear(peer_id)
	if gear.is_empty() or tier not in TIER_ORDER or tier == "legendary":
		return false
	gear["loot_filter"] = tier
	return true


## Autovenda ao voltar à vila: peças abaixo desta raridade. Vazio desliga.
func set_auto_sell(peer_id: int, tier: String) -> bool:
	var gear := _gear(peer_id)
	if gear.is_empty() or (tier != "" and tier not in ["uncommon", "rare", "epic"]):
		return false
	gear["auto_sell"] = tier
	return true


## Vende o que estiver abaixo do limite da autovenda; armas únicas e peças equipadas ficam.
## Devolve o resumo para o relatório de retorno ("" quando nada foi vendido).
func _auto_sell(peer_id: int) -> String:
	var gear := _gear(peer_id)
	var limit := TIER_ORDER.find(String(gear.get("auto_sell", "")))
	if gear.is_empty() or limit <= 0:
		return ""
	var inventory := gear["inventory"] as ItemInventory
	var sold := 0
	var earned := 0
	for instance_id: StringName in inventory.items.keys():
		var item := inventory.items[instance_id] as EquipmentItemInstance
		if int(item.tier) >= limit or _is_equipped(gear, item) or _find(_collection("items"), String(item.definition.id)).has("unique_gem"):
			continue
		earned += item_sell_price(item)
		inventory.remove(instance_id)
		sold += 1
	if sold == 0:
		return ""
	gear["silver"] = int(gear["silver"]) + earned
	return " Autovenda: %d %s por %d P." % [sold, "peca" if sold == 1 else "pecas", earned]


func _is_equipped(gear: Dictionary, item: EquipmentItemInstance) -> bool:
	var equipment := gear["equipment"] as EquipmentLoadout
	for spec: Array in LayoutScript.equipment_slot_specs():
		if equipment.get_equipped(spec[1] as EquipmentItemDefinition.Slot, int(spec[2])) == item:
			return true
	return false


## Quem tem filtro acima da raridade do equipamento passa por cima sem recolher.
func _filtered_out(peer_id: int, item_id: String, tier: String) -> bool:
	if not _is_equipment(item_id):
		return false
	return TIER_ORDER.find(tier) < TIER_ORDER.find(String(_gear(peer_id).get("loot_filter", "common")))


func _item_snapshot(item: EquipmentItemInstance, location: String, slot: int, index: int) -> Dictionary:
	return {
		"instance_id": String(item.instance_id), "definition_id": String(item.definition.id),
		"tier": int(item.tier), "quality": String(item.quality), "integrity": item.integrity,
		"location": location, "slot": slot, "index": index, "affixes": item.affixes.duplicate(true), "item_level": item.item_level,
	}


func _serialize_enemies(source: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for enemy in source:
		var serialized := enemy.duplicate(true) as Dictionary
		for key: String in ["position", "home", "wander_target"]:
			serialized[key] = _vector_array(enemy.get(key, enemy.get("position", Vector2.ZERO)) as Vector2)
		serialized["facing_direction"] = _vector_array(enemy.get("facing_direction", Vector2.DOWN) as Vector2)
		serialized.erase("flash")
		result.append(serialized)
	return result


func _serialize_ground_items() -> Array:
	var result: Array = []
	for item in ground_items:
		result.append({"zone": String(item["zone"]), "floor": int(item.get("floor", 0)), "position": _vector_array(item["position"] as Vector2), "item_id": item["item_id"], "quantity": item["quantity"], "quality": item.get("quality", "")})
	return result


func _restore_ground_items(source: Variant) -> void:
	ground_items.clear()
	if not source is Array:
		return
	var active := current_floor
	for value: Variant in source:
		if not value is Dictionary:
			continue
		var entry := value as Dictionary
		var item_id := String(entry.get("item_id", ""))
		var item_floor := int(entry.get("floor", 1))
		if _find(_collection("items"), item_id).is_empty() or item_floor < 1:
			continue
		current_floor = item_floor
		var quality := String(entry.get("quality", ""))
		var zone := StringName(String(entry.get("zone", "tower")))
		if zone not in [&"tower", &"boss_room"]:
			zone = &"tower"
		drop_item(zone, _array_vector(entry.get("position", []), Vector2(400.0, 360.0)), item_id, maxi(1, int(entry.get("quantity", 1))), quality if quality in LootDifficultyScript.FABRICATION_FACTORS else "")
	current_floor = active


func _deserialize_enemies(source: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not source is Array:
		return result
	for value: Variant in source:
		if not value is Dictionary:
			continue
		var enemy := (value as Dictionary).duplicate(true)
		enemy["position"] = _array_vector(enemy.get("position", []), Vector2.ZERO)
		enemy["home"] = _array_vector(enemy.get("home", []), enemy["position"] as Vector2)
		enemy["wander_target"] = _array_vector(enemy.get("wander_target", []), enemy["position"] as Vector2)
		enemy["facing_direction"] = _array_vector(enemy.get("facing_direction", []), Vector2.DOWN)
		enemy["health"] = maxf(0.001, float(enemy.get("health", 60.0)))
		enemy["max_health"] = maxf(1.0, float(enemy.get("max_health", 60.0)))
		enemy["shield_hits"] = maxi(0, int(enemy.get("shield_hits", 0)))
		enemy["minimum_affixes"] = clampi(int(enemy.get("minimum_affixes", 0)), 0, 2)
		enemy["maximum_affixes"] = clampi(int(enemy.get("maximum_affixes", 1)), 0, 2)
		for key: String in ["prefix_id", "suffix_id", "race_trait", "base_mechanic", "encounter_class", "loot_table_id", "race_id", "rank_id", "definition_id"]:
			enemy[key] = String(enemy.get(key, ""))
		if not enemy.has("modifier_mechanics"):
			enemy["modifier_mechanics"] = []
		result.append(enemy)
	return result


func _vector_array(value: Vector2) -> Array:
	return [value.x, value.y]


func _array_vector(value: Variant, fallback: Vector2) -> Vector2:
	if value is Array and (value as Array).size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback


# ---------------------------------------------------------------- conteúdo

func _load_gems() -> void:
	var definitions := _collection("active_gems")
	active_gems.clear()
	for gem_id in GEM_IDS:
		var definition := _find(definitions, gem_id)
		if not definition.is_empty():
			active_gems.append(definition)
	for index in range(mini(4, active_gems.size())):
		skill_max_cooldowns[index] = float(active_gems[index].get("cooldown", skill_max_cooldowns[index]))


## Coleções do catálogo beta somadas ao conteúdo da Torre; imutáveis durante a sessão, ficam em cache.
func _collection(key: String) -> Array[Dictionary]:
	var cache_key := "cache:" + key
	if _collections.has(cache_key):
		return _collections[cache_key] as Array[Dictionary]
	if not _collections.has("beta"):
		_collections["beta"] = _read_json(BETA_PATH)
	var result: Array[Dictionary] = []
	var raw: Variant = (_collections["beta"] as Dictionary).get(key, [])
	if raw is Array:
		for value: Variant in raw:
			if value is Dictionary:
				result.append(value as Dictionary)
	if key in ["enemies", "monster_races", "items", "loot_tables"]:
		result.append_array(TowerContentScript.collection(key))
	_collections[cache_key] = result
	return result


func _dev_collection(key: String) -> Array[Dictionary]:
	if not _collections.has("dev"):
		_collections["dev"] = _read_json(CONTENT_PATH)
	var result: Array[Dictionary] = []
	var raw: Variant = (_collections["dev"] as Dictionary).get(key, [])
	if raw is Array:
		for value: Variant in raw:
			if value is Dictionary and not String((value as Dictionary).get("id", "")).is_empty():
				result.append(value as Dictionary)
	return result


func _enemy_definitions() -> Array[Dictionary]:
	var definitions := _dev_collection("enemies")
	if definitions.is_empty():
		definitions = _collection("enemies")
	if definitions.is_empty():
		definitions.append({"id": "raspador_padrao", "kind": "melee", "health": 60.0, "speed": 42.0, "damage": 12.0, "attack_interval": 0.8, "loot_value": 1})
	return definitions


func _enemy_modifiers() -> Array[Dictionary]:
	var modifiers := _dev_collection("enemy_modifiers")
	return modifiers if not modifiers.is_empty() else _collection("enemy_modifiers")


func content(key: String) -> Array[Dictionary]:
	return _collection(key)


func _find(collection: Array[Dictionary], definition_id: String) -> Dictionary:
	for definition in collection:
		if String(definition.get("id", "")) == definition_id:
			return definition
	return {}


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}
