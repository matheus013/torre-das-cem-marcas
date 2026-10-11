extends RefCounted

## Páginas da wiki pública (só texto, sem arte nem som de terceiros), geradas dos dados reais do jogo.
## `build()` devolve {nome do arquivo: Markdown}. Escrita por tools/wiki/build_wiki.gd e coberta por
## tests/wiki_pages_test.gd. Licença das páginas: CC BY-NC 4.0 (decisão 604).

const Simulation := preload("res://src/gameplay/world/world_simulation.gd")
const TowerContentScript := preload("res://src/gameplay/world/tower_content.gd")
const ResistancesScript := preload("res://src/gameplay/combat/resistances.gd")
const ItemAffixesScript := preload("res://src/gameplay/items/item_affixes.gd")
const BestiaryScript := preload("res://src/gameplay/content/bestiary.gd")
const MenuScript := preload("res://src/prototype/village/player_menu.gd")
const WEAPON_PROFILES := "res://data/combat/weapon_profiles.json"

const PAGES := [
	["Home", "Início"], ["Personagens", "Personagens"], ["Armas", "Armas e ataque básico"],
	["Gemas-Ativas", "Gemas ativas"], ["Gemas-de-Suporte", "Gemas de suporte"], ["Invocacoes", "Invocações"],
	["Inimigos", "Inimigos"], ["Chefes", "Chefes"], ["Racas-e-Patentes", "Raças, patentes e afixos de monstro"],
	["Torre-e-Biomas", "Torre e biomas"], ["Andares", "Os 100 andares"], ["Resistencias", "Resistências"],
	["Dificuldades", "Dificuldades"], ["Armas-Unicas", "Armas únicas"], ["Lendarios-e-Reliquias", "Lendários e relíquias"],
	["Equipamentos-e-Materiais", "Equipamentos, consumíveis e materiais"], ["Afixos", "Afixos de item"],
]
const LICENSE_NOTE := "Conteúdo de *Aresta — A Torre das Cem Marcas* © 2026 Matheus Santos, sob [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/). Gerado dos dados do jogo; valores provisórios, sujeitos a balanceamento."
const ELEMENT_LABELS := {"": "Físico"}
const MECHANIC_LABELS := {
	"barrier": "Barreira", "beam": "Feixe", "boomerang": "Bumerangue", "chain": "Corrente", "cone": "Cone",
	"dash": "Movimento", "field": "Campo", "meteor": "Meteoro", "mine": "Mina", "nova": "Nova", "orbit": "Órbita",
	"poison_pool": "Poça de veneno", "projectile": "Projétil", "sanctuary": "Santuário", "spores": "Esporos",
	"summon": "Invocação", "volley": "Saraivada",
}
const BRANCH_LABELS := {"essence": "Essência", "adaptation": "Adaptação", "convergence": "Convergência"}
const SLOT_LABELS := {
	"weapon": "Arma", "offhand": "Mão secundária", "amulet": "Amuleto", "armor": "Armadura", "gloves": "Luvas",
	"boots": "Botas", "pants": "Calça", "ring": "Anel", "relic": "Relíquia", "none": "—",
}
const TIER_LABELS := {"common": "Comum", "uncommon": "Incomum", "rare": "Raro", "epic": "Épico", "legendary": "Lendário"}
const KIND_LABELS := {
	"melee": "Corpo a corpo", "ranged": "À distância", "support": "Suporte", "ambusher": "Emboscada",
	"mimic": "Imitador", "boss": "Chefe", "raid": "Raid",
}
const CLASS_LABELS := {"common": "Comum", "elite": "Elite", "boss": "Chefe", "raid": "Raid"}
const PEOPLE_LABELS := {"velaria": "Velária"}
const TAG_LABELS := {
	"area": "área", "chain": "corrente", "control": "controle", "damage": "dano", "defense": "defesa", "duration": "duração",
	"healing": "cura", "life": "Vida", "magic": "magia", "movement": "movimento", "physical": "físico", "poison": "veneno",
	"precision": "precisão", "projectile": "projétil", "protection": "proteção", "structure": "estrutura", "summon": "invocação",
}
const ENEMY_MECHANIC_LABELS := {
	"death_burst": "explode ao morrer", "echo_attack": "repete o ataque", "first_hit_shield": "anula o primeiro golpe",
	"gravity_pull": "puxa a personagem", "life_leech": "rouba Vida", "regeneration": "regenera Vida",
	"slowing_contact": "contato desacelera", "split_on_death": "divide-se ao morrer", "wall_hide": "esconde-se nas paredes",
}
const SUMMON_LABELS := {
	"chase_target": "persegue o alvo", "follow_owner": "segue o dono", "stationary": "fixa",
	"lowest_health_hostile": "inimigo mais ferido", "nearest_hostile": "inimigo mais próximo",
}

var sim: WorldSimulation
var _gem_names := {}
var _item_names := {}


func _init() -> void:
	sim = Simulation.new()
	sim.setup(1)
	for gem in sim.content("active_gems"):
		_gem_names[String(gem["id"])] = String(gem["name"])
	for item in sim.content("items"):
		_item_names[String(item["id"])] = String(item["name"])


func build() -> Dictionary:
	return {
		"Home.md": _home(), "_Sidebar.md": _sidebar(), "_Footer.md": LICENSE_NOTE + "\n",
		"Personagens.md": _characters(), "Armas.md": _weapons(), "Gemas-Ativas.md": _active_gems(),
		"Gemas-de-Suporte.md": _support_gems(), "Invocacoes.md": _summons(), "Inimigos.md": _enemies(),
		"Chefes.md": _bosses(), "Racas-e-Patentes.md": _races(), "Torre-e-Biomas.md": _biomes(),
		"Andares.md": _floors(), "Resistencias.md": _resistances(), "Dificuldades.md": _difficulties(),
		"Armas-Unicas.md": _uniques(), "Lendarios-e-Reliquias.md": _legendaries(),
		"Equipamentos-e-Materiais.md": _equipment(), "Afixos.md": _affixes(),
	}


# ---------------------------------------------------------------- navegação

func _home() -> String:
	var lines := PackedStringArray([
		"# Aresta — A Torre das Cem Marcas", "",
		"Wiki de referência do jogo: cada personagem, gema, inimigo, chefe, item e regra de combate, com os números que o jogo usa hoje.", "",
		"Aresta é um RPG de ação em pixel art (Godot 4) para até quatro jogadores. Você parte da vila de Aresta, sobe os 100 andares da Torre das Cem Marcas, derrota guardiões que entregam novas gemas e volta para trocar saque, forjar peças e evoluir a personagem.", "",
		"## Páginas", "",
	])
	for page: Array in PAGES.slice(1):
		lines.append("- [%s](%s)" % [page[1], page[0]])
	lines.append_array(PackedStringArray([
		"", "## Números em resumo", "",
		"| | |", "| --- | --- |",
		"| Personagens jogáveis | %d |" % sim.content("playable_characters").size(),
		"| Gemas ativas | %d |" % sim.content("active_gems").size(),
		"| Gemas de suporte | %d |" % sim.content("support_gems").size(),
		"| Inimigos | %d |" % _regular_enemies().size(),
		"| Chefes de andar | %d |" % TowerContentScript.collection("bosses").size(),
		"| Biomas | %d |" % TowerContentScript.collection("biomes").size(),
		"| Armas únicas | %d |" % _items_where(func(item: Dictionary) -> bool: return item.has("unique_gem")).size(),
		"| Lendários e relíquias | %d |" % _items_where(func(item: Dictionary) -> bool: return String(item.get("tier", "")) == "legendary" and not item.has("unique_gem")).size(),
		"| Dificuldades | %d |" % Simulation.DIFFICULTIES.size(),
		"", "Os textos internos do jogo ainda estão sem acentos; os nomes aparecem aqui como no jogo.", "",
		"> " + LICENSE_NOTE,
	]))
	return "\n".join(lines) + "\n"


func _sidebar() -> String:
	var lines := PackedStringArray(["**Aresta — Wiki**", ""])
	for page: Array in PAGES:
		lines.append("- [%s](%s)" % [page[1], page[0]])
	return "\n".join(lines) + "\n"


# ---------------------------------------------------------------- personagens e armas

func _characters() -> String:
	var lines := PackedStringArray(["# Personagens", "",
		"Quatro personagens jogáveis, todas até o nível 100. Cada uma tem uma passiva própria, uma arma inicial, uma gema inicial na tecla Q e marcos a cada 10 níveis, em que se escolhe uma opção entre as ofertas do marco.", ""])
	for character in sim.content("playable_characters"):
		var id := String(character["id"])
		var passive := character.get("passive", {}) as Dictionary
		var weapon_id := String(Simulation.STARTER_WEAPONS.get(StringName(id), ""))
		var gem_id := String(Simulation.STARTER_GEMS.get(StringName(id), ""))
		lines.append_array(PackedStringArray([
			"## %s" % character["name"], "",
			"| | |", "| --- | --- |",
			"| Povo | %s |" % _label(PEOPLE_LABELS, String(character.get("people", ""))),
			"| Família | %s |" % String(character.get("family", "")).capitalize(),
			"| Estilo | %s |" % String(character.get("style", "")).capitalize(),
			"| Nível máximo | %d |" % int(character.get("max_level", 100)),
			"| Arma inicial | %s |" % _item_names.get(weapon_id, weapon_id),
			"| Gema inicial | [%s](Gemas-Ativas#%s) |" % [_gem_names.get(gem_id, gem_id), _anchor(String(_gem_names.get(gem_id, gem_id)))],
			"| Afinidade de armas | %s |" % _affinities(id),
			"", "**Passiva — %s.** %s" % [passive.get("name", ""), passive.get("description", "")], "",
		]))
		if passive.has("maximum_resource"):
			lines.append("Recurso: %s, até %d." % [String(passive.get("resource_id", "")).capitalize(), int(passive["maximum_resource"])])
			lines.append("")
		lines.append("### Marcos de nível")
		lines.append("")
		var milestones := character.get("milestones", {}) as Dictionary
		var levels := milestones.keys()
		levels.sort_custom(func(a: Variant, b: Variant) -> bool: return int(a) < int(b))
		for level: Variant in levels:
			lines.append("#### Nível %s" % level)
			lines.append("")
			lines.append("| Opção | Ramo | Atributos | Efeito |")
			lines.append("| --- | --- | --- | --- |")
			for option: Dictionary in milestones[level] as Array:
				lines.append("| **%s** | %s | %s | %s |" % [option.get("name", ""), _label(BRANCH_LABELS, String(option.get("branch", ""))), _or_dash(_stats(option.get("stats", {}) as Dictionary)), _cell(String(option.get("description", "")))])
			lines.append("")
	return _page(lines)


func _affinities(character_id: String) -> String:
	var profiles := _weapon_profiles()
	var parts := PackedStringArray()
	var table := (profiles.get("affinities", {}) as Dictionary).get(character_id, {}) as Dictionary
	for weapon_type: String in table:
		parts.append("%s %d%%" % [((profiles["types"] as Dictionary).get(weapon_type, {}) as Dictionary).get("name", weapon_type), int(table[weapon_type])])
	return ", ".join(parts)


func _weapons() -> String:
	var profiles := _weapon_profiles()
	var lines := PackedStringArray(["# Armas e ataque básico", "",
		"O ataque básico depende do tipo da arma equipada. A afinidade da personagem com o tipo multiplica o dano. Armas únicas assumem a forma da arma inicial de quem as empunha, então qualquer personagem aproveita a peça.", "",
		"| Tipo | Dano | Alcance | Intervalo | Padrão | Dano por tipo | Guarda | Crítico extra | Escala |", "| --- | --- | --- | --- | --- | --- | --- | --- | --- |"])
	var types := profiles.get("types", {}) as Dictionary
	for weapon_type: String in types:
		var profile := types[weapon_type] as Dictionary
		var scaling := PackedStringArray()
		for stat: String in profile.get("scaling", {}) as Dictionary:
			scaling.append("%s +%s%%/ponto" % [_stat_name(stat), _num(float(profile["scaling"][stat]) * 100.0)])
		var pattern := String({"single": "Alvo único", "line": "Linha", "cone": "Cone"}.get(String(profile.get("pattern", "")), profile.get("pattern", "")))
		if profile.has("targets"):
			pattern += " (%d alvos)" % int(profile["targets"])
		lines.append("| %s | %s | %s | %ss | %s | %s | %s | %s | %s |" % [profile.get("name", weapon_type), _num(float(profile["power"])), _num(float(profile["range"])), _num(float(profile["interval"])), pattern,
			ResistancesScript.LABELS.get(String(profile.get("damage_type", "physical")), ""), _pct(float(profile.get("guard", 0.0))), _pct(float(profile.get("crit_add", 0.0))), ", ".join(scaling)])
	lines.append("")
	lines.append("Guarda reduz o dano recebido. Manoplas também roubam Vida (%s); Foco deixa o alvo vulnerável." % _pct(float((types.get("gauntlets", {}) as Dictionary).get("life_steal", 0.0))))
	lines.append("")
	lines.append("## Afinidade por personagem")
	lines.append("")
	var header := PackedStringArray(["Personagem"])
	var armed := types.keys().filter(func(weapon_type: String) -> bool: return weapon_type != "unarmed")
	for weapon_type: String in armed:
		header.append(String((types[weapon_type] as Dictionary).get("name", weapon_type)))
	lines.append("| " + " | ".join(header) + " |")
	lines.append("|" + " --- |".repeat(header.size()))
	for character in sim.content("playable_characters"):
		var row := PackedStringArray([String(character["name"])])
		var table := (profiles.get("affinities", {}) as Dictionary).get(String(character["id"]), {}) as Dictionary
		for weapon_type: String in armed:
			row.append("%d%%" % int(table.get(weapon_type, 100)))
		lines.append("| " + " | ".join(row) + " |")
	return _page(lines)


# ---------------------------------------------------------------- gemas

func _active_gems() -> String:
	var sources := _gem_sources()
	var lines := PackedStringArray(["# Gemas ativas", "",
		"Gemas são as habilidades. Cada personagem equipa até quatro (Q, W, E, R), começa com uma e ganha as demais dos guardiões da Torre: ao vencer um chefe, cada jogador na arena pode receber uma gema do conjunto dele que ainda não tem.", "",
		"**Maestria.** A gema ganha experiência quando é lançada e quando mata. Do nível 1 ao 21, cada nível soma potência; nos níveis 5, 10, 15 e 20 escolhe-se 1 de 3 evoluções e no 21 1 de 2 evoluções finais.", "",
		"| Gema | Elemento | Mecânica | Recarga | Fôlego | Potência | Escala |", "| --- | --- | --- | --- | --- | --- | --- |"])
	var gems := sim.content("active_gems").duplicate()
	gems.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["name"]) < String(b["name"]))
	for gem: Dictionary in gems:
		lines.append("| [%s](#%s) | %s | %s | %ss | %s | %s | %s |" % [gem["name"], _anchor(String(gem["name"])), _element(gem), _label(MECHANIC_LABELS, String(gem.get("mechanic", ""))),
			_num(float(gem.get("cooldown", 0.0))), _num(float(gem.get("breath_cost", 0.0))), _num(float(gem.get("power", 0.0))), _stat_list(gem.get("scaling", []) as Array)])
	lines.append("")
	for gem: Dictionary in gems:
		var id := String(gem["id"])
		lines.append_array(PackedStringArray([
			"## %s" % gem["name"], "", _text(String(gem.get("description", ""))), "",
			"- **Elemento:** %s · **Mecânica:** %s · **Marcadores:** %s" % [_element(gem), _label(MECHANIC_LABELS, String(gem.get("mechanic", ""))), _tags(gem.get("tags", []) as Array)],
			"- **Recarga:** %ss · **Fôlego:** %s · **Potência:** %s · **Raio:** %s · **Alcance:** %s" % [_num(float(gem.get("cooldown", 0.0))), _num(float(gem.get("breath_cost", 0.0))), _num(float(gem.get("power", 0.0))), _num(float(gem.get("radius", 0.0))), _num(float(gem.get("range", 0.0)))],
			"- **Escala com:** %s" % _stat_list(gem.get("scaling", []) as Array),
			"- **Onde conseguir:** %s" % ("; ".join(PackedStringArray(sources.get(id, []))) if sources.has(id) else "ainda sem fonte fixa"),
			"",
		]))
		var evolutions := gem.get("evolutions", {}) as Dictionary
		if not evolutions.is_empty():
			lines.append("| Maestria | Evoluções (escolha uma) |")
			lines.append("| --- | --- |")
			var levels := evolutions.keys()
			levels.sort_custom(func(a: Variant, b: Variant) -> bool: return int(a) < int(b))
			for level: Variant in levels:
				var options := PackedStringArray()
				for option: Dictionary in evolutions[level] as Array:
					options.append("**%s** (%s)" % [option.get("name", ""), _modifiers(option.get("modifiers", {}) as Dictionary)])
				lines.append("| %s | %s |" % [level, " · ".join(options)])
			lines.append("")
	return _page(lines)


func _gem_sources() -> Dictionary:
	var result := {}
	for character in sim.content("playable_characters"):
		var gem_id := String(Simulation.STARTER_GEMS.get(StringName(String(character["id"])), ""))
		result.get_or_add(gem_id, []).append("gema inicial de %s" % character["name"])
	for boss in TowerContentScript.collection("bosses"):
		for gem_id: Variant in boss.get("gem_set", []) as Array:
			result.get_or_add(String(gem_id), []).append("[%s](Chefes#%s), andar %d" % [boss["name"], _anchor(String(boss["name"])), int(boss["floor"])])
	for item in _items_where(func(item: Dictionary) -> bool: return item.has("unique_gem")):
		result.get_or_add(String(item["unique_gem"]), []).append("fortalecida pela arma única [%s](Armas-Unicas#%s)" % [item["name"], _anchor(String(item["name"]))])
	return result


func _support_gems() -> String:
	var lines := PackedStringArray(["# Gemas de suporte", "",
		"Suportes se encaixam numa gema ativa e mudam como ela funciona. Cada suporte drena Fôlego e só aceita gemas com os marcadores ou mecânicas indicados.", ""])
	for category in [["mechanic", "Suportes de mecânica"], ["buff", "Suportes de reforço"]]:
		lines.append("## " + category[1])
		lines.append("")
		lines.append("| Suporte | Efeito | Dreno | Exige | Mecânicas aceitas |")
		lines.append("| --- | --- | --- | --- | --- |")
		var supports := sim.content("support_gems").filter(func(support: Dictionary) -> bool: return String(support.get("category", "")) == category[0])
		supports.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["name"]) < String(b["name"]))
		for support: Dictionary in supports:
			var allowed := PackedStringArray()
			for mechanic: Variant in support.get("allowed_mechanics", []) as Array:
				allowed.append(_label(MECHANIC_LABELS, String(mechanic)))
			lines.append("| **%s** | %s | %s | %s | %s |" % [support["name"], _cell(String(support.get("description", ""))), _num(float(support.get("drain", 0.0))),
				_tags(support.get("requires", []) as Array), ", ".join(allowed) if not allowed.is_empty() else "todas"])
		lines.append("")
	return _page(lines)


func _summons() -> String:
	var lines := PackedStringArray(["# Invocações", "",
		"Criaturas criadas por gemas de invocação. Duração e limites valem por dono.", "",
		"| Invocação | Comportamento | Alvo | Vida | Potência | Intervalo | Alcance | Duração | Limite | Pode ser ferida |",
		"| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"])
	for summon in sim.content("summons"):
		lines.append("| **%s** | %s | %s | %s | %s | %ss | %s | %ss | %d | %s |" % [summon["name"], _label(SUMMON_LABELS, String(summon.get("behavior", ""))), _label(SUMMON_LABELS, String(summon.get("targeting", ""))),
			_num(float(summon.get("health", 0.0))), _num(float(summon.get("power", 0.0))), _num(float(summon.get("attack_interval", 0.0))), _num(float(summon.get("range", 0.0))),
			_num(float(summon.get("duration", 0.0))), int(summon.get("owner_limit", 1)), "sim" if bool(summon.get("can_be_damaged", false)) else "não"])
	return _page(lines)


# ---------------------------------------------------------------- inimigos

func _regular_enemies() -> Array[Dictionary]:
	return sim.content("enemies").filter(func(enemy: Dictionary) -> bool: return String(enemy.get("encounter_class", "")) in ["common", "elite"])


func _enemy_biome() -> Dictionary:
	var result := {}
	for biome in TowerContentScript.collection("biomes"):
		for enemy_id: Variant in biome.get("enemies", []) as Array:
			result[String(enemy_id)] = String(biome["id"])
	return result


func _enemies() -> String:
	var biome_of := _enemy_biome()
	var races := _by_id(sim.content("monster_races"))
	var ranks := _by_id(sim.content("enemy_ranks"))
	var loot := _by_id(sim.content("loot_tables"))
	var lines := PackedStringArray(["# Inimigos", "",
		"Inimigos comuns e de elite de cada bioma. **Vida base** já inclui o multiplicador global (x%s); no jogo ela ainda é multiplicada pela raça, pela patente, pelo andar e pela [dificuldade](Dificuldades). A velocidade final é %s%% da base." % [_num(Simulation.ENEMY_HEALTH_MULT), _num(Simulation.ENEMY_SPEED_MULT * 100.0)], "",
		"Resistências e fraquezas somam a raça e o bioma (veja [Resistências](Resistencias)). O bestiário do jogo revela estas informações aos poucos: comuns precisam de %s abates para cada nível de conhecimento; elites, %s." % [_join_ints(BestiaryScript.thresholds("common")), _join_ints(BestiaryScript.thresholds("elite"))], ""])
	for biome in TowerContentScript.collection("biomes"):
		var members := _regular_enemies().filter(func(enemy: Dictionary) -> bool: return biome_of.get(String(enemy["id"]), String(enemy.get("biome", ""))) == String(biome["id"]))
		if members.is_empty():
			continue
		lines.append("## %s (andares %d–%d)" % [biome["name"], int(biome["floors"][0]), int(biome["floors"][1])])
		lines.append("")
		for enemy: Dictionary in members:
			var race := races.get(String(enemy.get("race_id", "")), {}) as Dictionary
			var rank := ranks.get(String(enemy.get("rank_id", "")), {}) as Dictionary
			var profile := ResistancesScript.enemy_profile(String(enemy.get("race_id", "")), String(biome["id"]))
			lines.append_array(PackedStringArray([
				"### %s" % enemy["name"], "",
				"| | |", "| --- | --- |",
				"| Classe | %s |" % _label(CLASS_LABELS, String(enemy.get("encounter_class", ""))),
				"| Raça | [%s](Racas-e-Patentes#%s) |" % [race.get("name", enemy.get("race_id", "")), _anchor(String(race.get("name", "")))],
				"| Patente | %s |" % rank.get("name", enemy.get("rank_id", "")),
				"| Tipo | %s |" % _label(KIND_LABELS, String(enemy.get("kind", ""))),
				"| Vida base | %s |" % _num(float(enemy.get("health", 0.0)) * Simulation.ENEMY_HEALTH_MULT),
				"| Dano | %s a cada %ss |" % [_num(float(enemy.get("damage", 0.0))), _num(float(enemy.get("attack_interval", 1.0)))],
				"| Velocidade base | %s |" % _num(float(enemy.get("speed", 0.0))),
				"| Tipo de dano | %s |" % ResistancesScript.LABELS.get(String(ResistancesScript.RACE_DAMAGE.get(String(enemy.get("race_id", "")), "physical")), ""),
				"| Resistências | %s |" % _resist_text(profile, true),
				"| Fraquezas | %s |" % _resist_text(profile, false),
				"| Afixos | %s |" % ("pode ter" if bool(enemy.get("allow_affixes", true)) else "não"),
				"| Comportamento | %s |" % _cell(String(BestiaryScript.MECHANICS.get(String(enemy.get("mechanic", "")), String(enemy.get("mechanic", "")).replace("_", " ")))),
				"| Saque | %s |" % _loot_text(loot.get(String(enemy.get("loot_table_id", "")), {}) as Dictionary),
				"",
			]))
			var lore := String(enemy.get("lore", enemy.get("lore_basis", "")))
			if not lore.is_empty():
				lines.append("> " + _text(lore))
				lines.append("")
	return _page(lines)


func _bosses() -> String:
	var loot := _by_id(sim.content("loot_tables"))
	var lines := PackedStringArray(["# Chefes", "",
		"Cada bioma termina num guardião. Vencer o guardião libera o andar seguinte, entrega gemas do conjunto dele e abre na Forja da vila uma receita do bioma. Habilidades são anunciadas no chão antes de acertar; ao passar do tempo de fúria o chefe enfurece. A Vida mostrada é a base (x%s), antes de andar e dificuldade." % _num(Simulation.ENEMY_HEALTH_MULT), "",
		"| Andar | Chefe | Bioma | Vida base | Dano | Fúria |", "| --- | --- | --- | --- | --- | --- |"])
	for boss in TowerContentScript.collection("bosses"):
		lines.append("| %d | [%s](#%s) | %s | %s | %s | %ss |" % [int(boss["floor"]), boss["name"], _anchor(String(boss["name"])), TowerContentScript.biome(String(boss["biome"])).get("name", boss["biome"]),
			_num(float(boss.get("health", 0.0)) * Simulation.ENEMY_HEALTH_MULT), _num(float(boss.get("damage", 0.0))), _num(float(boss.get("enrage", 0.0)))])
	lines.append("")
	for boss in TowerContentScript.collection("bosses"):
		lines.append_array(PackedStringArray([
			"## %s" % boss["name"], "",
			"Andar %d · %s · Vida base %s · Dano %s · Velocidade %s · Fúria em %ss · Tipo de dano das habilidades: %s" % [int(boss["floor"]), TowerContentScript.biome(String(boss["biome"])).get("name", boss["biome"]),
				_num(float(boss.get("health", 0.0)) * Simulation.ENEMY_HEALTH_MULT), _num(float(boss.get("damage", 0.0))), _num(float(boss.get("speed", 0.0))), _num(float(boss.get("enrage", 0.0))),
				ResistancesScript.LABELS.get(String(ResistancesScript.BIOME_DAMAGE.get(String(boss["biome"]), "physical")), "")], "",
		]))
		var phases := PackedStringArray()
		for threshold: Variant in boss.get("phases", []) as Array:
			phases.append("%s da Vida" % _pct(float(threshold)))
		if not phases.is_empty():
			lines.append("**Fases:** muda de fase em %s." % ", ".join(phases))
			lines.append("")
		lines.append("| Habilidade | Detalhes | Recarga | Fase |")
		lines.append("| --- | --- | --- | --- |")
		for ability: Dictionary in boss.get("abilities", []) as Array:
			lines.append("| %s | %s | %ss | %s |" % [BestiaryScript.ABILITIES.get(String(ability["type"]), String(ability["type"])), _ability_details(ability), _num(float(ability.get("cooldown", 0.0))), str(int(ability["phase"])) if ability.has("phase") else "todas"])
		lines.append("")
		var gems := PackedStringArray()
		for gem_id: Variant in boss.get("gem_set", []) as Array:
			gems.append("[%s](Gemas-Ativas#%s)" % [_gem_names.get(String(gem_id), gem_id), _anchor(String(_gem_names.get(String(gem_id), gem_id)))])
		if not gems.is_empty():
			lines.append("**Gemas que entrega:** " + ", ".join(gems))
			lines.append("")
		var boss_loot := _loot_text(loot.get(String(boss.get("loot_table_id", "")), {}) as Dictionary)
		if boss_loot != "—":
			lines.append("**Saque:** " + boss_loot)
			lines.append("")
	lines.append("## Habilidades extras em grupo")
	lines.append("")
	lines.append("Com mais jogadores, os chefes ganham habilidades acumulativas (o dano é uma fração do dano do chefe):")
	lines.append("")
	for size in [2, 3, 4]:
		var extras := PackedStringArray()
		for ability: Dictionary in (TowerContentScript.data().get("party_abilities", {}) as Dictionary).get(str(size), []) as Array:
			extras.append("%s (%s, recarga %ss)" % [BestiaryScript.ABILITIES.get(String(ability["type"]), String(ability["type"])), _ability_details(ability), _num(float(ability.get("cooldown", 0.0)))])
		lines.append("- **%d jogadores:** %s" % [size, "; ".join(extras)])
	return _page(lines)


func _ability_details(ability: Dictionary) -> String:
	var parts := PackedStringArray()
	for spec in [["count", "quantidade %s"], ["targets", "alvos %s"], ["radius", "raio %s"], ["length", "comprimento %s"], ["width", "largura %s"], ["delay", "aviso %ss"], ["damage", "dano %s"]]:
		if ability.has(spec[0]):
			parts.append(String(spec[1]) % _num(float(ability[spec[0]])))
	if ability.has("damage_ratio"):
		parts.append("%s do dano" % _pct(float(ability["damage_ratio"])))
	return ", ".join(parts)


func _races() -> String:
	var lines := PackedStringArray(["# Raças, patentes e afixos de monstro", "", "## Raças", "",
		"| Raça | Traço | Vida | Dano | Velocidade | Intervalo de ataque | Tipo de dano | Resistências | Fraquezas |", "| --- | --- | --- | --- | --- | --- | --- | --- | --- |"])
	for race in sim.content("monster_races"):
		var profile := race.get("stat_profile", {}) as Dictionary
		var resist := ResistancesScript.enemy_profile(String(race["id"]), "")
		lines.append("| [%s](#%s) | %s | x%s | x%s | x%s | x%s | %s | %s | %s |" % [race["name"], _anchor(String(race["name"])), _cell(String(BestiaryScript.TRAITS.get(String(race.get("trait", "")), race.get("trait", ""))).get_slice(":", 0)),
			_num(float(profile.get("health", 1.0))), _num(float(profile.get("damage", 1.0))), _num(float(profile.get("speed", 1.0))), _num(float(profile.get("attack_interval", 1.0))),
			ResistancesScript.LABELS.get(String(ResistancesScript.RACE_DAMAGE.get(String(race["id"]), "physical")), ""), _resist_text(resist, true), _resist_text(resist, false)])
	lines.append("")
	for race in sim.content("monster_races"):
		lines.append("### %s" % race["name"])
		lines.append("")
		lines.append(_text(String(race.get("description", ""))))
		lines.append("")
		lines.append("**Traço:** " + String(BestiaryScript.TRAITS.get(String(race.get("trait", "")), race.get("trait", ""))))
		lines.append("")
	lines.append_array(PackedStringArray(["## Patentes", "",
		"Na dificuldade 4 e 5 a patente Nascente não aparece (sobe para Maduro).", "",
		"| Patente | Vida | Dano | Velocidade | Saque | Afixos |", "| --- | --- | --- | --- | --- | --- |"]))
	for rank in sim.content("enemy_ranks"):
		lines.append("| **%s** | x%s | x%s | x%s | x%s | %s |" % [rank["name"], _num(float(rank.get("health_multiplier", 1.0))), _num(float(rank.get("damage_multiplier", 1.0))), _num(float(rank.get("speed_multiplier", 1.0))),
			_num(float(rank.get("loot_multiplier", 1.0))), _range([rank.get("minimum_affixes", 0), rank.get("maximum_affixes", 0)]).replace("—", "0")])
	lines.append_array(PackedStringArray(["", "## Afixos de monstro", "",
		"Elites e bandos superiores podem ter um prefixo e um sufixo. Cada afixo multiplica atributos e saque e pode trazer uma mecânica.", "",
		"| Afixo | Posição | Vida | Dano | Velocidade | Intervalo de ataque | Saque | Mecânica |", "| --- | --- | --- | --- | --- | --- | --- | --- |"]))
	for modifier in sim.content("enemy_modifiers"):
		lines.append("| **%s** | %s | x%s | x%s | x%s | x%s | x%s | %s |" % [modifier["name"], "prefixo" if String(modifier.get("position", "")) == "prefix" else "sufixo",
			_num(float(modifier.get("health_multiplier", 1.0))), _num(float(modifier.get("damage_multiplier", 1.0))), _num(float(modifier.get("speed_multiplier", 1.0))),
			_num(float(modifier.get("attack_interval_multiplier", 1.0))), _num(float(modifier.get("loot_multiplier", 1.0))), _label(ENEMY_MECHANIC_LABELS, String(modifier.get("mechanic_id", ""))) if not String(modifier.get("mechanic_id", "")).is_empty() else "—"])
	return _page(lines)


# ---------------------------------------------------------------- Torre

func _biomes() -> String:
	var enemies := _by_id(sim.content("enemies"))
	var lines := PackedStringArray(["# Torre e biomas", "",
		"A Torre das Cem Marcas tem 100 andares divididos em biomas. A escada de um andar comum só abre depois que o grupo sobrevive %d minutos nele; o último andar de cada bioma tem o guardião. Lista andar a andar em [Os 100 andares](Andares).", ""])
	lines[2] = lines[2] % int(Simulation.FLOOR_SURVIVAL_SECONDS / 60.0)
	for biome in TowerContentScript.collection("biomes"):
		var hazard := biome.get("hazard", {}) as Dictionary
		var names := PackedStringArray()
		for enemy_id: Variant in biome.get("enemies", []) as Array:
			names.append("[%s](Inimigos#%s)" % [(enemies.get(String(enemy_id), {}) as Dictionary).get("name", enemy_id), _anchor(String((enemies.get(String(enemy_id), {}) as Dictionary).get("name", enemy_id)))])
		var materials := PackedStringArray()
		for material_id: Variant in biome.get("materials", []) as Array:
			materials.append(String(_item_names.get(String(material_id), material_id)))
		lines.append_array(PackedStringArray([
			"## %s" % biome["name"], "",
			"| | |", "| --- | --- |",
			"| Andares | %d a %d |" % [int(biome["floors"][0]), int(biome["floors"][1])],
			"| Mecânica do bioma | %s |" % biome.get("mechanic", ""),
			"| Perigo | %s: %s, raio %s, a cada %ss, dano %s |" % [hazard.get("label", ""), BestiaryScript.ABILITIES.get(String(hazard.get("type", "")), hazard.get("type", "")), _num(float(hazard.get("radius", 0.0))), _num(float(hazard.get("interval", 0.0))), _num(float(hazard.get("damage", 0.0)))],
			"| Tipo de dano do bioma | %s |" % ResistancesScript.LABELS.get(String(ResistancesScript.BIOME_DAMAGE.get(String(biome["id"]), "physical")), ""),
			"| Resistência extra dos inimigos | %s |" % _resist_text(ResistancesScript.enemy_profile("", String(biome["id"])), true),
			"| Fraqueza extra dos inimigos | %s |" % _resist_text(ResistancesScript.enemy_profile("", String(biome["id"])), false),
			"| Inimigos | %s |" % ", ".join(names),
			"| Materiais | %s |" % (", ".join(materials) if not materials.is_empty() else "—"),
			"",
		]))
	return _page(lines)


func _floors() -> String:
	var lines := PackedStringArray(["# Os 100 andares", "",
		"Multiplicadores do andar sobre Vida, dano e perigos dos inimigos, antes da dificuldade.", "",
		"| Andar | Nome | Bioma | Tipo | Vida | Dano | Perigos | Matilhas |", "| --- | --- | --- | --- | --- | --- | --- | --- |"])
	for entry in TowerContentScript.collection("floors"):
		lines.append("| %d | %s | %s | %s | x%s | x%s | x%s | %d |" % [int(entry["floor"]), entry.get("name", ""), TowerContentScript.biome(String(entry["biome"])).get("name", entry["biome"]),
			{"explore": "Exploração", "boss": "Chefe"}.get(String(entry.get("kind", "")), String(entry.get("kind", "")).capitalize()),
			_num(float(entry.get("health_multiplier", 1.0))), _num(float(entry.get("damage_multiplier", 1.0))), _num(float(entry.get("hazard_multiplier", 1.0))), int(entry.get("packs", 0))])
	return _page(lines)


func _resistances() -> String:
	var lines := PackedStringArray(["# Resistências", "",
		"Há dano físico e nove elementos: %s." % ", ".join(PackedStringArray(ResistancesScript.TYPES.map(func(kind: String) -> String: return String(ResistancesScript.LABELS[kind])))), "",
		"- Cada inimigo soma a resistência da raça, a do bioma e a da [dificuldade](Dificuldades), de %s (fraqueza) a %s." % [_pct(ResistancesScript.MINIMUM), _pct(ResistancesScript.MAXIMUM)],
		"- **Penetração** reduz só resistência positiva, nunca abaixo de zero; fraquezas continuam valendo.",
		"- **Quebra elemental** reduz a resistência por alguns segundos.",
		"- **Adaptação** (dificuldades 4 e 5, elites e chefes): o tipo que mais feriu o inimigo ganha +%s de resistência." % _pct(ResistancesScript.ADAPTATION_BONUS),
		"- Personagens resistem por afixos de item, até %s; nas dificuldades altas há penalidade nas resistências da personagem." % _pct(ResistancesScript.PLAYER_CAP),
		"- Dano contínuo (veneno, queimadura) não pode ser bloqueado nem esquivado. Esporos causam dano de natureza; toxina, ácido.",
		"", "## Por raça", "",
	])
	lines.append_array(_resist_table(ResistancesScript.RACE, func(id: String) -> String: return String(_by_id(sim.content("monster_races")).get(id, {}).get("name", id))))
	lines.append("")
	lines.append("## Por bioma")
	lines.append("")
	lines.append_array(_resist_table(ResistancesScript.BIOME, func(id: String) -> String: return String(TowerContentScript.biome(id).get("name", id))))
	return _page(lines)


func _resist_table(table: Dictionary, name_of: Callable) -> PackedStringArray:
	var lines := PackedStringArray()
	var header := PackedStringArray([""])
	for kind in ResistancesScript.TYPES:
		header.append(String(ResistancesScript.LABELS[kind]))
	lines.append("| " + " | ".join(header) + " |")
	lines.append("|" + " --- |".repeat(header.size()))
	for id: String in table:
		var row := PackedStringArray(["**%s**" % name_of.call(id)])
		for kind in ResistancesScript.TYPES:
			var value := float((table[id] as Dictionary).get(kind, 0.0))
			row.append(_signed_pct(value) if not is_zero_approx(value) else "")
		lines.append("| " + " | ".join(row) + " |")
	return lines


func _difficulties() -> String:
	var lines := PackedStringArray(["# Dificuldades", "",
		"A dificuldade é do mundo: o host escolhe no mapa da Torre, com todos fora dela, entre as liberadas. Concluir o andar 100 libera a seguinte naquele mundo. Andar mais fundo e recordes são guardados por dificuldade.", "",
		"| | " + " | ".join(PackedStringArray(Simulation.DIFFICULTIES.map(func(entry: Dictionary) -> String: return "%s" % entry["name"]))) + " |",
		"|" + " --- |".repeat(Simulation.DIFFICULTIES.size() + 1)])
	var rows := [
		["Vida dos inimigos", func(entry: Dictionary) -> String: return "x" + _num(float(entry["health"]))],
		["Dano dos inimigos", func(entry: Dictionary) -> String: return "x" + _num(float(entry["damage"]))],
		["Resistência extra dos inimigos", func(entry: Dictionary) -> String: return _signed_pct(float(entry["resist"]))],
		["Penalidade nas resistências da personagem", func(entry: Dictionary) -> String: return "-" + _pct(float(entry["penalty"])) if float(entry["penalty"]) > 0.0 else "—"],
		["Afixos de elite", func(entry: Dictionary) -> String: return _range(entry["elite_affixes"] as Array)],
		["Saque", func(entry: Dictionary) -> String: return "x" + _num(float(entry["loot"]))],
		["Experiência", func(entry: Dictionary) -> String: return "x" + _num(float(entry["exp"]))],
		["Armas únicas", func(entry: Dictionary) -> String: return "sim" if bool(entry["uniques"]) else "não"],
		["Elites e chefes adaptam", func(entry: Dictionary) -> String: return "sim" if bool(entry["adaptive"]) else "não"],
		["Sem Nascentes", func(entry: Dictionary) -> String: return "sim" if bool(entry["no_nascent"]) else "não"],
		["Bandos superiores", func(entry: Dictionary) -> String: return "%s das matilhas, %d+ afixos" % [_pct(float(entry["superior"])), int(entry["superior_affixes"])] if float(entry["superior"]) > 0.0 else "—"],
	]
	for row: Array in rows:
		var cells := PackedStringArray([String(row[0])])
		for entry in Simulation.DIFFICULTIES:
			cells.append((row[1] as Callable).call(entry))
		lines.append("| " + " | ".join(cells) + " |")
	lines.append("")
	lines.append("**Bandos superiores** vêm uma patente acima, com todos os membros com afixos e uma aura no chão em volta de cada um.")
	return _page(lines)


# ---------------------------------------------------------------- itens

func _uniques() -> String:
	var lines := PackedStringArray(["# Armas únicas", "",
		"Cada arma única pertence a uma gema: reforça os números dela e traz uma passiva que muda como a gema funciona. Caem a partir da [dificuldade](Dificuldades) 2. A arma assume a forma da arma inicial de quem a empunha.", ""])
	var items := _items_where(func(item: Dictionary) -> bool: return item.has("unique_gem"))
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(_gem_names.get(String(a["unique_gem"]), "")) < String(_gem_names.get(String(b["unique_gem"]), "")))
	for item: Dictionary in items:
		var gem_name := String(_gem_names.get(String(item["unique_gem"]), item["unique_gem"]))
		var passive := item.get("passive", {}) as Dictionary
		lines.append_array(PackedStringArray([
			"## %s" % item["name"], "",
			"Gema: [%s](Gemas-Ativas#%s) · Potência da arma %s" % [gem_name, _anchor(gem_name), _num(float(item.get("power", 0.0)))], "",
			"- **Reforço da gema:** %s" % _modifiers(item.get("gem_modifiers", {}) as Dictionary),
			"- **Passiva — %s:** %s" % [passive.get("name", ""), _text(String(passive.get("description", "")))],
			"",
		]))
	return _page(lines)


func _legendaries() -> String:
	var lines := PackedStringArray(["# Lendários e relíquias", "",
		"Peças lendárias têm atributos fixos e uma passiva que muda uma regra do jogo. Relíquias ocupam o encaixe próprio.", ""])
	for slot: String in SLOT_LABELS:
		var items := _items_where(func(item: Dictionary) -> bool: return String(item.get("tier", "")) == "legendary" and not item.has("unique_gem") and String(item.get("slot", "")) == slot)
		if items.is_empty():
			continue
		lines.append("## " + String(SLOT_LABELS[slot]))
		lines.append("")
		for item: Dictionary in items:
			var passive := item.get("passive", {}) as Dictionary
			lines.append("### %s" % item["name"])
			lines.append("")
			var stats := _stats(item.get("stats", {}) as Dictionary)
			if not stats.is_empty():
				lines.append("- **Atributos:** " + stats)
			for affix: Dictionary in item.get("fixed_affixes", []) as Array:
				lines.append("- **Afixo fixo:** %s a %s" % [ItemAffixesScript.describe({"id": affix["id"], "value": float(affix["min"])}), ItemAffixesScript.describe({"id": affix["id"], "value": float(affix["max"])})])
			if not passive.is_empty():
				lines.append("- **Passiva — %s:** %s" % [passive.get("name", ""), _text(String(passive.get("description", "")))])
			if item.has("description"):
				lines.append("")
				lines.append("> " + _text(String(item["description"])))
			lines.append("")
	return _page(lines)


func _equipment() -> String:
	var sources := sim.material_sources()
	var lines := PackedStringArray(["# Equipamentos, consumíveis e materiais", "",
		"Peças-base que caem na Torre e são vendidas na vila. Peças do saque ganham [afixos](Afixos) conforme a raridade e o nível do item. Materiais vão para o armazém comum da vila e alimentam as receitas da Forja.", ""])
	for group in [["weapon", "Armas iniciais"], ["gear", "Equipamentos"], ["consumable", "Consumíveis"], ["material", "Materiais"]]:
		var items := _items_where(func(item: Dictionary) -> bool:
			if String(item.get("tier", "")) == "legendary" or item.has("unique_gem"):
				return false
			var kind := String(item.get("item_type", ""))
			if group[0] == "gear":
				return kind not in ["weapon", "consumable", "material"]
			return kind == group[0])
		if items.is_empty():
			continue
		lines.append("## " + String(group[1]))
		lines.append("")
		if group[0] == "material":
			lines.append("| Material | Raridade | Bioma | Cai de |")
			lines.append("| --- | --- | --- | --- |")
			for item: Dictionary in items:
				lines.append("| **%s** | %s | %s | %s |" % [item["name"], _label(TIER_LABELS, String(item.get("tier", ""))), TowerContentScript.biome(String(item.get("biome", ""))).get("name", "Galerias Refeitas" if not item.has("biome") else item["biome"]),
					_sources_text(sources.get(String(item["id"]), []) as Array)])
		else:
			lines.append("| Item | Encaixe | Raridade | Atributos | Descrição |")
			lines.append("| --- | --- | --- | --- | --- |")
			for item: Dictionary in items:
				var description := String(ContentDescriptions.ITEM_TEXT.get(String(item["id"]).replace("couraça", "couraca"), item.get("description", "")))
				lines.append("| **%s** | %s | %s | %s | %s |" % [item["name"], _label(SLOT_LABELS, String(item.get("slot", ""))), _label(TIER_LABELS, String(item.get("tier", ""))), _or_dash(_stats(item.get("stats", {}) as Dictionary)), _cell(description)])
		lines.append("")
	return _page(lines)


func _affixes() -> String:
	var lines := PackedStringArray(["# Afixos de item", "",
		"Peças do saque sorteiam afixos conforme a raridade. A faixa abaixo é a do comum no nível 1: a raridade multiplica (%s) e cada nível do item soma %s (o nível 100 vale cerca de %sx o nível 1). Uma peça tem no máximo %d afixos." % [
			", ".join(PackedStringArray(ItemAffixesScript.SCALE.keys().map(func(tier: String) -> String: return "%s x%s" % [TIER_LABELS.get(tier, tier), _num(float(ItemAffixesScript.SCALE[tier]))]))),
			_pct(ItemAffixesScript.LEVEL_STEP), _num(ItemAffixesScript.level_factor(100)), ItemAffixesScript.MAX_AFFIXES], "",
		"| Raridade | Afixos |", "| --- | --- |"])
	for tier: String in ItemAffixesScript.COUNT:
		var count := ItemAffixesScript.COUNT[tier] as Array
		lines.append("| %s | %s |" % [TIER_LABELS.get(tier, tier), str(count[0]) if int(count[0]) == int(count[1]) else "%d a %d" % [int(count[0]), int(count[1])]])
	lines.append_array(PackedStringArray(["", "**Em breve:** itens divinos, com atributos-base no máximo, 7 afixos aleatórios no máximo, 1 afixo fixo coerente com o encaixe (botas: velocidade de movimento) e 1 ou 2 passivas divinas transformadoras.", "",
		"| Afixo | Faixa (comum, nível 1) |", "| --- | --- |"]))
	for affix_id: String in ItemAffixesScript.POOL:
		var spec := ItemAffixesScript.POOL[affix_id] as Dictionary
		var low := ItemAffixesScript.describe({"id": affix_id, "value": float(spec["min"])})
		var high := ItemAffixesScript.describe({"id": affix_id, "value": float(spec["max"])})
		var label := String(spec["label"])
		lines.append("| %s%s | %s a %s |" % [label.left(1).to_upper() + label.substr(1), " (só em lendários)" if not bool(spec.get("random", true)) else "", low.trim_suffix(" " + label).replace(".", ","), high.trim_suffix(" " + label).replace(".", ",")])
	return _page(lines)


# ---------------------------------------------------------------- utilidades

func _page(lines: PackedStringArray) -> String:
	lines.append("")
	lines.append("---")
	lines.append("")
	lines.append("_%s_" % LICENSE_NOTE)
	return "\n".join(lines) + "\n"


func _items_where(predicate: Callable) -> Array[Dictionary]:
	return sim.content("items").filter(predicate)


func _by_id(collection: Array[Dictionary]) -> Dictionary:
	var result := {}
	for entry in collection:
		result[String(entry.get("id", ""))] = entry
	return result


func _weapon_profiles() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(WEAPON_PROFILES))
	return parsed as Dictionary if parsed is Dictionary else {}


func _modifiers(modifiers: Dictionary) -> String:
	var parts := PackedStringArray()
	for key: Variant in modifiers:
		var raw := String(key)
		var value: Variant = modifiers[key]
		if raw.ends_with("_multiplier"):
			parts.append("%s %s" % [_modifier_name(raw.trim_suffix("_multiplier")), _signed_pct(float(value) - 1.0)])
		elif raw.ends_with("_add"):
			var amount := float(value)
			var shown := _signed_pct(amount) if raw.contains("chance") and absf(amount) < 1.0 else ("+" if amount >= 0.0 else "") + _num(amount)
			parts.append("%s %s" % [_modifier_name(raw.trim_suffix("_add")), shown])
		elif value is bool:
			parts.append(_modifier_name(raw))
		else:
			parts.append("%s %s" % [_modifier_name(raw), _num(float(value)) if (value is float or value is int) else str(value)])
	return _cell(", ".join(parts))


func _modifier_name(key: String) -> String:
	return String(MenuScript.MODIFIER_NAMES.get(key, key.replace("_", " ")))


func _stats(stats: Dictionary) -> String:
	var parts := PackedStringArray()
	for stat: String in stats:
		var unit := "%" if stat in ["movement_speed", "attack_speed", "critical_chance", "cooldown_recovery", "area"] else ""
		parts.append("%s +%s%s" % [_stat_name(stat), _num(float(stats[stat])), unit])
	return ", ".join(parts)


func _stat_name(stat: String) -> String:
	return String(ContentDescriptions.STAT_NAMES.get(stat, stat.replace("_", " ").capitalize()))


func _stat_list(stats: Array) -> String:
	return ", ".join(PackedStringArray(stats.map(func(stat: Variant) -> String: return _stat_name(String(stat)))))


func _element(gem: Dictionary) -> String:
	var element := String(gem.get("element", ""))
	return String(ResistancesScript.LABELS.get(element, "Físico")) if not element.is_empty() else "Físico"


func _resist_text(profile: Dictionary, positive: bool) -> String:
	var values := ResistancesScript.TYPES.map(func(kind: String) -> float: return float(profile.get(kind, 0.0)))
	if values.all(func(value: float) -> bool: return is_equal_approx(value, values[0]) and not is_zero_approx(value)):
		return "Todos os tipos %s" % _signed_pct(values[0]) if (values[0] > 0.0) == positive else "—"
	var parts := PackedStringArray()
	for kind in ResistancesScript.TYPES:
		var value := float(profile.get(kind, 0.0))
		if (positive and value > 0.0) or (not positive and value < 0.0):
			parts.append("%s %s" % [ResistancesScript.LABELS[kind], _signed_pct(value)])
	return ", ".join(parts) if not parts.is_empty() else "—"


func _loot_text(table: Dictionary) -> String:
	var parts := PackedStringArray()
	for entry: Dictionary in table.get("entries", []) as Array:
		var amount := "" if int(entry.get("maximum", 1)) <= 1 else " (%d–%d)" % [int(entry.get("minimum", 1)), int(entry.get("maximum", 1))]
		parts.append("%s %s%s" % [_item_names.get(String(entry["item_id"]), entry["item_id"]), BestiaryScript.percent(float(entry.get("chance", 0.0))), amount])
	return ", ".join(parts) if not parts.is_empty() else "—"


func _sources_text(names: Array) -> String:
	if names.size() > 12:
		return "quase todos os monstros e chefes (%d fontes)" % names.size()
	return ", ".join(PackedStringArray(names)) if not names.is_empty() else "—"


func _tags(tags: Array) -> String:
	return ", ".join(PackedStringArray(tags.map(func(tag: Variant) -> String: return String(TAG_LABELS.get(String(tag), String(tag))))))


func _label(table: Dictionary, key: String) -> String:
	return String(table.get(key, key.replace("_", " ").capitalize()))


func _range(values: Array) -> String:
	if values.is_empty():
		return "—"
	return str(int(values[0])) if int(values[0]) == int(values[-1]) else "%d a %d" % [int(values[0]), int(values[-1])]


func _join_ints(values: Array) -> String:
	return ", ".join(PackedStringArray(values.map(func(value: Variant) -> String: return str(int(value)))))


static func _num(value: float) -> String:
	if value < 0.0:
		return "-" + _num(-value)
	if is_equal_approx(value, roundf(value)):
		var digits := str(int(roundf(value)))
		var result := ""
		while digits.length() > 3:
			result = "." + digits.right(3) + result
			digits = digits.left(digits.length() - 3)
		return digits + result
	return ("%.2f" % value).rstrip("0").replace(".", ",")


static func _pct(value: float) -> String:
	return _num(snappedf(value * 100.0, 0.1)) + "%"


static func _signed_pct(value: float) -> String:
	return ("+" if value >= 0.0 else "-") + _pct(absf(value))


## Âncora no estilo do GitHub: minúsculas, sem pontuação, espaços viram hífen.
static func _anchor(title: String) -> String:
	var result := ""
	for character in title.to_lower():
		if character == " " or character == "-":
			result += "-"
		elif character.unicode_at(0) > 127 or (character >= "a" and character <= "z") or (character >= "0" and character <= "9") or character == "_":
			result += character
	return result


static func _or_dash(value: String) -> String:
	return value if not value.is_empty() else "—"


static func _cell(value: String) -> String:
	return _text(value).replace("|", "\\|").replace("\n", " ")


static func _text(value: String) -> String:
	return value.strip_edges()
