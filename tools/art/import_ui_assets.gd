extends SceneTree

const SOURCES := {
	"dark_ages.png": "res://assets/new/ui/DarkAgesUi_v1.0/32x32-Tilesheet.png",
	"medieval_icons.png": "res://assets/new/ui/Free_Medieval_Fantasy_UI_Pack/icons1.png",
}
const FRAME_REGIONS := [Rect2i(0, 0, 96, 96), Rect2i(208, 16, 64, 64), Rect2i(192, 96, 32, 32), Rect2i(256, 96, 32, 32), Rect2i(0, 104, 64, 18), Rect2i(128, 104, 64, 18)]
const ICON_CELLS := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), Vector2i(7, 0), Vector2i(0, 1), Vector2i(6, 1), Vector2i(6, 3), Vector2i(7, 3), Vector2i(7, 4), Vector2i(2, 6)]

func _init() -> void:
	var destination := ProjectSettings.globalize_path("res://assets/ui")
	DirAccess.make_dir_recursive_absolute(destination)
	for file_name: String in SOURCES:
		var source := Image.load_from_file(SOURCES[file_name])
		if source == null or source.is_empty():
			push_error("Could not integrate UI source: " + SOURCES[file_name])
			quit(1)
			return
		var atlas := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
		if file_name == "dark_ages.png":
			for rect: Rect2i in FRAME_REGIONS:
				atlas.blit_rect(source, rect, rect.position)
		else:
			for cell: Vector2i in ICON_CELLS:
				atlas.blit_rect(source, Rect2i(cell * 32, Vector2i(32, 32)), cell * 32)
		if atlas.save_png(destination.path_join(file_name)) != OK:
			push_error("Could not save integrated UI atlas")
			quit(1)
			return
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://assets/new/ui/DarkAgesUi_v1.0/LICENSE.txt"), destination.path_join("DarkAges-LICENSE.txt"))
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://assets/new/ui/Free_Medieval_Fantasy_UI_Pack/Readme.txt"), destination.path_join("MedievalIcons-README.txt"))
	print("UI_ASSETS_IMPORTED: six frame regions and thirteen icons; sources unchanged")
	quit(0)
