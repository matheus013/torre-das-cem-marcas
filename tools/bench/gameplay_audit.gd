extends SceneTree

## Read-only diagnostic. Uses fresh in-memory worlds; never touches user saves.
## --strict exits nonzero while findings exist; this is not a passing gameplay test.
const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Factory := preload("res://src/gameplay/content/beta_item_factory.gd")
var findings: Array[Dictionary] = []


func _init() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json"))
	for gem: Dictionary in catalog["active_gems"]:
		for stat: String in gem.get("scaling", []):
			if not CharacterBuild.PRIMARY_STATS.has(StringName(stat)):
				_report("unknown_scaling_stat", {"gem": gem["id"], "stat": stat})
	for item_id in ["escudo_de_escora", "foco_de_vidro_termico", "anel_de_area"]:
		var sim := _world()
		var before := _combat_values(sim)
		var instance: StringName = sim.call("_add_equipment_instance", &"eloa", item_id)
		sim.equip_item(1, instance)
		if before == _combat_values(sim):
			_report("equipment_has_no_derived_or_skill_effect", {"item": item_id})
	var factory := Factory.new()
	var definition := factory.definition_from_data({"id": "audit_only", "slot": "weapon", "two_handed": true, "tags": ["audit"], "incompatibility_tags": ["audit_conflict"]})
	if not definition.two_handed or definition.tags.is_empty() or definition.incompatibility_tags.is_empty():
		_report("factory_ignores_equipment_metadata", {})
	var ground := _world()
	ground.enter_tower(1)
	ground.drop_item(&"tower", Vector2(250, 250), "reliquia_lastro_partido", 1)
	for index in range(Simulation.MAX_GROUND_ITEMS):
		ground.drop_item(&"tower", Vector2(500 + (index % 12) * 40, 500 + (index / 12) * 40), "pedra_regenerativa", 1)
	var relic_retained := false
	for item: Dictionary in ground.ground_items:
		if item["item_id"] == "reliquia_lastro_partido":
			relic_retained = true
	if not relic_retained:
		_report("ground_cap_discards_valuable_loot", {"cap": Simulation.MAX_GROUND_ITEMS})
	var movement := _world()
	movement.set_move_target(1, Vector2(INF, 0))
	if not (movement.player(1)["target"] as Vector2).is_finite():
		_report("nonfinite_movement_target_accepted", {})
	print(JSON.stringify({"diagnostic": "gameplay_audit", "findings": findings}, "\t"))
	quit(1 if "--strict" in OS.get_cmdline_user_args() and not findings.is_empty() else 0)


func _world() -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(7301)
	sim.add_player(1, &"eloa")
	return sim


func _combat_values(sim: WorldSimulation) -> Dictionary:
	var slots: Array[Dictionary] = []
	for index in range(4):
		slots.append(sim.resolve_slot(1, index))
	return {"stats": sim.derived_stats(1), "skills": slots}


func _report(code: String, details: Dictionary) -> void:
	findings.append({"code": code, "details": details})
