class_name PrototypePlayerMenu
extends Control

const BindingsScript := preload("res://src/core/app/input_bindings.gd")

signal stat_requested(stat: StringName)
signal milestone_requested(choice_id: StringName)
signal equip_requested(instance_id: StringName)
signal unequip_requested(slot: int, index: int)
signal gem_slot_requested(slot: int, gem_id: String)
signal support_attach_requested(slot: int, support_id: String)
signal support_detach_requested(slot: int, support_id: String)
signal start_floor_requested(floor_number: int)
signal gem_evolution_requested(gem_id: String, choice_id: String)

const SpriteLibraryScript := preload("res://src/presentation/art/sprite_library.gd")

const BG := Color("111014f5")
const PANEL := Color("1b1a1ff5")
const BORDER := Color("8f7a6a")
const GOLD := Color("e8b84a")
const TEXT := Color("f2e6c9")
const MUTED := Color("aaa59a")

var _model: Dictionary = {}
var _active_tab := "inventory"
var _content: VBoxContainer
var _title: Label
var _tab_buttons: Dictionary = {}
var _scroll: ScrollContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_shell()
	hide()


func open(tab: String) -> void:
	_active_tab = tab
	show()
	_rebuild()
	_scroll.scroll_vertical = 0
	(_tab_buttons[_active_tab] as Button).grab_focus()


func close() -> void:
	hide()


func refresh(model: Dictionary) -> void:
	_model = model.duplicate(true)
	if visible:
		_rebuild()


func _build_shell() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = BG
	add_child(shade)
	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.position = Vector2(-450.0, -300.0)
	frame.size = Vector2(900.0, 600.0)
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL
	box.border_color = BORDER
	box.set_border_width_all(2)
	box.content_margin_left = 22.0
	box.content_margin_right = 22.0
	box.content_margin_top = 18.0
	box.content_margin_bottom = 18.0
	frame.add_theme_stylebox_override("panel", box)
	add_child(frame)
	var root_column := VBoxContainer.new()
	root_column.add_theme_constant_override("separation", 12)
	frame.add_child(root_column)
	var header := HBoxContainer.new()
	root_column.add_child(header)
	_title = Label.new()
	_title.text = "REGISTRO DA EXPEDICAO"
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", GOLD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close_button := Button.new()
	close_button.text = "X"
	close_button.tooltip_text = "Fechar"
	close_button.custom_minimum_size = Vector2(38.0, 34.0)
	close_button.pressed.connect(close)
	header.add_child(close_button)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	root_column.add_child(tabs)
	for spec in [["inventory", "INVENTARIO"], ["character", "PERSONAGEM"], ["skills", "SKILLS"], ["tower", "TORRE"]]:
		var button := Button.new()
		button.text = spec[1]
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(150.0, 36.0)
		button.pressed.connect(_select_tab.bind(spec[0]))
		tabs.add_child(button)
		_tab_buttons[spec[0]] = button
	var separator := HSeparator.new()
	root_column.add_child(separator)
	var scroll := ScrollContainer.new()
	_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_column.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)


func _select_tab(tab: String) -> void:
	_active_tab = tab
	_rebuild()
	_scroll.scroll_vertical = 0


func _rebuild() -> void:
	if _content == null:
		return
	for child in _content.get_children():
		child.queue_free()
	for tab: String in _tab_buttons:
		(_tab_buttons[tab] as Button).button_pressed = tab == _active_tab
	match _active_tab:
		"character": _build_character()
		"skills": _build_skills()
		"tower": _build_tower()
		_: _build_inventory()


func _build_inventory() -> void:
	_section("CARGA DA EXPEDICAO", "%d tipos carregados" % (_model.get("carried_loot", {}) as Dictionary).size())
	_loot_rows(_model.get("carried_loot", {}) as Dictionary, "Nenhum saque carregado")
	_section("ARMAZEM DA VILA", "%d tipos armazenados" % (_model.get("banked_loot", {}) as Dictionary).size())
	_loot_rows(_model.get("banked_loot", {}) as Dictionary, "Armazem vazio")
	_section("EQUIPAMENTOS DISPONIVEIS", "%d no inventario" % (_model.get("inventory_equipment", []) as Array).size())
	var available: Array = _model.get("inventory_equipment", []) as Array
	if available.is_empty():
		_add_text("Nenhum equipamento disponivel", MUTED)
	for entry: Dictionary in available:
		var equip_button := Button.new()
		equip_button.text = "%s   |   %s   |   %s   |   %s" % [String(entry.get("name", "")), String(entry.get("tier", "")).to_upper(), String(entry.get("fabrication", "Regular")), String(entry.get("slot", ""))]
		equip_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		equip_button.custom_minimum_size.y = 34.0
		DescriptionHover.attach(equip_button, String(entry.get("tooltip", "")))
		var instance_id := StringName(String(entry.get("instance_id", "")))
		equip_button.pressed.connect(func() -> void: equip_requested.emit(instance_id))
		_content.add_child(equip_button)
	_section("EQUIPAMENTO", "%d / 21 ocupados" % int(_model.get("equipped_count", 0)))
	var slots: Array = _model.get("equipment_slots", []) as Array
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	_content.add_child(grid)
	for slot: Dictionary in slots:
		var row := Button.new()
		row.text = "%s   %s" % [String(slot.get("slot", "")), String(slot.get("item", "VAZIO"))]
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.custom_minimum_size = Vector2(260.0, 32.0)
		row.disabled = not bool(slot.get("occupied", false))
		if not row.disabled:
			var slot_id := int(slot.get("slot_id", -1))
			var slot_index := int(slot.get("index", 0))
			DescriptionHover.attach(row, String(slot.get("tooltip", "")))
			row.pressed.connect(func() -> void: unequip_requested.emit(slot_id, slot_index))
		grid.add_child(row)


func _loot_rows(loot: Dictionary, empty_text: String) -> void:
	if loot.is_empty():
		_add_text(empty_text, MUTED)
		return
	var ids := loot.keys()
	ids.sort()
	for item_id: Variant in ids:
		_add_text("%s   x%d" % [_friendly(String(item_id)), int(loot[item_id])], TEXT)
		DescriptionHover.attach(_content.get_child(-1) as Control, String((_model.get("item_tooltips", {}) as Dictionary).get(String(item_id), "Item de expedicao.")))


func _build_character() -> void:
	var level := int(_model.get("level", 1))
	var xp := int(_model.get("experience", 0))
	var required := maxi(1, int(_model.get("experience_required", 1)))
	_section(String(_model.get("character_name", "PERSONAGEM")).to_upper(), "NIVEL %d / %d" % [level, int(_model.get("max_level", 100))])
	_add_text("EXPERIENCIA   %d / %d" % [xp, required], GOLD)
	var bar := ProgressBar.new()
	bar.max_value = required
	bar.value = xp
	bar.show_percentage = false
	bar.custom_minimum_size.y = 14.0
	_content.add_child(bar)
	_section("ATRIBUTOS", "%d pontos livres" % int(_model.get("unspent_stat_points", 0)))
	var stats := _model.get("stats", {}) as Dictionary
	for stat_id in ["vitality", "strength", "intelligence", "agility", "fortune", "wisdom"]:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "%s   %d" % [_stat_label(stat_id), int(stats.get(stat_id, 0))]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", TEXT)
		row.add_child(label)
		var add_button := Button.new()
		add_button.text = "+"
		add_button.tooltip_text = "Adicionar ponto"
		add_button.custom_minimum_size = Vector2(36.0, 30.0)
		add_button.disabled = int(_model.get("unspent_stat_points", 0)) <= 0
		add_button.pressed.connect(func() -> void: stat_requested.emit(StringName(stat_id)))
		row.add_child(add_button)
		_content.add_child(row)
	var derived := _model.get("derived_stats", {}) as Dictionary
	_section("VALORES DE COMBATE", "atributos e equipamento")
	_add_text("VIDA %.0f   MOVIMENTO %.0f%%   CRITICO %.1f%%   RECARGA %.0f%%" % [
		float(derived.get("max_health", 100.0)),
		float(derived.get("movement_speed_multiplier", 1.0)) * 100.0,
		float(derived.get("critical_chance", 0.12)) * 100.0,
		float(derived.get("cooldown_recovery_multiplier", 1.0)) * 100.0,
	], TEXT)
	var chosen: Array = _model.get("chosen_milestones", []) as Array
	var weapon := _model.get("weapon_attack", {}) as Dictionary
	if not weapon.is_empty():
		_section(String(weapon.get("item_name", weapon.get("name", ""))), "Afinidade %.0f%%" % float(weapon.get("affinity", 100.0)))
		_add_text("DANO %.1f   ALCANCE %.0f   INTERVALO %.2fs   CRITICO %.1f%%" % [float(weapon["damage"]), float(weapon["range"]), float(weapon["interval"]), float(weapon["critical_chance"]) * 100.0], TEXT)
		var damage_label := "ARCANO" if String(weapon["damage_type"]) == "arcane" else "FISICO"
		var pattern_label := String({"single":"ALVO UNICO", "line":"LINHA", "cone":"CONE"}.get(String(weapon["pattern"]), ""))
		_add_text("%s   |   %s   |   %s" % [String(weapon["name"]).to_upper(), damage_label, pattern_label], MUTED)
		for stat: String in weapon.get("scaling", {}) as Dictionary:
			_add_text("%s: +%.1f%% por ponto" % [_stat_label(stat), float(weapon["scaling"][stat]) * 100.0], MUTED)
		for type_id: String in weapon.get("affinities", {}) as Dictionary:
			_add_text("%s: %.0f%%" % [String((WeaponCombat.data()["types"][type_id] as Dictionary)["name"]), float(weapon["affinities"][type_id])], MUTED)
	if not chosen.is_empty():
		_section("EVOLUCOES ESCOLHIDAS", "%d de 10" % chosen.size())
		for entry: Dictionary in chosen:
			_add_text("NIVEL %d  ·  %s  ·  %s" % [int(entry.get("level", 0)), _branch_label(String(entry.get("branch", ""))), String(entry.get("name", ""))], GOLD)
			_add_text(String(entry.get("description", "")), MUTED)
	var choices: Array = _model.get("milestone_choices", []) as Array
	if not choices.is_empty():
		_section("EVOLUCAO DO NIVEL %d" % level, "Escolha uma direcao")
		for choice: Dictionary in choices:
			var button := Button.new()
			button.text = "%s  |  %s\n%s" % [_branch_label(String(choice.get("branch", ""))), String(choice.get("name", "")), String(choice.get("description", ""))]
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.custom_minimum_size.y = 58.0
			button.pressed.connect(func() -> void: milestone_requested.emit(StringName(String(choice.get("id", "")))))
			_content.add_child(button)


## Mapa da Torre e recordes: andares alcançados, melhor tempo por modo e escolha do andar de partida.
func _build_tower() -> void:
	var deepest := int(_model.get("deepest_floor", 1))
	var start := int(_model.get("tower_start_floor", 1))
	var safe := bool(_model.get("in_safe_area", true))
	_section("MAPA DA TORRE", "andar mais fundo: %d   ·   proxima entrada: andar %d" % [deepest, start])
	_add_text("Recordes de tempo por andar em SOLO, DUO, TRIO e SQUAD. Andares comuns contam ate a descida; andares de chefe, ate a queda do chefe.", MUTED)
	var records := _model.get("records", {}) as Dictionary
	var previous_biome := ""
	for entry: Dictionary in _model.get("floors", []) as Array:
		var number := int(entry.get("number", 1))
		if String(entry.get("biome", "")) != previous_biome:
			previous_biome = String(entry.get("biome", ""))
			_section(previous_biome.to_upper(), "")
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var label := Label.new()
		var kind := "CHEFE" if String(entry.get("kind", "")) == "boss" else "      "
		label.text = "%3d  %s  %s" % [number, kind, String(entry.get("name", ""))]
		label.custom_minimum_size.x = 330.0
		label.add_theme_color_override("font_color", GOLD if kind == "CHEFE" else TEXT)
		row.add_child(label)
		var by_floor := records.get(str(number), {}) as Dictionary
		for mode in ["solo", "duo", "trio", "squad"]:
			var list := by_floor.get(mode, []) as Array
			var time_label := Label.new()
			time_label.custom_minimum_size.x = 92.0
			time_label.text = "%s %s" % [mode.to_upper(), _format_time(float((list[0] as Dictionary)["time"])) if not list.is_empty() else "--"]
			time_label.add_theme_color_override("font_color", TEXT if not list.is_empty() else MUTED)
			row.add_child(time_label)
		var go := Button.new()
		go.text = "PARTIDA" if number == start else "partir daqui"
		go.disabled = not safe or number == start
		go.custom_minimum_size = Vector2(110.0, 28.0)
		go.pressed.connect(func() -> void: start_floor_requested.emit(number))
		row.add_child(go)
		if float(entry.get("boss_cooldown", 0.0)) > 0.0:
			var cooldown := Label.new()
			cooldown.text = "chefe volta em %d s" % int(entry["boss_cooldown"])
			cooldown.add_theme_color_override("font_color", MUTED)
			row.add_child(cooldown)
		_content.add_child(row)


func _format_time(seconds: float) -> String:
	return "%d:%05.2f" % [int(seconds) / 60, fmod(seconds, 60.0)]


func _branch_label(branch: String) -> String:
	return {"essence": "ESSENCIA", "adaptation": "ADAPTACAO", "convergence": "CONVERGENCIA"}.get(branch, branch.to_upper()) as String


func _build_skills() -> void:
	var safe := bool(_model.get("in_safe_area", true))
	var keys: Array[String] = []
	for slot in range(4):
		keys.append(BindingsScript.label("skill_%d" % (slot + 1)))
	_section("GEMAS ATIVAS", " / ".join(keys) if safe else "trocas e evolucoes so em Aresta")
	var gem_options: Array = _model.get("gem_options", []) as Array
	for skill: Dictionary in _model.get("skills", []) as Array:
		_build_skill_card(skill, gem_options, safe)
	_section("PASSIVA AUTORAL", String(_model.get("passive_name", "")))
	_add_text(String(_model.get("passive_description", "")), TEXT)


func _build_skill_card(skill: Dictionary, gem_options: Array, safe: bool) -> void:
	var slot := int(skill.get("slot", 0))
	var gem_id := String(skill.get("id", ""))
	var card := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("2f2a35c0")
	box.border_color = BORDER
	box.set_border_width_all(1)
	box.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", box)
	_content.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)
	var icon := TextureRect.new()
	icon.texture = SpriteLibraryScript.texture("icons/" + gem_id)
	icon.custom_minimum_size = Vector2(44.0, 44.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header.add_child(icon)
	DescriptionHover.attach(icon, ContentDescriptions.skill(skill))
	var key_label := Label.new()
	key_label.text = BindingsScript.label("skill_%d" % (slot + 1))
	key_label.add_theme_font_size_override("font_size", 22)
	key_label.add_theme_color_override("font_color", GOLD)
	header.add_child(key_label)
	var title := Label.new()
	title.text = "%s\nNivel %d / %d   EXP %d / %d   Capacidade %d / %d" % [
		String(skill.get("name", "")), int(skill.get("level", 1)), int(skill.get("max_level", 3)),
		int(skill.get("experience", 0)), int(skill.get("experience_required", 1)),
		int(skill.get("capacity_used", 0)), int(skill.get("capacity", 3)),
	]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", TEXT)
	header.add_child(title)
	DescriptionHover.attach(title, ContentDescriptions.skill(skill))
	var swap := OptionButton.new()
	swap.custom_minimum_size = Vector2(200.0, 32.0)
	swap.tooltip_text = "Trocar a gema deste encaixe"
	swap.disabled = not safe
	var selected := 0
	for index in range(gem_options.size()):
		var option := gem_options[index] as Dictionary
		swap.add_item(String(option.get("name", "")))
		swap.set_item_metadata(index, String(option.get("id", "")))
		swap.get_popup().set_item_tooltip(index, String(option.get("description", "")))
		if String(option.get("id", "")) == gem_id:
			selected = index
	swap.select(selected)
	swap.item_selected.connect(func(index: int) -> void:
		var chosen := String(swap.get_item_metadata(index))
		if chosen != gem_id:
			gem_slot_requested.emit(slot, chosen)
	)
	header.add_child(swap)
	if not String(skill.get("description", "")).is_empty():
		var description := Label.new()
		description.text = String(skill["description"])
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_color_override("font_color", TEXT)
		column.add_child(description)

	var stats := Label.new()
	var values := PackedStringArray()
	for spec in [["power", "Potencia da gema"], ["barrier", "Barreira"], ["healing", "Cura por pulso"]]:
		if float(skill.get(spec[0], 0.0)) > 0.0:
			values.append("%s %.0f" % [spec[1], float(skill[spec[0]])])
	values.append("Recarga %.1f s" % float(skill.get("cooldown", 0.0)))
	values.append("Folego %.0f" % float(skill.get("breath_cost", 0.0)))
	values.append("Cargas %d" % int(skill.get("charges", 1)))
	stats.text = "   |   ".join(values)
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.add_theme_color_override("font_color", MUTED)
	column.add_child(stats)
	var evolutions := Label.new()
	evolutions.text = "Evolucoes: " + (", ".join(PackedStringArray(skill.get("chosen", []) as Array)) if not (skill.get("chosen", []) as Array).is_empty() else "nenhuma")
	evolutions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	evolutions.add_theme_color_override("font_color", MUTED)
	column.add_child(evolutions)

	var supports_row := HBoxContainer.new()
	supports_row.add_theme_constant_override("separation", 6)
	column.add_child(supports_row)
	var supports_label := Label.new()
	supports_label.text = "Suportes:"
	supports_label.add_theme_color_override("font_color", GOLD)
	supports_row.add_child(supports_label)
	for support: Dictionary in skill.get("supports", []) as Array:
		var chip := Button.new()
		chip.text = "%s (%d)  x" % [String(support.get("name", "")), int(support.get("drain", 0))]
		chip.tooltip_text = "%s\n%s\nRemover suporte" % ["Mecanica" if String(support.get("category", "")) == "mechanic" else "Buff", String(support.get("description", ""))]
		chip.disabled = not safe
		var support_id := String(support.get("id", ""))
		chip.pressed.connect(func() -> void: support_detach_requested.emit(slot, support_id))
		supports_row.add_child(chip)
	var available: Array = skill.get("available_supports", []) as Array
	if (skill.get("supports", []) as Array).size() < 2 and not available.is_empty():
		var add := OptionButton.new()
		add.disabled = not safe
		add.add_item("+ adicionar suporte")
		add.set_item_metadata(0, "")
		for index in range(available.size()):
			var support := available[index] as Dictionary
			add.add_item("%s | %s (%d)" % ["Mecanica" if String(support.get("category", "")) == "mechanic" else "Buff", String(support.get("name", "")), int(support.get("drain", 0))])
			add.set_item_metadata(index + 1, String(support.get("id", "")))
			var fits := int(support.get("drain", 0)) <= int(skill.get("capacity", 3)) - int(skill.get("capacity_used", 0))
			add.set_item_disabled(index + 1, not fits)
			add.get_popup().set_item_tooltip(index + 1, String(support.get("description", "")) + ("" if fits else "\nCapacidade insuficiente"))
		add.item_selected.connect(func(index: int) -> void:
			var support_id := String(add.get_item_metadata(index))
			if not support_id.is_empty():
				support_attach_requested.emit(slot, support_id)
		)
		supports_row.add_child(add)

	var pending: Array = skill.get("pending_choices", []) as Array
	if not pending.is_empty():
		var hint := Label.new()
		hint.text = "Evolucao do nivel %d pendente — escolha uma:" % int(skill.get("level", 1))
		hint.add_theme_color_override("font_color", GOLD)
		column.add_child(hint)
		var choices_row := HBoxContainer.new()
		choices_row.add_theme_constant_override("separation", 8)
		column.add_child(choices_row)
		for choice: Dictionary in pending:
			var button := Button.new()
			button.text = "%s\n%s" % [String(choice.get("name", "")), _describe_modifiers(choice.get("modifiers", {}) as Dictionary)]
			button.custom_minimum_size = Vector2(300.0, 48.0)
			button.disabled = not safe
			var choice_id := String(choice.get("id", ""))
			button.pressed.connect(func() -> void: gem_evolution_requested.emit(gem_id, choice_id))
			choices_row.add_child(button)


const MODIFIER_NAMES := {
	"allies_receive_barrier": "barreira em aliados", "arrival_area": "area na chegada", "arrival_barrier": "barreira na chegada",
	"arrival_damage": "dano na chegada", "attack_interval": "intervalo de ataque", "barrier": "barreira",
	"barrier_per_hit": "barreira por acerto", "breath_cost": "custo de folego", "chain_count": "saltos",
	"chain_range": "alcance do salto", "contact_damage": "dano de contato", "cooldown": "recarga",
	"critical_chance": "chance critica", "damage_taken": "vulnerabilidade", "distance": "distancia",
	"duration": "duracao", "enemy_damage_per_tick": "dano por pulso", "expire_damage": "dano ao expirar",
	"expire_nova_damage": "explosao ao expirar", "expire_radius": "raio ao expirar", "extra_charge": "carga extra",
	"field_follows_player": "campo segue", "follows_player": "segue o portador", "heal_per_chain": "cura por salto",
	"healing": "cura", "homing": "teleguiado", "impact_area": "area no impacto", "inherits_support_one": "herda suporte",
	"knockback": "repulsao", "life_steal": "roubo de vida", "overheal_barrier": "excesso vira barreira",
	"pierce": "perfuracao", "power": "potencia", "projectile_count": "projeteis", "pull_strength": "atracao",
	"radius": "raio", "range": "alcance", "repeat_count": "repeticoes", "repeat_delay": "atraso do eco",
	"repeat_last_target": "repete no ultimo alvo", "return_projectile": "retorna", "ricochet": "ricochetes",
	"slow": "lentidao", "speed": "velocidade", "stability": "estabilidade", "summon_count": "invocacoes",
	"summon_follows_player": "invocacao segue", "trail_damage": "dano no rastro",
	"angle": "abertura", "width": "largura", "angular_speed": "rotacao", "orbit_count": "orbitas",
	"arm_delay": "tempo de armar", "meteor_count": "impactos", "delay": "atraso", "fork_count": "bifurcacoes",
	"remote_nova": "pulso remoto", "inner_radius": "centro vazio", "invulnerability": "invulnerabilidade",
	"breath_per_hit": "Folego por acerto",
}


func _describe_modifiers(modifiers: Dictionary) -> String:
	var parts: Array[String] = []
	for key: Variant in modifiers:
		var raw := String(key)
		var value: Variant = modifiers[key]
		if raw.ends_with("_multiplier"):
			parts.append("%s x%s" % [_modifier_name(raw.trim_suffix("_multiplier")), str(value)])
		elif raw.ends_with("_add"):
			parts.append("%s %s%s" % [_modifier_name(raw.trim_suffix("_add")), "+" if float(value) >= 0.0 else "", str(value)])
		elif value is bool:
			parts.append(_modifier_name(raw))
		else:
			parts.append("%s %s" % [_modifier_name(raw), str(value)])
	return ", ".join(PackedStringArray(parts))


func _modifier_name(key: String) -> String:
	return String(MODIFIER_NAMES.get(key, key.replace("_", " ")))


func _section(title: String, detail: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var title_label := Label.new()
	var detail_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", GOLD)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_label.text = detail
	detail_label.add_theme_color_override("font_color", MUTED)
	row.add_child(title_label)
	row.add_child(detail_label)
	_content.add_child(row)


func _add_text(value: String, color: Color) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	_content.add_child(label)


func _friendly(value: String) -> String:
	return value.replace("_", " ").capitalize()


func _stat_label(stat_id: String) -> String:
	return {
		"vitality": "VITALIDADE", "strength": "FORCA", "intelligence": "INTELIGENCIA",
		"agility": "AGILIDADE", "fortune": "SORTE", "wisdom": "SABEDORIA",
	}.get(stat_id, stat_id.to_upper())
