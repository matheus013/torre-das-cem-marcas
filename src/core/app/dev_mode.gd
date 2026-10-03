class_name DevMode
extends RefCounted

## Decide se o jogo abre como ferramenta de desenvolvimento ou como versão pública.
## Prioridade: linha de comando > preferência local > project.godot. Exportações release são sempre públicas.

const SETTING := "aresta/dev_mode"
const PREFERENCES_PATH := "user://aresta_settings.cfg"
const DEV_HOME := "res://src/prototype/network/network_prototype.tscn"
const PUBLIC_HOME := "res://src/game/title_screen.tscn"


static func enabled() -> bool:
	var args := OS.get_cmdline_user_args()
	if "--public" in args:
		return false
	if not OS.is_debug_build():
		return false
	if "--dev" in args:
		return true
	var preferences := ConfigFile.new()
	if preferences.load(PREFERENCES_PATH) == OK and preferences.has_section_key("app", "dev_mode"):
		return bool(preferences.get_value("app", "dev_mode"))
	return bool(ProjectSettings.get_setting(SETTING, true))


static func can_toggle() -> bool:
	return OS.is_debug_build()


static func set_enabled(value: bool) -> void:
	var preferences := ConfigFile.new()
	preferences.load(PREFERENCES_PATH)
	preferences.set_value("app", "dev_mode", value)
	preferences.save(PREFERENCES_PATH)


static func home_scene() -> String:
	return DEV_HOME if enabled() else PUBLIC_HOME


static func boot_scene(args: PackedStringArray) -> String:
	if OS.is_debug_build() and not "--public" in args:
		for arg in args:
			if arg == "--server" or arg.begins_with("--client="):
				return DEV_HOME
	return home_scene()
