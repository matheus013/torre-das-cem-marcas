extends SceneTree

const Sprites := preload("res://src/presentation/art/sprite_library.gd")
const DIRECTIONS := [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1440, 1620)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	RenderingServer.set_default_clear_color(Color("343b42"))
	var layer := Node2D.new()
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.add_child(layer)
	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://art/actor-animations.json")) as Dictionary
	var sprites: Array[Sprite2D] = []
	var keys: Array[String] = []
	for index in range(catalog["actors"].size()):
		var actor: Dictionary = catalog["actors"][index]
		var origin := Vector2(index % 8 * 180, index / 8 * 180)
		var label := Label.new()
		label.text = String(actor["id"]).replace("_", " ")
		label.position = origin + Vector2(6, 8)
		label.size = Vector2(168, 35)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 12)
		layer.add_child(label)
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.offset = -Sprites.CHARACTER_FOOT_ANCHOR
		sprite.position = origin + Vector2(90, 170)
		sprite.scale = Vector2.ONE * 2.0
		layer.add_child(sprite)
		sprites.append(sprite)
		keys.append(String(actor["group"]) + "/" + String(actor["id"]))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/shots"))
	for direction in range(4):
		var previous: Image
		for phase in range(4):
			for index in range(sprites.size()):
				sprites[index].texture = Sprites.actor_frame(keys[index], DIRECTIONS[direction], true, float(phase) / 8.0)
				if sprites[index].texture == null:
					push_error("Missing preview texture: " + keys[index])
					quit(1)
					return
			await process_frame
			await RenderingServer.frame_post_draw
			var image := viewport.get_texture().get_image()
			image.save_png(ProjectSettings.globalize_path("res://art/shots/actors_direction_%d_phase_%d.png" % [direction, phase]))
			if previous != null and image.get_data() == previous.get_data():
				push_error("Actor preview does not animate")
				quit(1)
				return
			previous = image
		print("ACTOR_RENDER_OK: direction %d, 72 actors, 4 changing frames" % direction)
	quit(0)
