extends RefCounted

const BindingsScript := preload("res://src/core/app/input_bindings.gd")

const PATH := "user://aresta_settings.cfg"
const SECTION := "game"
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
const FPS_LIMITS: Array[int] = [0, 30, 60, 120, 144]
const DEFAULTS := {"fullscreen": false, "resolution": 0, "fps": 60, "vsync": true, "master": 100.0, "music": 100.0, "effects": 100.0, "auto_aim": false}
static var auto_aim := false


static func read(path: String = PATH) -> Dictionary:
	var values := DEFAULTS.duplicate()
	var config := ConfigFile.new()
	if config.load(path) == OK:
		for key: String in DEFAULTS:
			values[key] = config.get_value(SECTION, key, DEFAULTS[key])
	return sanitize(values)


static func toggle_auto_aim(path: String = PATH) -> Error:
	var values := read(path)
	auto_aim = not auto_aim
	values["auto_aim"] = auto_aim
	return save(values, path)


static func save(values: Dictionary, path: String = PATH, bindings: Dictionary = {}) -> Error:
	if not bindings.is_empty() and not BindingsScript.valid(bindings):
		return ERR_INVALID_PARAMETER
	var config := ConfigFile.new()
	var error := config.load(path)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		return error
	var clean := sanitize(values)
	for key: String in DEFAULTS:
		config.set_value(SECTION, key, clean[key])
	for action: String in bindings:
		config.set_value("controls", action, bindings[action])
	return config.save(path)


static func sanitize(values: Dictionary) -> Dictionary:
	var clean := DEFAULTS.duplicate()
	for key: String in DEFAULTS:
		var value: Variant = values.get(key, DEFAULTS[key])
		if key in ["fullscreen", "vsync", "auto_aim"]:
			if value is bool:
				clean[key] = value
		elif value is int or value is float:
			if not is_finite(float(value)):
				continue
			if key == "resolution":
				clean[key] = clampi(int(value), 0, RESOLUTIONS.size() - 1)
			elif key == "fps":
				if int(value) in FPS_LIMITS:
					clean[key] = int(value)
			else:
				clean[key] = clampf(float(value), 0.0, 100.0)
	return clean


static func apply(values: Dictionary) -> void:
	var clean := sanitize(values)
	auto_aim = bool(clean["auto_aim"])
	Engine.max_fps = int(clean["fps"])
	for key: String in ["master", "music", "effects"]:
		var bus_name := {"master": "Master", "music": "Music", "effects": "Effects"}[key] as String
		var bus := AudioServer.get_bus_index(bus_name)
		if bus < 0:
			AudioServer.add_bus()
			bus = AudioServer.bus_count - 1
			AudioServer.set_bus_name(bus, bus_name)
			AudioServer.set_bus_send(bus, "Master")
		var volume := float(clean[key]) / 100.0
		AudioServer.set_bus_mute(bus, volume == 0.0)
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if clean["vsync"] else DisplayServer.VSYNC_DISABLED)
	if clean["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var desired := RESOLUTIONS[int(clean["resolution"])]
		var screen := DisplayServer.window_get_current_screen()
		var usable := DisplayServer.screen_get_usable_rect(screen)
		if usable.size.x > 0 and usable.size.y > 0:
			desired = Vector2i(mini(desired.x, usable.size.x), mini(desired.y, usable.size.y))
		DisplayServer.window_set_size(desired)
		DisplayServer.window_set_position(usable.position + (usable.size - desired) / 2)
