extends SceneTree

## Moradores (decisão 560): modo padrão determinístico e modo com IA contra um servidor falso no
## formato do Ollama. Valida aceitação só de ações listadas, recusa de ação inventada, queda para
## o padrão por tempo esgotado e leitura das respostas OpenAI e Anthropic.

const SimulationScript := preload("res://src/gameplay/world/world_simulation.gd")
const ClientScript := preload("res://src/core/ai/npc_model_client.gd")
const PORT := 18432

var _server := TCPServer.new()
var _reply_action := "responder"
var _connections: Array[StreamPeerTCP] = []
var _received_prompt := ""


func _init() -> void:
	_run()


func _run() -> void:
	# Modo padrão: rotina andando e conversa respondida na hora com fala autoral.
	var sim: RefCounted = SimulationScript.new()
	sim.call("setup", 9)
	sim.call("add_player", 1)
	var life := sim.get("village_life") as RefCounted
	if (life.get("npcs") as Array).size() < 20:
		return _fail("Aresta needs a living population")
	for _frame in range(900):
		sim.call("step", 1.0 / 60.0)
	var moved := 0
	for npc: Dictionary in life.get("npcs"):
		if (npc["position"] as Vector2).distance_to(npc["work"] as Vector2) > 60.0 or bool(npc["moving"]):
			moved += 1
	if moved < 5:
		return _fail("Villagers must follow routines around the village (%d moved)" % moved)
	var nara := life.call("find", "nara_quiral") as Dictionary
	(sim.call("player", 1) as Dictionary)["position"] = nara["position"]
	if not bool(sim.call("talk_to_npc", 1, "nara_quiral")) or String(nara["speech"]).is_empty():
		return _fail("Default mode must answer a conversation immediately")

	# Modo com IA contra o servidor falso.
	if _server.listen(PORT, "127.0.0.1") != OK:
		return _fail("Mock model server could not listen")
	life.set("mode", "ia")
	var client: Node = ClientScript.new()
	root.add_child(client)
	await process_frame
	client.call("configure", {"provider": "ollama", "url": "http://127.0.0.1:%d" % PORT, "model": "teste", "timeout": 5.0, "max_concurrent": 2, "temperature": 0.5})
	client.connect("answered", func(request_id: int, action_id: String, speech: String) -> void: sim.call("resolve_npc_request", request_id, action_id, speech))
	nara["pending"] = 0
	sim.call("talk_to_npc", 1, "nara_quiral")
	for request: Dictionary in life.call("drain_requests"):
		client.call("enqueue", request)
	if not await _wait_for(func() -> bool: return String(nara["speech"]) == "Bom ver voce de volta, Eloa."):
		return _fail("Model reply was not applied (speech: %s)" % nara["speech"])
	var last := (life.get("log") as Array).back() as Dictionary
	if String(last["source"]) != "modelo" or not _received_prompt.contains("Acoes possiveis") or not _received_prompt.contains("responder"):
		return _fail("Model prompt or log source is wrong")

	_reply_action = "voar_para_a_lua"
	nara["pending"] = 0
	sim.call("talk_to_npc", 1, "nara_quiral")
	for request: Dictionary in life.call("drain_requests"):
		client.call("enqueue", request)
	if not await _wait_for(func() -> bool: return int(nara["pending"]) == 0):
		return _fail("Invalid model reply was never resolved")
	if String(nara["speech"]).contains("lua") or String(nara["action"]) == "voar_para_a_lua":
		return _fail("Actions outside the list must be rejected")

	# Tempo esgotado: a decisão padrão assume.
	nara["pending"] = 0
	sim.call("talk_to_npc", 1, "nara_quiral")
	life.call("drain_requests")
	for request: Dictionary in (life.get("_requests") as Dictionary).values():
		request["deadline"] = 0.0
	sim.call("step", 0.1)
	if int(nara["pending"]) != 0 or String(nara["speech"]) == "...":
		return _fail("Timed out requests must fall back to the default mode")

	# Formatos dos outros provedores.
	var openai := ClientScript.parse_reply("openai", JSON.stringify({"choices": [{"message": {"content": "Claro: {\"acao\": \"noticia\", \"fala\": \"Andar 9!\"}"}}]}))
	var anthropic := ClientScript.parse_reply("anthropic", JSON.stringify({"content": [{"type": "text", "text": "{\"acao\": \"pedido\", \"fala\": \"Traga pedra.\"}"}]}))
	if String(openai.get("acao", "")) != "noticia" or String(anthropic.get("fala", "")) != "Traga pedra.":
		return _fail("Provider replies were not parsed")
	var built := ClientScript.build_http({"provider": "anthropic", "url": "https://api.anthropic.com", "model": "claude-haiku-4-5-20251001", "api_key_env": ""}, "s", "u")
	if String(built["url"]) != "https://api.anthropic.com/v1/messages" or not "anthropic-version: 2023-06-01" in (built["headers"] as PackedStringArray):
		return _fail("Anthropic request is malformed")
	_server.stop()
	print("NPC_AI_OK: routines, default answers, model replies, rejected actions, timeout fallback and providers")
	quit(0)


func _wait_for(condition: Callable) -> bool:
	for _frame in range(600):
		_serve()
		await process_frame
		if condition.call():
			return true
	return false


## Servidor HTTP mínimo: lê o pedido e responde no formato /api/chat do Ollama.
func _serve() -> void:
	while _server.is_connection_available():
		_connections.append(_server.take_connection())
	for index in range(_connections.size() - 1, -1, -1):
		var connection := _connections[index]
		connection.poll()
		var available := connection.get_available_bytes()
		if available <= 0:
			continue
		var raw := connection.get_utf8_string(available)
		if not raw.contains("\r\n\r\n"):
			continue
		_received_prompt = raw
		var content := JSON.stringify({"acao": _reply_action, "fala": "Bom ver voce de volta, Eloa."})
		var body := JSON.stringify({"message": {"role": "assistant", "content": content}, "done": true}).to_utf8_buffer()
		var header := "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % body.size()
		connection.put_data(header.to_utf8_buffer())
		connection.put_data(body)
		connection.disconnect_from_host()
		_connections.remove_at(index)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
