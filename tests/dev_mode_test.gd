extends SceneTree

const DevModeScript := preload("res://src/core/app/dev_mode.gd")
const VfxLayerScript := preload("res://src/presentation/vfx/vfx_layer.gd")
const TEST_PATH := "user://aresta_dev_mode_test.cfg"


func _init() -> void:
	_clean()
	DevModeScript.set_enabled(false, TEST_PATH)
	var public_ok := not DevModeScript.enabled(TEST_PATH) and DevModeScript.home_scene(TEST_PATH) == DevModeScript.PUBLIC_HOME
	for args in [PackedStringArray(["--server", "--public"]), PackedStringArray(["--client=127.0.0.1", "--public"])]:
		if DevModeScript.boot_scene(args) != DevModeScript.PUBLIC_HOME:
			_clean()
			_fail("Explicit public mode must override development network arguments")
			return
	if DevModeScript.boot_scene(PackedStringArray(["--server"])) != DevModeScript.DEV_HOME:
		_clean()
		_fail("Debug network smoke launch must remain available")
		return
	DevModeScript.set_enabled(true, TEST_PATH)
	var dev_ok := DevModeScript.enabled(TEST_PATH) and DevModeScript.home_scene(TEST_PATH) == DevModeScript.DEV_HOME
	_clean()
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


func _clean() -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(TEST_PATH + suffix)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
