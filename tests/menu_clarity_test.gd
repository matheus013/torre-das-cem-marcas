extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Menu := preload("res://src/prototype/village/player_menu.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var sim := Simulation.new()
	sim.setup(7312)
	sim.add_player(1, &"eloa")
	sim.character_build(1).base_stats[&"wisdom"] = 30
	if not sim.attach_support(1, 0, "aegis_por_acerto"):
		return _fail("Could not attach test support")
	sim.set_gem_slot(1, 2, "muralha_refeita")
	sim.set_gem_slot(1, 3, "semeadura_vital")
	var progress := ((sim.call("_gem_state", 1) as Dictionary)["gems"] as Dictionary)["passo_vetorial"] as Dictionary
	progress["level"] = 3
	progress["choices"] = {"3":"segunda_rota"}
	var model := sim.menu_model(1)
	if int(model["skills"][1]["charges"]) != 2 or float(model["skills"][2]["barrier"]) <= 0.0 or float(model["skills"][3]["healing"]) <= 0.0:
		return _fail("Extra charges, barrier or healing details are missing")
	var options := model["gem_options"] as Array
	for index in range(1, options.size()):
		if String(options[index - 1]["name"]).naturalnocasecmp_to(String(options[index]["name"])) > 0:
			return _fail("Active gems are not alphabetical")
	for skill: Dictionary in model["skills"] as Array:
		var resolved := sim.resolve_slot(1, int(skill["slot"]))
		var expected := float(resolved["cooldown"]) / float(sim.derived_stats(1)["cooldown_recovery_multiplier"])
		if not is_equal_approx(float(skill["cooldown"]), expected) or float(skill["breath_cost"]) != float(resolved.get("breath_cost", 0.0)) or int(skill["charges"]) != 1 + maxi(0, int(resolved.get("extra_charge", 0))):
			return _fail("Skill details differ from runtime")
	if String(model["weapon_attack"]["item_name"]) != "Filamentos de Forja":
		return _fail("Equipped weapon name is missing")
	var menu := Menu.new()
	root.add_child(menu)
	await process_frame
	menu.refresh(model)
	menu.open("skills")
	await process_frame
	var dropdowns: Array[Node] = menu.find_children("*", "OptionButton", true, false)
	var verified := false
	for node in dropdowns:
		var dropdown := node as OptionButton
		if dropdown.item_count == 0 or dropdown.get_item_text(0) != "+ adicionar suporte":
			continue
		for index in range(1, dropdown.item_count):
			var support := sim.support_definition(String(dropdown.get_item_metadata(index)))
			var should_disable := int(support["drain"]) > 1
			if dropdown.is_item_disabled(index) != should_disable:
				return _fail("Support capacity disabled state is wrong")
		verified = true
		break
	if not verified:
		return _fail("Support dropdown not found")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/aresta-menu-clarity-skills.png")
	menu._scroll.scroll_vertical = 400
	menu.call("_select_tab", "character")
	if menu._scroll.scroll_vertical != 0:
		return _fail("Changing tabs retained old scroll")
	await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		menu._scroll.scroll_vertical = 500
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/aresta-menu-clarity-character.png")
	menu.queue_free()
	await process_frame
	print("MENU_CLARITY_OK: alphabetical gems, runtime details, capacity hints, weapon names and scroll reset")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
