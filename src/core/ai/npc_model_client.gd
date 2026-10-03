class_name NpcModelClient
extends Node

## Cliente HTTP do modo "com IA" dos moradores (decisão 560). Roda só no host. Recebe pedidos de
## VillageLife (prompt e ações válidas), consulta o provedor configurado e devolve `{acao, fala}`.
## Respostas inválidas ou atrasadas são descartadas; VillageLife já tem a decisão padrão de reserva.

signal answered(request_id: int, action_id: String, speech: String)
signal failed(request_id: int, reason: String)

const NpcAiConfigScript := preload("res://src/core/ai/npc_ai_config.gd")

var settings: Dictionary = {}
var answered_count := 0
var failed_count := 0
var last_error := ""
var _queue: Array[Dictionary] = []
var _active := 0


func configure(new_settings: Dictionary) -> void:
	settings = new_settings.duplicate()


func enqueue(request: Dictionary) -> void:
	_queue.append(request)
	_pump()


func pending() -> int:
	return _queue.size() + _active


func _pump() -> void:
	while _active < int(settings.get("max_concurrent", 2)) and not _queue.is_empty():
		_send(_queue.pop_front())


func _send(request: Dictionary) -> void:
	var http := HTTPRequest.new()
	http.timeout = float(settings.get("timeout", 8.0))
	add_child(http)
	_active += 1
	var built := build_http(settings, String(request["system"]), String(request["user"]))
	http.request_completed.connect(_on_completed.bind(http, int(request["id"])))
	var error := http.request(String(built["url"]), built["headers"] as PackedStringArray, HTTPClient.METHOD_POST, JSON.stringify(built["body"]))
	if error != OK:
		_finish(http, int(request["id"]), "", "falha ao enviar: %s" % error_string(error))


func _on_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest, request_id: int) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
		_finish(http, request_id, "", "resposta HTTP %d (resultado %d)" % [code, result])
		return
	_finish(http, request_id, body.get_string_from_utf8(), "")


func _finish(http: HTTPRequest, request_id: int, raw: String, error: String) -> void:
	_active -= 1
	http.queue_free()
	if error.is_empty():
		var parsed := parse_reply(String(settings.get("provider", "ollama")), raw)
		if parsed.is_empty():
			error = "resposta sem JSON valido"
		else:
			answered_count += 1
			answered.emit(request_id, String(parsed["acao"]), String(parsed.get("fala", "")))
	if not error.is_empty():
		failed_count += 1
		last_error = error
		failed.emit(request_id, error)
	_pump()


## Monta URL, cabeçalhos e corpo para o provedor escolhido.
static func build_http(config: Dictionary, system: String, user: String) -> Dictionary:
	var base := String(config.get("url", "")).trim_suffix("/")
	var model := String(config.get("model", ""))
	var temperature := float(config.get("temperature", 0.7))
	var key := NpcAiConfigScript.api_key(config)
	match String(config.get("provider", "ollama")):
		"anthropic":
			return {
				"url": base + "/v1/messages",
				"headers": PackedStringArray(["Content-Type: application/json", "x-api-key: " + key, "anthropic-version: 2023-06-01"]),
				"body": {"model": model, "max_tokens": 200, "temperature": temperature, "system": system, "messages": [{"role": "user", "content": user}]},
			}
		"openai":
			var headers := PackedStringArray(["Content-Type: application/json"])
			if not key.is_empty():
				headers.append("Authorization: Bearer " + key)
			return {
				"url": base + "/v1/chat/completions",
				"headers": headers,
				"body": {"model": model, "temperature": temperature, "max_tokens": 200, "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}]},
			}
		_:
			return {
				"url": base + "/api/chat",
				"headers": PackedStringArray(["Content-Type: application/json"]),
				"body": {"model": model, "stream": false, "format": "json", "options": {"temperature": temperature}, "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}]},
			}


## Extrai `{acao, fala}` do texto devolvido por qualquer provedor (tolera texto em volta do JSON).
static func parse_reply(provider: String, raw: String) -> Dictionary:
	var envelope: Variant = JSON.parse_string(raw)
	var text := raw
	if envelope is Dictionary:
		var data := envelope as Dictionary
		match provider:
			"anthropic":
				var blocks := data.get("content", []) as Array
				text = String((blocks[0] as Dictionary).get("text", "")) if not blocks.is_empty() and blocks[0] is Dictionary else ""
			"openai":
				var choices := data.get("choices", []) as Array
				text = String(((choices[0] as Dictionary).get("message", {}) as Dictionary).get("content", "")) if not choices.is_empty() else ""
			_:
				text = String((data.get("message", {}) as Dictionary).get("content", data.get("response", "")))
	var start := text.find("{")
	var end := text.rfind("}")
	if start < 0 or end <= start:
		return {}
	var reply: Variant = JSON.parse_string(text.substr(start, end - start + 1))
	if not reply is Dictionary or not (reply as Dictionary).has("acao"):
		return {}
	return {"acao": String((reply as Dictionary)["acao"]), "fala": String((reply as Dictionary).get("fala", ""))}
