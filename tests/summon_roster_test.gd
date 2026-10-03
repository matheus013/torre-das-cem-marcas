extends SceneTree

const DefinitionScript := preload("res://src/gameplay/summons/summon_definition.gd")
const RosterScript := preload("res://src/gameplay/summons/summon_roster.gd")


func _init() -> void:
	var definition: RefCounted = DefinitionScript.from_dictionary({
		"id": "molde_vigilante",
		"name": "Molde Vigilante",
		"behavior": "stationary",
		"targeting": "nearest_hostile",
		"replacement_policy": "oldest",
		"health": 45,
		"power": 16,
		"attack_interval": 0.8,
		"range": 300,
		"duration": 10,
		"owner_limit": 2,
		"collision_radius": 12,
	})
	var definition_id := StringName(String(definition.get("id")))
	var roster: RefCounted = RosterScript.new()
	if not bool(roster.call("register_definition", definition)):
		_fail("Valid summon definition was rejected")
		return
	var first: Variant = roster.call("spawn", &"summon_1", definition_id, &"player_1", &"heroes", Vector2(10, 20))
	var second: Variant = roster.call("spawn", &"summon_2", definition_id, &"player_1", &"heroes", Vector2(20, 20))
	var third: Variant = roster.call("spawn", &"summon_3", definition_id, &"player_1", &"heroes", Vector2(30, 20))
	if first == null or second == null or third == null or roster.call("get_instance", &"summon_1") != null:
		_fail("Owner limit did not replace the oldest summon")
		return
	var owned: Array = roster.call("active_for_owner", &"player_1", definition_id)
	if owned.size() != 2:
		_fail("Summon ownership query returned an invalid count")
		return
	var saved: Array[Dictionary] = roster.call("snapshot")
	var restored: RefCounted = RosterScript.new()
	restored.call("register_definition", definition)
	if not bool(restored.call("restore", saved)) or restored.call("get_instance", &"summon_3") == null:
		_fail("Summon snapshot could not be restored")
		return
	restored.call("tick", 10.0)
	var active: Array = restored.call("all_active")
	if not active.is_empty():
		_fail("Timed summons did not expire authoritatively")
		return
	print("SUMMON_ROSTER_OK: ownership, limits, replacement, snapshots and expiry validated")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
