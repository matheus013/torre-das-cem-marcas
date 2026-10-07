extends SceneTree

const Themes := preload("res://src/presentation/vfx/skill_themes.gd")
const Vfx := preload("res://src/presentation/vfx/vfx_layer.gd")
const Sprites := preload("res://src/presentation/art/sprite_library.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json")) as Dictionary
	for gem: Dictionary in catalog["active_gems"]:
		var texture := Sprites.texture("icons/" + String(gem["id"]))
		if texture == null or texture.get_image().get_used_rect().size == Vector2i.ZERO:
			return _fail("Missing or blank skill icon: " + String(gem["id"]))
	for key: String in Vfx.ANIMS:
		if not key.begins_with("sk_"):
			continue
		if Vfx.anim_frames(key) != 4:
			return _fail("New skill animation must have four frames: " + key)
		var unique := {}
		for index in 4:
			var image := Sprites.texture("vfx/anim/" + key).get_image().get_region(Rect2i(index * 64, 0, 64, 64))
			if image.get_used_rect().size == Vector2i.ZERO:
				return _fail("Empty animation frame: " + key)
			for edge in 64:
				if image.get_pixel(edge, 0).a > 0.0 or image.get_pixel(edge, 63).a > 0.0 or image.get_pixel(0, edge).a > 0.0 or image.get_pixel(63, edge).a > 0.0:
						return _fail("Animation has no transparent padding: " + key)
			unique[image.get_data().hex_encode().sha256_text()] = true
			var config := Vfx.ANIMS[key] as Dictionary
			var frame := Vfx.sheet_frame(key, "prisao_gravitica", float(index) / float(config["fps"]))
			if frame["region"] != Rect2(index * 64, 0, 64, 64) or frame["tint"] != Color.WHITE:
				return _fail("Single-row animation incorrectly uses elemental row or tint: " + key)
		if unique.size() < 2:
			return _fail("Animation repeats one static frame: " + key)
	var dark := Themes.for_gem("prisao_gravitica")
	if dark.get("ground", "") != "sk_gravity_field" or Themes.for_gem("pulso_cicatriz").has("ground"):
		return _fail("Skill role overrides leaked into the shared element")
	if Themes.for_gem("laminas_orbitais").get("orbit", "") == Themes.for_gem("satelites_de_geada").get("orbit", ""):
		return _fail("Steel blades and ice crystals need distinct silhouettes")
	var layer := Vfx.new()
	root.add_child(layer)
	for gem in ["pilar_sagrado", "trovao_descendente", "chuva_ferral", "cometa_de_vidro"]:
		layer.clear()
		layer.theme = gem
		layer.target_ring(Vector2(100, 100), 40, 0.8)
		var projectiles := 0
		var rings := 0
		for effect: Dictionary in layer.get("_effects"):
			projectiles += int(effect["kind"] == "projectile")
			rings += int(effect["kind"] == "target_ring")
		if rings != 1 or projectiles != int(gem in ["chuva_ferral", "cometa_de_vidro"]):
			return _fail("Incorrect impact warning for " + gem)
	layer.queue_free()
	print("SKILL_ASSETS_OK: %d icons, 8 animated strips, padding, roles and impact warnings" % catalog["active_gems"].size())
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
