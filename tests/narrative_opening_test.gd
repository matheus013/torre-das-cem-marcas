extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Menu := preload("res://src/prototype/village/narrative_menu.gd")
const ServiceMenu := preload("res://src/prototype/village/service_menu.gd")
const Services := preload("res://src/gameplay/world/village_services.gd")
const Village := preload("res://src/prototype/village/village_exploration.gd")

class Presentation:
	extends "res://src/prototype/village/village_exploration.gd"
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

func _init() -> void:
	_run.call_deferred()

func _place(sim: RefCounted, npc_id: String, peer: int = 1) -> void:
	sim.player(peer)["zone"] = &"village"
	sim.player(peer)["position"] = sim.village_life.call("find", npc_id)["position"]
	sim.player(peer)["target"] = sim.player(peer)["position"]

func _run() -> void:
	var sim := Simulation.new()
	sim.setup(181)
	sim.add_player(1)
	sim.add_player(2)
	var initial := sim.save_data(1).duplicate(true)
	var opening: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/narrative/village_opening.json"))
	for npc_id: String in opening["conversations"]:
		if sim.village_life.call("find", npc_id).is_empty():
			return _fail("Opening NPC reference invalid")
	for character: String in ["eloa", "sena", "cira", "rui"]:
		if not opening["reactions"].has(character) or String(opening["reactions"][character]).is_empty():
			return _fail("Protagonist reaction missing")
	for secret: String in ["lastro", "duas marchas", "andar 78", "segunda ascensao"]:
		if JSON.stringify(opening).to_lower().contains(secret):
			return _fail("Early dialogue leaked a later revelation")
	var model := sim.narrative_view()
	if model["target_npc"] != "alda_serrin" or model["opening_known"] or not model["journal"].is_empty():
		return _fail("Opening inferred without confirmation")
	# Viewing the authored conversation is not a gameplay confirmation.
	var view := Presentation.new()
	root.add_child(view)
	view._view = sim.view_snapshot()
	view._local_peer = 1
	var alda := view._conversation_model("alda_serrin")
	if sim.save_data(1) != initial or alda["action"] != "acknowledge_crisis" or alda["npc_name"] != "Alda Serrin":
		return _fail("Reading advanced flags or delivered wrong conversation")
	if not String(view._conversation_model("nara_quiral")["objective"]).contains("Nara"):
		return _fail("Direct-to-Nara conversation still sends player to Alda")
	if sim.narrative_action(1, "acknowledge_crisis") or sim.narrative_action(123, "acknowledge_crisis"):
		return _fail("Remote opening confirmation accepted")
	_place(sim, "alda_serrin")
	sim.player(1)["downed"] = true
	if sim.narrative_action(1, "acknowledge_crisis"):
		return _fail("Incapacitated confirmation accepted")
	sim.player(1)["downed"] = false
	sim.player(1)["connected"] = false
	if sim.narrative_action(1, "acknowledge_crisis"):
		return _fail("Disconnected confirmation accepted")
	sim.player(1)["connected"] = true
	sim.player(1)["zone"] = &"tower"
	if sim.narrative_action(1, "acknowledge_crisis"):
		return _fail("Wrong zone accepted")
	_place(sim, "alda_serrin")
	if not sim.narrative_action(1, "acknowledge_crisis") or sim.narrative_action(1, "acknowledge_crisis"):
		return _fail("Opening confirmation duplicated or failed")
	model = sim.narrative_view()
	if not model["opening_known"] or model["target_npc"] != "nara_quiral" or model["journal"].size() != 1 or not sim.banked_loot.is_empty():
		return _fail("Opening rewarded or lost direction")
	if model["conversations"]["alda_serrin"].has("action"):
		return _fail("Opening summary offers duplicate confirmation")
	var save: Dictionary = JSON.parse_string(JSON.stringify(sim.save_data(1)))
	var loaded := Simulation.new()
	loaded.setup(9)
	loaded.add_player(1)
	if not loaded.load_data(save, 1) or not loaded.narrative.opening_known:
		return _fail("Opening lost after reload")
	var invalid := save.duplicate(true)
	invalid["narrative"]["opening_known"] = "true"
	if loaded.load_data(invalid, 1) or not loaded.narrative.opening_known:
		return _fail("Invalid flag accepted or mutated world")
	invalid["narrative"].erase("opening_known")
	if Simulation.validate_save(invalid) == OK:
		return _fail("Current opening flag silently discarded")
	invalid["version"] = 10
	if not loaded.load_data(invalid, 1) or loaded.narrative.opening_known or loaded.narrative.stage != "available":
		return _fail("N1 migration inferred opening or reset contract")
	# Direct-to-Nara and free exploration remain legal for every protagonist.
	for character: StringName in [&"eloa", &"sena", &"cira", &"rui"]:
		var direct := Simulation.new()
		direct.setup(9)
		direct.add_player(1, character)
		direct.deepest_floor = 14
		direct.tower_start_floor = 14
		_place(direct, "nara_quiral")
		if direct.narrative_action(1, "prepare_first_floor") or not direct.narrative_action(1, "accept") or direct.narrative.opening_known or direct.tower_start_floor != 14:
			return _fail("Alda became required or floor changed without consent")
		if not direct.narrative_action(1, "prepare_first_floor") or direct.tower_start_floor != 1 or direct.deepest_floor != 14:
			return _fail("First floor preparation lost unlocked floors")
		direct.enter_tower(1)
		if direct.current_floor != 1 or direct.narrative_action(1, "prepare_first_floor"):
			return _fail("Prepared destination or range validation failed")
	# Personal preparation is measured, not marked complete by reading a panel.
	_place(sim, "nara_quiral")
	sim.player(1)["health"] = 19.0
	sim.player(1)["wounds"] = 2
	sim.player(1)["quick_items"] = 0
	var weapon := (sim._gear(1)["equipment"] as EquipmentLoadout).get_equipped(EquipmentItemDefinition.Slot.WEAPON, 0)
	weapon.integrity = 0.25
	var prep := sim.expedition_preparation(1)
	if prep.size() != 4 or not prep[0].contains("19/") or not prep[0].contains("ferimentos 2") or not prep[1].contains("0/9") or not prep[2].contains("25%"):
		return _fail("Preparation does not reflect live player state")
	view._view = sim.view_snapshot()
	for character: String in ["eloa", "sena", "cira", "rui"]:
		view._view["players"][1]["character_id"] = character
		var nara := view._conversation_model("nara_quiral")
		if nara["reaction"] != opening["reactions"][character] or nara["preparation"] != prep:
			return _fail("Wrong personal reaction/preparation")
	if not view._conversation_model("sira_botanica").is_empty():
		return _fail("Unrelated service inherited Nara dialogue")
	var menu := Menu.new()
	root.add_child(menu)
	await process_frame
	menu.size = Vector2(640, 720)
	view._view = sim.view_snapshot()
	menu.open(view._conversation_model("alda_serrin"), true)
	await process_frame
	if menu._title.text != "Alda Serrin" or menu._reward.visible or menu._secondary.visible:
		return _fail("Alda UI leaks Nara reward or controls")
	var service := ServiceMenu.new()
	root.add_child(service)
	await process_frame
	for npc_id: String in ["dalia_ferral", "maura_salvedra", "cassio_rotavela"]:
		var context := view._conversation_model(npc_id)
		if context.has("action") or context.has("secondary_action") or String(context.get("rumor", "")).is_empty():
			return _fail("Service conversation missing rumor separation")
		service.open(sim.village_life.call("find", npc_id), view._local(), sim.village_life.economy.view(), context)
		if not service._context.visible or service._buttons.size() != Services.offers(npc_id).size():
			return _fail("Context removed service offers")
		menu.open(context, true)
		await process_frame
		if not menu._rumor.visible or not menu._rumor.text.begins_with("Rumor nao confirmado") or menu._action.visible or menu._reward.visible:
			return _fail("Rumor presented as confirmed fact or illegal transaction")
	menu.open(view._conversation_model(""), false)
	if menu._action.visible or menu._secondary.visible or not menu._preparation.visible:
		return _fail("Diary exposes transactions or omits preparation")
	# Text sections participate in focus navigation; long preparation scrolls into view.
	await process_frame
	menu._reward.grab_focus()
	await process_frame
	await process_frame
	var scroll := menu._preparation.get_parent().get_parent() as ScrollContainer
	if not menu._reward.has_focus() or not scroll.follow_focus or scroll.scroll_vertical <= 0:
		return _fail("Long preparation cannot be reached with keyboard/controller focus")
	if not sim.narrative_action(1, "accept"):
		return _fail("Accepted opening blocked contract")
	view._view = sim.view_snapshot()
	menu.open(view._conversation_model("nara_quiral"), true)
	await process_frame
	if not menu._secondary.visible or not menu._secondary.disabled or not menu._close.has_focus():
		return _fail("Already selected floor retained an unusable initial focus")
	sim.deepest_floor = 14
	sim.tower_start_floor = 14
	view._view = sim.view_snapshot()
	menu.open(view._conversation_model("nara_quiral"), true)
	await process_frame
	if menu._secondary.disabled or not menu._secondary.has_focus():
		return _fail("Explicit first-floor selection unavailable")
	sim.enter_tower(2)
	if not "\n".join(sim.expedition_preparation(1)).contains("entrar agora acompanha o grupo"):
		return _fail("Preparation hides the current party destination")
	menu.queue_free()
	service.queue_free()
	view.queue_free()
	await process_frame
	print("NARRATIVE_OPENING_OK: authored context, explicit flags, migrations, four reactions, optional preparation, service access and rumor separation")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
