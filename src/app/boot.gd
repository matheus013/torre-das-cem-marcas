extends Node

## Cena inicial: encaminha para o menu de desenvolvimento ou para a tela pública.

const DevModeScript := preload("res://src/core/app/dev_mode.gd")
const ReleaseCheckScript := preload("res://src/core/app/release_check.gd")
const SettingsScript := preload("res://src/core/app/game_settings.gd")


func _ready() -> void:
	SettingsScript.apply(SettingsScript.read())
	SettingsScript.BindingsScript.apply(SettingsScript.BindingsScript.read())
	var args := OS.get_cmdline_user_args()
	if "--release-check" in args and DisplayServer.get_name() == "headless":
		ReleaseCheckScript.run(get_tree())
		return
	var target := DevModeScript.boot_scene(args)
	get_window().title = "Aresta [DEV]" if DevModeScript.enabled() else "Aresta"
	get_tree().change_scene_to_file.call_deferred(target)
