extends SceneTree


func _init() -> void:
	var build := CharacterBuild.new(&"eloa")
	var residual_light := SignaturePassiveDefinition.new(
		&"residual_light", &"eloa", &"reveal_and_conduct"
	)
	residual_light.trigger_events = [&"skill_hit", &"world_trace_found"]
	if not build.assign_signature_passive(residual_light) or not build.is_ready_for_play():
		_fail("Character did not receive its unique signature passive")
		return
	var foreign_passive := SignaturePassiveDefinition.new(
		&"adaptive_plates", &"cira", &"absorb_condition"
	)
	if build.assign_signature_passive(foreign_passive):
		_fail("Character accepted another playable character's passive")
		return
	if not build.allocate_stat(&"vitality", 2) or not build.allocate_stat(&"strength", 3):
		_fail("Character rejected free allocation of level stat points")
		return
	if build.unspent_stat_points != 0:
		_fail("Character did not consume allocated stat points")
		return
	if float(build.derived_stats()["max_health"]) != 108.0:
		_fail("Primary stats did not update derived character stats")
		return

	var reinforced_body := EvolutionChoice.new(&"reinforced_body", EvolutionChoice.Kind.BUFF)
	reinforced_body.stat_modifiers = {&"vitality": 2.0}
	build.add_milestone_choice(10, reinforced_body)
	build.add_milestone_choice(10, EvolutionChoice.new(&"arcane_study", EvolutionChoice.Kind.BUFF))
	for step in range(9):
		if not build.level_up():
			_fail("Character failed to reach the first milestone")
			return
	if build.level != 10 or build.unspent_stat_points != 40:
		_fail("Regular levels did not grant five points or milestone granted points")
		return
	if build.level_up():
		_fail("Character passed a milestone without choosing an evolution")
		return
	if not build.choose_milestone(&"reinforced_body"):
		_fail("Character rejected a valid milestone evolution")
		return
	if build.choose_milestone(&"arcane_study"):
		_fail("Character accepted two evolutions at the same milestone")
		return

	var capstone := EvolutionChoice.new(&"living_conduit", EvolutionChoice.Kind.MECHANIC)
	capstone.mechanic_id = &"support_resonance"
	if not build.add_milestone_choice(100, capstone):
		_fail("Character rejected a mechanical level-ten capstone")
		return
	if build.add_milestone_choice(100, EvolutionChoice.new(&"flat_power", EvolutionChoice.Kind.BUFF)):
		_fail("Character level one hundred accepted a numerical-only buff")
		return

	var full_progression := CharacterBuild.new(&"progression_probe")
	for milestone in range(10, 101, 10):
		var kind := EvolutionChoice.Kind.MECHANIC if milestone == 100 else EvolutionChoice.Kind.BUFF
		var choice := EvolutionChoice.new(StringName("milestone_%d" % milestone), kind)
		if not full_progression.add_milestone_choice(milestone, choice):
			_fail("Could not register milestone %d" % milestone)
			return
	while full_progression.level < CharacterBuild.MAX_LEVEL:
		if full_progression.has_pending_milestone():
			var choice_id := StringName("milestone_%d" % full_progression.level)
			if not full_progression.choose_milestone(choice_id):
				_fail("Could not resolve milestone %d" % full_progression.level)
				return
		if not full_progression.level_up():
			_fail("Full progression stopped before level 100")
			return
	if full_progression.unspent_stat_points != 450:
		_fail("One hundred levels did not produce exactly 450 stat points")
		return
	if not full_progression.choose_milestone(&"milestone_100"):
		_fail("Could not resolve the mechanical level-100 milestone")
		return
	var restored := CharacterBuild.new(&"progression_probe")
	restored.restore(full_progression.snapshot())
	if restored.level != 100 or restored.unspent_stat_points != full_progression.unspent_stat_points:
		_fail("Character progression snapshot did not restore level and points")
		return

	print("CHARACTER_BUILD_OK: 100 levels, stat points, milestones, passive and capstone")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
