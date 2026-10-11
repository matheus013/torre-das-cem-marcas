extends SceneTree

## Wiki pública (decisão 604): as páginas geradas cobrem cada personagem, gema, suporte, inimigo,
## chefe, bioma, arma única e lendário do jogo, só em texto (sem arte de terceiros) e com a licença
## CC BY-NC 4.0 em todas as páginas.

const WikiPages := preload("res://tools/wiki/wiki_pages.gd")
const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const TowerContentScript := preload("res://src/gameplay/world/tower_content.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var pages: Dictionary = WikiPages.new().build()
	var sim := Simulation.new()
	sim.setup(1)
	var expected := {
		"Personagens.md": sim.content("playable_characters"),
		"Gemas-Ativas.md": sim.content("active_gems"),
		"Gemas-de-Suporte.md": sim.content("support_gems"),
		"Invocacoes.md": sim.content("summons"),
		"Inimigos.md": sim.content("enemies").filter(func(enemy: Dictionary) -> bool: return String(enemy.get("encounter_class", "")) in ["common", "elite"]),
		"Chefes.md": TowerContentScript.collection("bosses"),
		"Torre-e-Biomas.md": TowerContentScript.collection("biomes"),
		"Racas-e-Patentes.md": sim.content("monster_races"),
		"Armas-Unicas.md": sim.content("items").filter(func(item: Dictionary) -> bool: return item.has("unique_gem")),
		"Lendarios-e-Reliquias.md": sim.content("items").filter(func(item: Dictionary) -> bool: return String(item.get("tier", "")) == "legendary" and not item.has("unique_gem")),
	}
	for page: String in expected:
		var text := String(pages.get(page, ""))
		for entry: Dictionary in expected[page]:
			if not text.contains("## %s" % entry["name"]) and not text.contains("**%s**" % entry["name"]):
				return _fail("%s must document %s" % [page, entry["name"]])
	for floor_number in range(1, TowerContentScript.MAX_FLOOR + 1):
		if not String(pages["Andares.md"]).contains("| %d | %s |" % [floor_number, TowerContentScript.floor_def(floor_number)["name"]]):
			return _fail("Andares.md must list floor %d" % floor_number)
	for page: String in pages:
		var text := String(pages[page])
		if text.contains("![") or text.contains("assets/") or text.contains(".png"):
			return _fail("%s must stay text-only (no third-party art): licensed files cannot leave the private repo" % page)
		if page != "_Sidebar.md" and not text.contains("CC BY-NC 4.0"):
			return _fail("%s must carry the CC BY-NC 4.0 notice" % page)
	# Toda página citada na barra lateral existe.
	for page: Array in WikiPages.PAGES:
		if not pages.has("%s.md" % page[0]) or not String(pages["_Sidebar.md"]).contains("(%s)" % page[0]):
			return _fail("Sidebar and pages must match: %s" % page[0])
	print("WIKI_PAGES_OK: %d pages cover characters, gems, supports, summons, enemies, bosses, biomes, races, uniques, legendaries and 100 floors, text-only and licensed" % pages.size())
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
