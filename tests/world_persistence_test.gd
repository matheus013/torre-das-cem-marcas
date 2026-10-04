extends SceneTree

const PATH := "user://aresta_world_persistence_test.json"
const Store := preload("res://src/core/persistence/json_store.gd")
const Schema := preload("res://src/core/persistence/world_save_schema.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_clean()
	var scene := (load("res://src/prototype/village/village_exploration.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	var sim: RefCounted = scene.get("_sim")
	sim.set("banked_stone", 42)
	if not scene.call("_save_world", PATH):
		return _fail("Scene could not save")
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	sim.set("banked_stone", 0)
	if not scene.call("_load_world", PATH) or sim.get("banked_stone") != 42 or not String(scene.get("_status")).contains("backup"):
		return _fail("Scene did not restore backup or display recovery warning")
	if FileAccess.get_file_as_string(PATH) != "{broken":
		return _fail("Scene changed corrupt save during recovery")
	var before: Dictionary = sim.call("save_data", 1)
	DirAccess.remove_absolute(PATH + ".bak")
	if scene.call("_load_world", PATH) or sim.call("save_data", 1) != before:
		return _fail("Unrecoverable save mutated live world")
	scene.set("_sim", null)
	if scene.call("_save_world", PATH) or scene.call("_load_world", PATH):
		return _fail("Client accessed authoritative world save")
	scene.set("_sim", sim)
	if Schema.validate_records({"1": {"solo": [{"time": 3.0, "characters": ["Eloa"], "date": "2026-10-03"}]}}) != OK or Schema.validate_records({"1": []}) == OK or Schema.validate_records({"1": {"solo": [{}]}}) == OK:
		return _fail("Records validator did not protect record readers")
	scene.queue_free()
	await process_frame
	_clean()
	print("WORLD_PERSISTENCE_OK: scene recovery warning, unchanged files/world, host ownership and records validation")
	quit(0)


func _clean() -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(PATH + suffix)


func _fail(message: String) -> void:
	_clean()
	push_error(message)
	quit(1)
