extends SceneTree

## Gera a wiki pública (Markdown, só texto) a partir dos dados do jogo:
##   godot --headless --path . --script tools/wiki/build_wiki.gd [-- --out=<pasta>]
## Padrão: docs/wiki. Para publicar no repositório público da wiki: sh tools/wiki/publish_wiki.sh. Só texto: nada de
## arte, som ou ícones (assets de terceiros não podem sair do repositório privado).

const WikiPages := preload("res://tools/wiki/wiki_pages.gd")


func _init() -> void:
	var out := "res://docs/wiki"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			out = argument.trim_prefix("--out=")
	var path := ProjectSettings.globalize_path(out) if out.begins_with("res://") else out
	DirAccess.make_dir_recursive_absolute(path)
	var pages: Dictionary = WikiPages.new().build()
	for file_name: String in pages:
		var file := FileAccess.open(path.path_join(file_name), FileAccess.WRITE)
		if file == null:
			push_error("Could not write %s" % path.path_join(file_name))
			quit(1)
			return
		file.store_string(String(pages[file_name]))
	print("WIKI_OK: %d pages in %s" % [pages.size(), path])
	quit(0)
