extends SceneTree

const Bindings := preload("res://src/core/app/input_bindings.gd")
const Settings := preload("res://src/core/app/game_settings.gd")
const PATH := "user://aresta_controller_test.cfg"


func _init() -> void:
	_run.call_deferred()


func _button(index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = true
	return event


func _run() -> void:
	_clean()
	Bindings.apply(Bindings.defaults())
	Settings.apply(Settings.DEFAULTS)
	if not Bindings.pressed(_button(JOY_BUTTON_LEFT_SHOULDER), "skill_1") or not Bindings.pressed(_button(JOY_BUTTON_LEFT_STICK), "auto_aim") or Bindings.pad_label("skill_1", true) != "L1":
		return _fail("Xbox/PlayStation normalized mappings are incomplete")
	var village := (load("res://src/prototype/village/village_exploration.tscn") as PackedScene).instantiate()
	root.add_child(village)
	await process_frame
	(village.get("_character_panel") as Control).hide()
	village.call("_input", _button(JOY_BUTTON_BACK))
	village.call("_unhandled_input", _button(JOY_BUTTON_BACK))
	if not (village.get("_player_menu") as Control).visible or root.gui_get_focus_owner() == null:
		return _fail("Gamepad inventory entry did not open with navigable focus")
	village.call("_unhandled_input", _button(JOY_BUTTON_B))
	if (village.get("_player_menu") as Control).visible:
		return _fail("Gamepad cancel did not close the inventory")
	Input.action_press("aresta_move_right")
	village.call("_gather_keyboard")
	Input.action_release("aresta_move_right")
	village.call("_gather_keyboard")
	var sim: RefCounted = village.get("_sim")
	var player: Dictionary = sim.call("player", 1)
	if player["target"] != player["position"]:
		return _fail("Releasing the movement stick did not stop the player")
	Input.action_press("aresta_aim_up")
	village.call("_gather_keyboard")
	Input.action_release("aresta_aim_up")
	if (village.get("_pad_aim") as Vector2) != Vector2.UP:
		return _fail("Right-stick input did not update the manual aiming direction")
	Settings.save(Settings.DEFAULTS, PATH, Bindings.defaults())
	var dialog := village.get_node("SettingsDialog") as ConfirmationDialog
	dialog.set("_settings_path", PATH)
	village.call("_unhandled_input", _button(JOY_BUTTON_START))
	if not paused or not dialog.visible:
		return _fail("Start/Options did not open solo pause")
	dialog.push_input(_button(JOY_BUTTON_LEFT_STICK))
	await process_frame
	if not Settings.auto_aim or not Settings.read(PATH)["auto_aim"]:
		return _fail("L3 did not toggle and persist auto aim while paused")
	dialog.push_input(_button(JOY_BUTTON_START))
	await process_frame
	if paused or dialog.visible:
		return _fail("Start/Options did not resume from the pause window")
	var trigger := InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 1.0
	if not Bindings.pressed(trigger, "quick_item") or not bool(village.call("_command_event", trigger)) or bool(village.call("_command_event", trigger)):
		return _fail("Trigger did not fire exactly once per press")
	trigger.axis_value = 0.0
	village.call("_command_event", trigger)
	trigger.axis_value = 1.0
	if not bool(village.call("_command_event", trigger)):
		return _fail("Trigger did not reset on release")
	var view: Dictionary = village.get("_view")
	var saved := view.duplicate(true)
	view["players"][1]["position"] = Vector2.ZERO
	view["players"][1]["zone"] = "tower"
	village.set("_display", {})
	view["enemies"] = [
		{"position": Vector2(1, 0), "zone": "tower", "health": 0.0},
		{"position": Vector2(2, 0), "zone": "house", "health": 100.0},
		{"position": Vector2(80, 0), "zone": "tower", "health": 100.0},
		{"position": Vector2(0, 20), "zone": "tower", "health": 100.0},
	]
	if (village.call("_skill_target") as Vector2) != Vector2(0, 20):
		return _fail("Auto aim did not select the nearest living enemy in the same zone")
	view["enemies"][2]["position"] = Vector2(5, 0)
	if (village.call("_skill_target") as Vector2) != Vector2(5, 0):
		return _fail("Auto aim kept a stale target after the nearest enemy changed")
	village.call("_toggle_auto_aim", PATH)
	village.set("_pad_aim", Vector2.LEFT)
	if Settings.auto_aim or (village.call("_skill_target") as Vector2) != Vector2(-300, 0):
		return _fail("Disabling auto aim did not restore manual stick direction")
	Settings.auto_aim = true
	view["enemies"] = []
	if (village.call("_skill_target") as Vector2) != Vector2(-300, 0):
		return _fail("Auto aim without enemies did not fall back to manual direction")
	village.set("_view", saved)
	village.call("_on_pad_connection_changed", 0, false)
	if Bindings.pad_device != -1:
		return _fail("Disconnect did not restore keyboard/mouse input")
	village.queue_free()
	await process_frame
	Settings.apply(Settings.DEFAULTS)
	_clean()
	print("CONTROLLER_AIM_OK: gamepad menus, pause, triggers, auto/manual aim and disconnect")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	_clean()
	push_error(message)
	quit(1)


func _clean() -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(PATH + suffix)
