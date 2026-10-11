extends SceneTree

class Preview:
	extends "res://src/prototype/village/village_exploration.gd"
	func _run_test_hooks(_delta: float) -> void:
		pass

func _init() -> void:
	_run.call_deferred()

func _capture(file_name: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	var screenshot := root.get_texture().get_image()
	if screenshot.is_empty():
		push_error("Empty UI capture")
		quit(1)
		return
	screenshot.save_png(ProjectSettings.globalize_path("res://art/shots/ui/" + file_name + ".png"))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/shots/ui"))
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var preview := Preview.new()
	preview.name = "VillageExploration"
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	preview.set_physics_process(false)
	preview._camera.position_smoothing_enabled = false
	preview._character_panel.hide()
	var sim: WorldSimulation = preview._sim
	sim.unlock_all_gems(1, true)
	sim.set_gem_slot(1, 1, "saraivada_de_flechas")
	sim.set_gem_slot(1, 2, "muralha_refeita")
	sim.set_gem_slot(1, 3, "semeadura_vital")
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(640, 720)]:
		sim.player(1)["zone"] = &"village"
		root.size = dimensions
		await process_frame
		preview._layout_interface()
		preview._view = sim.view_snapshot()
		preview._update_display(0)
		preview._sync_floor()
		preview._camera.position = preview._local()["position"]
		preview._update_camera_limits()
		preview._update_interface()
		preview.queue_redraw()
		for tab: String in ["inventory", "character", "skills", "tower", "bestiary"]:
			preview._player_menu.refresh(sim.menu_model(1))
			preview._player_menu.open(tab)
			await _capture("%s-%dx%d" % [tab, dimensions.x, dimensions.y])
			preview._player_menu.close()
		sim.enter_tower(1)
		preview._view = sim.view_snapshot()
		preview._update_display(0)
		preview._sync_floor()
		preview._camera.position = preview._local()["position"]
		preview._update_camera_limits()
		preview._update_interface()
		preview.queue_redraw()
		var hud := preview._combat_hud as PrototypeCombatHud
		hud.visible = true
		hud.health = 31
		hud.max_health = 118
		hud.breath = 28
		hud.skill_costs = [10, 8, 40, 10]
		hud.skill_charges = [1, 0, 1, 1]
		hud.cooldowns = [0.0, 3.2, 0.0, 0.0]
		hud.maximum_cooldowns = [1.5, 8.0, 5.0, 8.0]
		hud.quick_item_count = 3
		hud.empty_slots = [false, false, false, false]
		hud.skill_icons = [load("res://assets/sprites/icons/agulha_lastro.png"), load("res://assets/sprites/icons/saraivada_de_flechas.png"), load("res://assets/sprites/icons/muralha_refeita.png"), load("res://assets/sprites/icons/semeadura_vital.png")] as Array[Texture2D]
		hud.party = [{"character_name": "Sena Rotavela", "health": 75, "max_health": 100, "breath": 55, "max_breath": 100, "zone": "tower"}, {"character_name": "Rui Pedralva", "health": 40, "max_health": 130, "breath": 80, "max_breath": 100, "zone": "tower"}]
		hud.effects = [{"name": "Escudo", "icon": "muralha_refeita", "kind": "buff", "remaining": 6.2, "duration": 10.0}]
		hud.queue_redraw()
		preview._objective_label.position.y = 320
		await _capture("combat-%dx%d" % [dimensions.x, dimensions.y])
		preview._objective_label.position.y = 170
		hud.clear_context()
		hud.hide()
		preview._milestone_choice.refresh({"character_id": "eloa", "character_name": "Eloa Ferral", "level": 5, "milestone_choices": [{"id": "choice_a", "name": "Conducao Residual", "description": "A luz conecta os alvos marcados."}, {"id": "choice_b", "name": "Corrente de Forja", "description": "Converte a energia residual em protecao."}]}, [1])
		await _capture("milestone-%dx%d" % [dimensions.x, dimensions.y])
		preview._milestone_choice.refresh({}, [])
	print("UI_SHOTS_OK: 21 captures across desktop and narrow viewports")
	quit(0)
