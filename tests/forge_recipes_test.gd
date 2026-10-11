extends SceneTree

## Épico E1, fase 2b (G3.3): fontes direcionadas. Cada guardião vencido libera na Forja uma receita
## que troca materiais do armazém e prata por uma peça garantida do encaixe escolhido (rara antes do
## andar 40, épica depois; nunca lendária). Materiais dizem quem os derruba, e a regra de partilha
## do saque fica visível.

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const ShopMenu := preload("res://src/prototype/village/shop_menu.gd")
const TowerContentScript := preload("res://src/gameplay/world/tower_content.gd")


func _init() -> void:
	_run.call_deferred()


func _world() -> WorldSimulation:
	var sim := Simulation.new()
	sim.setup(5874)
	sim.add_player(1, &"eloa")
	var npc := sim.village_life.call("find", "dalia_ferral") as Dictionary
	sim.player(1)["position"] = (npc["position"] as Vector2) + Vector2(20.0, 0.0)
	sim._gear(1)["silver"] = 10000
	return sim


func _run() -> void:
	var sim := _world()
	var recipes := sim.forge_recipes()
	if recipes.size() != TowerContentScript.collection("bosses").size() or recipes.any(func(recipe: Dictionary) -> bool: return bool(recipe["unlocked"])):
		return _fail("There must be one locked recipe per guardian at the start")
	sim.deepest_floor = 10
	var gallery := sim.forge_recipes()[0]
	if not bool(gallery["unlocked"]) or bool(sim.forge_recipes()[2]["unlocked"]):
		return _fail("Beating a guardian must unlock only its recipe")

	# Sem materiais não forja; com eles, a peça vem garantida no encaixe e no tier.
	if sim.forge_recipe(1, String(gallery["id"]), "boots"):
		return _fail("Forging needs the materials in the village storage")
	for material: String in gallery["materials"]:
		sim.banked_loot[material] = int(gallery["materials"][material]) + 2
	var inventory := sim._gear(1)["inventory"] as ItemInventory
	var before := inventory.items.keys()
	var silver := int(sim._gear(1)["silver"])
	if not sim.forge_recipe(1, String(gallery["id"]), "boots"):
		return _fail("A ready recipe must forge")
	var forged: EquipmentItemInstance = null
	for instance_id: StringName in inventory.items:
		if instance_id not in before:
			forged = inventory.items[instance_id]
	if forged == null or int(forged.definition.slot) != EquipmentItemDefinition.Slot.BOOTS or ItemTier.key(forged.tier) not in ["rare", "uncommon", "common"] or forged.item_level != int(gallery["floor"]):
		return _fail("The forged piece must be boots of the recipe tier and guardian level")
	if int(sim._gear(1)["silver"]) != silver - int(gallery["silver"]):
		return _fail("Forging must charge the recipe silver")
	for material: String in gallery["materials"]:
		if int(sim.banked_loot.get(material, 0)) != 2:
			return _fail("Forging must consume the recipe materials")

	# Recusas: longe da Forja, encaixe inválido, receita bloqueada.
	var far := _world()
	far.deepest_floor = 10
	for material: String in gallery["materials"]:
		far.banked_loot[material] = 99
	far.player(1)["position"] = (far.player(1)["position"] as Vector2) + Vector2(900.0, 0.0)
	if far.forge_recipe(1, String(gallery["id"]), "boots"):
		return _fail("Forging requires being at the forge")
	var near := _world()
	near.deepest_floor = 10
	for material: String in gallery["materials"]:
		near.banked_loot[material] = 99
	if near.forge_recipe(1, String(gallery["id"]), "relic") or near.forge_recipe(1, String(near.forge_recipes()[5]["id"]), "boots"):
		return _fail("Invalid slots and locked recipes must be refused")

	# Fontes visíveis: o material diz quem o derruba.
	var tooltips := sim.menu_model(1)["item_tooltips"] as Dictionary
	if not String(tooltips.get("junco_mineral", "")).contains("Cai de:"):
		return _fail("Materials must say which monsters drop them: %s" % tooltips.get("junco_mineral", ""))

	# Janela da Forja: uma linha por receita e a regra de partilha.
	var shop := ShopMenu.new()
	root.add_child(shop)
	shop.call("open", sim.shop_model(1))
	await process_frame
	var rows := shop.find_child("ForgeRecipes", true, false)
	var sharing := shop.find_child("SharingRule", true, false) as Label
	if rows == null or rows.get_child_count() != recipes.size() or sharing == null or not sharing.text.contains("Partilha"):
		return _fail("The forge window must list the recipes and the sharing rule")
	var locked_row := rows.get_child(rows.get_child_count() - 1)
	if not (locked_row.find_child("Forge", true, false) as Button).disabled:
		return _fail("Locked recipes must not be forgeable")
	shop.queue_free()
	await process_frame
	print("FORGE_RECIPES_OK: one recipe per guardian, guaranteed slot and tier, costs, refusals, material sources and sharing rule")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
