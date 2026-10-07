extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Vfx := preload("res://src/presentation/vfx/vfx_layer.gd")

class Preview:
	extends "res://src/prototype/village/village_exploration.gd"

	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

	func _draw() -> void:
		for peer: int in _view.get("players", {}):
			_draw_player(_view["players"][peer], peer)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1000, 320)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	RenderingServer.set_default_clear_color(Color("343b42"))
	var preview := Preview.new()
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(preview)
	for panel in 4:
		var sim := Simulation.new()
		sim.setup(9090)
		sim.add_player(1, &"sena")
		sim.enter_tower(1)
		sim.player(1)["position"] = Vector2(panel * 250 + 125, 155)
		sim.call("_toggle_volley", 1, {"gem_id": "saraivada_de_flechas", "power": 0.0, "range": 105.0}, {})
		var vfx := Vfx.new()
		preview.add_child(vfx)
		vfx.set_process(false)
		for tick in range(1, 5 + panel * 6):
			sim.call("_update_persistent_effects", 1.0 / 60.0)
			vfx._process(1.0 / 60.0)
			for event: Dictionary in sim.drain_events():
				if event.get("call", "") == "travel":
					vfx.theme = String(event["theme"])
					vfx.callv("travel", event["args"])
		var player_view := sim.view_snapshot()["players"][1] as Dictionary
		preview._view.get_or_add("players", {})[panel + 1] = player_view
		var label := Label.new()
		label.text = "Giro: %.2f s" % float((player_view["volley_spin"] as Dictionary)["elapsed"])
		label.position = Vector2(panel * 250 + 45, 280)
		preview.add_child(label)
	preview.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://art/shots/skills/volley-spin.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	root.get_texture().get_image().save_png(output)
	print("VOLLEY_SHOTS_OK")
	quit(0)
