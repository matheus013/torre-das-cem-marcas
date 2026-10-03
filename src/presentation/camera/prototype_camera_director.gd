class_name PrototypeCameraDirector
extends Node

signal mode_changed

@export var players_root_path: NodePath
@export var world_path: NodePath

const SPLIT_THRESHOLD := 260.0
const MERGE_THRESHOLD := 210.0
const SHARED_MARGIN := Vector2(360.0, 240.0)

var is_safe_context := false
var is_split_active := false

var _players_root: Node2D
var _world: Node2D
var _shared_camera: Camera2D
var _split_layer: CanvasLayer
var _split_root: Control
var _containers: Array[SubViewportContainer] = []
var _cameras: Array[Camera2D] = []


func _ready() -> void:
	_players_root = get_node(players_root_path)
	_world = get_node(world_path)
	_create_shared_camera()
	_create_split_views()
	get_viewport().size_changed.connect(_layout_split_views)


func _process(delta: float) -> void:
	var players := _players()
	_update_split_state(players)
	if is_split_active:
		_update_split_cameras(players, delta)
	else:
		_update_shared_camera(players, delta)


func toggle_context() -> void:
	is_safe_context = not is_safe_context
	_update_split_state(_players(), true)
	mode_changed.emit()


func refresh_players() -> void:
	_update_split_state(_players(), true)


func _create_shared_camera() -> void:
	_shared_camera = Camera2D.new()
	_shared_camera.name = "SharedCamera"
	_shared_camera.position_smoothing_enabled = true
	_shared_camera.position_smoothing_speed = 7.0
	_world.add_child.call_deferred(_shared_camera)


func _create_split_views() -> void:
	_split_layer = CanvasLayer.new()
	_split_layer.layer = 10
	add_child(_split_layer)

	_split_root = Control.new()
	_split_root.position = Vector2.ZERO
	_split_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_split_layer.add_child(_split_root)

	for index in range(4):
		var container := SubViewportContainer.new()
		container.name = "SplitPanel%d" % (index + 1)
		container.stretch = true
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.visible = false
		_split_root.add_child(container)

		var viewport := SubViewport.new()
		viewport.name = "Viewport"
		viewport.world_2d = get_viewport().world_2d
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.handle_input_locally = false
		container.add_child(viewport)

		var camera := Camera2D.new()
		camera.name = "Camera"
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 9.0
		viewport.add_child(camera)

		_containers.append(container)
		_cameras.append(camera)

	_layout_split_views()


func _players() -> Array[Node2D]:
	var result: Array[Node2D] = []
	if _players_root == null:
		return result
	for child in _players_root.get_children():
		if child is Node2D and not child.is_queued_for_deletion():
			result.append(child)
	result.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.name < b.name)
	return result


func _update_split_state(players: Array[Node2D], force: bool = false) -> void:
	var should_split := false
	if is_safe_context and players.size() > 1:
		var spread := _maximum_distance(players)
		should_split = spread > (MERGE_THRESHOLD if is_split_active else SPLIT_THRESHOLD)

	if not force and should_split == is_split_active:
		return

	is_split_active = should_split
	_shared_camera.enabled = not is_split_active
	for index in range(_containers.size()):
		_containers[index].visible = is_split_active and index < players.size()
	_layout_split_views()
	mode_changed.emit()


func _update_shared_camera(players: Array[Node2D], delta: float) -> void:
	if players.is_empty():
		_shared_camera.position = _shared_camera.position.lerp(Vector2.ZERO, minf(delta * 4.0, 1.0))
		_shared_camera.zoom = _shared_camera.zoom.lerp(Vector2.ONE, minf(delta * 4.0, 1.0))
		return

	var bounds := Rect2(players[0].global_position, Vector2.ZERO)
	for player in players:
		bounds = bounds.expand(player.global_position)
	var desired_position := bounds.get_center()
	var required := bounds.size + SHARED_MARGIN
	var viewport_size := get_viewport().get_visible_rect().size
	var zoom_value := minf(viewport_size.x / maxf(required.x, 1.0), viewport_size.y / maxf(required.y, 1.0))
	zoom_value = clampf(zoom_value, 0.72, 1.35)
	_shared_camera.position = _shared_camera.position.lerp(desired_position, minf(delta * 6.0, 1.0))
	_shared_camera.zoom = _shared_camera.zoom.lerp(Vector2.ONE * zoom_value, minf(delta * 5.0, 1.0))


func _update_split_cameras(players: Array[Node2D], delta: float) -> void:
	for index in range(mini(players.size(), _cameras.size())):
		_cameras[index].position = _cameras[index].position.lerp(
			players[index].global_position,
			minf(delta * 8.0, 1.0)
		)
		_cameras[index].zoom = Vector2.ONE


func _maximum_distance(players: Array[Node2D]) -> float:
	var maximum := 0.0
	for first in range(players.size()):
		for second in range(first + 1, players.size()):
			maximum = maxf(maximum, players[first].global_position.distance_to(players[second].global_position))
	return maximum


func _layout_split_views() -> void:
	if _split_root == null:
		return
	var size := get_viewport().get_visible_rect().size
	_split_root.size = size

	var active_count := 0
	for container in _containers:
		if container.visible:
			active_count += 1

	for index in range(_containers.size()):
		var container := _containers[index]
		if not container.visible:
			continue

		var rect := Rect2(Vector2.ZERO, size)
		if active_count == 2:
			rect = Rect2(Vector2(size.x * 0.5 * index, 0.0), Vector2(size.x * 0.5, size.y))
		elif active_count >= 3:
			var column := index % 2
			var row := floori(float(index) / 2.0)
			rect = Rect2(
				Vector2(size.x * 0.5 * column, size.y * 0.5 * row),
				Vector2(size.x * 0.5, size.y * 0.5)
			)

		container.position = rect.position
		container.size = rect.size
		var viewport := container.get_node("Viewport") as SubViewport
		viewport.size = Vector2i(maxi(1, int(rect.size.x)), maxi(1, int(rect.size.y)))
