class_name DevMode
extends RefCounted

## Decide se o jogo abre como ferramenta de desenvolvimento ou como versão pública.
## Prioridade: linha de comando > preferência local > project.godot. Exportações release são sempre públicas.

const SETTING := "aresta/dev_mode"
const ConfigStore := preload("res://src/core/persistence/config_store.gd")
const PREFERENCES_PATH := "user://aresta_settings.cfg"
const DEV_HOME := "res://src/prototype/network/network_prototype.tscn"
const PUBLIC_HOME := "res://src/game/title_screen.tscn"


static func enabled(path: String = PREFERENCES_PATH) -> bool:
	var args := OS.get_cmdline_user_args()
	if "--public" in args:
		return false
	if not OS.is_debug_build():
		return false
	if "--dev" in args:
		return true
	var result := ConfigStore.read(path)
	var preferences: ConfigFile = result["config"]
	if result["error"] == OK and preferences.has_section_key("app", "dev_mode"):
		return bool(preferences.get_value("app", "dev_mode"))
	return bool(ProjectSettings.get_setting(SETTING, true))


static func can_toggle() -> bool:
	return OS.is_debug_build()


static func set_enabled(value: bool, path: String = PREFERENCES_PATH) -> Error:
	return ConfigStore.update(path, {"app": {"dev_mode": value}})


static func home_scene(path: String = PREFERENCES_PATH) -> String:
	return DEV_HOME if enabled(path) else PUBLIC_HOME


static func boot_scene(args: PackedStringArray) -> String:
	if "--public" in args:
		return PUBLIC_HOME
	if OS.is_debug_build() and not "--public" in args:
		for arg in args:
			if arg == "--server" or arg.begins_with("--client="):
				return DEV_HOME
	return home_scene()
