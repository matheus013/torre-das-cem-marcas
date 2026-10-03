extends SceneTree

## Captura a vila, o interior e a Torre em art/shots/. Precisa de janela (não use --headless).

const OUTPUT_DIR := "res://art/shots/"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var title := (load("res://src/game/title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title)
	for _frame in range(6):
		await process_frame
	await _capture("title_screen")
	title.queue_free()
	var scene := load("res://src/prototype/village/village_exploration.tscn") as PackedScene
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await _settle(instance, Vector2(900.0, 580.0))
	await _capture("character_select")
	instance.call("_show_character_panel", false)
	var sim: RefCounted = instance.get("_sim")
	await _capture("village_center")
	await _settle(instance, Vector2(1560.0, 520.0))
	await _capture("village_tower_gate")
	sim.call("enter_house", 1)
	await _settle(instance, Vector2(640.0, 520.0))
	await _capture("house_interior")
	sim.call("leave_house", 1)
	sim.call("attach_support", 1, 0, "projeteis_gemeos")
	instance.call("_open_player_menu", "skills")
	for _frame in range(4):
		await process_frame
	await _capture("skills_menu")
	(instance.get("_player_menu") as Control).call("close")
	sim.call("enter_tower", 1)
	await _settle(instance, Vector2(560.0, 380.0))
	await _capture("tower_combat")
	sim.call("use_skill", 1, 0, Vector2(500.0, 200.0))
	sim.call("use_skill", 1, 2, Vector2(560.0, 380.0))
	sim.call("use_skill", 1, 3, Vector2(640.0, 520.0))
	sim.call("execute_gem_effect", 1, {"mechanic": "chain", "chain_count": 3, "range": 700.0, "power": 1.0}, Vector2.ZERO)
	sim.call("execute_gem_effect", 1, {"mechanic": "barrier", "barrier": 30.0}, Vector2.ZERO)
	sim.call("execute_gem_effect", 1, {"mechanic": "sanctuary", "radius": 70.0, "duration": 5.0, "power": 0.0}, Vector2.ZERO)
	for _frame in range(4):
		await process_frame
	await _capture("tower_skills")
	sim.call("leave_tower", 1)
	sim.call("select_character", 1, &"rui")
	sim.call("enter_tower", 1)
	for index in range(8):
		sim.call("damage_enemies", 1, Vector2(560.0, 380.0), 900.0, 1.0)
	await _settle(instance, Vector2(700.0, 330.0))
	await _capture("tower_rui")
	await _capture("tower_drops")
	var build := sim.call("character_build", 1) as CharacterBuild
	for milestone in [10, 20, 30]:
		while build.level < milestone:
			sim.call("add_experience", 1, int(sim.call("experience_required", build.level)))
		var options := build.milestone_choices[milestone] as Array
		if milestone < 30:
			sim.call("choose_milestone", 1, (options[milestone / 10] as EvolutionChoice).id)
	instance.call("_open_player_menu", "character")
	for _frame in range(4):
		await process_frame
	await _capture("character_tree")
	(instance.get("_player_menu") as Control).call("close")
	var vfx: Node2D = instance.get("_vfx")
	vfx.call("number", Vector2(620.0, 330.0), 18.0, false)
	vfx.call("number", Vector2(760.0, 300.0), 42.0, true)
	vfx.call("number", Vector2(700.0, 380.0), 9.0, false, "player")
	vfx.call("label", Vector2(840.0, 360.0), "BLOQUEIO", Color("c9d4d6"))
	for _frame in range(5):
		await process_frame
	await _capture("damage_numbers")
	quit(0)


func _settle(instance: Node, position: Vector2) -> void:
	var state := (instance.get("_sim") as RefCounted).call("player", 1) as Dictionary
	state["position"] = position
	state["target"] = position
	var camera := instance.get_node("PlayerCamera") as Camera2D
	camera.position = position
	camera.reset_smoothing()
	for _frame in range(12):
		await process_frame


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR + name + ".png"))
	print("shot %s" % name)
