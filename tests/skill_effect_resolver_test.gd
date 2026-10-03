extends SceneTree

const CatalogScript := preload("res://src/gameplay/content/beta_content_catalog.gd")
const ResolverScript := preload("res://src/gameplay/skills/skill_effect_resolver.gd")


func _init() -> void:
	var catalog: RefCounted = CatalogScript.new()
	if not bool(catalog.call("load_from")):
		push_error("Could not load beta content for skill resolution")
		quit(1)
		return
	var active: Dictionary = catalog.call("find_definition", "active_gems", "agulha_lastro")
	var twin: Dictionary = catalog.call("find_definition", "support_gems", "projeteis_gemeos")
	var area: Dictionary = catalog.call("find_definition", "support_gems", "area_expandida")
	var resolver: RefCounted = ResolverScript.new()
	if not bool(resolver.call("supports", active, twin)) or bool(resolver.call("supports", active, area)):
		push_error("Support tag compatibility is incorrect")
		quit(1)
		return
	var supports: Array[Dictionary] = [twin]
	var evolutions: Array[Dictionary] = [{"power_multiplier": 1.25, "pierce_add": 1}]
	var effect: Dictionary = resolver.call("resolve", active, supports, evolutions)
	if (
		not is_equal_approx(float(effect["power"]), 35.0 * 0.78 * 1.25)
		or int(effect["projectile_count"]) != 1
		or int(effect["pierce"]) != 1
	):
		push_error("Support and evolution modifiers did not compose")
		quit(1)
		return
	print("SKILL_EFFECT_OK: support compatibility and modifier composition validated")
	quit(0)
