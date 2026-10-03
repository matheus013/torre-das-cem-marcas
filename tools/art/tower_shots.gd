extends SceneTree

## Captura um andar comum de cada bioma e arenas de chefe com telegrafias em art/shots/tower/.
## Precisa de janela (não use --headless). Uso: godot --path . --script tools/art/tower_shots.gd

const OUTPUT_DIR := "res://art/shots/tower/"
const SAMPLES: Array[int] = [1, 9, 20, 30, 44, 55, 66, 75, 85, 96]
const BOSSES: Array[int] = [4, 16, 51, 100]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var instance := (load("res://src/prototype/village/village_exploration.tscn") as PackedScene).instantiate()
	root.add_child(instance)
	await process_frame
	instance.call("_show_character_panel", false)
	var sim: RefCounted = instance.get("_sim")
	sim.set("deepest_floor", 100)
	for number in SAMPLES + BOSSES:
		if (sim.call("player", 1) as Dictionary)["zone"] == &"tower":
			sim.call("leave_tower", 1)
		sim.set("tower_start_floor", number)
		sim.call("enter_tower", 1)
		var state := sim.call("player", 1) as Dictionary
		var enemies := sim.get("enemies") as Array
		var focus := state["position"] as Vector2
		if not enemies.is_empty():
			var pick := enemies[enemies.size() / 2] as Dictionary
			focus = (pick["position"] as Vector2) + Vector2(-150.0, 60.0)
		if number in BOSSES:
			focus = (sim.get("floor_layout") as Dictionary)["arena_center"] as Vector2 + Vector2(0.0, 160.0)
		state["position"] = focus
		state["target"] = focus
		var camera := instance.get_node("PlayerCamera") as Camera2D
		for frame in range(150 if number in BOSSES else 20):
			state["health"] = 1.0e6
			state["position"] = focus
			state["target"] = focus
			await physics_frame
			if number in BOSSES and frame > 40 and not (sim.get("telegraphs") as Array).is_empty() and frame % 7 == 0:
				break
		camera.position = focus
		camera.reset_smoothing()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var name := "%s_%03d" % ["boss" if number in BOSSES else "floor", number]
		image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR + name + ".png"))
		print("shot %s" % name)
	quit(0)
