extends Node2D

const PrototypePlayerScene := preload("res://src/gameplay/player/prototype_player.gd")

@onready var registry: LocalPlayerRegistry = $LocalPlayerRegistry
@onready var players_root: Node2D = $World/Players
@onready var camera_director: PrototypeCameraDirector = $CameraDirector
@onready var status_label: Label = $Interface/StatusPanel/Margin/Status


func _ready() -> void:
	registry.player_joined.connect(_on_player_joined)
	registry.player_left.connect(_on_player_left)
	camera_director.mode_changed.connect(_update_status)
	registry.roster_changed.connect(_update_status)
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			camera_director.toggle_context()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()


func _on_player_joined(slot: int, source: LocalPlayerRegistry.InputSource) -> void:
	var player := PrototypePlayerScene.new() as PrototypePlayer
	player.name = "Player%d" % (slot + 1)
	player.configure(slot, source)
	players_root.add_child(player)
	player.global_position = _spawn_position(slot)
	camera_director.refresh_players()


func _on_player_left(slot: int) -> void:
	var player := players_root.get_node_or_null("Player%d" % (slot + 1))
	if player != null:
		player.queue_free()
	await get_tree().process_frame
	camera_director.refresh_players()


func _spawn_position(slot: int) -> Vector2:
	const POSITIONS: Array[Vector2] = [
		Vector2(-120.0, -80.0),
		Vector2(120.0, -80.0),
		Vector2(-120.0, 80.0),
		Vector2(120.0, 80.0),
	]
	return POSITIONS[slot]


func _update_status() -> void:
	var context := "Área segura" if camera_director.is_safe_context else "Torre"
	var split := "split ativo" if camera_director.is_split_active else "câmera compartilhada"
	status_label.text = "%s | %d jogador(es) | %s" % [context, registry.player_count(), split]
