extends SceneTree

const Sprites := preload("res://src/presentation/art/sprite_library.gd")
const Vfx := preload("res://src/presentation/vfx/vfx_layer.gd")

class FieldPreview:
	extends "res://src/prototype/village/village_exploration.gd"

	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

	func _draw() -> void:
		var gems := ["brasa_persistente", "pantano_acido", "prisao_gravitica", "raizes_presas", "circulo_de_reparo", "semeadura_vital", "laminas_orbitais", "satelites_de_geada"]
		for index in gems.size():
			var origin := Vector2((index % 4) * 250 + 125, (index / 4) * 220 + 110)
			_draw_ground_effect({"gem_id": gems[index], "position": origin, "radius": 75.0, "duration": 3.0,
				"mechanic": "orbit" if index >= 6 else "sanctuary" if index >= 4 else "field",
				"points": [origin + Vector2(0, -40), origin + Vector2(-40, 30), origin + Vector2(40, 30)], "collision_radius": 20.0})


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 900)
	RenderingServer.set_default_clear_color(Color("343b42"))
	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json")) as Dictionary
	var layer := Node2D.new()
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(layer)
	var index := 0
	for gem: Dictionary in catalog["active_gems"]:
		var origin := Vector2((index % 8) * 160, (index / 8) * 145)
		var label := Label.new()
		label.text = String(gem["name"]) + "\n" + String(gem["mechanic"])
		label.add_theme_font_size_override("font_size", 11)
		label.position = origin + Vector2(4, 103)
		layer.add_child(label)
		var icon := Sprite2D.new()
		icon.texture = Sprites.texture("icons/" + String(gem["id"]))
		icon.position = origin + Vector2(80, 55)
		icon.scale = Vector2.ONE * 72.0 / icon.texture.get_width()
		layer.add_child(icon)
		index += 1
	var output := "res://art/shots/skills"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output + "/icons.png"))
	layer.queue_free()
	await process_frame
	layer = Node2D.new()
	root.size.y = ceili(Vfx.ANIMS.size() / 8.0) * 145
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(layer)
	index = 0
	for key: String in Vfx.ANIMS:
		var config := Vfx.ANIMS[key] as Dictionary
		var texture := Sprites.texture(Vfx.ANIM_ROOT + String(config.get("sprite", key)))
		if texture == null:
			continue
		var origin := Vector2((index % 8) * 160, (index / 8) * 145)
		var label := Label.new()
		label.text = key
		label.add_theme_font_size_override("font_size", 12)
		label.position = origin + Vector2(4, 104)
		layer.add_child(label)
		var sprite := Sprite2D.new()
		var frame := AtlasTexture.new()
		frame.atlas = texture
		var width := Vfx._frame_width(key)
		var height := Vfx._frame_height(key)
		frame.region = Rect2(width * mini(2, Vfx.anim_frames(key) - 1), 0, width, height)
		sprite.texture = frame
		sprite.position = origin + Vector2(80, 55)
		sprite.scale = Vector2.ONE * 80.0 / maxf(width, height)
		layer.add_child(sprite)
		index += 1
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output + "/vfx.png"))
	layer.queue_free()
	await process_frame
	root.size = Vector2i(1000, 680)
	var fields := FieldPreview.new()
	root.add_child(fields)
	for item in 8:
		var label := Label.new()
		label.text = ["Brasa Persistente", "Pantano Acido", "Prisao Gravitica", "Raizes Presas", "Circulo de Reparo", "Semeadura Vital", "Laminas Orbitais", "Satelites de Geada"][item]
		label.position = Vector2((item % 4) * 250 + 12, (item / 4) * 220 + 195)
		fields.add_child(label)
	for item in 3:
		var warning := Vfx.new()
		fields.add_child(warning)
		warning.theme = ["pilar_sagrado", "trovao_descendente", "cometa_de_vidro"][item]
		warning.target_ring(Vector2(item * 330 + 160, 580), 45.0, 1.0)
		warning.set_process(false)
		warning._process(0.7)
		var label := Label.new()
		label.text = warning.theme
		label.position = Vector2(item * 330 + 50, 645)
		fields.add_child(label)
	for time in [0.0, 0.3]:
		fields.set("_anim_time", time)
		fields.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output + "/fields-%d.png" % roundi(time * 10)))
	print("SKILL_ASSET_SHOTS_OK")
	quit(0)
