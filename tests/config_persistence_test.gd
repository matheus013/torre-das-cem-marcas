extends SceneTree

const Store := preload("res://src/core/persistence/config_store.gd")
const Settings := preload("res://src/core/app/game_settings.gd")
const Bindings := preload("res://src/core/app/input_bindings.gd")
const Dev := preload("res://src/core/app/dev_mode.gd")
const Profile := preload("res://src/core/net/profile_identity.gd")
const Npc := preload("res://src/core/ai/npc_ai_config.gd")
const PATH := "user://aresta_config_persistence_test.cfg"
const PROFILE_PATH := "user://aresta_profile_persistence_test.cfg"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_clean()
	var legacy := ConfigFile.new()
	legacy.set_value("app", "dev_mode", false)
	legacy.set_value("extension", "untouched", ["keep", 42])
	legacy.save(PATH)
	var keys := Bindings.defaults()
	keys["auto_aim"] = KEY_J
	var values := Settings.DEFAULTS.duplicate()
	values["auto_aim"] = true
	values["music"] = 23.0
	if Settings.save(values, PATH, keys) != OK or Dev.set_enabled(true, PATH) != OK:
		return _fail("Shared config could not be updated")
	var config: ConfigFile = Store.read(PATH)["config"]
	if Settings.read(PATH) != values or Bindings.read(PATH) != keys or config.get_value("extension", "untouched") != ["keep", 42]:
		return _fail("Updating dev preference erased options, bindings or extension data")
	_raw(PATH, "[broken")
	var recovered := Store.read(PATH)
	if not recovered["recovered"] or Settings.read(PATH) != values or Bindings.read(PATH) != keys:
		return _fail("Shared settings did not recover consistently")
	var dialog := preload("res://src/game/settings_dialog.gd").new()
	root.add_child(dialog)
	dialog.set("_settings_path", PATH)
	dialog.open()
	if not String((dialog.get("_error") as Label).text).contains("backup"):
		return _fail("Recovered options did not warn the player")
	dialog.hide()
	dialog.queue_free()
	await process_frame
	if Settings.save(values, PATH) != OK or not Store.read(PATH)["config"].has_section("extension"):
		return _fail("Update after recovery erased unrelated sections")
	var original := FileAccess.get_file_as_string(PATH)
	DirAccess.make_dir_absolute(PATH + ".tmp")
	if Settings.save(Settings.DEFAULTS, PATH) == OK or FileAccess.get_file_as_string(PATH) != original:
		return _fail("Failed temporary write modified settings")
	DirAccess.remove_absolute(PATH + ".tmp")
	DirAccess.make_dir_absolute(PATH + ".bak.tmp")
	if Dev.set_enabled(false, PATH) == OK or FileAccess.get_file_as_string(PATH) != original:
		return _fail("Failed backup write modified shared config")
	DirAccess.remove_absolute(PATH + ".bak.tmp")
	_raw(PATH, "[broken")
	DirAccess.remove_absolute(PATH + ".bak")
	if Settings.save(values, PATH) == OK or FileAccess.get_file_as_string(PATH) != "[broken":
		return _fail("Unrecoverable config was silently overwritten")
	_clean()

	var identity := Profile.id(PROFILE_PATH)
	if identity.is_empty() or Profile.id(PROFILE_PATH) != identity:
		return _fail("New identity did not persist")
	_raw(PROFILE_PATH, "[profile]\nid=123\n")
	if Profile.id(PROFILE_PATH) != identity or FileAccess.get_file_as_string(PROFILE_PATH) != "[profile]\nid=123\n":
		return _fail("Invalid profile changed identity or overwritten evidence")
	DirAccess.remove_absolute(PROFILE_PATH + ".bak")
	var temporary := Profile.id(PROFILE_PATH)
	if temporary.is_empty() or Profile.id(PROFILE_PATH) != temporary or FileAccess.get_file_as_string(PROFILE_PATH) != "[profile]\nid=123\n":
		return _fail("Unrecoverable identity was unstable within session")
	_clean()
	_raw(PROFILE_PATH, "file parent")
	var unavailable_path := PROFILE_PATH + "/profile.cfg"
	var unavailable := Profile.id(unavailable_path)
	if Profile.id(unavailable_path) != unavailable:
		return _fail("Failed identity save regenerated ID on each call")
	_clean()

	var npc := Npc.DEFAULTS.duplicate()
	npc["mode"] = "ia"
	npc["api_key"] = "NEVER_PERSIST_THIS_TEST_SECRET"
	npc["timeout"] = []
	if Npc.save_settings(npc, PATH) != OK or FileAccess.get_file_as_string(PATH).contains("NEVER_PERSIST"):
		return _fail("NPC save failed or wrote a secret/unknown field")
	if Npc.load_settings(PATH)["timeout"] != Npc.DEFAULTS["timeout"]:
		return _fail("Malformed NPC numeric value was not sanitized")
	var npc_original := FileAccess.get_file_as_string(PATH)
	DirAccess.make_dir_absolute(PATH + ".tmp")
	if Npc.save_settings(Npc.DEFAULTS, PATH) == OK or FileAccess.get_file_as_string(PATH) != npc_original:
		return _fail("NPC save failure was hidden or changed old config")
	DirAccess.remove_absolute(PATH + ".tmp")
	_raw(PATH, "[broken")
	if not Store.read(PATH)["recovered"]:
		return _fail("NPC config could not recover")
	_clean()
	print("CONFIG_PERSISTENCE_OK: legacy sections, controls/aim recovery, failed writes, stable profile and secret exclusion")
	quit(0)


func _raw(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _clean() -> void:
	for path in [PATH, PROFILE_PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
			DirAccess.remove_absolute(path + suffix)


func _fail(message: String) -> void:
	_clean()
	push_error(message)
	quit(1)
