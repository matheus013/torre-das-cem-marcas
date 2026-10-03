class_name ProfileIdentity
extends RefCounted

## Identidade local estável do jogador, usada pelo host para devolver a personagem reservada
## numa reconexão (o peer_id do ENet muda a cada conexão). `--profile=NOME` substitui o valor
## salvo, o que permite vários clientes na mesma máquina.

const PATH := "user://aresta_profile.cfg"


static func id() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--profile="):
			return arg.trim_prefix("--profile=")
	var config := ConfigFile.new()
	if config.load(PATH) == OK and config.has_section_key("profile", "id"):
		return String(config.get_value("profile", "id"))
	var random := RandomNumberGenerator.new()
	random.randomize()
	var generated := "%08x%08x" % [random.randi(), random.randi()]
	config.set_value("profile", "id", generated)
	config.save(PATH)
	return generated
