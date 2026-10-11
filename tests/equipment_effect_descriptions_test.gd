extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var sim := Simulation.new()
	sim.setup(8351)
	sim.add_player(1, &"eloa")
	var unavailable := {}
	for definition: Dictionary in sim._collection("items"):
		var plain := ContentDescriptions.item(definition, "common")
		var rich := ContentDescriptions.item_rich(definition, "common", "offhand", "Regular", {}, [])
		for stat: String in definition.get("stats", {}):
			if stat not in ContentDescriptions.FUNCTIONAL_STATS:
				unavailable[stat] = true
				var label := String(ContentDescriptions.STAT_NAMES.get(stat, stat))
				if not rich.contains(label + ": sem efeito no beta") or not plain.contains("(sem efeito no beta)"):
					return _fail("Unavailable stat lacks warning: %s/%s" % [definition["id"], stat])
		var pending := not (definition.get("mechanics", []) as Array).is_empty()
		if plain.contains("integracao pendente") != pending or rich.contains("integracao pendente") != pending:
			return _fail("Legacy mechanic warning differs between descriptions")
	for stat in ["magic_power", "stability", "carry_capacity", "interaction_speed"]:
		var legacy := {"id": "legacy", "stats": {stat: 5}, "mechanics": ["legacy_effect"]}
		var rich := ContentDescriptions.item_rich(legacy, "common", "offhand", "Regular", {}, [])
		if not rich.contains("sem efeito no beta") or not rich.contains("integracao pendente"):
			return _fail("Legacy stat or mechanic lacks warning: " + stat)
	var unknown := {"id": "future", "stats": {"future_stat": 5}}
	if not ContentDescriptions.item_rich(unknown, "common", "ring", "Regular", {}, []).contains("future_stat: sem efeito no beta"):
		return _fail("Unknown stat silently advertised as functional")
	var supported := {"id": "functional", "stats": {"defense": 5}, "passive": {"name": "Teste", "description": "Efeito ativo"}}
	var text := ContentDescriptions.item_rich(supported, "common", "armor", "Regular", {}, [])
	if text.contains("sem efeito") or text.contains("integracao pendente") or not text.contains("Efeito ativo"):
		return _fail("Functional stat or real passive falsely marked unavailable")
	print("EQUIPMENT_EFFECT_DESCRIPTIONS_OK: full catalog, unavailable stats, legacy mechanics, unknown stats and real passives")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
