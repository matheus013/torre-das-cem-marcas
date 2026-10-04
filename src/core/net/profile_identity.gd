class_name ProfileIdentity
extends RefCounted

## Identidade local estável do jogador, usada pelo host para devolver a personagem reservada
## numa reconexão (o peer_id do ENet muda a cada conexão). `--profile=NOME` substitui o valor
## salvo, o que permite vários clientes na mesma máquina.

const PATH := "user://aresta_profile.cfg"
const ConfigStore := preload("res://src/core/persistence/config_store.gd")
static var _session_ids: Dictionary = {}


static func id(path: String = PATH) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--profile="):
			return arg.trim_prefix("--profile=")
	var result := ConfigStore.read(path, _validate)
	var config: ConfigFile = result["config"]
	if result["error"] == OK:
		return String(config.get_value("profile", "id"))
	if _session_ids.has(path):
		return _session_ids[path]
	var random := RandomNumberGenerator.new()
	random.randomize()
	var generated := "%08x%08x" % [random.randi(), random.randi()]
	var error: Error = result["error"]
	if error == ERR_FILE_NOT_FOUND:
		error = ConfigStore.update(path, {"profile": {"id": generated}}, _validate)
	if error != OK:
		_session_ids[path] = generated
		push_warning("Identidade temporaria nesta sessao (%d); perfil anterior preservado." % error)
	return generated


static func _validate(config: ConfigFile) -> Error:
	if not config.has_section_key("profile", "id"):
		return ERR_FILE_CORRUPT
	var value: Variant = config.get_value("profile", "id")
	if not value is String or String(value).strip_edges().is_empty():
		return ERR_FILE_CORRUPT
	return OK
