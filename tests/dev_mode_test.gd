extends SceneTree

const DevModeScript := preload("res://src/core/app/dev_mode.gd")
const VfxLayerScript := preload("res://src/presentation/vfx/vfx_layer.gd")


func _init() -> void:
	var preferences := ConfigFile.new()
	var had_preferences := preferences.load(DevModeScript.PREFERENCES_PATH) == OK
	var previous: Variant = null
	if had_preferences and preferences.has_section_key("app", "dev_mode"):
		previous = preferences.get_value("app", "dev_mode")

	DevModeScript.set_enabled(false)
	var public_ok := not DevModeScript.enabled() and DevModeScript.home_scene() == DevModeScript.PUBLIC_HOME
	DevModeScript.set_enabled(true)
	var dev_ok := DevModeScript.enabled() and DevModeScript.home_scene() == DevModeScript.DEV_HOME
	_restore(had_preferences, previous)
	if not public_ok or not dev_ok:
		_fail("Dev mode preference did not switch between public and development homes")
		return

	var boot_script := load("res://src/app/boot.gd") as GDScript
	if boot_script == null or not boot_script.can_instantiate() or load("res://src/app/boot.tscn") == null:
		_fail("Boot scene must compile and load")
		return
	if ProjectSettings.get_setting("application/run/main_scene") != "res://src/app/boot.tscn":
		_fail("Boot scene must be the project main scene")
		return

	var title := (load(DevModeScript.PUBLIC_HOME) as PackedScene).instantiate()
	root.add_child(title)
	await process_frame
	if title.get_node_or_null("Menu/Play") == null or title.get_node_or_null("Menu/Quit") == null:
		_fail("Public title screen must offer play and quit")
		return
	if title.get_node_or_null("Menu/CoopHost") == null or title.get_node_or_null("Menu/CoopJoin") == null:
		_fail("Public title screen must offer co-op host and join")
		return
	for forbidden in ["BuildLab", "DeveloperTools", "Host"]:
		if title.find_child(forbidden, true, false) != null:
			_fail("Public title screen exposed development option %s" % forbidden)
			return
	title.queue_free()

	var vfx: Node2D = VfxLayerScript.new()
	root.add_child(vfx)
	vfx.call("number", Vector2.ZERO, 12.0, false)
	vfx.call("number", Vector2.ZERO, 30.0, true)
	vfx.call("number", Vector2.ZERO, 8.0, false, "player")
	vfx.call("label", Vector2.ZERO, "BLOQUEIO", Color.WHITE)
	if int(vfx.call("active_count")) != 4:
		_fail("Damage numbers were not queued")
		return
	await process_frame
	print("DEV_MODE_OK: public and development homes, public title screen and damage numbers")
	quit(0)


func _restore(had_preferences: bool, previous: Variant) -> void:
	var preferences := ConfigFile.new()
	preferences.load(DevModeScript.PREFERENCES_PATH)
	if had_preferences and previous != null:
		preferences.set_value("app", "dev_mode", previous)
		preferences.save(DevModeScript.PREFERENCES_PATH)
	elif preferences.has_section_key("app", "dev_mode"):
		preferences.erase_section_key("app", "dev_mode")
		preferences.save(DevModeScript.PREFERENCES_PATH)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
