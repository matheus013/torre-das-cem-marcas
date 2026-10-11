extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Menu := preload("res://src/prototype/village/player_menu.gd")
const Shop := preload("res://src/prototype/village/shop_menu.gd")
const Services := preload("res://src/prototype/village/service_menu.gd")
const Narrative := preload("res://src/prototype/village/narrative_menu.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var sim := Simulation.new()
	sim.setup(7312)
	sim.add_player(1, &"eloa")
	sim.unlock_all_gems(1, true)
	sim._add_equipment_instance(&"eloa", "protecao_de_trabalho", "regular", 20)
	sim._add_equipment_instance(&"eloa", "unica_saraivada_de_flechas", "regular", 20)
	var model := sim.menu_model(1)
	for index in range(30):
		model["carried_loot"]["loot_%d" % index] = 99
	var skill: Dictionary = model["skills"][0]
	skill["supports"] = [{"id": "a", "name": "Suporte com nome muito longo para testar largura", "drain": 1}, {"id": "b", "name": "Outro modificador de mecanica de combate", "drain": 1}]
	skill["pending_choices"] = [{"id": "a", "name": "Modificador um", "preview": "Descricao extensa que deve ocupar varias linhas sem perder o conteudo."}, {"id": "b", "name": "Modificador dois"}, {"id": "c", "name": "Modificador tres"}]
	var menu := Menu.new()
	root.add_child(menu)
	menu._show_details = true
	var shop := Shop.new()
	root.add_child(shop)
	var services := Services.new()
	root.add_child(services)
	var narrative := Narrative.new()
	root.add_child(narrative)
	for dimensions: Vector2i in [Vector2i(480, 600), Vector2i(640, 720), Vector2i(853, 720), Vector2i(900, 720), Vector2i(960, 720), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = dimensions
		await _settle()
		for tab: String in ["inventory", "character", "skills", "tower", "bestiary"]:
			menu.refresh(model)
			menu.open(tab)
			await _settle()
			if not _check(menu, "%s at %s" % [tab, dimensions]):
				quit(1)
				return
		menu.close()
		shop.open(sim.shop_model(1))
		services.open(sim.village_life.call("find", "dalia_ferral"), sim.player(1), {"stock": {}}, {"dialogue": "Uma conversa longa na forja da vila para verificar a quebra de linhas."})
		narrative.open({"npc_name": "Nara Quiral", "action": "talk", "action_label": "Uma acao longa que precisa caber na janela sem rolagem horizontal"}, true)
		await _settle()
		for panel: Control in [shop, services, narrative]:
			if not _check(panel, "%s at %s" % [panel.get_script().resource_path, dimensions]):
				quit(1)
				return
		shop.close()
		services.close()
		narrative.close()
	print("UI_NO_HORIZONTAL_SCROLL_OK: five tabs, detailed stats, 30 loot types, supports, mastery choices, shop, services and journal at seven widths")
	quit(0)

func _settle() -> void:
	for frame in range(8):
		await process_frame

func _check(node: Node, context: String) -> bool:
	if node is PanelContainer and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		if rect.position.x < -1 or rect.end.x > root.size.x + 1:
			push_error("Panel exceeds viewport: " + context + " " + str(rect))
			return false
		if node.get_parent() is Control and node.get_parent().get_parent() == root and (rect.position.y < -1 or rect.end.y > root.size.y + 1):
			push_error("Panel exceeds viewport height: " + context + " " + str(rect))
			return false
	if node is ScrollContainer:
		if node.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED or node.get_h_scroll_bar().visible:
			push_error("Horizontal scrolling enabled: " + context)
			return false
		for child in node.get_children():
			if child is Control and not child is ScrollBar:
				if child.size.x > node.size.x + 1 or child.get_combined_minimum_size().x > node.size.x + 1:
					push_error("Content exceeds scroll width: %s (%s > %s)" % [context, child.get_combined_minimum_size(), node.size])
					return false
	for child in node.get_children():
		if not _check(child, context):
			return false
	return true
