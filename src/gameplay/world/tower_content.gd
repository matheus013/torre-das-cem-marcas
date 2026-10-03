class_name TowerContent
extends RefCounted

## Conteúdo da Torre (`data/tower/tower_content.json`, gerado por tools/content/build_tower.py):
## biomas, cem andares, chefes, inimigos e materiais por bioma. Lido uma vez e compartilhado.

const PATH := "res://data/tower/tower_content.json"
const MAX_FLOOR := 100

static var _data: Dictionary = {}
static var _floors: Dictionary = {}
static var _biomes: Dictionary = {}
static var _bosses: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed as Dictionary if parsed is Dictionary else {}
		for entry: Dictionary in _data.get("floors", []) as Array:
			_floors[int(entry["floor"])] = entry
		for entry: Dictionary in _data.get("biomes", []) as Array:
			_biomes[String(entry["id"])] = entry
		for entry: Dictionary in _data.get("bosses", []) as Array:
			_bosses[String(entry["id"])] = entry
	return _data


static func floor_def(number: int) -> Dictionary:
	data()
	return _floors.get(clampi(number, 1, MAX_FLOOR), {}) as Dictionary


static func biome(biome_id: String) -> Dictionary:
	data()
	return _biomes.get(biome_id, {}) as Dictionary


static func boss(boss_id: String) -> Dictionary:
	data()
	return _bosses.get(boss_id, {}) as Dictionary


static func collection(key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Variant in data().get(key, []) as Array:
		if entry is Dictionary:
			result.append(entry as Dictionary)
	return result


static func party_abilities(party_size: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var table := data().get("party_abilities", {}) as Dictionary
	for size in range(2, party_size + 1):
		for entry: Variant in table.get(str(size), []) as Array:
			result.append((entry as Dictionary).duplicate(true))
	return result


## Andares em que cada região começa e andares de chefe, usados pelo mapa da Torre.
static func region_starts() -> Array[int]:
	var result: Array[int] = []
	for entry: Dictionary in data().get("biomes", []) as Array:
		result.append(int((entry["floors"] as Array)[0]))
	return result
