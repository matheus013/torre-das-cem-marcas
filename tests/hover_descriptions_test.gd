extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Menu := preload("res://src/prototype/village/player_menu.gd")
const Hud := preload("res://src/prototype/village/combat_hud.gd")


func _init() -> void:
	_run.call_deferred()
	create_timer(15.0).timeout.connect(func() -> void: _fail("Hover test did not complete"))


func _motion(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	root.push_input(event, true)


func _run() -> void:
	var sim := Simulation.new()
	sim.setup(9141)
	sim.add_player(1, &"eloa")
	sim.unlock_all_gems(1, true)
	sim.player(1)["carried_loot"] = {"pedra_regenerativa":1}
	var model := sim.menu_model(1)
	for item: Dictionary in model["inventory_equipment"] as Array:
		if not String(item["tooltip"]).begins_with(String(item["name"])):
			return _fail("Inventory item has no description")
	for slot: Dictionary in model["equipment_slots"] as Array:
		if bool(slot["occupied"]) and String(slot["tooltip"]).is_empty():
			return _fail("Equipped item has no description")
	if not String(model["equipment_slots"][0]["tooltip"]).contains("Afinidade") or not String(model["item_tooltips"]["pedra_regenerativa"]).contains("vila"):
		return _fail("Weapon or material description is missing")
	for definition in sim.call("_collection", "items") as Array:
		if not definition.has("biome") and String(definition.get("description", ContentDescriptions.ITEM_TEXT.get(String(definition["id"]).replace("couraça", "couraca"), ""))).is_empty():
			return _fail("Catalog item is missing authored text: " + String(definition["id"]))
	for slot in range(4):
		var text := String((sim.view_snapshot()["players"][1]["skill_tooltips"] as Array)[slot])
		if not text.contains("Recarga") or not text.contains("Folego"):
			return _fail("Replicated skill description lacks runtime details")
	var menu := Menu.new()
	root.add_child(menu)
	await process_frame
	menu.refresh(model)
	menu.open("inventory")
	await process_frame
	var regions := menu.find_children("*", "Control", true, false).filter(func(node: Node) -> bool: return node is DescriptionHover)
	var region: DescriptionHover
	for node in regions:
		if node.get_parent() is Button and node.tooltip_text.begins_with(String(model["inventory_equipment"][0]["name"])):
			region = node
			break
	if region == null:
		return _fail("Inventory hover region is missing")
	var pressed := [0]
	menu.equip_requested.connect(func(_id: StringName) -> void: pressed[0] += 1)
	var position := region.get_global_rect().get_center()
	_motion(position)
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = position
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		root.push_input(click, true)
	if pressed[0] != 1:
		return _fail("Hover description blocked equipment click")
	if "--capture" in OS.get_cmdline_user_args():
		_motion(Vector2(10, 10))
		await process_frame
		_motion(position)
		await create_timer(1.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/aresta-item-hover.png")
	menu.queue_free()
	await process_frame
	var hud := Hud.new()
	root.add_child(hud)
	hud.size = Vector2(1280, 720)
	hud.set_skill_tooltips(sim.skill_tooltips(1))
	var icons: Array[Texture2D] = []
	for gem: Variant in sim.view_snapshot()["players"][1]["gem_ids"] as Array:
		icons.append(load("res://assets/sprites/icons/%s.png" % gem))
	hud.set_skill_icons(icons)
	await process_frame
	if hud._skill_hover[0].position != Vector2(480, 655) or not hud._skill_hover[0].tooltip_text.begins_with("Agulha de Lastro"):
		return _fail("HUD tooltip differs from drawn slot")
	hud.size = Vector2(1600, 900)
	if hud._skill_hover[0].position != Vector2(640, 835):
		return _fail("HUD hover region did not follow resize")
	hud.size = Vector2(1280, 720)
	if "--capture" in OS.get_cmdline_user_args():
		_motion(hud._skill_hover[0].get_global_rect().get_center())
		await create_timer(1.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/aresta-skill-hover.png")
	hud.queue_free()
	await process_frame
	print("HOVER_DESCRIPTIONS_OK: inventory, equipment, materials, replicated skills, click-through and resized HUD")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
