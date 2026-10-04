extends SceneTree

const Store := preload("res://src/core/persistence/json_store.gd")
const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const PATH := "user://aresta_atomic_test.json"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_clean()
	if Store.read(PATH)["error"] != ERR_FILE_NOT_FOUND:
		return _fail("Missing save was not reported")
	if Store.write(PATH, {"value": 1}) != OK or Store.write(PATH, {"value": 2}) != OK:
		return _fail("Atomic writes failed")
	if Store.read(PATH)["data"].get("value") != 2 or Store.read(PATH + ".bak")["data"].get("value") != 1:
		return _fail("Backup did not retain the previous successful save")
	_raw(PATH + ".tmp", "{\"value\":999}")
	if Store.read(PATH)["data"].get("value") != 2:
		return _fail("Interrupted write was promoted without committing")
	_raw(PATH, "{\"value\":")
	var recovered := Store.read(PATH)
	if not recovered["recovered"] or recovered["data"].get("value") != 1:
		return _fail("Truncated save did not recover from backup")
	if FileAccess.get_file_as_string(PATH) != "{\"value\":":
		return _fail("Recovery overwrote corrupt-file evidence")
	if Store.write(PATH, {"value": 3}) != OK or Store.read(PATH + ".bak")["data"].get("value") != 1:
		return _fail("Corrupt primary replaced a good backup")
	DirAccess.remove_absolute(PATH)
	if not Store.read(PATH)["recovered"]:
		return _fail("Missing primary did not recover")
	_raw(PATH, "[]")
	_raw(PATH + ".bak", "null")
	if Store.read(PATH)["error"] != ERR_FILE_CORRUPT:
		return _fail("Invalid roots were accepted")
	_clean()
	Store.write(PATH, {"value": 4})
	var original := FileAccess.get_file_as_string(PATH)
	DirAccess.make_dir_absolute(PATH + ".tmp")
	if Store.write(PATH, {"value": 5}) == OK or FileAccess.get_file_as_string(PATH) != original:
		return _fail("Failed temporary write changed the primary")
	DirAccess.remove_absolute(PATH + ".tmp")
	DirAccess.make_dir_absolute(PATH + ".bak.tmp")
	if Store.write(PATH, {"value": 5}) == OK or FileAccess.get_file_as_string(PATH) != original:
		return _fail("Failed backup write changed the primary")
	DirAccess.remove_absolute(PATH + ".bak.tmp")
	_clean()
	DirAccess.make_dir_absolute(PATH)
	if Store.write(PATH, {"value": 6}) == OK or not DirAccess.dir_exists_absolute(PATH):
		return _fail("Destination directory was replaced by a save")
	_clean()

	var sim := Simulation.new()
	sim.setup(7301)
	sim.add_player(1)
	sim.add_player(2)
	var save: Dictionary = sim.save_data(1)
	if Store.write(PATH, save, Simulation.validate_save) != OK:
		return _fail("Current world save was rejected")
	var future := save.duplicate(true)
	future["version"] = Simulation.SAVE_VERSION + 1
	_raw(PATH, JSON.stringify(future))
	if Store.read(PATH, Simulation.validate_save)["error"] != ERR_UNAVAILABLE:
		return _fail("Newer save silently rolled back to an older backup")
	if Store.write(PATH, save, Simulation.validate_save) != ERR_UNAVAILABLE or FileAccess.get_file_as_string(PATH) != JSON.stringify(future):
		return _fail("An older build overwrote a newer save")
	var invalid := save.duplicate(true)
	invalid["character_gems"]["eloa"]["gems"]["lamina_curta"] = {"choices": []}
	invalid["character_progress"]["eloa"] = []
	var before := sim.save_data(1)
	if sim.load_data(invalid, 1) or sim.save_data(1) != before or sim.player(2).is_empty():
		return _fail("Invalid structure mutated live world or co-op peers")
	_raw(PATH, JSON.stringify(invalid))
	if not Store.read(PATH, Simulation.validate_save)["recovered"]:
		return _fail("Valid JSON with invalid structure did not recover")
	for version in range(1, Simulation.SAVE_VERSION + 1):
		var legacy := save.duplicate(true)
		legacy["version"] = version
		if not sim.load_data(legacy, 1):
			return _fail("Supported version was rejected")
	_clean()
	print("JSON_STORE_OK: rotation, recovery, interrupted writes, write failures, version protection and non-destructive validation")
	quit(0)


func _raw(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()


func _clean() -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(PATH + suffix)


func _fail(message: String) -> void:
	_clean()
	push_error(message)
	quit(1)
