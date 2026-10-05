extends SceneTree


func _init() -> void:
	var version := preload("res://src/core/app/app_version.gd").current()
	var parts := version.split(".")
	if parts.size() != 3 or not parts[0].is_valid_int() or not parts[1].is_valid_int() or not parts[2].is_valid_int():
		push_error("Invalid release version: " + version)
		quit(1)
		return
	var presets := ConfigFile.new()
	if presets.load("res://export_presets.cfg") != OK:
		quit(1)
		return
	for field in ["application/file_version", "application/product_version"]:
		presets.set_value("preset.0.options", field, version + ".0")
	for field in ["application/short_version", "application/version"]:
		presets.set_value("preset.2.options", field, version)
	quit(0 if presets.save("res://export_presets.cfg") == OK else 1)
