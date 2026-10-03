extends SceneTree

## Árvores 10-100 no combate: Vida por nível, modificadores, parâmetros da passiva, mecânicas e uma
## varredura que aplica cada uma das 240 escolhas numa luta curta para garantir execução sem erro.

const SimulationScript := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run()


func _run() -> void:
	var sim: RefCounted = SimulationScript.new()
	sim.call("setup", 77)
	sim.call("add_player", 1, &"eloa")
	var build := sim.call("character_build", 1) as CharacterBuild
	var base_health := float(sim.call("max_health", 1))
	for _level in range(9):
		build.level_up()
	if not is_equal_approx(float(sim.call("max_health", 1)), base_health + 45.0):
		return _fail("Each character level must add 5 maximum health")

	build.selected_milestones = {10: &"eloa_malha_estavel", 30: &"geral_casco_de_campo", 80: &"geral_estilhaco_coletivo"}
	sim.call("_refresh_milestones", 1)
	var state := sim.call("player", 1) as Dictionary
	var passive := state["passive"] as RefCounted
	if int((passive.get("params") as Dictionary)["max_residues"]) != 4:
		return _fail("Level 10 choice must reconfigure the passive")
	if not is_equal_approx(float(sim.call("max_health", 1)), base_health + 45.0 + 25.0):
		return _fail("Modifiers must add maximum health")
	sim.call("enter_tower", 1)
	var enemies := sim.get("enemies") as Array
	enemies.clear()
	var definition := {"id": "alvo", "name": "Alvo", "health": 10.0, "rank_id": "maduro", "allow_affixes": false}
	enemies.append(sim.call("create_enemy", definition, Vector2(600.0, 300.0), 1))
	enemies.append(sim.call("create_enemy", definition, Vector2(640.0, 300.0), 2))
	for enemy: Dictionary in enemies:
		enemy["health"] = 10.0
		enemy["max_health"] = 10.0
	sim.call("damage_enemy", 1, 0, 100.0)
	if not (sim.get("enemies") as Array).is_empty():
		return _fail("Kill burst must damage enemies around the defeated one")

	var sena_sim: RefCounted = SimulationScript.new()
	sena_sim.call("setup", 78)
	sena_sim.call("add_player", 1, &"sena")
	(sena_sim.call("character_build", 1) as CharacterBuild).selected_milestones = {100: &"sena_correntes_unidas"}
	sena_sim.call("_refresh_milestones", 1)
	var currents := (sena_sim.call("player", 1) as Dictionary)["passive"] as RefCounted
	currents.call("on_skill_used", 0)
	currents.call("on_skill_used", 1)
	currents.call("on_skill_used", 2)
	if currents.call("currents") != Vector2i(2, 2):
		return _fail("Correntes Unidas must let improvisation feed both currents (got %s)" % currents.call("currents"))

	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json")) as Dictionary
	var checked := 0
	for character: Dictionary in catalog["playable_characters"]:
		for level_text: String in character["milestones"]:
			for choice: Dictionary in character["milestones"][level_text]:
				if not _exercise(StringName(String(character["id"])), int(level_text), StringName(String(choice["id"]))):
					return _fail("Choice failed in combat: %s" % choice["id"])
				checked += 1
	if checked != 240:
		return _fail("Expected 240 choices, found %d" % checked)
	print("MILESTONE_EFFECTS_OK: health per level, modifiers, passive parameters, mechanics and %d choices in combat" % checked)
	quit(0)


func _exercise(character_id: StringName, level: int, choice_id: StringName) -> bool:
	var sim: RefCounted = SimulationScript.new()
	sim.call("setup", level)
	sim.call("add_player", 1, character_id)
	sim.call("add_player", 2)
	(sim.call("character_build", 1) as CharacterBuild).selected_milestones = {level: choice_id}
	sim.call("_refresh_milestones", 1)
	for peer_id in [1, 2]:
		sim.call("enter_tower", peer_id)
	var state := sim.call("player", 1) as Dictionary
	var ally := sim.call("player", 2) as Dictionary
	ally["position"] = (state["position"] as Vector2) + Vector2(30.0, 0.0)
	var target := ((sim.get("enemies") as Array)[0] as Dictionary)["position"] as Vector2
	state["position"] = target + Vector2(-90.0, 0.0)
	for frame in range(40):
		if frame % 6 == 0:
			sim.call("use_skill", 1, (frame / 6) % 4, target)
		if frame == 20:
			state["invulnerable"] = 0.0
			sim.call("take_damage", 1, 70.0)
		sim.call("step", 1.0 / 20.0)
	return (sim.get("players") as Dictionary).has(1)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
