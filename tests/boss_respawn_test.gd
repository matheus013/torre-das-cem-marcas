extends SceneTree

## Decisão 587: chefes não têm recarga. Vencido, o guardião volta sempre que o grupo entra de novo
## no andar, inclusive ao carregar saves antigos que ainda traziam "boss_cooldowns".

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _boss(sim: WorldSimulation) -> int:
	for index in range(sim.enemies.size()):
		if bool(sim.enemies[index].get("floor_boss", false)):
			return index
	return -1


func _run() -> void:
	var sim := Simulation.new()
	sim.setup(5870)
	sim.add_player(1, &"rui")
	sim.set("deepest_floor", 4)
	sim.set("tower_start_floor", 4)
	sim.enter_tower(1)
	if _boss(sim) < 0:
		return _fail("Floor 4 must spawn its boss")
	sim.damage_enemy(1, _boss(sim), 1.0e9)
	if _boss(sim) >= 0 or not bool(sim.floor_run["stairs_open"]):
		return _fail("Boss victory opens the stairs")
	sim.leave_tower(1)
	sim.set("tower_start_floor", 4)
	sim.enter_tower(1)
	if _boss(sim) < 0 or bool(sim.floor_run["stairs_open"]):
		return _fail("Defeated boss must be back right away when the floor is entered again")

	var data := sim.save_data(1)
	data["boss_cooldowns"] = {"4": 1200.0}
	data["current_floor"] = 0
	var restored := Simulation.new()
	restored.setup(5870)
	restored.add_player(1, &"rui")
	if not restored.load_data(data, 1):
		return _fail("Old saves with boss cooldowns must still load")
	restored.set("tower_start_floor", 4)
	restored.enter_tower(1)
	if _boss(restored) < 0:
		return _fail("Old boss cooldowns are ignored: the boss is there")
	print("BOSS_RESPAWN_OK: no boss cooldown, boss back on re-entry, old saved cooldowns ignored")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
