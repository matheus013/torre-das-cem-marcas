extends SceneTree

## Sonda de gemas: mede quanto dano cada gema ativa acrescenta ao ataque automático, contra
## horda (andar comum, 60 s, média de 3 sementes) e contra alvo único (dano no chefe nos
## primeiros 15 s, antes de ele morrer e saturar a medida), com atributos distribuídos por igual
## para não favorecer gemas mágicas ou físicas. Joga com o Rui: a passiva dele depende de
## obstáculos, não de lançar gemas (a da Eloa soma dano fixo por lançamento e inflaria gemas de
## recarga curta). Novas e órbitas centradas na personagem são usadas de perto, como um jogador faria.
## Imprime GEM <id> <familia> horda chefe.
## Uso: godot --headless --path . --script tools/bench/gem_probe.gd [-- --gems=a,b] [--level=30]

const SimulationScript := preload("res://src/gameplay/world/world_simulation.gd")
const DURATION := 60.0
const DELTA := 1.0 / 30.0
const STATS: Array[StringName] = [&"strength", &"intelligence", &"agility", &"wisdom", &"vitality", &"fortune"]
const ARENAS := {"horda": 10, "chefe": 16}
const SEEDS := {"horda": 3, "chefe": 2}
const BOSS_WINDOW := 15.0

var level := 30


func _init() -> void:
	var only: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--gems="):
			for id in arg.trim_prefix("--gems=").split(","):
				only.append(id)
		elif arg.begins_with("--level="):
			level = maxi(1, int(arg.trim_prefix("--level=")))
	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json")) as Dictionary
	var baseline := {}
	for arena: String in ARENAS:
		baseline[arena] = _average(arena, "")
	print("GEM baseline horda=%.0f chefe=%.0f" % [baseline["horda"], baseline["chefe"]])
	for gem: Dictionary in catalog["active_gems"]:
		var gem_id := String(gem["id"])
		if not only.is_empty() and gem_id not in only:
			continue
		var values := []
		for arena: String in ARENAS:
			values.append(_average(arena, gem_id) - float(baseline[arena]))
		print("GEM %s %s horda=%.0f chefe=%.0f" % [gem_id, gem["mechanic"], values[0], values[1]])
	quit(0)


func _average(arena: String, gem_id: String) -> float:
	var total := 0.0
	for seed_index in range(int(SEEDS[arena])):
		total += _measure(int(ARENAS[arena]), gem_id, seed_index, arena == "chefe")
	return total / float(SEEDS[arena])


## Dano causado: na horda, a todos em 60 s; no chefe, só ao chefe nos primeiros 15 s.
## Com gem_id vazio, só o ataque automático.
func _measure(floor_number: int, gem_id: String, seed_index: int, boss_only: bool) -> float:
	var sim: RefCounted = SimulationScript.new()
	sim.call("setup", floor_number * 31 + seed_index * 7919)
	sim.call("add_player", 1, &"rui")
	var build := sim.call("character_build", 1) as CharacterBuild
	while build.level < level:
		if build.has_pending_milestone():
			build.choose_milestone((build.milestone_choices[build.level] as Array)[0].id)
		elif not build.level_up():
			break
	if build.has_pending_milestone():
		build.choose_milestone((build.milestone_choices[build.level] as Array)[0].id)
	var index := 0
	while build.unspent_stat_points > 0:
		build.allocate_stat(STATS[index % STATS.size()], 1)
		index += 1
	sim.call("_refresh_milestones", 1)
	var mechanic := ""
	if not gem_id.is_empty():
		sim.call("grant_gem", 1, gem_id)
		sim.call("set_gem_slot", 1, 0, gem_id)
		mechanic = String(sim.call("gem_definition", gem_id).get("mechanic", ""))
	sim.set("deepest_floor", floor_number)
	sim.set("tower_start_floor", floor_number)
	sim.call("enter_tower", 1)
	var dealt := 0.0
	var time := 0.0
	var boss: Dictionary = {}
	for enemy: Dictionary in sim.get("enemies") as Array:
		if bool(enemy.get("floor_boss", false)):
			boss = enemy
	var boss_start := float(boss.get("health", 0.0))
	while time < (BOSS_WINDOW if boss_only else DURATION):
		var state := sim.call("player", 1) as Dictionary
		state["health"] = 1.0e6
		# Saraivada mede com o Fôlego real: ela existe para gastá-lo.
		if mechanic != "volley":
			state["breath"] = 1.0e3
		var enemies := sim.get("enemies") as Array
		if not enemies.is_empty():
			var position := state["position"] as Vector2
			var nearest := enemies[0]["position"] as Vector2
			for enemy: Dictionary in enemies:
				if position.distance_to(enemy["position"] as Vector2) < position.distance_to(nearest):
					nearest = enemy["position"] as Vector2
			sim.call("set_move_target", 1, nearest + (position - nearest).normalized() * (40.0 if mechanic in ["nova", "orbit"] else 110.0))
			var channeling := (sim.get("persistent_effects") as Array).any(func(effect: Dictionary) -> bool: return effect["mechanic"] == "volley")
			if not gem_id.is_empty() and not channeling:
				sim.call("use_skill", 1, 0, nearest)
		sim.call("step", DELTA)
		time += DELTA
		for event: Dictionary in sim.call("drain_events"):
			if String(event.get("call", "")) == "number":
				var args := event["args"] as Array
				if args.size() < 4 or String(args[3]) in ["enemy", "poison"]:
					dealt += float(args[1])
	if boss_only:
		var alive := (sim.get("enemies") as Array).any(func(enemy: Dictionary) -> bool: return is_same(enemy, boss))
		return boss_start - (float(boss.get("health", 0.0)) if alive else 0.0)
	return dealt
