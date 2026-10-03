extends SceneTree


func _init() -> void:
	var active_definition := SkillGemDefinition.new(
		&"ember_lance", SkillGemDefinition.Kind.ACTIVE
	)
	active_definition.tags = [&"projectile", &"fire"]
	for level in range(1, 11):
		var kind := EvolutionChoice.Kind.MECHANIC if level == 10 else EvolutionChoice.Kind.BUFF
		active_definition.add_level_choice(
			level, EvolutionChoice.new(StringName("power_%d" % level), kind)
		)
		active_definition.add_level_choice(
			level, EvolutionChoice.new(StringName("control_%d" % level), kind)
		)

	var chain_support := SkillGemDefinition.new(
		&"chain", SkillGemDefinition.Kind.SUPPORT
	)
	chain_support.required_active_tags = [&"projectile"]
	var burn_support := SkillGemDefinition.new(
		&"deep_burn", SkillGemDefinition.Kind.SUPPORT
	)
	burn_support.required_active_tags = [&"fire"]
	burn_support.support_drain = 2
	var melee_support := SkillGemDefinition.new(
		&"heavy_impact", SkillGemDefinition.Kind.SUPPORT
	)
	melee_support.required_active_tags = [&"melee"]
	var third_support := SkillGemDefinition.new(
		&"fast_cast", SkillGemDefinition.Kind.SUPPORT
	)
	third_support.required_active_tags = [&"projectile"]

	var active_gem := EquippedActiveGem.new(active_definition)
	if active_gem.level_up():
		_fail("Gem advanced without selecting its level-one buff")
		return
	if not active_gem.choose_evolution(&"power_1"):
		_fail("Gem rejected a valid level-one buff")
		return
	if active_gem.choose_evolution(&"control_1"):
		_fail("Gem accepted two buffs at the same level")
		return
	if not active_gem.level_up() or active_gem.level != 2:
		_fail("Gem did not advance after its choice")
		return
	if not active_gem.attach_support(chain_support):
		_fail("Projectile gem rejected compatible chain support")
		return
	if not active_gem.attach_support(burn_support):
		_fail("Fire gem rejected compatible burn support")
		return
	if active_gem.attach_support(melee_support):
		_fail("Gem accepted an incompatible melee support")
		return
	if active_gem.attach_support(third_support):
		_fail("Gem accepted more than two support gems")
		return
	if active_gem.used_support_capacity() != 3 or active_gem.support_capacity() != 4:
		_fail("Support drain did not respect active gem capacity")
		return

	var loadout := SkillGemLoadout.new()
	if not loadout.equip_active(0, active_gem):
		_fail("Loadout rejected a valid active gem")
		return
	if loadout.gem_for_command(&"Q") != active_gem:
		_fail("Q did not resolve to the equipped active gem")
		return

	var invalid_capstone := EvolutionChoice.new(&"only_numbers", EvolutionChoice.Kind.BUFF)
	if active_definition.add_level_choice(10, invalid_capstone):
		_fail("Level ten accepted a buff without a new mechanic")
		return

	print("SKILL_GEM_OK: slots, supports, one choice per level and mechanical capstone")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
