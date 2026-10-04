class_name ContentDescriptions
extends RefCounted

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
const FUNCTIONAL_STATS := ["health", "breath", "strength", "intelligence", "agility", "vitality", "wisdom", "fortune", "movement_speed", "attack_speed", "critical_chance", "cooldown_recovery"]


static func item(definition: Dictionary, tier: String, fabrication: String = "", weapon: Dictionary = {}) -> String:
	var id := String(definition.get("id", ""))
	var tier_label := String({"common":"Comum", "uncommon":"Incomum", "rare":"Raro", "epic":"Epico", "legendary":"Lendario"}.get(tier, tier))
	var lines := PackedStringArray([String(definition.get("name", id)), tier_label + (" | " + fabrication if not fabrication.is_empty() else "")])
	var fallback := "Material de coleta da regiao: %s." % String(definition["biome"]).replace("_", " ").capitalize() if definition.has("biome") else "Item de expedicao."
	lines.append(String(definition.get("description", ITEM_TEXT.get(id.replace("couraça", "couraca"), fallback))))
	if not weapon.is_empty():
		lines.append("%s | %s | Afinidade %.0f%%" % [weapon["name"], "Arcano" if weapon["damage_type"] == "arcane" else "Fisico", float(weapon["affinity"])])
		lines.append("Potencia da arma %.1f | Alcance %.0f | Intervalo base %.2fs" % [float(weapon["damage"]), float(weapon["range"]), float(weapon["interval"])])
		for stat: String in weapon["scaling"] as Dictionary:
			lines.append("%s: +%.1f%% por ponto" % [STAT_NAMES.get(stat, stat), float(weapon["scaling"][stat]) * 100.0])
	var stats := definition.get("stats", {}) as Dictionary
	for stat: String in stats:
		var unit := "%" if stat in ["movement_speed", "attack_speed", "critical_chance", "cooldown_recovery"] else ""
		lines.append("%s: +%.1f%s%s" % [STAT_NAMES.get(stat, stat.replace("_", " ")), float(stats[stat]), unit, " (sem efeito no beta)" if stat not in FUNCTIONAL_STATS else ""])
	if not (definition.get("mechanics", []) as Array).is_empty():
		lines.append("Efeitos especiais deste item: integracao pendente no beta.")
	return "\n".join(lines)


static func skill(model: Dictionary) -> String:
	var lines := PackedStringArray([String(model.get("name", "")), String(model.get("description", ""))])
	lines.append("Folego %.0f | Recarga %.1fs | Cargas %d" % [float(model.get("breath_cost", 0.0)), float(model.get("cooldown", 0.0)), int(model.get("charges", 1))])
	for spec in [["power", "Potencia da gema"], ["barrier", "Barreira da gema"], ["healing", "Cura base por pulso"]]:
		if float(model.get(spec[0], 0.0)) > 0.0:
			lines.append("%s: %.0f" % [spec[1], float(model[spec[0]])])
	for support: Dictionary in model.get("supports", []) as Array:
		lines.append("%s: %s" % [support.get("name", ""), support.get("description", "")])
	return "\n".join(lines)
