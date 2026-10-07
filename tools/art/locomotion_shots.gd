extends SceneTree

const Sprites := preload("res://src/presentation/art/sprite_library.gd")
const DIRECTIONS := [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1260, 720)
	RenderingServer.set_default_clear_color(Color("343b42"))
	var entries: Array = []
	for id in ["eloa", "sena", "cira", "rui"]:
		entries.append({"id": id, "group": "characters"})
	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://art/actor-animations.json")) as Dictionary
	for actor: Dictionary in catalog["actors"]:
		if actor["group"] == "npcs":
			entries.append(actor)
	var output := "res://art/shots/locomotion"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for page in range(3):
		var layer := Node2D.new()
		layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		root.add_child(layer)
		var animated: Array[Dictionary] = []
		for column in range(7):
			var entry := entries[page * 7 + column] as Dictionary
			var key := String(entry["group"]) + "/" + String(entry["id"])
			var label := Label.new()
			label.text = String(entry["id"]).replace("_", " ") + "\nparado / andando"
			label.add_theme_font_size_override("font_size", 12)
			label.position = Vector2(column * 180 + 6, 12)
			layer.add_child(label)
			for row in range(4):
				for mode in range(2):
					var sprite := Sprite2D.new()
					sprite.centered = false
					sprite.offset = -Sprites.CHARACTER_FOOT_ANCHOR
					sprite.position = Vector2(column * 180 + 45 + mode * 90, row * 160 + 195)
					sprite.scale = Vector2.ONE * 1.35
					sprite.texture = Sprites.actor_frame(key, DIRECTIONS[row], mode == 1, 0.0)
					if sprite.texture == null:
						push_error("Missing locomotion texture: " + key)
						quit(1)
						return
					layer.add_child(sprite)
					if mode == 1:
						animated.append({"sprite": sprite, "key": key, "direction": DIRECTIONS[row]})
		var previous: PackedByteArray
		for phase in range(4):
			for actor: Dictionary in animated:
				(actor["sprite"] as Sprite2D).texture = Sprites.actor_frame(actor["key"], actor["direction"], true, float(phase) / 8.0)
			await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			if image.get_used_rect().size == Vector2i.ZERO or image.get_data() == previous:
				push_error("Locomotion render is blank or static")
				quit(1)
				return
			previous = image.get_data()
			image.save_png(ProjectSettings.globalize_path(output + "/page_%d_phase_%d.png" % [page, phase]))
		layer.queue_free()
		await process_frame
	print("LOCOMOTION_RENDER_OK: 21 actors, 84 idle directions, 336 walk poses")
	quit(0)
