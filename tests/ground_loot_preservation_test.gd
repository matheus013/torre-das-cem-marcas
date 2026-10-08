extends SceneTree

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var sim := Simulation.new()
	sim.setup(4242)
	sim.add_player(1)
	sim.add_player(2)
	sim.enter_tower(1)
	sim.enter_tower(2)
	var first := sim.player(1)
	var second := sim.player(2)
	first["position"] = Vector2(300, 300)
	second["position"] = Vector2(1000, 800)
	sim.drop_item(&"tower", first["position"], "reliquia_molde_sem_dono", 1, "masterwork")
	for index in range(178):
		sim.drop_item(&"tower", Vector2(600, 500), "reliquia_coracao_de_junta", 1)
	sim.drop_item(&"tower", second["position"], "reliquia_lastro_partido", 1, "refined")
	first["carried_loot"] = {"pedra_regenerativa": 225}
	first["carried_stone"] = 225
	if sim._drop_carried(1, &"tower", Vector2(450, 450)) != 225:
		return _fail("Lost cargo was not transferred to the ground")
	sim.drop_item(&"tower", Vector2(450, 450), "pedra_regenerativa", 20001)
	if sim.ground_items.size() <= 120:
		return _fail("Fixture must exceed the old destructive cap")
	var views := sim._drop_views()
	if views.size() != 120:
		return _fail("Snapshot exceeded its representation budget")
	var nearby_first := false
	var nearby_second := false
	for item: Dictionary in views:
		nearby_first = nearby_first or item["item_id"] == "reliquia_molde_sem_dono"
		nearby_second = nearby_second or item["item_id"] == "reliquia_lastro_partido"
	if not nearby_first or not nearby_second:
		return _fail("Nearest loot must remain visible for both separated allies")
	if views != sim._drop_views():
		return _fail("Unchanged state must select deterministic drop views")
	sim.drop_item(&"boss_room", Vector2(600, 500), "reliquia_lastro_partido", 1, "masterwork")
	var active_floor := sim.current_floor
	sim.current_floor = active_floor + 1
	sim.drop_item(&"tower", Vector2(600, 500), "pedra_regenerativa", 7)
	sim.current_floor = active_floor
	var expected := _totals(sim)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(sim.save_data(1)))
	var restored := Simulation.new()
	restored.setup(4242)
	restored.add_player(1)
	if not restored.load_data(saved, 1) or _totals(restored) != expected:
		return _fail("JSON save/reload lost quantity, quality, zone or floor")
	var state := restored.player(1)
	# Collect even entries omitted from the snapshot; no ledger entry may be stranded.
	for item: Dictionary in restored.ground_items.duplicate():
		state["zone"] = item["zone"]
		state["position"] = item["position"]
		restored.current_floor = int(item["floor"])
		restored._collect_ground_items(1)
	if not restored.ground_items.is_empty():
		return _fail("Hidden drops could not be recovered")
	var carried := (state["carried_loot"] as Dictionary).duplicate()
	# Materiais ficam na carga; relíquias e outros equipamentos só na mochila (conferidos abaixo).
	if int(carried.get("pedra_regenerativa", 0)) != 20233 or carried.has("reliquia_coracao_de_junta") or carried.has("reliquia_molde_sem_dono") or carried.has("reliquia_lastro_partido"):
		return _fail("Recovery did not conserve the full loot ledger: %s" % [carried])
	var gear: Dictionary = restored.save_data(1)["character_gear"][String(state["character_id"])]
	var recovered := 0
	var masterwork := 0
	var refined := 0
	for item: Dictionary in gear["items"]:
		if String(item["definition_id"]).begins_with("reliquia_"):
			recovered += 1
			masterwork += int(item["quality"] == "masterwork")
			refined += int(item["quality"] == "refined")
	if recovered != 181 or masterwork != 2 or refined != 1:
		return _fail("Relic instances or fabrication quality were lost during recovery")
	restored._collect_ground_items(1)
	if state["carried_loot"] != carried:
		return _fail("Repeated pickup duplicated loot")
	print("GROUND_LOOT_OK: bounded fair snapshots, full ledger, lost cargo, relics, large stacks and JSON reload recovery")
	quit(0)


func _totals(sim: RefCounted) -> Dictionary:
	var result := {}
	for item: Dictionary in sim.get("ground_items"):
		var key := "%s/%d/%s/%s" % [item["zone"], item["floor"], item["item_id"], item["quality"]]
		result[key] = int(result.get(key, 0)) + int(item["quantity"])
	return result


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
