extends SceneTree


func _init() -> void:
	if StatResolver.effective_primary(100.0) != 100.0:
		_fail("First stat band should convert at full value")
		return
	if StatResolver.effective_primary(200.0) != 175.0:
		_fail("Second stat band did not apply diminishing returns")
		return
	if StatResolver.effective_primary(450.0) != 262.5:
		_fail("Full specialization did not use all soft-cap bands")
		return

	var raw_stats := {
		&"vitality": 0.0,
		&"strength": 225.0,
		&"intelligence": 0.0,
		&"agility": 225.0,
		&"fortune": 0.0,
		&"wisdom": 0.0,
	}
	var derived := StatResolver.resolve(raw_stats)
	if float(derived["movement_speed_multiplier"]) > 1.25:
		_fail("Agility exceeded the movement speed safety cap")
		return
	if derived.has("loot_bonus") or derived.has("experience_bonus"):
		_fail("Stats introduced mandatory loot or experience bonuses")
		return

	var scaling := SkillScalingProfile.new()
	if not scaling.set_weight(&"strength", 0.7):
		_fail("Skill rejected its primary scaling stat")
		return
	if not scaling.set_weight(&"agility", 0.3):
		_fail("Skill rejected its secondary scaling stat")
		return
	if not scaling.set_weight(&"fortune", 0.2):
		_fail("Skill rejected its third scaling stat")
		return
	if scaling.set_weight(&"wisdom", 0.1):
		_fail("Skill accepted more than three scaling stats")
		return
	if scaling.power_multiplier(raw_stats) <= 1.0:
		_fail("Allocated stats did not increase skill power")
		return

	print("STAT_SCALING_OK: soft caps, safety limits and three-stat gem scaling")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
