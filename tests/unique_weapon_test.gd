extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Sprites := preload("res://src/presentation/art/sprite_library.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var beta := JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json")) as Dictionary
	var uniques := {}
	for item: Dictionary in beta["items"]:
		if item.has("unique_gem"):
			uniques[String(item["unique_gem"])] = item
	for gem: Dictionary in beta["active_gems"]:
		var item := uniques.get(String(gem["id"]), {}) as Dictionary
		if item.is_empty() or String(item["tier"]) != "legendary" or String(item["slot"]) != "weapon":
			return _fail("Gem without a legendary unique weapon: " + String(gem["id"]))
		if Sprites.texture("items/" + String(item["id"])) == null:
			return _fail("Unique weapon without icon: " + String(item["id"]))
	if uniques.size() != (beta["active_gems"] as Array).size():
		return _fail("Exactly one unique weapon per active gem")

	var sim := Simulation.new()
	sim.setup(4040)
	sim.add_player(1, &"eloa")
	# Armas únicas só caem da dificuldade 2 em diante (decisão 597).
	sim.unlocked_difficulty = 2
	sim.set_difficulty(1, 2)
	sim.unlock_all_gems(1, true)
	sim.set_gem_slot(1, 0, "agulha_lastro")
	sim.set_gem_slot(1, 1, "elo_residual")
	var plain_needle := sim.resolve_slot(1, 0)
	var plain_chain := sim.resolve_slot(1, 1)
	sim.equip_item(1, sim._add_equipment_instance(&"eloa", "unica_agulha_lastro", "regular"))
	var needle := sim.resolve_slot(1, 0)
	if not is_equal_approx(float(needle["power"]), float(plain_needle["power"]) * 1.5) or not is_equal_approx(float(needle["cooldown"]), float(plain_needle["cooldown"]) * 0.75):
		return _fail("Unique weapon must give +50% power and -25% cooldown to its gem")
	# projectile_count guarda projéteis extras: a execução dispara 1 + projectile_count.
	if int(needle["projectile_count"]) != int(plain_needle.get("projectile_count", 0)) + 1 or int(needle["pierce"]) != int(plain_needle.get("pierce", 0)) + 2:
		return _fail("Projectile unique must add a projectile and two pierces")
	if sim.resolve_slot(1, 1)["power"] != plain_chain["power"]:
		return _fail("Unique weapon must not buff other gems")
	var card := (sim.menu_model(1)["skills"] as Array)[0] as Dictionary
	if not String(card["unique_weapon"]).begins_with("Arma unica de Agulha de Lastro"):
		return _fail("Gem card must announce its active unique weapon")

	# Chefe solta arma única com 10% (decisão 585), sempre de uma das gemas de quem abateu.
	sim.enter_tower(1)
	var boss := {"encounter_class": "boss", "rank_id": "alfa", "loot_table_id": "", "position": Vector2(400.0, 400.0), "loot_value": 1}
	var slots := sim._gem_state(1)["slots"] as Array
	var drops := 0
	for victory in range(200):
		(sim.get("ground_items") as Array).clear()
		sim._grant_loot(1, boss)
		for item: Dictionary in sim.get("ground_items") as Array:
			var item_id := String(item["item_id"])
			if item_id.begins_with("unica_"):
				if not slots.has(item_id.trim_prefix("unica_")):
					return _fail("Boss unique weapon must match one of the killer's gems")
				drops += 1
	if drops < 8 or drops > 40:
		return _fail("Boss unique weapon chance must be ~10%%, got %d in 200" % drops)
	print("UNIQUE_WEAPON_OK: %d unique weapons, gem-only buff, boss drop ~10%% and targeted" % uniques.size())
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
