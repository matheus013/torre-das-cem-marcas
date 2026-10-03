extends SceneTree

const DirectorScript := preload("res://src/gameplay/encounters/threat_escalation_director.gd")
const RoomStateScript := preload("res://src/gameplay/encounters/special_boss_room_state.gd")


func _init() -> void:
	var director: RefCounted = DirectorScript.new()
	director.call("configure", {"normal_kills_per_boss": 3, "boss_kills_per_raid": 10})
	for index in range(3):
		director.call("register_defeat", &"common" if index < 2 else &"elite")
	if director.call("consume_next_spawn") != &"boss":
		_fail("Normal and elite kills did not queue a boss")
		return
	for index in range(10):
		director.call("register_defeat", &"boss")
	if director.call("consume_next_spawn") != &"raid":
		_fail("Ten boss defeats did not queue a raid")
		return
	var restored: RefCounted = DirectorScript.new()
	restored.call("restore", director.call("snapshot"))
	if int(restored.get("raid_kills")) != 0 or int(restored.get("boss_kills")) != 0:
		_fail("Threat counters were not restored")
		return
	var room: RefCounted = RoomStateScript.new()
	if not bool(room.call("setup", {
		"id": "camara_refeita", "encounter_id": "guardiao_camara_refeita",
		"exclusive_enemy": true, "respawn_seconds": 1200.0,
	})) or not bool(room.call("begin_encounter")):
		_fail("Exclusive boss room could not begin")
		return
	room.call("complete_encounter")
	room.call("tick_world_time", 1199.0)
	if bool(room.call("can_enter")):
		_fail("Special boss returned before its long cooldown")
		return
	room.call("tick_world_time", 1.0)
	if not bool(room.call("can_enter")):
		_fail("Special boss did not return after its cooldown")
		return
	print("THREAT_ESCALATION_OK: normal kills, bosses, raids and exclusive room cooldown validated")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
