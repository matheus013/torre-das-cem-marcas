extends SceneTree

const Bindings := preload("res://src/core/app/input_bindings.gd")
const Settings := preload("res://src/core/app/game_settings.gd")
const PATH := "user://aresta_bindings_test.cfg"


func _init() -> void:
	_run.call_deferred()


func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event


func _run() -> void:
	_clean()
	var defaults := Bindings.defaults()
	if not Bindings.valid(defaults) or not Bindings.conflict(defaults, "skill_1", KEY_E) == "skill_3" or not Bindings.conflict(defaults, "interact", KEY_Q).is_empty():
		return _fail("Context-aware conflict rules are incorrect")
	var invalid := defaults.duplicate()
	invalid["inventory"] = null
	if Bindings.valid(invalid) or Bindings.allowed(KEY_ESCAPE) or Bindings.allowed(KEY_F12):
		return _fail("Malformed or reserved bindings were accepted")
	var config := ConfigFile.new()
	config.set_value("controls", "inventory", KEY_Q)
	config.save(PATH)
	if Bindings.read(PATH) != defaults:
		return _fail("Corrupt conflicting settings did not recover defaults")
	_clean()
	Bindings.apply(defaults)
	var title := (load("res://src/game/title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title)
	var dialog := title.get_node("SettingsDialog") as ConfirmationDialog
	dialog.set("_settings_path", PATH)
	dialog.call("open")
	dialog.call("_begin_capture", "skill_1")
	dialog.call("_input", _key(KEY_I))
	if (dialog.get("_bindings") as Dictionary)["skill_1"] != KEY_Q or (dialog.get("_error") as Label).text.is_empty():
		return _fail("Capture did not reject an inventory conflict")
	dialog.call("_input", _key(KEY_ESCAPE))
	if not String(dialog.get("_capturing")).is_empty() or not dialog.visible:
		return _fail("Escape closed options instead of cancelling key capture")
	dialog.call("_begin_capture", "skill_1")
	dialog.push_input(_key(KEY_Z))
	await process_frame
	if (dialog.get("_bindings") as Dictionary)["skill_1"] != KEY_Z:
		return _fail("Window input routing did not deliver a captured key")
	dialog.call("_begin_capture", "inventory")
	dialog.call("_input", _key(KEY_B))
	dialog.call("_begin_capture", "move_right")
	dialog.call("_input", _key(KEY_D))
	if Bindings.label("skill_1") != "Q":
		return _fail("Pending controls affected gameplay before Apply")
	dialog.call("_apply")
	if Bindings.label("skill_1") != "Z" or Bindings.read(PATH)["inventory"] != KEY_B or not Bindings.pressed(_key(KEY_B), "inventory") or Bindings.pressed(_key(KEY_I), "inventory"):
		return _fail("Apply did not persist and replace keyboard actions")
	title.queue_free()
	await process_frame
	var village := (load("res://src/prototype/village/village_exploration.tscn") as PackedScene).instantiate()
	root.add_child(village)
	(village.get("_character_panel") as Control).hide()
	village.call("_unhandled_input", _key(KEY_B))
	if not (village.get("_player_menu") as Control).visible:
		return _fail("Remapped inventory key did not open the live menu")
	village.call("_unhandled_input", _key(KEY_B))
	if (village.get("_player_menu") as Control).visible:
		return _fail("Remapped inventory key did not close the live menu")
	Input.action_press("aresta_move_right")
	village.call("_gather_keyboard")
	Input.action_release("aresta_move_right")
	var sim: RefCounted = village.get("_sim")
	var player: Dictionary = sim.call("player", 1)
	if not Bindings.pressed(_key(KEY_D), "move_right") or (player["target"] as Vector2).x <= (player["position"] as Vector2).x:
		return _fail("Remapped movement did not update the live move target")
	if int(village.call("_skill_slot_for_event", _key(KEY_Z))) != 0 or int(village.call("_skill_slot_for_event", _key(KEY_Q))) != -1:
		return _fail("Live skill dispatcher ignored remapping")
	village.queue_free()
	await process_frame
	Bindings.apply(defaults)
	Settings.apply(Settings.DEFAULTS)
	_clean()
	print("INPUT_BINDINGS_OK: conflicts, capture, persistence and live menu/skill dispatch")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	_clean()
	push_error(message)
	quit(1)


func _clean() -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(PATH + suffix)
