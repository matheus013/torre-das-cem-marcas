extends Node

## Cena inicial: encaminha para o menu de desenvolvimento ou para a tela pública.

const DevModeScript := preload("res://src/core/app/dev_mode.gd")


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var wants_session := false
	for arg in args:
		if arg == "--server" or arg.begins_with("--client="):
			wants_session = true
	var target := DevModeScript.DEV_HOME if wants_session else DevModeScript.home_scene()
	get_window().title = "Aresta [DEV]" if DevModeScript.enabled() else "Aresta"
	get_tree().change_scene_to_file.call_deferred(target)
