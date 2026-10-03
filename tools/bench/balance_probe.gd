extends SceneTree

## Sonda de balanceamento sem janelas: uma personagem no nível do andar, com atributos e marcos
## distribuídos, joga andares de amostra com um piloto simples (caça, usa gemas, foge de áreas).
## Mede tempo para cumprir a cota ou derrotar o chefe, dano sofrido e quedas.
## Uso: godot --headless --path . --script tools/bench/balance_probe.gd [-- --party=2]

const SimulationScript := preload("res://src/gameplay/world/world_simulation.gd")
const TelegraphScript := preload("res://src/gameplay/encounters/telegraph.gd")
const FLOORS: Array[int] = [1, 4, 9, 16, 30, 39, 51, 63, 75, 81, 93, 100]
const LIMIT := 300.0
const DELTA := 1.0 / 30.0
const PLAN := {"eloa": ["intelligence", "wisdom"], "sena": ["agility", "strength"], "cira": ["intelligence", "vitality"], "rui": ["strength", "vitality"]}


func _init() -> void:
	var party := 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--party="):
			party = clampi(int(arg.trim_prefix("--party=")), 1, 4)
	print("BALANCE party=%d" % party)
	for number in FLOORS:
		var result := _run(number, party)
		print("BALANCE floor=%3d kind=%-7s level=%3d result=%-8s time=%6.1fs damage_taken=%7.0f falls=%d defeats=%d kills=%d" % [
			number, result["kind"], result["level"], result["result"], result["time"], result["damage"], result["falls"], result["defeats"], result["kills"]])
	quit(0)


func _run(number: int, party: int) -> Dictionary:
	var sim: RefCounted = SimulationScript.new()
	sim.call("setup", number * 101)
	var characters := ["eloa", "sena", "cira", "rui"]
	var level := maxi(1, number)
	for peer_id in range(1, party + 1):
		sim.call("add_player", peer_id, StringName(characters[peer_id - 1]))
		_grow(sim, peer_id, level, characters[peer_id - 1])
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
			_pilot(sim, peer_id, state)
		sim.call("step", DELTA)
		time += DELTA
		for peer_id in range(1, party + 1):
			if bool((sim.call("player", peer_id) as Dictionary).get("downed", false)) and not bool(last_health.get("down_%d" % peer_id, false)):
				falls += 1
			last_health["down_%d" % peer_id] = bool((sim.call("player", peer_id) as Dictionary).get("downed", false))
		if bool((sim.get("floor_run") as Dictionary).get("stairs_open", false)):
			return {"kind": kind, "level": level, "result": "ok", "time": time, "damage": damage, "falls": falls, "defeats": defeats, "kills": int((sim.get("floor_run") as Dictionary).get("kills", 0))}
	return {"kind": kind, "level": level, "result": "timeout", "time": time, "damage": damage, "falls": falls, "defeats": defeats, "kills": int((sim.get("floor_run") as Dictionary).get("kills", 0))}


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


func _pilot(sim: RefCounted, peer_id: int, state: Dictionary) -> void:
	var position := state["position"] as Vector2
	for telegraph: Dictionary in sim.get("telegraphs"):
		if TelegraphScript.contains(telegraph, position, 24.0):
			var away := (position - (telegraph["position"] as Vector2)).normalized()
			if String(telegraph["shape"]) == "ring":
				away = -away
			elif String(telegraph["shape"]) == "rect":
				away = Vector2.DOWN.rotated(float(telegraph["angle"]))
			sim.call("set_move_target", peer_id, position + (away if away != Vector2.ZERO else Vector2.LEFT) * 160.0)
			return
	var enemies := sim.get("enemies") as Array
	if enemies.is_empty():
		return
	var nearest := enemies[0]["position"] as Vector2
	for enemy: Dictionary in enemies:
		if position.distance_to(enemy["position"] as Vector2) < position.distance_to(nearest):
			nearest = enemy["position"] as Vector2
	var distance := position.distance_to(nearest)
	var away := (position - nearest).normalized() if distance > 1.0 else Vector2.LEFT
	sim.call("set_move_target", peer_id, nearest + away.rotated(0.6) * 140.0 if distance < 700.0 else nearest)
	if float(state["health"]) < float(sim.call("max_health", peer_id)) * 0.4:
		sim.call("use_quick_item", peer_id)
	if distance < 320.0:
		for slot in range(4):
			if sim.call("use_skill", peer_id, slot, nearest):
				break
