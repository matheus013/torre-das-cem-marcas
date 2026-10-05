extends SceneTree

const Sprites := preload("res://src/presentation/art/sprite_library.gd")
const IDS := ["eloa", "sena", "cira", "rui"]
const DIRECTIONS := [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	RenderingServer.set_default_clear_color(Color("343b42"))
	var layer := Node2D.new()
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(layer)
	var sprites: Array[Sprite2D] = []
	for column in range(4):
		var label := Label.new()
		label.text = String(IDS[column]).to_upper()
		label.position = Vector2(column * 320 + 130, 16)
		layer.add_child(label)
		for row in range(4):
			var sprite := Sprite2D.new()
			sprite.centered = false
			sprite.offset = -Sprites.CHARACTER_FOOT_ANCHOR
			sprite.position = Vector2(column * 320 + 160, row * 155 + 210)
			sprite.scale = Vector2.ONE * 3.0
			layer.add_child(sprite)
			sprites.append(sprite)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/shots"))
	var previous: Image
	for phase in range(4):
		for column in range(4):
			for row in range(4):
				sprites[column * 4 + row].texture = Sprites.character_frame(IDS[column], DIRECTIONS[row], true, float(phase) / 8.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png(ProjectSettings.globalize_path("res://art/shots/character_walk_phase_%d.png" % phase))
		if previous != null:
			var changed := 0
			for y in range(image.get_height()):
				for x in range(image.get_width()):
					if image.get_pixel(x, y) != previous.get_pixel(x, y):
						changed += 1
			if changed < 1000:
				push_error("Walk preview is blank or does not animate")
				quit(1)
				return
			print("ANIMATION_RENDER: phase %d, %d changed pixels" % [phase, changed])
		previous = image
	quit(0)
