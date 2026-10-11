extends Control

const TAB_PROGRESSION := 0
const TAB_GEMS := 1
const TAB_EQUIPMENT := 2
const BetaCatalogScript := preload("res://src/gameplay/content/beta_content_catalog.gd")
const BetaCharacterFactoryScript := preload("res://src/gameplay/progression/beta_character_factory.gd")

const STAT_NAMES: Dictionary = {
	&"vitality": "Vitalidade",
	&"strength": "Força",
	&"intelligence": "Inteligência",
	&"agility": "Agilidade",
	&"fortune": "Sorte",
	&"wisdom": "Sabedoria",
}

var _build: CharacterBuild
var _character_definitions: Array[Dictionary] = []
var _character_builds: Dictionary = {}
var _character_definition: Dictionary = {}
var _gem_loadout: SkillGemLoadout
var _supports: Array[SkillGemDefinition] = []
var _inventory: ItemInventory
var _equipment: EquipmentLoadout
var _equipment_catalog: Dictionary = {}
var _active_tab := TAB_PROGRESSION

var _content: MarginContainer
var _status_label: Label
var _tab_buttons: Array[Button] = []
var _character_selector: OptionButton


func _ready() -> void:
	_initialize_models()
	_build_shell()
	var initial_tab := TAB_PROGRESSION
	for argument in OS.get_cmdline_user_args():
		if argument == "--tab=gems": initial_tab = TAB_GEMS
		elif argument == "--tab=equipment": initial_tab = TAB_EQUIPMENT
	_show_tab(initial_tab)


func _initialize_models() -> void:
	_initialize_beta_characters()
	_initialize_gems()
	_initialize_equipment()


func _initialize_beta_characters() -> void:
	var catalog: RefCounted = BetaCatalogScript.new()
	if not bool(catalog.call("load_from")):
		return
	_character_definitions.assign(catalog.call("collection", "playable_characters"))
	var factory: RefCounted = BetaCharacterFactoryScript.new()
	for definition in _character_definitions:
		var build := factory.call("create_build", definition) as CharacterBuild
		_character_builds[build.character_id] = build
	if not _character_definitions.is_empty():
		_select_character(0, false)


func _select_character(index: int, refresh := true) -> void:
	if index < 0 or index >= _character_definitions.size():
		return
	_character_definition = _character_definitions[index]
	_build = _character_builds.get(StringName(String(_character_definition.get("id", "")))) as CharacterBuild
	if refresh and _content != null:
		_show_tab(TAB_PROGRESSION)


func _initialize_gems() -> void:
	_gem_loadout = SkillGemLoadout.new()
	var gem_specs := [
		[&"ember_lance", [ &"projectile", &"fire" ]],
		[&"fold_step", [ &"movement", &"space" ]],
		[&"gravity_well", [ &"area", &"gravity" ]],
		[&"living_aegis", [ &"protection", &"life" ]],
	]
	for slot in gem_specs.size():
		var definition := SkillGemDefinition.new(gem_specs[slot][0], SkillGemDefinition.Kind.ACTIVE)
		definition.tags.assign(gem_specs[slot][1])
		for gem_level in range(1, 11):
			var kind := EvolutionChoice.Kind.MECHANIC if gem_level == 10 else EvolutionChoice.Kind.BUFF
			definition.add_level_choice(
				gem_level,
				EvolutionChoice.new(StringName("power_%d" % gem_level), kind)
			)
			definition.add_level_choice(
				gem_level,
				EvolutionChoice.new(StringName("form_%d" % gem_level), kind)
			)
		_gem_loadout.equip_active(slot, EquippedActiveGem.new(definition))

	for spec in [
		[&"amplification", 1],
		[&"echo", 2],
		[&"corrupted_reach", 3],
	]:
		var support := SkillGemDefinition.new(spec[0], SkillGemDefinition.Kind.SUPPORT)
		support.support_drain = spec[1]
		_supports.append(support)


func _initialize_equipment() -> void:
	_inventory = ItemInventory.new(&"beta_player")
	_equipment = EquipmentLoadout.new()
	var fixed_specs := [
		["Arma", &"blade_of_marks", EquipmentItemDefinition.Slot.WEAPON, ItemTier.Value.RARE],
		["Offhand", &"memory_lantern", EquipmentItemDefinition.Slot.OFFHAND, ItemTier.Value.UNCOMMON],
		["Amuleto", &"first_ligature", EquipmentItemDefinition.Slot.AMULET, ItemTier.Value.RARE],
		["Armadura", &"ferral_plate", EquipmentItemDefinition.Slot.ARMOR, ItemTier.Value.COMMON],
		["Luvas", &"conductor_gloves", EquipmentItemDefinition.Slot.GLOVES, ItemTier.Value.UNCOMMON],
		["Botas", &"route_boots", EquipmentItemDefinition.Slot.BOOTS, ItemTier.Value.COMMON],
		["Calça", &"warden_pants", EquipmentItemDefinition.Slot.PANTS, ItemTier.Value.COMMON],
	]
	for spec in fixed_specs:
		_create_catalog_item(spec[0], spec[1], spec[2], spec[3], 0, true)
	for index in EquipmentLoadout.RING_SLOT_COUNT:
		var tier := ItemTier.Value.RARE if index >= 7 else ItemTier.Value.UNCOMMON
		_create_catalog_item(
			"Anel %d" % (index + 1), StringName("ring_%d" % index),
			EquipmentItemDefinition.Slot.RING, tier, index, index < 1
		)
	for index in EquipmentLoadout.RELIC_SLOT_COUNT:
		var tier := ItemTier.Value.LEGENDARY if index == 3 else ItemTier.Value.EPIC
		_create_catalog_item(
			"Relíquia %d" % (index + 1), StringName("relic_%d" % index),
			EquipmentItemDefinition.Slot.RELIC, tier, index, index == 0
		)


func _create_catalog_item(
	label: String,
	id: StringName,
	slot: EquipmentItemDefinition.Slot,
	tier: ItemTier.Value,
	index: int,
	equip_now: bool
) -> void:
	var definition := EquipmentItemDefinition.new(id, slot)
	if slot == EquipmentItemDefinition.Slot.RELIC:
		definition.mechanic_changes = [StringName("relic_rule_%d" % index)]
	else:
		definition.stat_modifiers = {&"vitality": 2.0 + float(index % 3)}
	var instance := EquipmentItemInstance.new(StringName("instance_%s" % id), definition, &"beta_player")
	instance.tier = tier
	_inventory.add(instance)
	_equipment_catalog[_equipment_key(slot, index)] = {"label": label, "item": instance}
	if equip_now:
		EquipmentTransaction.equip_from_inventory(_inventory, _equipment, instance.instance_id, index)


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("10171d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root_column := VBoxContainer.new()
	root_column.name = "RootColumn"
	root_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_column.add_theme_constant_override("separation", 0)
	add_child(root_column)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 72.0
	header.add_theme_constant_override("separation", 8)
	root_column.add_child(header)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 22)
	header_margin.add_theme_constant_override("margin_top", 16)
	header_margin.add_theme_constant_override("margin_right", 22)
	header_margin.add_theme_constant_override("margin_bottom", 12)
	header.add_child(header_margin)
	header_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	header_margin.add_child(header_row)
	var back := Button.new()
	back.text = "Voltar"
	back.tooltip_text = "Retornar ao menu de sessão"
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/prototype/network/network_prototype.tscn")
	)
	header_row.add_child(back)
	var title := Label.new()
	title.text = "LABORATÓRIO DE BUILD"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)
	_character_selector = OptionButton.new()
	_character_selector.name = "CharacterSelector"
	_character_selector.tooltip_text = "Personagem do beta"
	for definition in _character_definitions:
		_character_selector.add_item(String(definition.get("name", "Personagem")))
	_character_selector.item_selected.connect(func(index: int) -> void: _select_character(index))
	header_row.add_child(_character_selector)
	for tab_data in [["Progressão", TAB_PROGRESSION], ["Gemas", TAB_GEMS], ["Equipamentos", TAB_EQUIPMENT]]:
		var tab := Button.new()
		tab.text = tab_data[0]
		tab.toggle_mode = true
		tab.pressed.connect(_show_tab.bind(tab_data[1]))
		header_row.add_child(tab)
		_tab_buttons.append(tab)

	var separator := HSeparator.new()
	root_column.add_child(separator)
	_content = MarginContainer.new()
	_content.name = "Content"
	_content.add_theme_constant_override("margin_left", 24)
	_content.add_theme_constant_override("margin_top", 18)
	_content.add_theme_constant_override("margin_right", 24)
	_content.add_theme_constant_override("margin_bottom", 14)
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_column.add_child(_content)

	var footer := PanelContainer.new()
	footer.custom_minimum_size.y = 42.0
	root_column.add_child(footer)
	_status_label = Label.new()
	_status_label.name = "Status"
	_status_label.text = "Pronto"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(_status_label)


func _show_tab(tab_index: int) -> void:
	_active_tab = tab_index
	for index in _tab_buttons.size():
		_tab_buttons[index].button_pressed = index == tab_index
	for child in _content.get_children():
		child.queue_free()
	match tab_index:
		TAB_PROGRESSION: _build_progression_tab()
		TAB_GEMS: _build_gems_tab()
		TAB_EQUIPMENT: _build_equipment_tab()


func _build_progression_tab() -> void:
	var layout := HBoxContainer.new()
	layout.name = "ProgressionTab"
	layout.add_theme_constant_override("separation", 28)
	_content.add_child(layout)

	var stats_column := VBoxContainer.new()
	stats_column.custom_minimum_size.x = 560.0
	stats_column.add_theme_constant_override("separation", 10)
	layout.add_child(stats_column)
	var passive := _character_definition.get("passive", {}) as Dictionary
	_add_section_title(
		stats_column,
		String(_character_definition.get("name", "Personagem")),
		"Passiva: %s" % String(passive.get("name", "Nao definida"))
	)
	var passive_description := Label.new()
	passive_description.text = String(passive.get("description", ""))
	passive_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	passive_description.custom_minimum_size.x = 540.0
	passive_description.modulate = Color("a9bbc7")
	stats_column.add_child(passive_description)
	var summary := Label.new()
	summary.text = "Nível %d / %d     Pontos livres: %d" % [_build.level, _build.max_level, _build.unspent_stat_points]
	summary.add_theme_font_size_override("font_size", 18)
	stats_column.add_child(summary)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	stats_column.add_child(grid)
	for heading in ["Atributo", "Bruto", "Efetivo", "Distribuir"]:
		var label := Label.new()
		label.text = heading
		label.modulate = Color("8fa7b5")
		grid.add_child(label)
	var effective := StatResolver.effective_primaries(_build.base_stats)
	for stat in CharacterBuild.PRIMARY_STATS:
		_add_grid_label(grid, STAT_NAMES[stat])
		_add_grid_label(grid, str(int(_build.base_stats[stat])))
		_add_grid_label(grid, "%.1f" % float(effective[stat]))
		var add_button := Button.new()
		add_button.text = "+1"
		add_button.disabled = _build.unspent_stat_points <= 0
		add_button.pressed.connect(_allocate_stat.bind(stat))
		grid.add_child(add_button)

	var advance_row := HBoxContainer.new()
	advance_row.add_theme_constant_override("separation", 10)
	stats_column.add_child(advance_row)
	var advance := Button.new()
	advance.text = "Avançar nível"
	advance.disabled = _build.level >= _build.max_level or _build.has_pending_milestone()
	advance.pressed.connect(_advance_level)
	advance_row.add_child(advance)
	var next_milestone := Button.new()
	next_milestone.text = "Avançar até o próximo marco"
	next_milestone.disabled = advance.disabled
	next_milestone.pressed.connect(_advance_to_milestone)
	advance_row.add_child(next_milestone)

	var milestone_column := VBoxContainer.new()
	milestone_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	milestone_column.add_theme_constant_override("separation", 10)
	layout.add_child(milestone_column)
	_add_section_title(milestone_column, "Evolução de marco", "Uma escolha nos múltiplos de 10")
	if _build.has_pending_milestone():
		var prompt := Label.new()
		prompt.text = "Escolha a evolução do nível %d" % _build.level
		prompt.add_theme_font_size_override("font_size", 18)
		milestone_column.add_child(prompt)
		for choice_value: Variant in _build.milestone_choices.get(_build.level, []):
			var choice := choice_value as EvolutionChoice
			var button := Button.new()
			button.text = "%s  |  %s" % [_friendly_branch(choice.branch), choice.display_name]
			button.tooltip_text = choice.description
			button.custom_minimum_size.y = 42.0
			button.pressed.connect(_choose_milestone.bind(choice.id))
			milestone_column.add_child(button)
	else:
		var next_level := int(ceil(float(_build.level + 1) / 10.0) * 10.0)
		var info := Label.new()
		if _build.level >= _build.max_level:
			info.text = "Limite do beta alcançado.\nAs escolhas dos níveis 10 e 20 permanecem registradas neste personagem."
		else:
			info.text = "Próxima escolha no nível %d.\nNíveis comuns concedem 5 pontos.\nO nível 20 sempre oferece uma nova mecânica." % mini(next_level, _build.max_level)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		milestone_column.add_child(info)
	var derived := _build.derived_stats()
	var derived_label := Label.new()
	derived_label.text = "Vida %.0f   Crítico %.1f%%   Movimento %.1f%%" % [
		float(derived["max_health"]),
		float(derived["critical_chance"]) * 100.0,
		(float(derived["movement_speed_multiplier"]) - 1.0) * 100.0,
	]
	derived_label.modulate = Color("72d6a0")
	milestone_column.add_child(derived_label)


func _build_gems_tab() -> void:
	var column := VBoxContainer.new()
	column.name = "GemsTab"
	column.add_theme_constant_override("separation", 12)
	_content.add_child(column)
	_add_section_title(column, "Gemas Ativas", "Q/W/E/R • duas Gemas de Suporte por ativa")
	for slot in SkillGemLoadout.ACTIVE_SLOT_COUNT:
		var gem := _gem_loadout.active_slots[slot]
		var row := PanelContainer.new()
		row.custom_minimum_size.y = 112.0
		column.add_child(row)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_bottom", 12)
		row.add_child(margin)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 16)
		margin.add_child(line)
		var command := Label.new()
		command.text = String(SkillGemLoadout.SLOT_COMMANDS[slot])
		command.custom_minimum_size.x = 42.0
		command.add_theme_font_size_override("font_size", 28)
		command.modulate = Color("ffcb69")
		line.add_child(command)
		var description := VBoxContainer.new()
		description.custom_minimum_size.x = 410.0
		line.add_child(description)
		var name_label := Label.new()
		name_label.text = _friendly_choice_name(gem.definition.id)
		name_label.add_theme_font_size_override("font_size", 18)
		description.add_child(name_label)
		var support_names: Array[String] = []
		for support in gem.support_gems:
			support_names.append(_friendly_choice_name(support.id))
		var detail := Label.new()
		detail.text = "Nível %d/10   Capacidade %d/%d\nSuportes: %s" % [
			gem.level, gem.used_support_capacity(), gem.support_capacity(),
			", ".join(support_names) if not support_names.is_empty() else "nenhum"
		]
		detail.modulate = Color("a9bbc7")
		description.add_child(detail)
		var evolve := Button.new()
		evolve.text = "Escolher evolução" if gem.has_pending_choice() else "Subir nível"
		evolve.disabled = gem.level == 10 and not gem.has_pending_choice()
		evolve.pressed.connect(_advance_gem.bind(slot))
		line.add_child(evolve)
		var support_button := Button.new()
		support_button.text = "Adicionar suporte"
		support_button.disabled = gem.support_gems.size() >= EquippedActiveGem.MAX_SUPPORTS
		support_button.pressed.connect(_add_support.bind(slot))
		line.add_child(support_button)
		var remove_button := Button.new()
		remove_button.text = "Remover suporte"
		remove_button.disabled = gem.support_gems.is_empty()
		remove_button.pressed.connect(_remove_support.bind(slot))
		line.add_child(remove_button)


func _build_equipment_tab() -> void:
	var column := VBoxContainer.new()
	column.name = "EquipmentTab"
	column.add_theme_constant_override("separation", 12)
	_content.add_child(column)
	_add_section_title(column, "Equipamentos", "%d / %d equipados • clique para equipar ou retirar" % [_equipment.equipped_count(), 7 + EquipmentLoadout.RING_SLOT_COUNT + EquipmentLoadout.RELIC_SLOT_COUNT])
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.resized.connect(func() -> void:
		grid.columns = clampi(int((grid.size.x + 12) / 372), 1, 3))
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	var slots: Array = [
		[EquipmentItemDefinition.Slot.WEAPON, 0], [EquipmentItemDefinition.Slot.OFFHAND, 0],
		[EquipmentItemDefinition.Slot.AMULET, 0], [EquipmentItemDefinition.Slot.ARMOR, 0],
		[EquipmentItemDefinition.Slot.GLOVES, 0], [EquipmentItemDefinition.Slot.BOOTS, 0],
		[EquipmentItemDefinition.Slot.PANTS, 0],
	]
	for index in EquipmentLoadout.RING_SLOT_COUNT:
		slots.append([EquipmentItemDefinition.Slot.RING, index])
	for index in EquipmentLoadout.RELIC_SLOT_COUNT:
		slots.append([EquipmentItemDefinition.Slot.RELIC, index])
	for slot_data in slots:
		var slot: EquipmentItemDefinition.Slot = slot_data[0]
		var index: int = slot_data[1]
		var entry: Dictionary = _equipment_catalog[_equipment_key(slot, index)]
		var item := entry["item"] as EquipmentItemInstance
		var equipped := _equipment.get_equipped(slot, index) != null
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 68.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s\n%s • %s" % [
			entry["label"], ItemTier.label(item.tier), "Equipado" if equipped else "No inventário"
		]
		button.modulate = ItemTier.color(item.tier)
		button.pressed.connect(_toggle_equipment.bind(slot, index, item.instance_id))
		grid.add_child(button)


func _allocate_stat(stat: StringName) -> void:
	if _build.allocate_stat(stat, 1):
		_set_status("+1 em %s" % STAT_NAMES[stat])
	_show_tab(TAB_PROGRESSION)


func _advance_level() -> void:
	if _build.level_up():
		_set_status("Nível %d alcançado" % _build.level)
	_show_tab(TAB_PROGRESSION)


func _advance_to_milestone() -> void:
	while _build.level < _build.max_level and not _build.has_pending_milestone():
		_build.level_up()
	_set_status("Marco do nível %d alcançado" % _build.level)
	_show_tab(TAB_PROGRESSION)


func _choose_milestone(choice_id: StringName) -> void:
	if _build.choose_milestone(choice_id):
		_set_status("Evolução escolhida: %s" % _friendly_choice_name(choice_id))
	_show_tab(TAB_PROGRESSION)


func _advance_gem(slot: int) -> void:
	var gem := _gem_loadout.active_slots[slot]
	if gem.has_pending_choice():
		var choices := gem.definition.choices_for_level(gem.level)
		if not choices.is_empty():
			gem.choose_evolution(choices[0].id)
			_set_status("Evolução aplicada em %s" % SkillGemLoadout.SLOT_COMMANDS[slot])
	elif gem.level_up():
		_set_status("Gema %s alcançou o nível %d" % [SkillGemLoadout.SLOT_COMMANDS[slot], gem.level])
	_show_tab(TAB_GEMS)


func _add_support(slot: int) -> void:
	var gem := _gem_loadout.active_slots[slot]
	for support in _supports:
		if gem.support_gems.has(support):
			continue
		if gem.attach_support(support):
			_set_status("Suporte %s equipado" % _friendly_choice_name(support.id))
			break
	_show_tab(TAB_GEMS)


func _remove_support(slot: int) -> void:
	var gem := _gem_loadout.active_slots[slot]
	if not gem.support_gems.is_empty():
		var removed := gem.detach_support(gem.support_gems[-1].id)
		_set_status("Suporte %s removido" % _friendly_choice_name(removed.id))
	_show_tab(TAB_GEMS)


func _toggle_equipment(slot: EquipmentItemDefinition.Slot, index: int, instance_id: StringName) -> void:
	if _equipment.get_equipped(slot, index) != null:
		if EquipmentTransaction.unequip_to_inventory(_inventory, _equipment, slot, index):
			_set_status("Item devolvido ao inventário")
	else:
		if EquipmentTransaction.equip_from_inventory(_inventory, _equipment, instance_id, index):
			_set_status("Item equipado")
		else:
			_set_status("Equipamento incompatível ou indisponível")
	_show_tab(TAB_EQUIPMENT)


func _add_section_title(parent: Control, title: String, subtitle: String) -> void:
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 22)
	parent.add_child(title_label)
	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.modulate = Color("8fa7b5")
	parent.add_child(subtitle_label)


func _add_grid_label(grid: GridContainer, value: String) -> void:
	var label := Label.new()
	label.text = value
	label.custom_minimum_size.x = 92.0
	grid.add_child(label)


func _friendly_choice_name(value: StringName) -> String:
	return String(value).replace("_", " ").capitalize()


func _friendly_branch(value: StringName) -> String:
	return {
		&"essence": "ESSENCIA",
		&"adaptation": "ADAPTACAO",
		&"convergence": "CONVERGENCIA",
	}.get(value, "LINHA")


func _equipment_key(slot: EquipmentItemDefinition.Slot, index: int) -> String:
	return "%d:%d" % [slot, index]


func _set_status(message: String) -> void:
	_status_label.text = message
