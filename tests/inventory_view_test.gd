extends SceneTree

## Decisão 584: inventário no estilo de Hero Siege. Boneco com os 21 encaixes, mochila em grade de
## ícones, clique equipa, botão direito vende com confirmação, clique no boneco desequipa e a dica
## é colorida (raridade, afixos, nível do item).

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const Menu := preload("res://src/prototype/village/player_menu.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var sim := Simulation.new()
	sim.setup(5840)
	sim.add_player(1, &"rui")
	sim._add_equipment_instance(&"rui", "lendario_coroa_de_brasa", "regular", 40)
	var model := sim.menu_model(1)
	var menu := Menu.new()
	root.add_child(menu)
	await process_frame
	menu.refresh(model)
	menu.open("inventory")
	await process_frame
	var doll := menu.find_child("Doll", true, false) as Control
	if doll == null or doll.find_children("Slot_*", "", false, false).size() != 21:
		return _fail("Doll must show the 21 equipment slots")
	var backpack := menu.find_child("Backpack", true, false) as GridContainer
	var items := backpack.find_children("Item_*", "", false, false)
	if backpack.get_child_count() < Menu.BACKPACK_MIN_CELLS or items.size() != (model["inventory_equipment"] as Array).size():
		return _fail("Backpack must be an icon grid with one cell per item")
	var crown: Control = null
	for cell: Control in items:
		if String(cell.name).contains("lendario_coroa_de_brasa"):
			crown = cell
	var tooltip := String((crown.get_child(0) as Control).tooltip_text)
	if not tooltip.contains("[color=#7fb0ff]") or not tooltip.contains("Nivel 40") or not tooltip.contains(ItemTier.color("legendary").to_html(false)):
		return _fail("Item tooltip must color rarity and affixes and show item level: %s" % tooltip)
	var equipped := []
	var sold := []
	menu.equip_requested.connect(func(instance_id: StringName) -> void: equipped.append(instance_id))
	menu.sell_requested.connect(func(instance_id: StringName) -> void: sold.append(instance_id))
	crown.emit_signal("pressed")
	crown.emit_signal("secondary_pressed")
	var dialog := menu.find_child("SellDialog", true, false) as ConfirmationDialog
	if equipped.size() != 1 or dialog == null or not dialog.visible or not sold.is_empty():
		return _fail("Click equips; right click asks before selling")
	dialog.confirmed.emit()
	if sold.size() != 1 or sold[0] != equipped[0]:
		return _fail("Confirming the dialog sells that item")
	var weapon_slot := doll.find_child("Slot_ARMA", false, false)
	var unequipped := []
	menu.unequip_requested.connect(func(slot: int, index: int) -> void: unequipped.append([slot, index]))
	weapon_slot.emit_signal("pressed")
	if unequipped.size() != 1:
		return _fail("Clicking an equipped slot unequips it")
	print("INVENTORY_VIEW_OK: 21-slot doll, icon backpack, colored tooltips with affixes and level, equip, confirmed sell and unequip")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
