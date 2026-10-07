extends SceneTree

## Calibra GEM_EXPERIENCE_SHARE (decisão 588): joga andares com quatro gemas de dano equipadas,
## lançadas sempre que prontas, e compara a EXP que cada gema ganha com a da personagem. A gema mais
## usada define a parte: com ela, levar a gema ao 21 custa o mesmo que levar a personagem ao 95.
## Uso: godot --headless --path . --script tools/bench/gem_experience_probe.gd [-- --seconds=120]

const SimulationScript := preload("res://src/gameplay/world/world_simulation.gd")
const DELTA := 1.0 / 30.0
const LOADOUTS := {
	"eloa": ["elo_residual", "bola_de_fogo", "anel_de_geada", "chuva_ferral"],
	"sena": ["agulha_lastro", "lanca_ferral", "ceifa_ampla", "laminas_orbitais"],
	"cira": ["pulso_cicatriz", "ruptura_sismica", "prisao_gravitica", "dreno_em_rede"],
	"rui": ["mina_de_lastro", "semente_explosiva", "raio_prismatico", "molde_vigilante"],
}


func _init() -> void:
	var seconds := 120.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):
			seconds = float(arg.trim_prefix("--seconds="))
	var shares: Array[float] = []
	for character: String in LOADOUTS:
		for floor_number in [10, 30, 60]:
			var result := _run(character, floor_number, seconds)
			shares.append(float(result["best_share"]))
			print("GEMXP %s floor=%d player=%d gems=%s best_share=%.3f" % [character, floor_number, int(result["player"]), result["gems"], float(result["best_share"])])
	shares.sort()
	print("GEMXP median_best_share=%.3f" % shares[shares.size() / 2])
	quit(0)


func _total(sim: RefCounted, progress: Dictionary) -> int:
	var total := int(progress["experience"])
	for level in range(1, int(progress["level"])):
		total += int(sim.call("gem_experience_required", level))
	return total


func _run(character: String, floor_number: int, seconds: float) -> Dictionary:
	var sim: RefCounted = SimulationScript.new()
	sim.call("setup", floor_number * 53 + character.length())
	sim.call("add_player", 1, StringName(character))
	# Personagem no nível do andar, pontos nos atributos das gemas e primeira escolha de cada marco.
	var build := sim.call("character_build", 1) as CharacterBuild
	while build.level < floor_number:
		if build.has_pending_milestone():
			build.choose_milestone((build.milestone_choices[build.level] as Array)[0].id)
		elif not build.level_up():
			break
	if build.has_pending_milestone():
		build.choose_milestone((build.milestone_choices[build.level] as Array)[0].id)
	var plan: Array = (sim.call("gem_definition", LOADOUTS[character][0]) as Dictionary).get("scaling", ["intelligence", "wisdom"])
	var index := 0
	while build.unspent_stat_points > 0:
		build.allocate_stat(StringName(String(plan[index % plan.size()]) if index % 3 != 2 else "vitality"), 1)
		index += 1
	sim.call("_refresh_milestones", 1)
	sim.call("unlock_all_gems", 1)
	var gems := LOADOUTS[character] as Array
	for slot in range(4):
		sim.call("set_gem_slot", 1, slot, gems[slot])
	sim.set("deepest_floor", floor_number)
	sim.set("tower_start_floor", floor_number)
	sim.call("enter_tower", 1)
	var owned := (sim.call("_gem_state", 1) as Dictionary)["gems"] as Dictionary
	var before := {}
	for gem_id: String in gems:
		before[gem_id] = _total(sim, owned[gem_id])
	var player_xp := 0
	var time := 0.0
	while time < seconds:
		var state := sim.call("player", 1) as Dictionary
		state["health"] = 1.0e6
		state["breath"] = 1.0e3
		var enemies := sim.get("enemies") as Array
		if not enemies.is_empty():
			var position := state["position"] as Vector2
			var nearest := enemies[0]["position"] as Vector2
			for enemy: Dictionary in enemies:
				if position.distance_to(enemy["position"] as Vector2) < position.distance_to(nearest):
					nearest = enemy["position"] as Vector2
			sim.call("set_move_target", 1, nearest + (position - nearest).normalized() * 90.0)
			for slot in range(4):
				sim.call("use_skill", 1, slot, nearest)
		var kills_before := enemies.size()
		var defeated := []
		for enemy: Dictionary in enemies:
			defeated.append(enemy)
		sim.call("step", DELTA)
		var alive := sim.get("enemies") as Array
		for enemy: Dictionary in defeated:
			if not alive.has(enemy) and not bool(enemy.get("fragment", false)):
				player_xp += int(SimulationScript.EXPERIENCE_REWARDS.get(String(enemy.get("encounter_class", "common")), 12))
		time += DELTA
	var gained := {}
	var best := 0.0
	for gem_id: String in gems:
		gained[gem_id] = _total(sim, owned[gem_id]) - int(before[gem_id])
		best = maxf(best, float(gained[gem_id]) / maxf(1.0, float(player_xp)))
	return {"player": player_xp, "gems": gained, "best_share": best}
