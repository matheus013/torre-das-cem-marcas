extends SceneTree

## Capturas do README (docs/images), tiradas do jogo real em 1280x720 com GPU. Reproduzível:
##   godot --path . --script tools/art/readme_shots.gd
## Nunca toca no save do jogador (SaveSlot aponta para um arquivo descartável).

class Preview:
	extends "res://src/prototype/village/village_exploration.gd"
	func _run_test_hooks(_delta: float) -> void:
		pass

const LayoutScript := preload("res://src/gameplay/world/world_layout.gd")
const OUTPUT := "res://docs/images"
const SIZE := Vector2i(1280, 720)

var preview: Preview


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveSlot.path = "user://readme_shots_unused.json"
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = SIZE
	preview = Preview.new()
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	preview.set_physics_process(false)
	preview._character_panel.hide()
	preview._camera.position_smoothing_enabled = false
	var sim: WorldSimulation = preview._sim
	# Imagens reproduzíveis e sem dados do jogador: sem os recordes lidos do disco.
	sim.records = {}
	sim.narrative.stage = "completed"
	sim.narrative.return_outcome = "retreat"
	sim.unlock_all_gems(1)
	sim.set_gem_slot(1, 0, "elo_residual")
	sim.set_gem_slot(1, 1, "bola_de_fogo")
	sim.set_gem_slot(1, 2, "esfera_de_gelo")
	sim.set_gem_slot(1, 3, "saraivada_de_flechas")
	for item_id in ["protecao_de_trabalho", "botas_de_rota_antiga", "anel_de_folego"]:
		sim.equip_item(1, sim._add_equipment_instance(&"eloa", item_id, "refined", 20))
	var build := sim.character_build(1)
	while build.level < 24:
		if build.has_pending_milestone():
			build.choose_milestone((build.milestone_choices[build.level] as Array)[0].id)
		build.level_up()
	sim._passive_cache.clear()

	# Vila de dia e à noite, na praça.
	for period in [["vila-praca", 1], ["vila-noite", 3]]:
		sim.village_life.period_index = int(period[1])
		sim.player(1)["zone"] = &"village"
		sim.player(1)["position"] = LayoutScript.WORLD_SPAWN + Vector2(260.0, -40.0)
		await _shot(sim, String(period[0]))

	# Andares comuns: a personagem perto de uma matilha, depois de alguns instantes de luta.
	for floor_shot in [["andar-ermo", 45], ["andar-bosque", 10]]:
		sim.enter_tower(1)
		sim.start_floor(int(floor_shot[1]))
		# Junta duas matilhas perto da personagem para a imagem mostrar a luta.
		var pack := sim.enemies[0]["position"] as Vector2
		for index in range(mini(8, sim.enemies.size())):
			sim.enemies[index]["position"] = pack + Vector2.RIGHT.rotated(TAU * index / 8.0) * 110.0
			sim.enemies[index]["provoked"] = 10.0
		sim.player(1)["position"] = pack + Vector2(-60.0, 20.0)
		sim.player(1)["target"] = sim.player(1)["position"]
		await _fight(sim, 2.0, pack)
		await _shot(sim, String(floor_shot[0]))
		sim.leave_tower(1)

	# Chefe: Pastor das Correntes com os avisos no chão.
	sim.enter_tower(1)
	sim.start_floor(16)
	sim.player(1)["position"] = (sim.floor_layout.get("arena_center", sim.player(1)["position"]) as Vector2) + Vector2(-120.0, 60.0)
	sim.player(1)["target"] = sim.player(1)["position"]
	await _fight(sim, 4.0, sim.enemies[0]["position"] as Vector2)
	await _shot(sim, "chefe-pastor")
	sim.leave_tower(1)

	# Menus: gemas, bestiário (com abates registrados) e dificuldade.
	sim.player(1)["zone"] = &"village"
	sim.player(1)["position"] = LayoutScript.WORLD_SPAWN
	await _menu(sim, "skills", "menu-skills")
	for definition in sim.content("enemies").slice(0, 14):
		sim._bestiary_entry(1, String(definition["id"]))["kills"] = 70
		sim._bestiary_entry(1, String(definition["id"]))["min_health"] = 300.0
		sim._bestiary_entry(1, String(definition["id"]))["max_health"] = 900.0
	await _menu(sim, "bestiary", "bestiario")
	sim.unlocked_difficulty = 3
	await _menu(sim, "tower", "dificuldades")

	# Forja da Dália: vitrine e receitas com materiais no armazém.
	sim.deepest_floor = 30
	sim._gear(1)["silver"] = 2400
	for recipe in sim.forge_recipes().slice(0, 4):
		for material: String in recipe["materials"]:
			sim.banked_loot[material] = 12
	var npc := sim.village_life.call("find", "dalia_ferral") as Dictionary
	sim.player(1)["position"] = (npc["position"] as Vector2) + Vector2(24.0, 0.0)
	_refresh(sim)
	preview._shop_menu.call("open", sim.shop_model(1))
	await _capture("forja")
	preview._shop_menu.call("close")
	print("README_SHOTS_OK: 9 images in docs/images at %dx%d" % [SIZE.x, SIZE.y])
	quit(0)


## Alguns instantes de simulação com a personagem invulnerável, mirando a matilha.
func _fight(sim: WorldSimulation, seconds: float, toward: Vector2) -> void:
	var state := sim.player(1)
	for frame in range(int(seconds * 30.0)):
		state["invulnerable"] = 1.0
		state["health"] = sim.max_health(1)
		state["breath"] = sim.max_breath(1)
		if frame % 20 == 0:
			for slot in range(3):
				(state["cooldowns"] as Array)[slot] = 0.0
				(state["charges"] as Array)[slot] = 1
				sim.use_skill(1, slot, toward)
		sim.step(1.0 / 30.0)
		preview._apply_events(sim.drain_events())


func _menu(sim: WorldSimulation, tab: String, id: String) -> void:
	_refresh(sim)
	preview._player_menu.refresh(sim.menu_model(1))
	preview._player_menu.open(tab)
	await _capture(id)
	preview._player_menu.close()


func _shot(sim: WorldSimulation, id: String) -> void:
	_refresh(sim)
	await _capture(id)


func _refresh(sim: WorldSimulation) -> void:
	preview._status = ""
	preview._view = sim.view_snapshot()
	preview._update_display(0)
	preview._sync_floor()
	preview._camera.position = sim.player(1)["position"]
	preview._update_camera_limits()
	preview._layout_interface()
	preview._update_interface()
	preview.queue_redraw()


func _capture(id: String) -> void:
	for frame in range(10):
		await process_frame
	RenderingServer.force_draw()
	var image := root.get_texture().get_image()
	assert(not image.is_empty() and image.get_size() == SIZE)
	assert(image.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT, id])) == OK)
