extends SceneTree

const OUTPUT := "res://art/shots/scenery/"
const World := preload("res://src/gameplay/world/world_layout.gd")

class Preview:
	extends "res://src/prototype/village/village_exploration.gd"
	func _run_test_hooks(_delta: float) -> void:
		pass

var _preview: Preview
var _sheet: Image
var _sheet_index := 0
var _count := 0

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	SaveSlot.path = "user://scenery_preview_unused.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	_preview = Preview.new()
	root.add_child(_preview)
	await process_frame
	_preview.set_process(false)
	_preview.set_physics_process(false)
	_preview._character_panel.hide()
	_preview._camera.position_smoothing_enabled = false
	_sheet = Image.create(1280, 960, false, Image.FORMAT_RGBA8)
	_sheet.fill(Color("1b2224"))
	var sim: WorldSimulation = _preview._sim
	sim.deepest_floor = 100
	var overview_biomes := {}
	for number in [1, 2, 3, 5, 6, 11, 21, 31, 41, 61, 71, 75, 91, 96]:
		if sim.player(1)["zone"] == &"tower":
			sim.leave_tower(1)
		sim.tower_start_floor = number
		sim.enter_tower(1)
		var biome := String(sim.floor_layout["biome"])
		await _capture("floor_%03d_entry" % number, sim.player(1)["position"], not overview_biomes.has(biome))
		overview_biomes[biome] = true
		var layout: Dictionary = sim.floor_layout
		var focus := (layout["route"] as Array)[1] as Vector2 if layout.has("route") else layout["arena_center"] as Vector2
		sim.player(1)["position"] = focus
		await _capture("floor_%03d_route" % number, focus)
	for number in [4, 16, 51, 100]:
		sim.leave_tower(1)
		sim.tower_start_floor = number
		sim.enter_tower(1)
		var focus: Vector2 = sim.floor_layout["arena_center"]
		sim.player(1)["position"] = focus
		await _capture("boss_%03d" % number, focus)
	sim.leave_tower(1)
	for item: Array in [["village_arrival", Vector2(650, 650)], ["village_square", Vector2(1650, 1350)], ["village_workshops", Vector2(1400, 2010)], ["village_production", Vector2(2830, 1930)]]:
		sim.player(1)["zone"] = &"village"
		sim.player(1)["position"] = item[1]
		await _capture(item[0], item[1], item[0] == "village_square")
	for zone: StringName in [&"house", &"boss_room"]:
		sim.player(1)["zone"] = zone
		sim.player(1)["position"] = Vector2(640, 460)
		await _capture(String(zone), Vector2(640, 360), zone == &"house")
	_sheet.save_png(ProjectSettings.globalize_path(OUTPUT + "overview.png"))
	root.size = Vector2i(640, 720)
	sim.player(1)["zone"] = &"village"
	sim.player(1)["position"] = Vector2(1650, 1350)
	await _capture("village_narrow", Vector2(1650, 1350))
	print("SCENERY_SHOTS_OK: %d captures, ten biome samples, four arenas, village districts and interiors" % _count)
	quit(0)

func _capture(id: String, focus: Vector2, overview := false) -> void:
	_preview._view = _preview._sim.view_snapshot()
	_preview._update_display(0)
	_preview._sync_floor()
	_preview._camera.position = focus
	_preview._update_camera_limits()
	_preview._layout_interface()
	_preview._update_interface()
	_preview._anim_time = 2.5
	_preview.queue_redraw()
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	var screenshot := root.get_texture().get_image()
	assert(not screenshot.is_empty())
	assert(screenshot.get_size() == root.size)
	assert(screenshot.save_png(ProjectSettings.globalize_path(OUTPUT + id + ".png")) == OK)
	if overview:
		var thumbnail := screenshot.duplicate() as Image
		thumbnail.resize(426, 240, Image.INTERPOLATE_NEAREST)
		_sheet.blit_rect(thumbnail, Rect2i(0, 0, 426, 240), Vector2i((_sheet_index % 3) * 426, (_sheet_index / 3) * 240))
		_sheet_index += 1
	_count += 1
