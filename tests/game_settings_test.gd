extends SceneTree

const SettingsScript := preload("res://src/core/app/game_settings.gd")
const TEST_PATH := "user://aresta_settings_test.cfg"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_clean()
	var clean := SettingsScript.sanitize({"fullscreen": "true", "resolution": 99, "fps": 19, "vsync": null, "master": -20.0, "music": INF, "effects": 250.0})
	if clean["fullscreen"] or not clean["vsync"] or clean["resolution"] != 3 or clean["fps"] != 60 or clean["master"] != 0.0 or clean["music"] != 100.0 or clean["effects"] != 100.0:
		return _fail("Invalid configuration values were not sanitized")
	var config := ConfigFile.new()
	config.set_value("app", "dev_mode", false)
	config.save(TEST_PATH)
	var chosen := {"fullscreen": true, "resolution": 2, "fps": 120, "vsync": false, "master": 0.0, "music": 35.0, "effects": 70.0, "auto_aim": false, "auto_attack": false}
	if SettingsScript.save(chosen, TEST_PATH) != OK or SettingsScript.read(TEST_PATH) != chosen:
		return _fail("Settings did not survive a disk round trip")
	config.load(TEST_PATH)
	if config.get_value("app", "dev_mode", true):
		return _fail("Game settings overwrote development preferences")
	SettingsScript.apply(chosen)
	if Engine.max_fps != 120 or not AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")) or not is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))), 0.35):
		return _fail("Runtime settings did not update FPS and audio buses")
	SettingsScript.apply(SettingsScript.DEFAULTS)
	if AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")):
		return _fail("Restoring volume did not unmute Master")
	_clean()

	var title := (load("res://src/game/title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await process_frame
	if title.get_node_or_null("Menu/Settings") == null:
		return _fail("Title screen is missing its settings entry")
	title.call("_open_settings")
	var dialog := title.get_node("SettingsDialog") as ConfirmationDialog
	if not dialog.visible or paused:
		return _fail("Title settings unexpectedly paused the tree")
	dialog.call("_custom_action", &"defaults")
	if (dialog.get("_fps") as OptionButton).get_selected_id() != 60:
		return _fail("Restore defaults did not update pending controls")
	dialog.set("_settings_path", TEST_PATH)
	(dialog.get("_fps") as OptionButton).select(SettingsScript.FPS_LIMITS.find(120))
	dialog.call("_apply")
	if dialog.visible or SettingsScript.read(TEST_PATH)["fps"] != 120:
		return _fail("Applying dialog controls did not persist or close")
	dialog.call("open")
	dialog.set("_settings_path", TEST_PATH + "/unwritable.cfg")
	(dialog.get("_fps") as OptionButton).select(SettingsScript.FPS_LIMITS.find(30))
	dialog.call("_apply")
	if not dialog.visible or Engine.max_fps != 120 or (dialog.get("_error") as Label).text.is_empty():
		return _fail("Failed save closed the dialog or changed runtime preferences")
	_clean()
	dialog.hide()
	title.queue_free()
	await process_frame

	var village := (load("res://src/prototype/village/village_exploration.tscn") as PackedScene).instantiate()
	root.add_child(village)
	await process_frame
	(village.get("_character_panel") as Control).hide()
	village.call("_open_settings")
	dialog = village.get_node("SettingsDialog") as ConfirmationDialog
	var animation := float(village.get("_anim_time"))
	await physics_frame
	await physics_frame
	if not paused or float(village.get("_anim_time")) != animation or not bool(village.call("_input_blocked")):
		return _fail("Solo simulation or input continued while settings were open")
	dialog.hide()
	if paused:
		return _fail("Closing solo settings did not resume the simulation")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	village.call("_unhandled_input", escape)
	if not dialog.visible or not paused:
		return _fail("Escape did not open solo pause options")
	dialog.hide()
	village.set("_mode", &"host")
	village.call("_open_settings")
	await physics_frame
	await physics_frame
	if paused or float(village.get("_anim_time")) <= animation:
		return _fail("Online settings paused the authoritative simulation")
	dialog.hide()
	village.set("_mode", &"solo")
	village.call("_open_settings")
	village.queue_free()
	await process_frame
	if paused:
		return _fail("Destroying an open settings dialog left the next scene paused")
	SettingsScript.apply(SettingsScript.DEFAULTS)
	print("GAME_SETTINGS_OK: validation, persistence, audio, title, solo pause and online continuity")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	_clean()
	push_error(message)
	quit(1)


func _clean() -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(TEST_PATH + suffix)
