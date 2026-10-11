extends RefCounted

## Paragon do jogador (decisão 607): fica no perfil local, fora do save do mundo, e vai junto quando o
## jogador entra no mundo de outro host. Gravação atômica; arquivo inválido volta ao vazio sem apagar.

const JsonStoreScript := preload("res://src/core/persistence/json_store.gd")
const ParagonScript := preload("res://src/gameplay/progression/paragon.gd")
const DEFAULT_PATH := "user://aresta_paragon.json"

static var path := DEFAULT_PATH


static func load_data() -> Dictionary:
	var result := JsonStoreScript.read(path)
	if result["error"] != OK:
		return ParagonScript.empty()
	return ParagonScript.sanitize(result["data"])


static func save_data(data: Dictionary) -> Error:
	return JsonStoreScript.write(path, ParagonScript.sanitize(data))
