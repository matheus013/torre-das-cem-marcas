extends PanelContainer

## Configuração dos moradores (decisão 560): modo padrão ou com IA, provedor, endereço, modelo e o
## nome da variável de ambiente da chave. "Testar conexão" envia uma pergunta curta ao modelo.

const NpcAiConfigScript := preload("res://src/core/ai/npc_ai_config.gd")
const NpcModelClientScript := preload("res://src/core/ai/npc_model_client.gd")
const GOLD := Color("e8b84a")
const TEXT := Color("f2e6c9")

var _settings: Dictionary = {}
var _mode: OptionButton
var _provider: OptionButton
var _url: LineEdit
var _model: LineEdit
var _key_env: LineEdit
var _result: Label
var _client: Node


func _ready() -> void:
	name = "NpcAiPanel"
	custom_minimum_size = Vector2(520.0, 0.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b1a1ff2")
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_content_margin_all(16)
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	var title := Label.new()
	title.text = "MORADORES DE ARESTA"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", GOLD)
	column.add_child(title)
	var info := Label.new()
	info.text = "Padrao: decisoes da mente sistemica e falas autorais. Com IA: um modelo de linguagem escolhe entre as mesmas acoes validas e escreve a fala; se falhar, o padrao assume."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_color_override("font_color", TEXT)
	column.add_child(info)
	_mode = _option(column, "Modo", ["padrao", "ia"], ["Padrao", "Com IA"])
	_provider = _option(column, "Provedor", NpcAiConfigScript.PROVIDERS, ["Ollama", "Servidor compativel com OpenAI", "Anthropic"])
	_provider.item_selected.connect(_on_provider_selected)
	_url = _field(column, "Endereco")
	_model = _field(column, "Modelo")
	_key_env = _field(column, "Variavel da chave")
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	column.add_child(buttons)
	for spec: Array in [["Testar conexao", _test], ["Salvar", _save], ["Fechar", hide]]:
		var button := Button.new()
		button.text = spec[0]
		button.pressed.connect(spec[1])
		buttons.add_child(button)
	_result = Label.new()
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result.add_theme_color_override("font_color", TEXT)
	column.add_child(_result)
	_client = NpcModelClientScript.new()
	add_child(_client)
	_client.connect("answered", func(_id: int, action: String, speech: String) -> void: _result.text = "Modelo respondeu: %s — \"%s\"" % [action, speech])
	_client.connect("failed", func(_id: int, reason: String) -> void: _result.text = "Falhou: %s" % reason)
	_load()


func _option(parent: Control, label_text: String, ids: Array[String], labels: Array) -> OptionButton:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 150.0
	label.add_theme_color_override("font_color", TEXT)
	row.add_child(label)
	var option := OptionButton.new()
	for index in range(ids.size()):
		option.add_item(String(labels[index]), index)
		option.set_item_metadata(index, ids[index])
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(option)
	parent.add_child(row)
	return option


func _field(parent: Control, label_text: String) -> LineEdit:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 150.0
	label.add_theme_color_override("font_color", TEXT)
	row.add_child(label)
	var edit := LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(edit)
	parent.add_child(row)
	return edit


func _load() -> void:
	_settings = NpcAiConfigScript.load_settings()
	_mode.select(NpcAiConfigScript.MODES.find(String(_settings["mode"])))
	_provider.select(NpcAiConfigScript.PROVIDERS.find(String(_settings["provider"])))
	_url.text = String(_settings["url"])
	_model.text = String(_settings["model"])
	_key_env.text = String(_settings["api_key_env"])


func _on_provider_selected(index: int) -> void:
	var defaults := NpcAiConfigScript.PROVIDER_DEFAULTS[String(_provider.get_item_metadata(index))] as Dictionary
	_url.text = String(defaults["url"])
	_model.text = String(defaults["model"])
	_key_env.text = String(defaults["api_key_env"])


func _collect() -> Dictionary:
	var settings := _settings.duplicate()
	settings["mode"] = String(_mode.get_item_metadata(_mode.selected))
	settings["provider"] = String(_provider.get_item_metadata(_provider.selected))
	settings["url"] = _url.text
	settings["model"] = _model.text
	settings["api_key_env"] = _key_env.text
	return settings


func _save() -> void:
	NpcAiConfigScript.save_settings(_collect())
	_settings = NpcAiConfigScript.load_settings()
	_result.text = "Configuracao salva. Modo: %s." % ("com IA" if _settings["mode"] == "ia" else "padrao")


func _test() -> void:
	var settings := _collect()
	if not String(settings["api_key_env"]).is_empty() and NpcAiConfigScript.api_key(settings).is_empty():
		_result.text = "A variavel %s nao esta definida neste ambiente." % settings["api_key_env"]
		return
	_result.text = "Consultando %s..." % settings["url"]
	_client.call("configure", settings)
	_client.call("enqueue", {"id": 1, "system": "Voce e um morador de Aresta. Responda somente JSON {\"acao\": \"id\", \"fala\": \"texto\"}.", "user": "Acoes possiveis:\n- cumprimentar: cumprimentar o visitante\nDiga uma frase curta de boas-vindas."})
