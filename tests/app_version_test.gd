extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var version := preload("res://src/core/app/app_version.gd").current()
	if version.is_empty() or version != FileAccess.get_file_as_string("res://VERSION").strip_edges():
		return _fail("App version did not use VERSION")
	var presets := ConfigFile.new()
	if presets.load("res://export_presets.cfg") != OK:
		return _fail("Missing export presets")
	for index in range(3):
		if not "VERSION" in str(presets.get_value("preset.%d" % index, "include_filter", "")):
			return _fail("Export omits VERSION")
	var scene := (load("res://src/game/title_screen.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	if not str(scene.get("_game_version")).ends_with(version):
		return _fail("Title displays a different version")
	scene.queue_free()
	await process_frame
	print("APP_VERSION_OK: canonical version, export inclusion and title")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
