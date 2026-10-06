extends SceneTree

## Regressão (2026-10-06): lendários caíam mais que raros (1 a 2 por 100 abates), quase todos
## armas únicas a 1% em comuns e 5% em elites. Lendários precisam ser raros de verdade.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for floor_number in [20, 60]:
		var kills := 0
		var counts := {}
		for seed_index in range(6):
			var sim := Simulation.new()
			sim.setup(floor_number * 13 + seed_index)
			sim.add_player(1, &"eloa")
			sim.unlock_all_gems(1, true)
			sim.set("deepest_floor", floor_number)
			sim.set("tower_start_floor", floor_number)
			sim.enter_tower(1)
			for enemy: Dictionary in (sim.enemies as Array).duplicate():
				if bool(enemy.get("floor_boss", false)):
					continue
				var before := sim.ground_items.size()
				sim._grant_loot(1, enemy)
				kills += 1
				for item: Dictionary in sim.ground_items.slice(before):
					var data := sim.item_data(String(item["item_id"]))
					if String(data.get("slot", "none")) != "none":
						counts[data["tier"]] = int(counts.get(data["tier"], 0)) + 1
		var legendary := float(counts.get("legendary", 0)) * 100.0 / float(kills)
		var rare := float(counts.get("rare", 0)) * 100.0 / float(kills)
		if legendary > 0.3 or legendary >= rare:
			return _fail("Floor %d: %.2f legendaries per 100 kills (rare %.2f); legendaries must be rare" % [floor_number, legendary, rare])
	print("LEGENDARY_DROP_RATE_OK: legendaries stay under 0.3 per 100 kills and below rares")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
