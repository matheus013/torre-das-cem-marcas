class_name EnemyRespawnDirector
extends RefCounted

var interval := 12.0
var variance := 3.0
var maximum_alive := 6
var batch_size := 1
var minimum_player_distance := 220.0
var minimum_enemy_distance := 48.0
var eligible_classes: Array[StringName] = [&"common", &"elite"]
var seed := 7301
var _death_sequence := 0
var _spawn_sequence := 0
var _queue: Array[Dictionary] = []


func configure(data: Dictionary) -> bool:
	interval = float(data.get("interval", interval))
	variance = float(data.get("variance", variance))
	maximum_alive = int(data.get("maximum_alive", maximum_alive))
	batch_size = int(data.get("batch_size", batch_size))
	minimum_player_distance = float(data.get("minimum_player_distance", minimum_player_distance))
	minimum_enemy_distance = float(data.get("minimum_enemy_distance", minimum_enemy_distance))
	seed = int(data.get("seed", seed))
	var raw_classes: Variant = data.get("eligible_classes", [])
	if raw_classes is Array and not raw_classes.is_empty():
		eligible_classes.clear()
		for value: Variant in raw_classes:
			eligible_classes.append(StringName(String(value)))
	return (
		interval > 0.0
		and variance >= 0.0
		and maximum_alive > 0
		and batch_size > 0
		and minimum_player_distance >= 0.0
		and minimum_enemy_distance >= 0.0
		and not eligible_classes.is_empty()
	)


func register_defeat(definition_id: StringName, encounter_class: StringName, preferred_position: Vector2) -> bool:
	if definition_id.is_empty() or encounter_class not in eligible_classes:
		return false
	var random := RandomNumberGenerator.new()
	random.seed = seed + _death_sequence * 7919
	var delay := interval + random.randf_range(-variance, variance)
	_queue.append({
		"definition_id": definition_id,
		"encounter_class": encounter_class,
		"preferred_position": preferred_position,
		"remaining": maxf(0.1, delay),
		"death_sequence": _death_sequence,
	})
	_death_sequence += 1
	return true


func tick(
	delta: float,
	alive_count: int,
	player_positions: Array[Vector2],
	spawn_points: Array[Vector2],
	occupied_positions: Array[Vector2]
) -> Array[Dictionary]:
	var requests: Array[Dictionary] = []
	if delta <= 0.0 or spawn_points.is_empty():
		return requests
	for queued in _queue:
		queued["remaining"] = float(queued.get("remaining", 0.0)) - delta
	var capacity := maxi(0, maximum_alive - alive_count)
	var allowed := mini(batch_size, capacity)
	var index := 0
	while index < _queue.size() and requests.size() < allowed:
		var queued := _queue[index]
		if float(queued.get("remaining", 0.0)) > 0.0:
			index += 1
			continue
		var position: Variant = _select_spawn_position(queued, spawn_points, player_positions, occupied_positions)
		if position == null:
			index += 1
			continue
		requests.append({
			"definition_id": queued.get("definition_id", ""),
			"position": position,
			"spawn_sequence": _spawn_sequence,
		})
		occupied_positions.append(position)
		_spawn_sequence += 1
		_queue.remove_at(index)
	return requests


func pending_count() -> int:
	return _queue.size()


func clear() -> void:
	_queue.clear()


func snapshot() -> Dictionary:
	var queue_data: Array[Dictionary] = []
	for queued in _queue:
		var position := queued.get("preferred_position", Vector2.ZERO) as Vector2
		queue_data.append({
			"definition_id": String(queued.get("definition_id", "")),
			"encounter_class": String(queued.get("encounter_class", "common")),
			"preferred_position": [position.x, position.y],
			"remaining": maxf(0.0, float(queued.get("remaining", 0.0))),
			"death_sequence": int(queued.get("death_sequence", 0)),
		})
	return {
		"death_sequence": _death_sequence,
		"spawn_sequence": _spawn_sequence,
		"queue": queue_data,
	}


func restore(data: Dictionary) -> bool:
	var restored_queue: Array[Dictionary] = []
	var raw_queue: Variant = data.get("queue", [])
	if not raw_queue is Array:
		return false
	for raw_entry: Variant in raw_queue:
		if not raw_entry is Dictionary:
			return false
		var entry := raw_entry as Dictionary
		var definition_id := StringName(String(entry.get("definition_id", "")))
		var encounter_class := StringName(String(entry.get("encounter_class", "")))
		var position_data: Variant = entry.get("preferred_position", [])
		if definition_id.is_empty() or encounter_class not in eligible_classes or not position_data is Array or position_data.size() < 2:
			return false
		restored_queue.append({
			"definition_id": definition_id,
			"encounter_class": encounter_class,
			"preferred_position": Vector2(float(position_data[0]), float(position_data[1])),
			"remaining": maxf(0.0, float(entry.get("remaining", 0.0))),
			"death_sequence": maxi(0, int(entry.get("death_sequence", 0))),
		})
	_queue = restored_queue
	_death_sequence = maxi(0, int(data.get("death_sequence", 0)))
	_spawn_sequence = maxi(0, int(data.get("spawn_sequence", 0)))
	return true


func _select_spawn_position(
	queued: Dictionary,
	spawn_points: Array[Vector2],
	player_positions: Array[Vector2],
	occupied_positions: Array[Vector2]
) -> Variant:
	var candidates := spawn_points.duplicate()
	var preferred := queued.get("preferred_position", Vector2.ZERO) as Vector2
	candidates.sort_custom(func(left: Vector2, right: Vector2) -> bool:
		return left.distance_squared_to(preferred) < right.distance_squared_to(preferred)
	)
	for candidate: Vector2 in candidates:
		if _far_enough(candidate, player_positions, minimum_player_distance) and _far_enough(candidate, occupied_positions, minimum_enemy_distance):
			return candidate
	return null


func _far_enough(position: Vector2, others: Array[Vector2], minimum_distance: float) -> bool:
	for other in others:
		if position.distance_to(other) < minimum_distance:
			return false
	return true
