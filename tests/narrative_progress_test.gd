extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Progress := preload("res://src/gameplay/world/narrative_progress.gd")
const Menu := preload("res://src/prototype/village/narrative_menu.gd")
const Layout := preload("res://src/gameplay/world/floor_layout.gd")
const Store := preload("res://src/core/persistence/json_store.gd")

func _init() -> void:
	_run.call_deferred()

func _near_nara(sim: RefCounted, peer: int) -> void:
	var state: Dictionary = sim.player(peer)
	state["zone"] = &"village"
	state["position"] = sim.village_life.call("find", "nara_quiral")["position"]
	state["target"] = state["position"]

func _run() -> void:
	var sim := Simulation.new()
	sim.setup(91)
	sim.add_player(1)
	sim.add_player(2)
	var catalog := sim.narrative.catalog()
	if sim.village_life.call("find", catalog["npc_id"]).is_empty() or catalog["floor"] != 1 or not FileAccess.file_exists("res://assets/sprites/props/rocks.png"):
		return _fail("Catalog references missing")
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json"))
	var item_exists := false
	for item: Dictionary in content["items"]:
		item_exists = item_exists or item["id"] == catalog["reward"]["item_id"]
	if not item_exists or catalog["reward"]["quantity"] != 1:
		return _fail("Reward reference invalid")
	if sim.narrative_action(123, "accept") or sim.narrative_action(1, "accept") or sim.narrative_action(1, "report"):
		return _fail("Invalid actor, proximity or stage accepted")
	_near_nara(sim, 1)
	sim.player(1)["downed"] = true
	if sim.narrative_action(1, "accept"):
		return _fail("Downed actor accepted")
	sim.player(1)["downed"] = false
	sim.player(1)["connected"] = false
	if sim.narrative_action(1, "accept"):
		return _fail("Disconnected actor accepted")
	sim.player(1)["connected"] = true
	if not sim.narrative_action(1, "accept") or sim.narrative_action(1, "accept") or sim.narrative_action(1, "forged"):
		return _fail("Acceptance not idempotent")
	if not sim.narrative.view()["journal"].is_empty():
		return _fail("Undiscovered evidence leaked")
	sim.enter_tower(2)
	if sim.narrative_action(2, "inspect") or sim.narrative.stage != "active":
		return _fail("Entry or distant interaction advanced objective")
	var marker := sim.narrative_marker()
	if not Layout.can_stand(Layout.generate(1), marker, Simulation.PLAYER_RADIUS):
		return _fail("Evidence inaccessible")
	sim.player(2)["position"] = marker
	sim.current_floor = 2
	if sim.narrative_action(2, "inspect"):
		return _fail("Wrong floor accepted")
	sim.current_floor = 1
	if not sim.narrative_action(2, "inspect") or sim.narrative_action(2, "inspect"):
		return _fail("Evidence confirmation failed or duplicated")
	_near_nara(sim, 1)
	if sim.narrative_action(1, "report"):
		return _fail("Report accepted before a real field return")
	var field_save := sim.save_data(2).duplicate(true)
	# JSON roundtrip exercises the on-disk number and dictionary representation.
	field_save = JSON.parse_string(JSON.stringify(field_save)) as Dictionary
	var restored := Simulation.new()
	restored.setup(9)
	restored.add_player(1)
	if not restored.load_data(field_save, 1) or restored.narrative.stage != "evidence_found":
		return _fail("Field save lost observation")
	restored._handle_defeat(1)
	_near_nara(restored, 1)
	if restored.narrative.return_outcome != "defeat" or not restored.narrative_action(1, "report") or int(restored.banked_loot.get("musgo_de_orientacao", 0)) != 1:
		return _fail("Defeat lost evidence/reward")
	sim.leave_tower(2)
	if sim.narrative.stage != "report_ready" or sim.narrative.return_outcome != "retreat":
		return _fail("Field return not recorded")
	_near_nara(sim, 1)
	if not sim.narrative_action(1, "report") or sim.narrative_action(1, "report"):
		return _fail("Shared report not idempotent")
	sim.add_player(3)
	_near_nara(sim, 3)
	if sim.narrative_action(3, "report") or sim.view_snapshot()["narrative"]["stage"] != "completed":
		return _fail("Late join duplicated reward or lost world state")
	var completed_save: Dictionary = JSON.parse_string(JSON.stringify(sim.save_data(1)))
	if not restored.load_data(completed_save, 1) or restored.narrative_action(1, "report") or int(restored.banked_loot.get("musgo_de_orientacao", 0)) != 1:
		return _fail("Reload repeated reward")
	var invalid := completed_save.duplicate(true)
	invalid["narrative"]["return_outcome"] = ""
	if restored.load_data(invalid, 1) or restored.narrative.stage != "completed":
		return _fail("Inconsistent save accepted or mutated world")
	var missing := completed_save.duplicate(true)
	missing.erase("narrative")
	if Simulation.validate_save(missing) == OK:
		return _fail("Current save without narrative silently reset contract")
	missing["narrative"] = {}
	if Simulation.validate_save(missing) == OK:
		return _fail("Empty current narrative silently reset contract")
	var backup_path := "user://aresta_narrative_test.json"
	for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(backup_path + suffix)
	if Store.write(backup_path, completed_save, Simulation.validate_save) != OK or Store.write(backup_path, completed_save, Simulation.validate_save) != OK:
		return _fail("Narrative atomic save failed")
	var corrupt := FileAccess.open(backup_path, FileAccess.WRITE)
	corrupt.store_string(JSON.stringify(missing))
	corrupt.close()
	var recovery := Store.read(backup_path, Simulation.validate_save)
	if not recovery["recovered"] or recovery["data"]["narrative"]["stage"] != "completed":
		return _fail("Corrupt narrative did not recover completed state from backup")
	for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(backup_path + suffix)
	for raw: Variant in [null, [], {"quest_id": "wrong", "stage": "completed", "return_outcome": "retreat"}, {"quest_id": catalog["id"], "stage": "active", "return_outcome": "defeat"}]:
		if Progress.valid(raw):
			return _fail("Malformed narrative accepted")
	var legacy := completed_save.duplicate(true)
	legacy.erase("narrative")
	legacy["version"] = 9
	legacy["deepest_floor"] = 14
	if not restored.load_data(legacy, 1) or restored.narrative.stage != "available" or restored.deepest_floor != 14 or restored.character_gems != sim.character_gems:
		return _fail("Legacy migration lost progression or inferred evidence")
	var migrated := restored.save_data(1)
	for key: String in ["character_gear", "character_progress"]:
		if (JSON.parse_string(JSON.stringify(migrated[key])) as Dictionary) != legacy[key]:
			return _fail("Legacy migration changed " + key)
	var menu := Menu.new()
	root.add_child(menu)
	await process_frame
	menu.size = Vector2(640, 720)
	menu.open(sim.narrative.view(), false)
	await process_frame
	if not menu.visible or menu._action.visible or not menu._close.has_focus() or menu._panel.size.x > menu.size.x:
		return _fail("Journal focus, size or action safety failed")
	menu.open(restored.narrative.view(), true)
	await process_frame
	if not menu._action.visible or not menu._action.has_focus():
		return _fail("Narrative controller focus missing")
	menu.refresh(restored.narrative.view(), false)
	if not menu.visible or not menu._action.disabled or not menu._close.has_focus():
		return _fail("Roaming NPC interrupted reading or allowed remote action")
	menu.close()
	menu.queue_free()
	await process_frame
	print("NARRATIVE_PROGRESS_OK: shared contract, proximity, evidence, retreat/defeat, reward once, JSON saves, legacy migration and focused journal")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
