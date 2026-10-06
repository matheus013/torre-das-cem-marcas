extends Node

## Clique sonoro em todo botão de qualquer cena. Vive na raiz para sobreviver às trocas de cena.

const CombatAudioScript := preload("res://src/presentation/audio/combat_audio.gd")

var _audio: Node


func _ready() -> void:
	_audio = CombatAudioScript.new()
	add_child(_audio)
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button != null and not button.pressed.is_connected(_on_pressed):
		button.pressed.connect(_on_pressed)


func _on_pressed() -> void:
	_audio.call("play", "click")
