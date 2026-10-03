extends SceneTree

## Captura bairros da vila com moradores em art/shots/village/ (dia e noite). Precisa de janela.
## Uso: godot --path . --script tools/art/village_shots.gd

const OUTPUT_DIR := "res://art/shots/village/"
const SPOTS := {"praca": Vector2(1960.0, 880.0), "conselho": Vector2(2300.0, 520.0), "forja_obra": Vector2(1450.0, 1100.0), "campos": Vector2(420.0, 1380.0), "centro": Vector2(900.0, 600.0)}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var instance := (load("res://src/prototype/village/village_exploration.tscn") as PackedScene).instantiate()
	root.add_child(instance)
	await process_frame
	instance.call("_show_character_panel", false)
	var sim: RefCounted = instance.get("_sim")
	for _frame in range(600):
		await physics_frame
	for period in [0, 3]:
		(sim.get("village_life") as RefCounted).set("period_index", period)
		for spot_name: String in SPOTS:
			var spot := SPOTS[spot_name] as Vector2
			var state := sim.call("player", 1) as Dictionary
			state["position"] = spot
			state["target"] = spot
			var camera := instance.get_node("PlayerCamera") as Camera2D
			for _frame in range(30):
				await physics_frame
			camera.position = spot
			camera.reset_smoothing()
			await process_frame
			await RenderingServer.frame_post_draw
			var name := "%s_%s" % [spot_name, "noite" if period == 3 else "dia"]
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_DIR + name + ".png"))
			print("shot %s" % name)
	quit(0)
