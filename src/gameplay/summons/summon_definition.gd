class_name SummonDefinition
extends RefCounted

const BEHAVIORS: Array[StringName] = [&"stationary", &"follow_owner", &"chase_target"]
const TARGETING_RULES: Array[StringName] = [&"nearest_hostile", &"owner_target", &"lowest_health_hostile"]
const REPLACEMENT_POLICIES: Array[StringName] = [&"oldest", &"reject"]

var id: StringName
var display_name := ""
var behavior := &"stationary"
var targeting := &"nearest_hostile"
var replacement_policy := &"oldest"
var max_health := 1.0
var movement_speed := 0.0
var attack_power := 0.0
var attack_interval := 1.0
var attack_range := 100.0
var duration := 0.0
var owner_limit := 1
var collision_radius := 10.0
var can_be_damaged := true
var blocks_movement := false
var persists_between_areas := false


static func from_dictionary(data: Dictionary) -> RefCounted:
	var definition: RefCounted = load("res://src/gameplay/summons/summon_definition.gd").new()
	definition.id = StringName(String(data.get("id", "")))
	definition.display_name = String(data.get("name", definition.id))
	definition.behavior = StringName(String(data.get("behavior", "stationary")))
	definition.targeting = StringName(String(data.get("targeting", "nearest_hostile")))
	definition.replacement_policy = StringName(String(data.get("replacement_policy", "oldest")))
	definition.max_health = float(data.get("health", 1.0))
	definition.movement_speed = float(data.get("movement_speed", 0.0))
	definition.attack_power = float(data.get("power", 0.0))
	definition.attack_interval = float(data.get("attack_interval", 1.0))
	definition.attack_range = float(data.get("range", 100.0))
	definition.duration = float(data.get("duration", 0.0))
	definition.owner_limit = int(data.get("owner_limit", 1))
	definition.collision_radius = float(data.get("collision_radius", 10.0))
	definition.can_be_damaged = bool(data.get("can_be_damaged", true))
	definition.blocks_movement = bool(data.get("blocks_movement", false))
	definition.persists_between_areas = bool(data.get("persists_between_areas", false))
	return definition


func is_valid_definition() -> bool:
	return (
		not id.is_empty()
		and behavior in BEHAVIORS
		and targeting in TARGETING_RULES
		and replacement_policy in REPLACEMENT_POLICIES
		and max_health > 0.0
		and movement_speed >= 0.0
		and attack_power >= 0.0
		and attack_interval > 0.0
		and attack_range > 0.0
		and duration >= 0.0
		and owner_limit > 0
		and collision_radius > 0.0
	)
