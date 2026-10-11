extends SceneTree

class Preview:
	extends "res://src/prototype/village/village_exploration.gd"
	func _run_test_hooks(_delta: float) -> void:
		pass

var preview: Preview
var output := "res://art/shots/visual-gameplay"

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveSlot.path = "user://visual_gameplay_preview_unused.json"
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	preview = Preview.new()
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	preview.set_physics_process(false)
	preview._character_panel.hide()
	preview._camera.position_smoothing_enabled = false
	var sim: WorldSimulation = preview._sim
	sim.narrative.stage = "completed"
	sim.narrative.return_outcome = "retreat"
	var armor_id := sim._add_equipment_instance(&"eloa", "protecao_de_trabalho", "regular", 20)
	var weapon_id := sim._add_equipment_instance(&"eloa", "bastao_modular_de_campo", "regular", 20)
	assert(sim.attach_support(1, 4, "projeteis_gemeos"))
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(640, 720)]:
		root.size = dimensions
		for number in ([17, 18, 19, 20] if "--manto" in OS.get_cmdline_user_args() else [8, 9, 10]):
			sim.start_floor(number)
			sim.player(1)["zone"] = &"tower"
			sim.player(1)["position"] = sim.floor_layout["arena_center"] if sim.floor_layout.has("arena_center") else sim.floor_layout["route"][1]
			_refresh(sim)
			await _capture("%s-%d-%dx%d" % ["manto" if "--manto" in OS.get_cmdline_user_args() else "bosque", number, dimensions.x, dimensions.y])
		sim.player(1)["zone"] = &"village"
		_refresh(sim)
		for id: StringName in [armor_id, weapon_id]:
			preview._player_menu.refresh(sim.menu_model(1))
			preview._player_menu.open("inventory")
			for frame in range(8):
				await process_frame
			var cell := preview._player_menu.find_child("Item_%s" % id, true, false) as Control
			cell.grab_focus()
			await _capture("comparison-%s-%dx%d" % ["armor" if id == armor_id else "weapon", dimensions.x, dimensions.y])
			preview._player_menu.close()
	print("VISUAL_GAMEPLAY_SHOTS_OK: biome variants and equipment comparison at three widths")
	quit(0)

func _refresh(sim: WorldSimulation) -> void:
	preview._view = sim.view_snapshot()
	preview._update_display(0)
	preview._sync_floor()
	preview._camera.position = sim.player(1)["position"]
	preview._update_camera_limits()
	preview._layout_interface()
	preview._update_interface()
	preview.queue_redraw()

func _capture(id: String) -> void:
	for frame in range(8):
		await process_frame
	RenderingServer.force_draw()
	var image := root.get_texture().get_image()
	assert(not image.is_empty() and image.get_size() == root.size)
	assert(image.save_png(ProjectSettings.globalize_path("%s/%s.png" % [output, id])) == OK)
