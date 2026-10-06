class_name SaveSlot
extends RefCounted

## Vaga única do mundo salvo (decisão 582): salvamento manual, automático e o CONTINUAR da tela
## inicial usam o mesmo arquivo. `path` é variável para que testes nunca toquem no save real.

const JsonStoreScript := preload("res://src/core/persistence/json_store.gd")
const SimulationScript := preload("res://src/gameplay/world/world_simulation.gd")
const DEFAULT_PATH := "user://aresta_prototype_save.json"

static var path := DEFAULT_PATH


## Há save legível (o arquivo ou o backup que a gravação atômica mantém).
static func exists() -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")


## Resumo para o botão CONTINUAR: personagem, nível, andar mais fundo e quando foi salvo.
## Vazio se não houver save válido.
static func summary() -> Dictionary:
	if not exists():
		return {}
	var result := JsonStoreScript.read(path, SimulationScript.validate_save)
	if result["error"] != OK:
		return {}
	var data := result["data"] as Dictionary
	var character := String(data.get("character_id", ""))
	var build := ((data.get("character_progress", {}) as Dictionary).get(character, {}) as Dictionary).get("build", {}) as Dictionary
	var file := path if FileAccess.file_exists(path) else path + ".bak"
	return {
		"character_id": character,
		"level": int(build.get("level", 1)),
		"deepest_floor": int(data.get("deepest_floor", 1)),
		"saved_at": FileAccess.get_modified_time(file),
	}
