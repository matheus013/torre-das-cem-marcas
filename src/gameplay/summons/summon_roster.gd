class_name SummonRoster
extends RefCounted

const SummonInstanceScript := preload("res://src/gameplay/summons/summon_instance.gd")

var _definitions: Dictionary = {}
var _instances: Dictionary = {}
var _next_spawn_order := 1


func register_definition(definition: RefCounted) -> bool:
	if not definition.is_valid_definition() or _definitions.has(definition.id):
		return false
	_definitions[definition.id] = definition
	return true


func spawn(
	instance_id: StringName,
	definition_id: StringName,
	owner_id: StringName,
	team_id: StringName,
	position: Vector2
) -> RefCounted:
	if instance_id.is_empty() or owner_id.is_empty() or team_id.is_empty() or _instances.has(instance_id):
		return null
	var definition := _definitions.get(definition_id) as RefCounted
	if definition == null:
		return null
	var owned := active_for_owner(owner_id, definition_id)
	if owned.size() >= definition.owner_limit:
		if definition.replacement_policy == &"reject":
			return null
		_dismiss_oldest(owned)
	var instance: RefCounted = SummonInstanceScript.new(
		instance_id, definition, owner_id, team_id, position, _next_spawn_order
	)
	_next_spawn_order += 1
	_instances[instance_id] = instance
	return instance


func tick(delta: float) -> Array[StringName]:
	var expired: Array[StringName] = []
	for instance: RefCounted in all_active():
		if instance.definition.duration > 0.0:
			instance.remaining_duration = maxf(0.0, instance.remaining_duration - delta)
		instance.attack_timer = maxf(0.0, instance.attack_timer - delta)
		if instance.is_expired():
			expired.append(instance.instance_id)
	for instance_id in expired:
		_instances.erase(instance_id)
	return expired


func dismiss(instance_id: StringName, requesting_owner_id: StringName = &"") -> bool:
	var instance := _instances.get(instance_id) as RefCounted
	if instance == null or (not requesting_owner_id.is_empty() and instance.owner_id != requesting_owner_id):
		return false
	_instances.erase(instance_id)
	return true


func dismiss_owner(owner_id: StringName, include_persistent: bool = false) -> int:
	var removed := 0
	for instance: RefCounted in all_active():
		if instance.owner_id == owner_id and (include_persistent or not instance.definition.persists_between_areas):
			_instances.erase(instance.instance_id)
			removed += 1
	return removed


func get_instance(instance_id: StringName) -> RefCounted:
	return _instances.get(instance_id) as RefCounted


func all_active() -> Array[RefCounted]:
	var result: Array[RefCounted] = []
	for value: Variant in _instances.values():
		result.append(value as RefCounted)
	result.sort_custom(func(left: RefCounted, right: RefCounted) -> bool: return left.spawn_order < right.spawn_order)
	return result


func active_for_owner(owner_id: StringName, definition_id: StringName = &"") -> Array[RefCounted]:
	var result: Array[RefCounted] = []
	for instance: RefCounted in all_active():
		if instance.owner_id == owner_id and (definition_id.is_empty() or instance.definition.id == definition_id):
			result.append(instance)
	return result


func snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for instance: RefCounted in all_active():
		result.append(instance.to_snapshot())
	return result


func restore(snapshots: Array) -> bool:
	var restored: Dictionary = {}
	var highest_order := 0
	for raw_snapshot: Variant in snapshots:
		if not raw_snapshot is Dictionary:
			return false
		var summon_snapshot := raw_snapshot as Dictionary
		var instance_id := StringName(String(summon_snapshot.get("instance_id", "")))
		var definition_id := StringName(String(summon_snapshot.get("definition_id", "")))
		var definition := _definitions.get(definition_id) as RefCounted
		if instance_id.is_empty() or definition == null or restored.has(instance_id):
			return false
		var instance: RefCounted = SummonInstanceScript.from_snapshot(summon_snapshot, definition)
		if instance.owner_id.is_empty() or instance.team_id.is_empty() or instance.is_expired():
			return false
		restored[instance_id] = instance
		highest_order = maxi(highest_order, instance.spawn_order)
	_instances = restored
	_next_spawn_order = highest_order + 1
	return true


func _dismiss_oldest(owned: Array[RefCounted]) -> void:
	if owned.is_empty():
		return
	var oldest := owned[0]
	for instance in owned:
		if instance.spawn_order < oldest.spawn_order:
			oldest = instance
	_instances.erase(oldest.instance_id)
