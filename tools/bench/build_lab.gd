extends RefCounted

## Laboratório de builds (decisão 610): monta o melhor set de uma gema ou autoataque por simulação e
## avalia nas cinco dificuldades. Usado por tools/bench/build_probe.gd e pelo teste da sonda.

const SimulationScript := preload("res://src/gameplay/world/world_simulation.gd")
const ParagonScript := preload("res://src/gameplay/progression/paragon.gd")
const AffixesScript := preload("res://src/gameplay/items/item_affixes.gd")
const ResistancesScript := preload("res://src/gameplay/combat/resistances.gd")
const DELTA := 1.0 / 15.0
const WINDOW := 14.0
const PACK := 6
const CONTACT := 3
const DUMMY_HEALTH := 1.0e12
const LOW_HEALTH := 1.0e9
const ARENA_FLOOR := 16
const BOSS_FLOORS: Array[int] = [16, 51, 100]
const PACK_FLOORS: Array[int] = [30, 75, 99]
## Metas de aprovação: chefe abaixo da fúria; aguentar 3 golpes da maior habilidade; limpar uma
## matilha em até 20 s e aguentar o contato de até 3 comuns por esse tempo (mínimo 8 s).
const PACK_CLEAR_LIMIT := 20.0
const BOSS_HITS := 3.0
const SURVIVE_MIN := 8.0
## Paragon por dificuldade (0 nas duas primeiras: só existe depois do nível 100 na 3).
const PARAGON_BY_DIFFICULTY: Array[int] = [0, 0, 50, 100, 175]
## Personagem por atributo principal da gema (a que mais aproveita a arma inicial).
const CHARACTER_BY_STAT := {"intelligence": "eloa", "wisdom": "rui", "strength": "cira", "agility": "sena", "vitality": "cira", "fortune": "sena"}
const AUTO_SUBJECTS := {"auto_foco": "eloa", "auto_lanca": "sena", "auto_manoplas": "cira", "auto_bastao": "rui"}
const AUTO_PLAN := {"eloa": ["intelligence", "wisdom"], "sena": ["strength", "agility"], "cira": ["strength", "vitality"], "rui": ["wisdom", "strength"]}
const SLOTS: Array[String] = ["weapon", "offhand", "amulet", "armor", "gloves", "boots", "pants", "ring", "ring", "relic"]
const PARAGON_PRESETS: Array[Dictionary] = [
	{"ofensiva": 0.6, "defensiva": 0.2, "utilidade": 0.1, "elemental": 0.1},
	{"ofensiva": 0.2, "defensiva": 0.2, "utilidade": 0.0, "elemental": 0.6},
	{"ofensiva": 0.35, "defensiva": 0.35, "utilidade": 0.15, "elemental": 0.15},
]

var fast := false
var _catalog: Dictionary = {}
var _items_by_slot: Dictionary = {}


func _init() -> void:
	_catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json")) as Dictionary
	for item: Dictionary in _catalog["items"]:
		if String(item.get("tier", "")) in ["legendary", "divine"] and not item.has("unique_gem"):
			_items_by_slot.get_or_add(String(item.get("slot", "")), []).append(item)


func subjects() -> Array[String]:
	var result: Array[String] = []
	for gem: Dictionary in _catalog["active_gems"]:
		result.append(String(gem["id"]))
	for auto_id: String in AUTO_SUBJECTS:
		result.append(auto_id)
	return result


# ---------------------------------------------------------------- estudo de um assunto

func study(subject: String) -> Dictionary:
	var build := _base_build(subject)
	_optimize_evolutions(build)
	_optimize_supports(build)
	var stages := {}
	# Dificuldade 2: equipamento sem divinos.
	_optimize_gear(build, false)
	stages[2] = build.duplicate(true)
	_optimize_paragon(build)
	stages[3] = _with_paragon(build, 50)
	# Dificuldade 4: Paragon 100 e o melhor divino sobre o set da 3.
	var four := _with_paragon(build, 100)
	_best_single_divine(four)
	stages[4] = four
	# Dificuldade 5: Paragon 175 e o set completo, divinos inclusos.
	var five := _with_paragon(build, 175)
	_optimize_gear(five, true)
	stages[5] = five
	var report := {"subject": subject, "character": build["character"], "element": _element(build), "stages": {}, "evaluation": {}}
	for level in [2, 3, 4, 5]:
		var power := _power(stages[level])
		(report["stages"] as Dictionary)[str(level)] = {"build": _describe(stages[level]), "power": power}
		print("POWER %s d%d boss=%.0f pack=%.0f boss_share=%.5f pack_share=%.5f health=%.0f" % [subject, level, float(power["boss"]), float(power["pack"]), float(power["boss_share"]), float(power["pack_share"]), float(power["health"])])
	print("BUILD %s %s" % [subject, JSON.stringify(_describe(stages[5]))])
	for level in range(1, 6):
		var verdicts: Array = []
		for floor_number in BOSS_FLOORS + PACK_FLOORS:
			var stage := _d1_build(build, floor_number) if level == 1 else stages[level] as Dictionary
			var power := _power(stage) if level == 1 else (report["stages"][str(level)]["power"] as Dictionary)
			var verdict := _evaluate(stage, power, level, floor_number)
			verdicts.append(verdict)
			print("EVAL %s d%d floor=%d %s" % [subject, level, floor_number, JSON.stringify(verdict)])
		(report["evaluation"] as Dictionary)[str(level)] = verdicts
	return report


func _base_build(subject: String) -> Dictionary:
	var gem := {}
	for entry: Dictionary in _catalog["active_gems"]:
		if String(entry["id"]) == subject:
			gem = entry
	# Gemas de potência fixa (Esporos) não escalam com atributos: Eloa, com o plano dela.
	var scaling := gem.get("scaling", []) as Array
	var character := String(AUTO_SUBJECTS.get(subject, CHARACTER_BY_STAT.get(String(scaling[0]), "cira") if not scaling.is_empty() else "eloa"))
	var plan: Array = AUTO_PLAN[character] if gem.is_empty() or scaling.is_empty() else scaling.duplicate()
	if plan.size() == 1:
		plan.append("vitality")
	var gear := {}
	if not gem.is_empty() and _has_item("unica_" + subject):
		gear["weapon"] = "unica_" + subject
	elif gem.is_empty():
		gear["weapon"] = String(SimulationScript.STARTER_WEAPONS[StringName(character)])
	return {"subject": subject, "character": character, "gem": String(gem.get("id", "")), "plan": plan, "level": 100, "mastery": 21,
		"evolutions": {}, "supports": [], "gear": gear, "paragon_level": 0, "paragon": {}}


func _has_item(item_id: String) -> bool:
	return (_catalog["items"] as Array).any(func(item: Dictionary) -> bool: return String(item["id"]) == item_id)


func _with_paragon(build: Dictionary, points: int) -> Dictionary:
	var copy := build.duplicate(true)
	copy["paragon_level"] = points
	var shares := copy.get("paragon_shares", PARAGON_PRESETS[0]) as Dictionary
	var board := {}
	var left := points
	for track in ParagonScript.TRACKS:
		board[track] = mini(left, int(round(float(shares.get(track, 0.0)) * points)))
		left -= int(board[track])
	board["ofensiva"] = int(board["ofensiva"]) + left
	copy["paragon"] = board
	return copy


## Dificuldade 1: personagem no nível do andar, maestria proporcional e o equipamento inicial.
func _d1_build(build: Dictionary, floor_number: int) -> Dictionary:
	var copy := build.duplicate(true)
	copy["level"] = clampi(floor_number, 1, 100)
	copy["mastery"] = clampi(1 + floor_number / 5, 1, 21)
	# Build simples: o equipamento inicial da personagem, no nível do andar, com afixos comuns.
	copy["gear"] = {"weapon": String(SimulationScript.STARTER_WEAPONS[StringName(String(build["character"]))]), "armor": "protecao_de_trabalho", "boots": "botas_de_rota_antiga", "ring0": "anel_de_folego"}
	copy["paragon_level"] = 0
	copy["paragon"] = {}
	var kept := {}
	for level: String in copy["evolutions"]:
		if int(level) <= int(copy["mastery"]):
			kept[level] = copy["evolutions"][level]
	copy["evolutions"] = kept
	return copy


# ---------------------------------------------------------------- otimização

func _score(build: Dictionary) -> float:
	var boss := _measure(build, "boss")
	var pack := _measure(build, "pack")
	return sqrt(maxf(boss, 1.0) * maxf(pack, 1.0))


func _optimize_evolutions(build: Dictionary) -> void:
	if String(build["gem"]).is_empty():
		return
	var gem := _gem(String(build["gem"]))
	for level in [5, 10, 15, 20, 21]:
		var options := (gem.get("evolutions", {}) as Dictionary).get(str(level), []) as Array
		var best := ""
		var best_score := -1.0
		for option: Dictionary in options:
			(build["evolutions"] as Dictionary)[str(level)] = String(option["id"])
			var score := _score(build)
			if score > best_score:
				best_score = score
				best = String(option["id"])
		(build["evolutions"] as Dictionary)[str(level)] = best


func _optimize_supports(build: Dictionary) -> void:
	var candidates: Array[String] = []
	for support: Dictionary in _catalog["support_gems"]:
		var trial := build.duplicate(true)
		trial["supports"] = [String(support["id"])]
		if _supports_attached(trial) == 1:
			candidates.append(String(support["id"]))
	var scored: Array = []
	for support_id in candidates:
		var trial := build.duplicate(true)
		trial["supports"] = [support_id]
		scored.append([support_id, _score(trial)])
	scored.sort_custom(func(left: Array, right: Array) -> bool: return float(left[1]) > float(right[1]))
	var top := scored.slice(0, 2 if fast else 4)
	var best: Array = [String(top[0][0])] if not top.is_empty() else []
	var best_score := float(top[0][1]) if not top.is_empty() else _score(build)
	for first in range(top.size()):
		for second in range(first + 1, top.size()):
			var trial := build.duplicate(true)
			trial["supports"] = [String(top[first][0]), String(top[second][0])]
			if _supports_attached(trial) < 2:
				continue
			var score := _score(trial)
			if score > best_score:
				best_score = score
				best = trial["supports"]
	build["supports"] = best


func _optimize_gear(build: Dictionary, divines: bool) -> void:
	var gear := build["gear"] as Dictionary
	var ring_index := 0
	for slot in SLOTS:
		var key := slot if slot != "ring" else "ring%d" % ring_index
		if slot == "ring":
			ring_index += 1
		var candidates: Array[String] = []
		if gear.has(key):
			candidates.append(String(gear[key]))
		if slot == "weapon":
			if not String(build["gem"]).is_empty() and _has_item("unica_" + String(build["gem"])):
				candidates.append("unica_" + String(build["gem"]))
			else:
				# Autoataque: arma inicial ou uma arma única (assume a forma da inicial, com mais potência).
				candidates.append(String(SimulationScript.STARTER_WEAPONS[StringName(String(build["character"]))]))
				candidates.append("unica_" + String(SimulationScript.STARTER_GEMS[StringName(String(build["character"]))]))
		for item: Dictionary in _items_by_slot.get(slot, []) as Array:
			if String(item["tier"]) == "divine" and not divines:
				continue
			if slot == "ring" and String(item["id"]) in [String(gear.get("ring0", "")), String(gear.get("ring1", ""))]:
				continue
			candidates.append(String(item["id"]))
		if fast:
			candidates = candidates.slice(0, 3)
		var best := String(gear.get(key, ""))
		var best_score := _score(build) if not best.is_empty() else -1.0
		for item_id in candidates:
			gear[key] = item_id
			var score := _score(build)
			if score > best_score:
				best_score = score
				best = item_id
		if best.is_empty():
			gear.erase(key)
		else:
			gear[key] = best


func _best_single_divine(build: Dictionary) -> void:
	var gear := build["gear"] as Dictionary
	var base_score := _score(build)
	var best_key := ""
	var best_item := ""
	for slot: String in _items_by_slot:
		for item: Dictionary in _items_by_slot[slot] as Array:
			if String(item["tier"]) != "divine":
				continue
			var key := slot if slot != "ring" else "ring0"
			var previous := String(gear.get(key, ""))
			gear[key] = String(item["id"])
			var score := _score(build)
			if score > base_score:
				base_score = score
				best_key = key
				best_item = String(item["id"])
			if previous.is_empty():
				gear.erase(key)
			else:
				gear[key] = previous
	if not best_key.is_empty():
		gear[best_key] = best_item


func _optimize_paragon(build: Dictionary) -> void:
	var best_score := -1.0
	var chosen: Dictionary = PARAGON_PRESETS[0].duplicate()
	for preset in PARAGON_PRESETS:
		var candidate := build.duplicate(true)
		candidate["paragon_shares"] = preset
		var trial := _with_paragon(candidate, 175)
		var score := _score(trial)
		if score > best_score:
			best_score = score
			chosen = preset.duplicate()
	build["paragon_shares"] = chosen


# ---------------------------------------------------------------- mundo e medida

func _world(build: Dictionary, difficulty: int = 1) -> WorldSimulation:
	var sim := SimulationScript.new()
	sim.setup(int(build.get("seed", 9101)))
	sim.add_player(1, StringName(String(build["character"])))
	var character := sim.character_build(1)
	while character.level < int(build["level"]):
		if character.has_pending_milestone():
			character.choose_milestone((character.milestone_choices[character.level] as Array)[0].id)
		elif not character.level_up():
			break
	if character.has_pending_milestone():
		character.choose_milestone((character.milestone_choices[character.level] as Array)[0].id)
	var plan := build["plan"] as Array
	var index := 0
	while character.unspent_stat_points > 0:
		var stat := "vitality" if index % 3 == 2 else String(plan[0] if index % 3 == 0 else plan[1])
		character.allocate_stat(StringName(stat), 1)
		index += 1
	sim._refresh_milestones(1)
	var gem_id := String(build["gem"])
	if not gem_id.is_empty():
		sim.grant_gem(1, gem_id)
		var progress := (sim._gem_state(1)["gems"] as Dictionary)[gem_id] as Dictionary
		progress["level"] = int(build["mastery"])
		progress["choices"] = (build["evolutions"] as Dictionary).duplicate()
		sim.set_gem_slot(1, 0, gem_id)
		for support_id: Variant in build["supports"] as Array:
			sim.attach_support(1, 0, String(support_id))
	else:
		for support_id: Variant in build["supports"] as Array:
			sim.attach_auto_support(1, String(support_id))
	for key: String in build["gear"] as Dictionary:
		var item_id := String(build["gear"][key])
		var instance_id := sim._add_equipment_instance(StringName(String(build["character"])), item_id, "masterwork", int(build["level"]))
		if String(instance_id).is_empty():
			continue
		var item := (sim._gear(1)["inventory"] as ItemInventory).items[instance_id] as EquipmentItemInstance
		if ItemTier.key(item.tier) != "divine":
			item.affixes = _good_affixes(build, ItemTier.key(item.tier), int(build["level"]))
		sim.equip_item(1, instance_id)
	if int(build.get("paragon_level", 0)) > 0:
		sim.set_paragon(1, {"level": int(build["paragon_level"]), "experience": 0, "boards": {String(build["character"]): build["paragon"]}})
	sim._passive_cache.clear()
	sim.unlocked_difficulty = 5
	sim.set_difficulty(1, difficulty)
	return sim


## Afixos de um jogador atento: dano do elemento da build, crítico, recarga e resistência a tudo.
func _good_affixes(build: Dictionary, tier: String, item_level: int) -> Array[Dictionary]:
	var element := _element(build)
	var damage_id: String = "dano_fisico" if element == "physical" else "dano_" + {"fire": "fogo", "ice": "gelo", "lightning": "raio", "acid": "acido", "nature": "natureza", "dark": "trevas", "holy": "sagrado", "earth": "terra", "arcane": "arcano"}.get(element, "magico")
	var result: Array[Dictionary] = []
	var count := int(AffixesScript.count_range(tier)[1])
	for id in [damage_id, "critico", "recarga", "resistencia_todas"].slice(0, count):
		var spec := AffixesScript.POOL[id] as Dictionary
		result.append({"id": id, "value": AffixesScript._round(spec, float(spec["max"]) * float(AffixesScript.SCALE.get(tier, 1.0)) * AffixesScript.affix_level_factor(spec, item_level))})
	return result


func _element(build: Dictionary) -> String:
	if String(build["gem"]).is_empty():
		var weapon := {"eloa": "arcane"}.get(String(build["character"]), "physical") as String
		return weapon
	var element := String(_gem(String(build["gem"])).get("element", ""))
	return element if not element.is_empty() else "physical"


func _gem(gem_id: String) -> Dictionary:
	for entry: Dictionary in _catalog["active_gems"]:
		if String(entry["id"]) == gem_id:
			return entry
	return {}


func _supports_attached(build: Dictionary) -> int:
	var sim := _world(build)
	if String(build["gem"]).is_empty():
		return ((sim._gem_state(1).get("auto_supports", []) as Array)).size()
	return (((sim._gem_state(1)["supports"] as Array)[0]) as Array).size()


## Dano por segundo em arena de alvos fixos. `kind`: "boss" (um alvo) ou "pack" (seis juntos).
func _measure(build: Dictionary, kind: String, dummy_health: float = DUMMY_HEALTH) -> float:
	return float(measurement(build, kind, dummy_health)["total_dps"])


func measurement(build: Dictionary, kind: String, dummy_health: float = DUMMY_HEALTH, seconds: float = WINDOW, isolated: bool = false) -> Dictionary:
	var sim := _world(build)
	sim.damage_meter_enabled = true
	if isolated:
		sim.set_auto_attack(1, false)
		# No item-specific power or procs in the equal-investment comparison.
		sim._gear(1)["equipment"] = EquipmentLoadout.new()
		sim._passive_cache.clear()
	sim.clock.call("set_period", "tarde")
	sim.enter_tower(1)
	sim.start_floor(ARENA_FLOOR)
	sim.floor_run["population"] = 0
	sim.respawn.call("clear")
	sim.enemies.clear()
	sim.telegraphs.clear()
	var origin := sim.player(1)["position"] as Vector2
	var center := origin + Vector2(220.0, 0.0)
	var definition := (sim.content("enemies") as Array).filter(func(item: Dictionary) -> bool: return String(item.get("encounter_class", "")) == "common")[0] as Dictionary
	var count := 1 if kind == "boss" else PACK
	for index in range(count):
		var spot := center if count == 1 else center + Vector2.RIGHT.rotated(TAU * index / float(count)) * 55.0
		var dummy := sim.create_enemy(definition, spot, index)
		for key in ["max_health", "health"]:
			dummy[key] = dummy_health
		dummy["speed"] = 0.0
		dummy["damage"] = 0.0
		dummy["resistances"] = {}
		dummy["shield_hits"] = 0
		dummy["modifier_mechanics"] = []
		dummy["allow_affixes"] = false
		dummy.erase("behavior_id")
		# O alvo único faz papel de chefe (efeitos por fração da Vida são menores em chefes).
		if count == 1:
			dummy["encounter_class"] = "boss"
		sim.enemies.append(dummy)
	var mechanic := String(_gem(String(build["gem"])).get("mechanic", "")) if not String(build["gem"]).is_empty() else ""
	# Distância de combate como um jogador escolheria: perto para o que gira em volta da personagem
	# (novas, órbitas, campos e santuários que a seguem) e a meia distância para o resto.
	var resolved := sim.resolve_slot(1, 0) if not mechanic.is_empty() else {}
	var close := mechanic in ["nova", "orbit", "barrier", "sanctuary"] or bool(resolved.get("field_follows_player", false)) or String(resolved.get("mechanic", "")) in ["nova", "orbit"]
	var weapon_range := float(sim.weapon_attack_model(1).get("range", 140.0))
	var reach := minf(weapon_range * 0.8, float(resolved.get("range", 999.0)) * 0.6) if not resolved.is_empty() else weapon_range * 0.8
	var standoff := clampf(reach, 60.0, 160.0)
	var stand := center - Vector2(standoff, 0.0)
	var resolved_mechanic := String(resolved.get("mechanic", mechanic))
	var orbit_distance := float(resolved.get("radius", 100.0)) if resolved_mechanic == "orbit" else clampf(float(resolved.get("radius", 80.0)) * 0.5, 25.0, 90.0)
	sim.player(1)["position"] = center - Vector2(orbit_distance, 0.0) if close else stand
	var time := 0.0
	var casts := 0
	var starved := 0.0
	while time < seconds:
		var state := sim.player(1)
		# Vida real: gemas que custam Vida gastam de verdade (os alvos não ferem; a regeneração é a do jogo).
		state["invulnerable"] = 1.0
		if close:
			# Curto alcance: circula o alvo na distância que a mecânica pede (órbita no raio dela,
			# nova e campo que segue dentro de metade do raio), oscilando um pouco.
			var radius := orbit_distance + 12.0 * sin(time * 1.3)
			sim.set_move_target(1, center + Vector2.RIGHT.rotated(time * 1.2 + PI) * radius)
		elif int(time / DELTA) % 10 == 0:
			sim.set_move_target(1, stand)
			if mechanic == "dash":
				state["position"] = stand
		var channeling := (sim.persistent_effects as Array).any(func(effect: Dictionary) -> bool: return effect["mechanic"] == "volley")
		if not mechanic.is_empty() and not channeling:
			if sim.use_skill(1, 0, center):
				casts += 1
		if isolated and not String(build["gem"]).is_empty():
			var progress := (sim._gem_state(1)["gems"] as Dictionary)[String(build["gem"])] as Dictionary
			progress["level"] = int(build["mastery"])
			progress["experience"] = 0
			progress["choices"] = (build["evolutions"] as Dictionary).duplicate()
		if float(state["breath"]) < float(resolved.get("breath_cost", 0.0)):
			starved += DELTA
		sim.step(DELTA)
		sim.drain_events()
		time += DELTA
	var sources := {}
	var shares := {}
	var dealt := 0.0
	for source: String in sim.damage_meter:
		var amount := float(sim.damage_meter[source])
		dealt += amount
		sources[source] = amount / time
		shares[source] = float(sim.damage_meter_percent.get(source, 0.0)) / (dummy_health * count * time)
	return {"total_dps": dealt / time, "sources": sources, "shares": shares, "seconds": time, "casts": casts, "starved_seconds": starved}


## Dano fixo por segundo e fração da Vida máxima do alvo por segundo (esporos e afins), medidos com
## duas Vidas de alvo: dano = fixo + fração x Vida. Na matilha a fração é por alvo.
func _power(build: Dictionary) -> Dictionary:
	var sim := _world(build)
	var result := {"health": sim.max_health(1)}
	for kind in ["boss", "pack"]:
		var low := _measure(build, kind, LOW_HEALTH)
		var high := _measure(build, kind, DUMMY_HEALTH)
		var targets := 1.0 if kind == "boss" else float(PACK)
		var share := maxf(0.0, (high - low) / ((DUMMY_HEALTH - LOW_HEALTH) * targets))
		result[kind] = maxf(0.0, low - share * LOW_HEALTH * targets)
		result[kind + "_share"] = share
	return result


## Dano por segundo efetivo contra alvos de Vida `health` (no chefe, um; na matilha, a soma dos seis).
static func effective(power: Dictionary, kind: String, health: float) -> float:
	return float(power[kind]) + float(power.get(kind + "_share", 0.0)) * health * (1.0 if kind == "boss" else float(PACK))


# ---------------------------------------------------------------- avaliação

func _evaluate(build: Dictionary, power: Dictionary, difficulty: int, floor_number: int) -> Dictionary:
	var sim := _world(build, difficulty)
	sim.clock.call("set_period", "tarde")
	sim.enter_tower(1)
	sim.start_floor(floor_number)
	var element := _element(build)
	var health := sim.max_health(1)
	# Ressonância da dificuldade: o poder medido na arena (dificuldade 1) cresce com ela.
	var resonance := float(SimulationScript.DIFFICULTIES[difficulty - 1].get("power", 1.0))
	if floor_number in BOSS_FLOORS:
		var boss := sim.enemies.filter(func(enemy: Dictionary) -> bool: return bool(enemy.get("floor_boss", false)))[0] as Dictionary
		var resist := clampf(float((boss.get("resistances", {}) as Dictionary).get(element, 0.0)), -0.5, 0.75)
		# Escudos da dificuldade 5 somam Vida a derrubar.
		var shields := 1.0 + (SimulationScript.BOSS_SHIELD_SHARE * SimulationScript.BOSS_SHIELD_THRESHOLDS.size() if difficulty >= 5 else 0.0)
		var ttk := float(boss["max_health"]) * shields / maxf(1.0, effective(power, "boss", float(boss["max_health"])) * resonance * (1.0 - resist))
		var biggest := float(boss["damage"])
		for ability: Dictionary in boss.get("kit", []) as Array:
			biggest = maxf(biggest, float(ability.get("damage", 0.0)))
		var lost := _hit_loss(sim, biggest, ResistancesScript.BIOME_DAMAGE.get(String(sim.floor_def().get("biome", "")), "physical"))
		var hits := health / maxf(0.001, lost)
		return {"floor": floor_number, "kind": "boss", "ttk": snappedf(ttk, 0.1), "enrage": float(boss.get("enrage", 200.0)), "hits": snappedf(hits, 0.1),
			"kill": ttk <= float(boss.get("enrage", 200.0)), "survive": hits >= BOSS_HITS,
			"dps_gap": snappedf(ttk / float(boss.get("enrage", 200.0)), 0.01), "pass": ttk <= float(boss.get("enrage", 200.0)) and hits >= BOSS_HITS}
	var commons := sim.enemies.filter(func(enemy: Dictionary) -> bool: return String(enemy.get("encounter_class", "")) == "common" and String(enemy.get("time_of_day", "")).is_empty() and not bool(enemy.get("superior", false)))
	var sample := commons[0] as Dictionary if not commons.is_empty() else sim.enemies[0] as Dictionary
	var resist := clampf(float((sample.get("resistances", {}) as Dictionary).get(element, 0.0)), -0.5, 0.75)
	var clear := float(sample["max_health"]) * PACK / maxf(1.0, effective(power, "pack", float(sample["max_health"])) * resonance * (1.0 - resist))
	var per_hit := _hit_loss(sim, float(sample["damage"]), String(sample.get("damage_type", "physical")))
	# Até 3 comuns batem ao mesmo tempo: o resto da matilha espera vaga em volta da personagem.
	var incoming := per_hit * mini(PACK, CONTACT) / maxf(0.2, float(sample.get("attack_interval", 0.8)))
	var down := health / maxf(0.001, incoming)
	var need := maxf(SURVIVE_MIN, clear)
	return {"floor": floor_number, "kind": "pack", "clear": snappedf(clear, 0.1), "down": snappedf(down, 0.1),
		"kill": clear <= PACK_CLEAR_LIMIT, "survive": down >= need, "dps_gap": snappedf(clear / PACK_CLEAR_LIMIT, 0.01),
		"pass": clear <= PACK_CLEAR_LIMIT and down >= need}


## Vida perdida por um golpe de `amount` do tipo dado, com tudo o que a personagem tem de defesa.
func _hit_loss(sim: WorldSimulation, amount: float, damage_type: String) -> float:
	var state := sim.player(1)
	state["invulnerable"] = 0.0
	state["barrier"] = 0.0
	state["health"] = 1.0e12
	var before := float(state["health"])
	sim.take_damage(1, amount, damage_type)
	var lost := before - float(state["health"])
	state["health"] = sim.max_health(1)
	state["downed"] = false
	return lost


func _describe(build: Dictionary) -> Dictionary:
	var evolutions := {}
	for level: String in build["evolutions"]:
		evolutions[level] = String(build["evolutions"][level])
	return {"character": build["character"], "gem": build["gem"], "evolutions": evolutions, "supports": build["supports"],
		"gear": build["gear"], "paragon_level": build.get("paragon_level", 0), "paragon": build.get("paragon", {})}
