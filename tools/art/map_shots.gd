extends SceneTree

const OUTPUT := "res://art/shots/maps/"
const Floor := preload("res://src/gameplay/world/floor_layout.gd")
const Layout := preload("res://src/gameplay/world/world_layout.gd")
const Sprites := preload("res://src/presentation/art/sprite_library.gd")

class MapCanvas extends Node2D:
	var maps: Array[Dictionary] = []
	func _draw() -> void:
		for index in range(maps.size()):
			var map := maps[index]
			var village := bool(map.get("village", false))
			var origin := Vector2.ZERO if village else Vector2((index % 2) * 640, (index / 2) * 360 + 28)
			var size := map["size"] as Vector2
			var scale_factor := 0.4 if village else minf(610.0 / size.x, 310.0 / size.y)
			draw_set_transform(origin, 0, Vector2.ONE * scale_factor)
			var tile := Sprites.texture(String(map["tile"]))
			if map.has("arena_center"):
				draw_circle(map["arena_center"], float(map["arena_radius"]), Color("60665d"))
			else:
				draw_texture_rect(tile, Rect2(Vector2.ZERO, size), true)
			if village:
				for district: Dictionary in Layout.VillagePlan.DISTRICTS:
					draw_texture_rect(Sprites.texture(district["tile"]), district["rect"], true)
				for road in Layout.VILLAGE_ROADS:
					draw_texture_rect(Sprites.texture("tiles/road"), road, true)
			else:
				var route := map.get("route", []) as Array
				for at in range(route.size() - 1):
					draw_line(route[at], route[at + 1], Color(0.8, 0.83, 0.75, 0.1), 180)
			var pieces := (map["props"] as Array).duplicate()
			pieces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["base"].y < b["base"].y)
			for piece: Dictionary in pieces:
				var texture := Sprites.texture(piece["sprite"])
				if texture == null:
					continue
				var dimensions := texture.get_size() * float(piece.get("visual_scale", 1.0))
				draw_texture_rect(texture, Rect2((piece["base"] as Vector2) - Vector2(dimensions.x * 0.5, dimensions.y), dimensions), false)
			if not village:
				draw_circle(map["entry"], 32, Color("71ddb1"))
				draw_circle((map["stairs"] as Rect2).get_center(), 32, Color("f6d473"))
			draw_set_transform(Vector2.ZERO)
			if not village:
				draw_string(ThemeDB.fallback_font, origin + Vector2(6, -8), "Andar %d · %s" % [int(map["floor"]), String(map["biome"])], HORIZONTAL_ALIGNMENT_LEFT, 600, 16, Color.WHITE)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1536, 960)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var canvas := MapCanvas.new()
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.add_child(canvas)
	canvas.maps = [{"village": true, "size": Layout.WORLD_SIZE, "tile": "tiles/grass", "props": Layout.pieces(&"village", 1)}]
	await _capture(viewport, canvas, "village_plan")
	viewport.size = Vector2i(1280, 1800)
	for page in range(10):
		canvas.maps.clear()
		for number in range(page * 10 + 1, page * 10 + 11):
			var layout := Floor.generate(number).duplicate(true)
			layout["tile"] = preload("res://src/gameplay/world/tower_content.gd").biome(layout["biome"])["tile"]
			canvas.maps.append(layout)
		await _capture(viewport, canvas, "floors_%02d_%02d" % [page * 10 + 1, page * 10 + 10])
	viewport.queue_free()
	await process_frame
	quit(0)

func _capture(viewport: SubViewport, canvas: MapCanvas, id: String) -> void:
	canvas.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image()
	assert(not result.is_empty())
	assert(result.get_pixel(result.get_width() / 4, result.get_height() / 4).a > 0.0)
	result.save_png(ProjectSettings.globalize_path(OUTPUT + id + ".png"))
	print("MAP_SHOT ", id)
