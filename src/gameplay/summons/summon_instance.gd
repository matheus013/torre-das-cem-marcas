class_name SummonInstance
extends RefCounted

var instance_id: StringName
var definition: RefCounted
var owner_id: StringName
var team_id: StringName
var position := Vector2.ZERO
var health := 1.0
var remaining_duration := 0.0
var attack_timer := 0.0
var spawn_order := 0


func _init(
	summon_instance_id: StringName,
	summon_definition: RefCounted,
	summon_owner_id: StringName,
	summon_team_id: StringName,
	spawn_position: Vector2,
	order: int
) -> void:
	instance_id = summon_instance_id
	definition = summon_definition
	owner_id = summon_owner_id
	team_id = summon_team_id
	position = spawn_position
	health = definition.max_health
	remaining_duration = definition.duration
	spawn_order = order


func is_expired() -> bool:
	return health <= 0.0 or (definition.duration > 0.0 and remaining_duration <= 0.0)


func to_snapshot() -> Dictionary:
	return {
		"instance_id": String(instance_id),
		"definition_id": String(definition.id),
		"owner_id": String(owner_id),
		"team_id": String(team_id),
		"position": [position.x, position.y],
		"health": health,
		"remaining_duration": remaining_duration,
		"attack_timer": attack_timer,
		"spawn_order": spawn_order,
	}


static func from_snapshot(snapshot: Dictionary, summon_definition: RefCounted) -> RefCounted:
	var raw_position: Variant = snapshot.get("position", [])
	var restored_position := Vector2.ZERO
	if raw_position is Array and raw_position.size() >= 2:
		restored_position = Vector2(float(raw_position[0]), float(raw_position[1]))
	var instance: RefCounted = load("res://src/gameplay/summons/summon_instance.gd").new(
		StringName(String(snapshot.get("instance_id", ""))),
		summon_definition,
		StringName(String(snapshot.get("owner_id", ""))),
		StringName(String(snapshot.get("team_id", ""))),
		restored_position,
		int(snapshot.get("spawn_order", 0))
	)
	instance.health = clampf(float(snapshot.get("health", summon_definition.max_health)), 0.0, summon_definition.max_health)
	instance.remaining_duration = maxf(0.0, float(snapshot.get("remaining_duration", summon_definition.duration)))
	instance.attack_timer = maxf(0.0, float(snapshot.get("attack_timer", 0.0)))
	return instance
