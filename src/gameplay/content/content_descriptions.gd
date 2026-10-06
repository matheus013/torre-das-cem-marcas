class_name ContentDescriptions
extends RefCounted

const ItemAffixesScript := preload("res://src/gameplay/items/item_affixes.gd")

const ITEM_TEXT := {
	"filamentos_de_forja":"Filamentos que canalizam energia arcana a distancia.",
	"lanca_de_duas_rotas":"Haste longa que atravessa inimigos alinhados.",
	"manoplas_de_placa_viva":"Placas de combate para golpes rapidos a curta distancia.",
	"bastao_modular_de_campo":"Bastao pesado para varrer uma area em frente ao portador.",
	"escudo_de_escora":"Escudo montado com placas de sustentacao.",
	"foco_de_vidro_termico":"Vidro lapidado para concentrar energia.",
	"amuleto_da_primeira_marca":"Amuleto associado ao aprendizado e recuperacao das habilidades.",
	"protecao_de_trabalho":"Armadura de trabalho reforcada para expedicoes.",
	"couraca_de_reboco":"Couraca feita de camadas de reboco endurecido.",
	"luvas_de_junta":"Luvas articuladas que favorecem a cadencia de combate.",
	"luvas_de_molde":"Luvas usadas na manipulacao de moldes.",
	"botas_de_rota_antiga":"Botas leves para percorrer as rotas da Torre.",
	"botas_de_retirada":"Botas reforcadas para jornadas de retorno.",
	"calca_de_carga":"Roupa de expedicao com reforcos e compartimentos de carga.",
	"calca_de_passagem":"Tecido resistente ao desgaste das galerias.",
	"anel_de_folego":"Anel que amplia a reserva de Folego.",
	"anel_de_precisao":"Anel que favorece acertos criticos.",
	"anel_de_area":"Anel gravado com circulos concentricos.",
	"anel_de_retorno":"Anel associado ao retorno das expedicoes.",
	"anel_de_cicatriz":"Anel marcado pelas cicatrizes de antigas batalhas.",
	"anel_de_partilha":"Anel associado a partilha de recursos.",
	"reliquia_coracao_de_junta":"Nucleo preservado de uma antiga estrutura.",
	"reliquia_molde_sem_dono":"Molde que sobreviveu ao desaparecimento de seu criador.",
	"reliquia_lastro_partido":"Fragmento de lastro que guarda marcas de gravidade.",
	"faixa_coagulante":"Faixa medicinal coletada nas expedicoes.",
	"tonico_de_folego":"Preparado destinado a recuperacao de Folego.",
	"sal_de_fissura":"Sal mineral encontrado nas fissuras da Torre.",
	"cunha_de_retorno":"Cunha marcada como testemunho de uma rota.",
	"pedra_regenerativa":"Material recolhido na Torre e entregue a vila.",
	"musgo_de_orientacao":"Musgo de coleta das galerias.",
	"escama_de_reboco":"Fragmento mineral recolhido dos habitantes da Torre.",
	"argila_de_enxerto":"Argila rara preservada para futuras aplicacoes.",
}
const STAT_NAMES := {
	"health":"Vida maxima", "breath":"Folego maximo", "strength":"Forca", "intelligence":"Inteligencia",
	"agility":"Agilidade", "vitality":"Vitalidade", "wisdom":"Sabedoria", "fortune":"Sorte",
	"movement_speed":"Velocidade de movimento", "attack_speed":"Cadencia de ataque", "critical_chance":"Chance critica",
	"cooldown_recovery":"Recuperacao de recarga", "defense":"Defesa", "stability":"Estabilidade",
	"magic_power":"Potencia magica", "area":"Area", "interaction_speed":"Velocidade de interacao", "carry_capacity":"Capacidade de carga",
}
const FUNCTIONAL_STATS := ["health", "breath", "strength", "intelligence", "agility", "vitality", "wisdom", "fortune", "movement_speed", "attack_speed", "critical_chance", "cooldown_recovery", "area", "defense"]


## `stat_factor` (fabricação x nível) mostra os atributos-base como valem de fato na peça.
static func item(definition: Dictionary, tier: String, fabrication: String = "", weapon: Dictionary = {}, affixes: Array = [], item_level: int = 0, stat_factor: float = 1.0) -> String:
	var id := String(definition.get("id", ""))
	var tier_label := String({"common":"Comum", "uncommon":"Incomum", "rare":"Raro", "epic":"Epico", "legendary":"Lendario"}.get(tier, tier))
	var lines := PackedStringArray([String(definition.get("name", id)), tier_label + (" | " + fabrication if not fabrication.is_empty() else "") + (" | Nivel %d" % item_level if item_level > 0 else "")])
	var fallback := "Material de coleta da regiao: %s." % String(definition["biome"]).replace("_", " ").capitalize() if definition.has("biome") else "Item de expedicao."
	lines.append(String(definition.get("description", ITEM_TEXT.get(id.replace("couraça", "couraca"), fallback))))
	if not weapon.is_empty():
		lines.append("%s | %s | Afinidade %.0f%%" % [weapon["name"], "Arcano" if weapon["damage_type"] == "arcane" else "Fisico", float(weapon["affinity"])])
		lines.append("Potencia da arma %.1f | Alcance %.0f | Intervalo base %.2fs" % [float(weapon["damage"]), float(weapon["range"]), float(weapon["interval"])])
		if float(weapon.get("guard", 0.0)) > 0.0 or float(weapon.get("life_steal", 0.0)) > 0.0:
			lines.append("Guarda: -%.0f%% de dano recebido | Roubo de Vida: %.0f%%" % [float(weapon.get("guard", 0.0)) * 100.0, float(weapon.get("life_steal", 0.0)) * 100.0])
		for stat: String in weapon["scaling"] as Dictionary:
			lines.append("%s: +%.1f%% por ponto" % [STAT_NAMES.get(stat, stat), float(weapon["scaling"][stat]) * 100.0])
	var stats := definition.get("stats", {}) as Dictionary
	for stat: String in stats:
		var unit := "%" if stat in ["movement_speed", "attack_speed", "critical_chance", "cooldown_recovery", "area"] else ""
		lines.append("%s: +%.1f%s%s" % [STAT_NAMES.get(stat, stat.replace("_", " ")), float(stats[stat]) * stat_factor, unit, " (sem efeito no beta)" if stat not in FUNCTIONAL_STATS else ""])
	for affix: Dictionary in affixes:
		lines.append(ItemAffixesScript.describe(affix))
	var passive := definition.get("passive", {}) as Dictionary
	if not passive.is_empty():
		lines.append("PASSIVA %s: %s" % [String(passive.get("name", "")).to_upper(), String(passive.get("description", ""))])
	if not (definition.get("mechanics", []) as Array).is_empty():
		lines.append("Efeitos especiais deste item: integracao pendente no beta.")
	return "\n".join(lines)


## Dica colorida do inventário, no estilo de Hero Siege (decisão 584): nome na cor da raridade,
## tipo e fabricação, atributos-base, afixos em azul, passiva em laranja e ambientação no fim.
static func item_rich(definition: Dictionary, tier_id: String, slot: String, fabrication: String, weapon: Dictionary, affixes: Array, hint: String = "", item_level: int = 1, stat_factor: float = 1.0) -> String:
	var id := String(definition.get("id", ""))
	var tier_color := ItemTier.color(tier_id).to_html(false)
	var tier_label := String({"common":"Comum", "uncommon":"Incomum", "rare":"Raro", "epic":"Epico", "legendary":"Lendario"}.get(tier_id, tier_id))
	var out := PackedStringArray()
	out.append("[font_size=17][color=#%s][b]%s[/b][/color][/font_size]" % [tier_color, String(definition.get("name", id))])
	var kind := "Arma unica" if not String(definition.get("unique_gem", "")).is_empty() else slot.capitalize()
	out.append("[color=#%s]%s %s[/color][color=#8f7a6a]  |  %s  |  Nivel %d[/color]" % [tier_color, tier_label, kind, fabrication, item_level])
	if not weapon.is_empty():
		out.append("[color=#f2e6c9]Dano %.1f  |  Alcance %.0f  |  Intervalo %.2fs[/color]" % [float(weapon["damage"]), float(weapon["range"]), float(weapon["interval"])])
		if float(weapon.get("guard", 0.0)) > 0.0 or float(weapon.get("life_steal", 0.0)) > 0.0:
			out.append("[color=#f2e6c9]Guarda -%.0f%%  |  Roubo de Vida %.0f%%[/color]" % [float(weapon.get("guard", 0.0)) * 100.0, float(weapon.get("life_steal", 0.0)) * 100.0])
	var stats := definition.get("stats", {}) as Dictionary
	for stat: String in stats:
		var unit := "%" if stat in ["movement_speed", "attack_speed", "critical_chance", "cooldown_recovery", "area"] else ""
		out.append("[color=#f2e6c9]+%s%s %s[/color]" % [_number(float(stats[stat]) * stat_factor), unit, STAT_NAMES.get(stat, stat)])
	if not affixes.is_empty():
		out.append("")
		for affix: Dictionary in affixes:
			out.append("[color=#7fb0ff]%s[/color]" % ItemAffixesScript.describe(affix))
	var passive := definition.get("passive", {}) as Dictionary
	if not passive.is_empty():
		out.append("")
		out.append("[color=#f08a3c][b]%s[/b][/color]" % String(passive.get("name", "")).to_upper())
		out.append("[color=#f0b07a]%s[/color]" % String(passive.get("description", "")))
	var flavor := String(definition.get("description", ITEM_TEXT.get(id.replace("couraça", "couraca"), "")))
	if not flavor.is_empty():
		out.append("")
		out.append("[i][color=#8f7a6a]%s[/color][/i]" % flavor)
	if not hint.is_empty():
		out.append("")
		out.append("[color=#aaa59a]%s[/color]" % hint)
	return "\n".join(out)


static func _number(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value


static func skill(model: Dictionary) -> String:
	var lines := PackedStringArray([String(model.get("name", "")), String(model.get("description", ""))])
	lines.append("Folego %.0f | Recarga %.1fs | Cargas %d" % [float(model.get("breath_cost", 0.0)), float(model.get("cooldown", 0.0)), int(model.get("charges", 1))])
	for spec in [["power", "Potencia"], ["barrier", "Barreira"], ["healing", "Cura por pulso"]]:
		if float(model.get(spec[0], 0.0)) > 0.0:
			lines.append("%s: %.0f" % [spec[1], float(model[spec[0]])])
	var scaling := PackedStringArray()
	for entry: Dictionary in model.get("scaling", []) as Array:
		scaling.append("%s +%.1f%%/ponto" % [STAT_NAMES.get(String(entry["stat"]), String(entry["stat"])), float(entry["per_point"]) * 100.0])
	if not scaling.is_empty():
		lines.append("Escala com: " + ", ".join(scaling))
	for support: Dictionary in model.get("supports", []) as Array:
		lines.append("%s: %s" % [support.get("name", ""), support.get("description", "")])
	return "\n".join(lines)
