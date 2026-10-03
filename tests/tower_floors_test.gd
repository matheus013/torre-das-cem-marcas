extends SceneTree

## Torre de cem andares (decisão 553): biomas pela divisão do documento 05, chefe por Limiar,
## andares comuns grandes, arenas pequenas, habilidades em área, perigos de bioma, patrulha,
## respawn acelerado e recordes separados por solo, duo, trio e squad.

const SimulationScript := preload("res://src/gameplay/world/world_simulation.gd")
const TowerContentScript := preload("res://src/gameplay/world/tower_content.gd")
const FloorLayoutScript := preload("res://src/gameplay/world/floor_layout.gd")
const BOSS_FLOORS: Array[int] = [4, 7, 16, 27, 39, 51, 63, 72, 81, 93, 100]
const REGIONS := {"galerias": [1, 7], "bosque": [8, 16], "manto": [17, 27], "bacias": [28, 39], "ermo": [40, 51],
	"arquivo": [52, 63], "planicie": [64, 72], "eixos": [73, 81], "campos": [82, 93], "obra": [94, 100]}


func _init() -> void:
	_run()


func _run() -> void:
	for number in range(1, 101):
		var definition := TowerContentScript.floor_def(number)
		var biome := String(definition.get("biome", ""))
		var span := REGIONS.get(biome, [0, 0]) as Array
		if number < int(span[0]) or number > int(span[1]):
			return _fail("Floor %d is outside its region biome %s" % [number, biome])
		var boss := String(definition.get("kind", "")) == "boss"
		if boss != (number in BOSS_FLOORS):
			return _fail("Floor %d has the wrong kind" % number)
		var layout := FloorLayoutScript.generate(number)
		var size := layout["size"] as Vector2
		if boss and (size.x > 1600.0 or not layout.has("arena_radius")):
			return _fail("Boss floor %d must be a small arena" % number)
		if not boss and (size.x < 3200.0 or (layout["spawn_points"] as Array).size() < 15):
			return _fail("Explore floor %d must be large with many patrol points" % number)
		if not FloorLayoutScript.can_stand(layout, layout["entry"] as Vector2, 14.0):
			return _fail("Floor %d entry is blocked" % number)
	for biome_id: String in REGIONS:
		var bosses := 0
		for entry in TowerContentScript.collection("bosses"):
			if String(entry["biome"]) == biome_id:
				bosses += 1
		if bosses < 1:
			return _fail("Biome %s needs a boss" % biome_id)

	# Cada chefe lança habilidades em área; com quatro jogadores ganha combinações extras.
	for boss_floor in BOSS_FLOORS:
		var sim := _sim_at(boss_floor, 1)
		var shapes := _fight(sim, 900)
		if shapes.is_empty():
			return _fail("Boss of floor %d never telegraphed an area ability" % boss_floor)
	var squad := _sim_at(16, 4)
	var squad_casts := _count_casts(squad, 1200)
	var solo := _sim_at(16, 1)
	var solo_casts := _count_casts(solo, 1200)
	if squad_casts <= solo_casts:
		return _fail("Bosses must add party abilities for larger groups (%d vs %d)" % [squad_casts, solo_casts])

	# Perigo de bioma e patrulha num andar comum.
	var explore := _sim_at(9, 1)
	var hazard_seen := false
	var watched := (explore.get("enemies") as Array)[0] as Dictionary
	var start := watched["position"] as Vector2
	for _frame in range(900):
		(explore.call("player", 1) as Dictionary)["health"] = 1.0e6
		explore.call("step", 1.0 / 60.0)
		for telegraph: Dictionary in explore.get("telegraphs"):
			hazard_seen = hazard_seen or String(telegraph.get("source", "")) == "hazard"
	if not hazard_seen:
		return _fail("Explore floors must cast their biome hazard")
	if (watched["position"] as Vector2).distance_to(start) < 5.0:
		return _fail("Idle monsters must walk around their territory")

	# Recordes separados por modo.
	var duo := _sim_at(9, 2)
	var run := duo.get("floor_run") as Dictionary
	run["kills"] = int(run["quota"])
	run["stairs_open"] = true
	run["time"] = 42.5
	duo.call("descend", 1)
	if float(duo.call("best_time", 9, "duo")) != 42.5 or float(duo.call("best_time", 9, "solo")) >= 0.0:
		return _fail("Records must be stored per party mode")
	if int(duo.get("current_floor")) != 10:
		return _fail("Descending must take the party to the next floor")
	print("TOWER_FLOORS_OK: 100 floors in 10 biomes, 11 bosses with area kits, hazards, patrol and records per mode")
	quit(0)


func _sim_at(number: int, players: int) -> RefCounted:
	var sim: RefCounted = SimulationScript.new()
	sim.call("setup", number * 13)
	for peer_id in range(1, players + 1):
		sim.call("add_player", peer_id)
	sim.set("deepest_floor", number)
	sim.set("tower_start_floor", number)
	for peer_id in range(1, players + 1):
		sim.call("enter_tower", peer_id)
	return sim


func _fight(sim: RefCounted, frames: int) -> Dictionary:
	var shapes := {}
	for _frame in range(frames):
		for state: Dictionary in (sim.get("players") as Dictionary).values():
			state["health"] = 1.0e6
		sim.call("step", 1.0 / 60.0)
		for telegraph: Dictionary in sim.get("telegraphs"):
			shapes[String(telegraph["shape"])] = true
	return shapes


func _count_casts(sim: RefCounted, frames: int) -> int:
	var seen := 0
	var previous := 0
	for _frame in range(frames):
		for state: Dictionary in (sim.get("players") as Dictionary).values():
			state["health"] = 1.0e6
		sim.call("step", 1.0 / 60.0)
		var now := (sim.get("telegraphs") as Array).size()
		if now > previous:
			seen += now - previous
		previous = now
	return seen


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
