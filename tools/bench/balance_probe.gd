extends SceneTree

## Sonda de balanceamento sem janelas: uma personagem no nível do andar, com atributos e marcos
## distribuídos, joga andares de amostra com um piloto simples (caça, usa gemas, foge de áreas).
## Mede tempo para cumprir a cota ou derrotar o chefe, dano sofrido e quedas.
## Uso: godot --headless --path . --script tools/bench/balance_probe.gd [-- --party=2]
##   [--characters=sena,rui] [--floors=1,16,51] [--seeds=3]  (personagens e andares escolhidos; média de sementes)

const SimulationScript := preload("res://src/gameplay/world/world_simulation.gd")
const TelegraphScript := preload("res://src/gameplay/encounters/telegraph.gd")
const FLOORS: Array[int] = [1, 4, 10, 16, 30, 39, 51, 63, 75, 81, 93, 100]
const LIMIT := 300.0
const DELTA := 1.0 / 30.0
## Pontos nos atributos que a arma inicial escala (documento armas-e-afinidades), como faria
## um jogador razoável; a cada três pontos, um vai para Vitalidade.
const PLAN := {"eloa": ["intelligence", "wisdom"], "sena": ["strength", "agility"], "cira": ["strength", "vitality"], "rui": ["wisdom", "strength"]}


var characters: Array[String] = ["eloa", "sena", "cira", "rui"]
## Item lendário ou arma única equipado em todas as personagens (`--item=`; `starter` usa a arma
## única da gema inicial de cada uma). A gema da arma única entra sempre no loadout.
var item := ""
## Alvo atual por jogador e alvos abandonados: inimigo que não perde vida em 4 s está
## inalcançável (atrás de obstáculos, como no andar 9) e o piloto passa ao próximo.
var _focus := {}
## Fuga de telegrafia que não sai do lugar (parede no caminho) inverte o sentido.
var _flee := {}
var _ignored: Array[Dictionary] = []


func _init() -> void:
	var party := 1
	var floors := FLOORS
	var seeds := 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--party="):
			party = clampi(int(arg.trim_prefix("--party=")), 1, 4)
		elif arg.begins_with("--characters="):
			characters.clear()
			for id in arg.trim_prefix("--characters=").split(","):
				characters.append(id)
			party = characters.size()
		elif arg.begins_with("--floors="):
			floors = [] as Array[int]
			for value in arg.trim_prefix("--floors=").split(","):
				floors.append(int(value))
		elif arg.begins_with("--seeds="):
			seeds = maxi(1, int(arg.trim_prefix("--seeds=")))
		elif arg.begins_with("--item="):
			item = arg.trim_prefix("--item=")
	print("BALANCE party=%d characters=%s seeds=%d item=%s" % [party, ",".join(characters.slice(0, party)), seeds, item])
	for number in floors:
		for seed_index in range(seeds):
			var result := _run(number, party, seed_index)
			print("BALANCE floor=%3d seed=%d kind=%-7s level=%3d result=%-8s time=%6.1fs damage_taken=%7.0f falls=%d defeats=%d kills=%d" % [
				number, seed_index, result["kind"], result["level"], result["result"], result["time"], result["damage"], result["falls"], result["defeats"], result["kills"]])
	quit(0)


func _run(number: int, party: int, seed_index: int = 0) -> Dictionary:
	var sim: RefCounted = SimulationScript.new()
	sim.call("setup", number * 101 + seed_index * 7919)
	var level := maxi(1, number)
	for peer_id in range(1, party + 1):
		sim.call("add_player", peer_id, StringName(characters[peer_id - 1]))
		_grow(sim, peer_id, level, characters[peer_id - 1])
		var item_id := ("unica_" + String(SimulationScript.STARTER_GEMS[StringName(characters[peer_id - 1])])) if item == "starter" else item
		var forced := String((sim.call("item_data", item_id) as Dictionary).get("unique_gem", "")) if not item_id.is_empty() else ""
		_equip_owned_gems(sim, peer_id, number, characters[peer_id - 1], forced)
		if not item_id.is_empty():
			sim.call("equip_item", peer_id, sim.call("_add_equipment_instance", StringName(characters[peer_id - 1]), item_id, "regular"))
	sim.set("deepest_floor", number)
	sim.set("tower_start_floor", number)
	for peer_id in range(1, party + 1):
		sim.call("enter_tower", peer_id)
	var kind := String((sim.call("floor_def") as Dictionary).get("kind", ""))
	var time := 0.0
	var damage := 0.0
	var falls := 0
	var defeats := 0
	var last_health := {}
	while time < LIMIT:
		for peer_id in range(1, party + 1):
			var state := sim.call("player", peer_id) as Dictionary
			if state["zone"] != &"tower":
				defeats += 1
				sim.call("enter_tower", peer_id)
				continue
			var health := float(state["health"])
			if last_health.has(peer_id) and health < float(last_health[peer_id]):
				damage += float(last_health[peer_id]) - health
			last_health[peer_id] = health
			if bool(state.get("downed", false)):
				continue
			_pilot(sim, peer_id, state, time)
		sim.call("step", DELTA)
		time += DELTA
		for peer_id in range(1, party + 1):
			if bool((sim.call("player", peer_id) as Dictionary).get("downed", false)) and not bool(last_health.get("down_%d" % peer_id, false)):
				falls += 1
			last_health["down_%d" % peer_id] = bool((sim.call("player", peer_id) as Dictionary).get("downed", false))
		if bool((sim.get("floor_run") as Dictionary).get("stairs_open", false)):
			return {"kind": kind, "level": level, "result": "ok", "time": time, "damage": damage, "falls": falls, "defeats": defeats, "kills": int((sim.get("floor_run") as Dictionary).get("kills", 0))}
	if OS.get_cmdline_user_args().has("--diagnose"):
		var me := (sim.call("player", 1) as Dictionary)["position"] as Vector2
		for enemy: Dictionary in sim.get("enemies") as Array:
			print("STUCK enemy=%s mech=%s pos=%s dist=%.0f awake=%s" % [enemy.get("definition_id"), enemy.get("base_mechanic"), str((enemy["position"] as Vector2).round()), me.distance_to(enemy["position"] as Vector2), str(enemy.get("awakened", "-"))])
		print("STUCK player=%s alive=%d breath=%.0f weapon=%s" % [str(me.round()), (sim.get("enemies") as Array).size(), float((sim.call("player", 1) as Dictionary)["breath"]), str(sim.call("weapon_attack_model", 1))])
		var nearest_index := int(sim.call("nearest_enemy_to", me, 400.0))
		if nearest_index >= 0:
			var near := (sim.get("enemies") as Array)[nearest_index] as Dictionary
			print("STUCK nearest id=%s health=%.0f/%.0f mechanics=%s prefix=%s suffix=%s pos=%s" % [near.get("definition_id"), float(near["health"]), float(near.get("max_health", 0)), str(near.get("modifier_mechanics", [])), near.get("prefix_id", ""), near.get("suffix_id", ""), str((near["position"] as Vector2).round())])
		var covering := 0
		for telegraph: Dictionary in sim.get("telegraphs"):
			if TelegraphScript.contains(telegraph, me, 24.0):
				covering += 1
		var state := sim.call("player", 1) as Dictionary
		print("STUCK telegraphs=%d covering=%d target=%s moving=%s focus=%s ignored=%d" % [(sim.get("telegraphs") as Array).size(), covering, str(state.get("target")), str(state.get("moving")), str(_focus.get(1, {}).get("health", "-")), _ignored.size()])
	return {"kind": kind, "level": level, "result": "timeout", "time": time, "damage": damage, "falls": falls, "defeats": defeats, "kills": int((sim.get("floor_run") as Dictionary).get("kills", 0))}


## Gemas que a personagem teria (decisão 579): a inicial e os conjuntos dos chefes abaixo deste
## andar. Encaixa as quatro que um jogador escolheria: de dano, escalando com os atributos do
## plano da personagem, uma por mecânica; no empate, a mais recente.
func _equip_owned_gems(sim: RefCounted, peer_id: int, floor_number: int, character: String, forced: String = "") -> void:
	var owned: Array[String] = [String(SimulationScript.STARTER_GEMS[StringName(character)])]
	var obtained := {owned[0]: 1}
	for boss_floor in range(1, floor_number):
		for gem_id in SimulationScript.boss_gem_set(boss_floor):
			if sim.call("grant_gem", peer_id, gem_id):
				owned.append(gem_id)
				obtained[gem_id] = boss_floor
	var plan := PLAN[character] as Array
	var scored: Array[Dictionary] = []
	for index in range(owned.size()):
		var gem := sim.call("gem_definition", owned[index]) as Dictionary
		var score := 4.0 if "damage" in (gem.get("tags", []) as Array) else 0.0
		var scaling := gem.get("scaling", []) as Array
		for rank in range(scaling.size()):
			if String(scaling[rank]) in plan:
				score += 2.0 if rank == 0 else 1.0
		scored.append({"id": owned[index], "score": score + index * 0.001 + (100.0 if owned[index] == forced else 0.0)})
	scored.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left["score"]) > float(right["score"]))
	# Uma gema por mecânica, como um jogador montaria (quatro meteoros não fecham uma build).
	var picked: Array[String] = []
	var mechanics := {}
	for entry in scored:
		var mechanic := String((sim.call("gem_definition", String(entry["id"])) as Dictionary).get("mechanic", ""))
		if picked.size() < 4 and not mechanics.has(mechanic):
			picked.append(String(entry["id"]))
			mechanics[mechanic] = true
	for slot in range(4):
		sim.call("set_gem_slot", peer_id, slot, picked[slot] if slot < picked.size() else "")
	# Gema em uso cresce: um nível a cada 6 andares desde que chegou, com a primeira evolução de cada nível.
	for gem_id in picked:
		var levels := clampi(1 + (floor_number - int(obtained[gem_id])) / 6, 1, int(SimulationScript.GEM_MAX_LEVEL_BETA))
		for level in range(1, levels):
			sim.call("gain_gem_experience", peer_id, gem_id, int(sim.call("gem_experience_required", level)))
			var options := ((sim.call("gem_definition", gem_id) as Dictionary).get("evolutions", {}) as Dictionary).get(str(level), []) as Array
			if not options.is_empty():
				sim.call("choose_gem_evolution", peer_id, gem_id, String((options[0] as Dictionary)["id"]))


## Nível do andar, atributos pelo plano da personagem e a primeira escolha de cada marco.
func _grow(sim: RefCounted, peer_id: int, level: int, character: String) -> void:
	var build := sim.call("character_build", peer_id) as CharacterBuild
	while build.level < level:
		if build.has_pending_milestone():
			build.choose_milestone((build.milestone_choices[build.level] as Array)[0].id)
		elif not build.level_up():
			break
	if build.has_pending_milestone():
		build.choose_milestone((build.milestone_choices[build.level] as Array)[0].id)
	var plan := PLAN[character] as Array
	var index := 0
	while build.unspent_stat_points > 0:
		build.allocate_stat(StringName("vitality" if index % 3 == 2 else String(plan[index % 2])), 1)
		index += 1
	sim.call("_refresh_milestones", peer_id)


func _pilot(sim: RefCounted, peer_id: int, state: Dictionary, now: float) -> void:
	var position := state["position"] as Vector2

	for telegraph: Dictionary in sim.get("telegraphs"):
		if TelegraphScript.contains(telegraph, position, 24.0):
			var away := (position - (telegraph["position"] as Vector2)).normalized()
			if String(telegraph["shape"]) == "ring":
				away = -away
			elif String(telegraph["shape"]) == "rect":
				away = Vector2.DOWN.rotated(float(telegraph["angle"]))
			if away == Vector2.ZERO:
				away = Vector2.LEFT
			var last := _flee.get(peer_id, {}) as Dictionary
			var flip := bool(last.get("flip", false))
			if not last.is_empty() and now - float(last["time"]) > 0.6 and position.distance_to(last["position"] as Vector2) < 8.0:
				flip = not flip
				last = {}
			if last.is_empty():
				_flee[peer_id] = {"position": position, "time": now, "flip": flip}
			sim.call("set_move_target", peer_id, position + (-away if flip else away) * 160.0)
			return
	var enemies := sim.get("enemies") as Array
	var chosen: Dictionary = {}
	for enemy: Dictionary in enemies:
		if _ignored.any(func(other: Dictionary) -> bool: return is_same(other, enemy)):
			continue
		if chosen.is_empty() or position.distance_to(enemy["position"] as Vector2) < position.distance_to(chosen["position"] as Vector2):
			chosen = enemy
	if chosen.is_empty():
		_ignored.clear()
		return
	var focus := _focus.get(peer_id, {}) as Dictionary
	if focus.is_empty() or not is_same(focus["enemy"], chosen) or float(chosen["health"]) < float(focus["health"]):
		_focus[peer_id] = {"enemy": chosen, "health": float(chosen["health"]), "since": now}
	elif now - float(focus["since"]) > 4.0:
		_ignored.append(chosen)
		_focus.erase(peer_id)
	var nearest := chosen["position"] as Vector2
	var distance := position.distance_to(nearest)
	var away := (position - nearest).normalized() if distance > 1.0 else Vector2.LEFT
	# Distância de combate pelo alcance da arma: armas curtas precisam chegar perto para acertar.
	var standoff := clampf(float((sim.call("weapon_attack_model", peer_id) as Dictionary).get("range", 140.0)) * 0.75, 60.0, 200.0)
	sim.call("set_move_target", peer_id, nearest + away.rotated(0.6) * standoff if distance < 700.0 else nearest)
	if float(state["health"]) < float(sim.call("max_health", peer_id)) * 0.4:
		sim.call("use_quick_item", peer_id)
	if distance < 320.0:
		for slot in range(4):
			if sim.call("use_skill", peer_id, slot, nearest):
				break
