class_name SessionLaunch
extends RefCounted

## Pedido de sessão feito por um menu antes de abrir Aresta: solo, hospedar ou entrar.

const DEFAULT_PORT := 7777

static var mode: StringName = &"solo"
static var address := "127.0.0.1"
static var port := DEFAULT_PORT


static func request(new_mode: StringName, new_address: String = "127.0.0.1", new_port: int = DEFAULT_PORT) -> void:
	mode = new_mode
	address = new_address
	port = new_port


## Lê e limpa o pedido. Argumentos de linha de comando têm prioridade para testes e servidores.
static func consume() -> Dictionary:
	var result := {"mode": mode, "address": address, "port": port}
	for arg in OS.get_cmdline_user_args():
		if arg == "--host-session":
			result["mode"] = &"host"
		elif arg.begins_with("--join-session="):
			result["mode"] = &"client"
			result["address"] = arg.trim_prefix("--join-session=")
		elif arg.begins_with("--session-port="):
			result["port"] = int(arg.trim_prefix("--session-port="))
	mode = &"solo"
	return result
