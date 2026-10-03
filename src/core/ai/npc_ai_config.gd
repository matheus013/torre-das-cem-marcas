class_name NpcAiConfig
extends RefCounted

## Configuração dos moradores (decisão 560). Modo "padrao" usa só a Utility AI; modo "ia" consulta
## um modelo de linguagem. Fontes, da menor para a maior prioridade: padrões abaixo,
## `user://aresta_npc_ai.cfg`, variáveis de ambiente `ARESTA_NPC_*` e argumentos `--npc-*`.
## A chave de API nunca é gravada: o arquivo guarda apenas o nome da variável de ambiente.

const PATH := "user://aresta_npc_ai.cfg"
const MODES: Array[String] = ["padrao", "ia"]
const PROVIDERS: Array[String] = ["ollama", "openai", "anthropic"]
const DEFAULTS := {
	"mode": "padrao",
	"provider": "ollama",
	"url": "http://127.0.0.1:11434",
	"model": "qwen2.5:3b",
	"api_key_env": "",
	"timeout": 8.0,
	"max_concurrent": 2,
	"temperature": 0.7,
}
const PROVIDER_DEFAULTS := {
	"ollama": {"url": "http://127.0.0.1:11434", "model": "qwen2.5:3b", "api_key_env": ""},
	"openai": {"url": "http://127.0.0.1:1234", "model": "local-model", "api_key_env": "OPENAI_API_KEY"},
	"anthropic": {"url": "https://api.anthropic.com", "model": "claude-haiku-4-5-20251001", "api_key_env": "ANTHROPIC_API_KEY"},
}


static func load_settings() -> Dictionary:
	var settings := DEFAULTS.duplicate()
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		for key: String in DEFAULTS:
			if config.has_section_key("npc_ai", key):
				settings[key] = config.get_value("npc_ai", key)
	for key: String in DEFAULTS:
		var env := OS.get_environment("ARESTA_NPC_" + key.to_upper())
		if not env.is_empty():
			settings[key] = env
	for arg in OS.get_cmdline_user_args():
		for key: String in DEFAULTS:
			var prefix := "--npc-%s=" % key.replace("_", "-")
			if arg.begins_with(prefix):
				settings[key] = arg.trim_prefix(prefix)
	return _sanitize(settings)


static func save_settings(settings: Dictionary) -> void:
	var config := ConfigFile.new()
	config.load(PATH)
	var clean := _sanitize(settings)
	for key: String in DEFAULTS:
		config.set_value("npc_ai", key, clean[key])
	config.save(PATH)


static func api_key(settings: Dictionary) -> String:
	var variable := String(settings.get("api_key_env", ""))
	return OS.get_environment(variable) if not variable.is_empty() else ""


static func _sanitize(settings: Dictionary) -> Dictionary:
	var result := settings.duplicate()
	if String(result["mode"]) not in MODES:
		result["mode"] = "padrao"
	if String(result["provider"]) not in PROVIDERS:
		result["provider"] = "ollama"
	result["url"] = String(result["url"]).strip_edges().trim_suffix("/")
	result["model"] = String(result["model"]).strip_edges()
	result["api_key_env"] = String(result["api_key_env"]).strip_edges()
	result["timeout"] = clampf(float(result["timeout"]), 2.0, 30.0)
	result["max_concurrent"] = clampi(int(result["max_concurrent"]), 1, 6)
	result["temperature"] = clampf(float(result["temperature"]), 0.0, 1.5)
	return result
