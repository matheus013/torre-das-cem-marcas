extends SceneTree

const SkillThemes := preload("res://src/presentation/vfx/skill_themes.gd")
const VfxLayerScript := preload("res://src/presentation/vfx/vfx_layer.gd")
const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const NEW_GEMS := ["bola_de_fogo", "bolha_corrosiva", "cometa_sombrio", "raizes_presas", "pilar_sagrado", "esfera_de_gelo", "trovao_descendente"]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var beta := JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json")) as Dictionary
	var gem_ids := {}
	for gem: Dictionary in beta["active_gems"]:
		gem_ids[String(gem["id"])] = true
	for gem_id: String in SkillThemes.GEMS:
		if not gem_ids.has(gem_id):
			return _fail("Theme for unknown gem: " + gem_id)
	for gem_id in NEW_GEMS:
		if not gem_ids.has(gem_id) or SkillThemes.for_gem(gem_id).is_empty():
			return _fail("New elemental gem missing or without element: " + gem_id)
	for element: String in SkillThemes.ELEMENTS:
		for role in ["projectile", "impact", "burst", "strike", "link", "beam"]:
			var key := String((SkillThemes.ELEMENTS[element] as Dictionary).get(role, ""))
			if not key.is_empty() and int(VfxLayerScript.anim_frames(key)) < 2:
				return _fail("Element %s role %s has no animation strip (%s)" % [element, role, key])

	var layer: Node2D = VfxLayerScript.new()
	root.add_child(layer)
	layer.set("theme", "bola_de_fogo")
	layer.call("travel", "vfx/needle", Vector2.ZERO, Vector2(200.0, 0.0), 0.2, 30.0)
	if _kinds(layer) != ["projectile", "anim"]:
		return _fail("Themed projectile must fly animated and end in its element impact: %s" % [_kinds(layer)])
	layer.call("clear")
	layer.set("theme", "arco_voltaico")
	layer.call("chain", [Vector2.ZERO, Vector2(90.0, 0.0), Vector2(180.0, 20.0)])
	if _kinds(layer).count("stretch") != 2:
		return _fail("Lightning chain must stretch a bolt between each pair of targets")
	layer.call("clear")
	layer.set("theme", "raio_prismatico")
	layer.call("beam", Vector2.ZERO, Vector2(400.0, 0.0), 16.0)
	if not _kinds(layer).has("stretch"):
		return _fail("Beam must stretch the light strip")
	layer.call("clear")
	layer.set("theme", "")
	layer.call("travel", "vfx/needle", Vector2.ZERO, Vector2(200.0, 0.0), 0.2, 9.0)
	if _kinds(layer)[0] != "travel":
		return _fail("Physical gems keep the neutral projectile")

	var sim := Simulation.new()
	sim.setup(77)
	sim.add_player(1, &"eloa")
	sim.unlock_all_gems(1, true)
	sim.set_gem_slot(1, 0, "bola_de_fogo")
	sim.enter_tower(1)
	sim.drain_events()
	var target := ((sim.get("enemies") as Array)[0] as Dictionary)["position"] as Vector2
	sim.use_skill(1, 0, target)
	var themed := false
	for event: Dictionary in sim.drain_events():
		if String(event.get("type", "")) == "vfx" and String(event.get("theme", "")) == "bola_de_fogo":
			themed = true
	if not themed:
		return _fail("Simulation must tag gem visuals with the gem id")
	print("SKILL_THEMES_OK: %d themed gems, %d elements, projectile/link/beam and simulation tagging" % [SkillThemes.GEMS.size(), SkillThemes.ELEMENTS.size()])
	quit(0)


func _kinds(layer: Node2D) -> Array[String]:
	var result: Array[String] = []
	for effect: Dictionary in layer.get("_effects") as Array:
		result.append(String(effect["kind"]))
	return result


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
