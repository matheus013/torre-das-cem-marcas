extends RefCounted

## Bestiário (decisão 593): cada personagem aprende sobre um tipo de monstro abatendo-o. Cada
## nível de conhecimento revela uma camada: identidade, atributos, comportamento e defesas, saque
## com chances e, no último, o saque e os afixos efetivamente observados.

const LEVEL_NAMES: Array[String] = ["Desconhecido", "Avistado", "Estudado", "Compreendido", "Catalogado", "Dominado"]
const SECTION_NAMES: Array[String] = ["", "Identidade", "Atributos", "Comportamento e defesas", "Saque", "Registro de campo"]
## Abates necessários para cada nível (1 a 5), por classe de encontro.
const THRESHOLDS := {
	"common": [1, 5, 15, 30, 60],
	"elite": [1, 3, 8, 15, 30],
	"boss": [1, 2, 3, 5, 8],
	"raid": [1, 2, 3, 5, 8],
}
const CLASS_NAMES := {"common": "Comum", "elite": "Elite", "boss": "Chefe", "raid": "Raid"}
const MECHANICS := {
	"swarm": "Enxame: avança em bando e ataca corpo a corpo.",
	"erode_cover": "Erosão: avança 15% mais rápido que o normal e ataca corpo a corpo.",
	"mark_target": "Marcador: mantém distância (até 300) e dispara projéteis que marcam o alvo.",
	"telegraphed_shot": "Atirador: mantém distância (até 300) e dispara projéteis anunciados.",
	"wall_ambush": "Emboscada: espera escondido nas paredes até a personagem chegar a 170.",
	"enemy_barrier": "Escudeiro: a cada 4 s dá 1 bloqueio (até 2) aos aliados num raio de 190.",
	"incorporate_objects": "Absorvedor: a cada 3,5 s causa o próprio dano a todos num raio de 180.",
	"loot_mimic": "Imitador: parece saque no chão até a personagem chegar a 180.",
	"boss_kit": "Guardião de andar: luta com habilidades próprias (abaixo).",
	"shadow_blink": "Sombra (só à noite): a cada 5 s some e reaparece atrás de quem persegue.",
	"light_eater": "Bebe-luz (só à noite): perto dele (260) a luz da personagem cai pela metade.",
	"flee": "Coletor (só de manhã): foge de quem chega perto e nunca ataca; solta Âmbar Solar.",
}
const TRAITS := {
	"stone_skin": "Pele de Pedra: corpo mineral, com resistência física alta (veja Resistências).",
	"adaptive_shell": "Casca Adaptável: a cada 3 golpes diretos ganha 1 bloqueio. Dano contínuo atravessa.",
	"barrier_breaker": "Quebra-Barreira: causa 35% mais dano a quem tem barreira.",
	"effect_feeder": "Devorador de Efeitos: regenera 1% da Vida por segundo enquanto houver zonas e efeitos persistentes no andar.",
	"wall_camouflage": "Camuflagem: espera escondido nas paredes até a personagem chegar a 170.",
}
const ABILITIES := {
	"slam": "Golpe no chão", "nova": "Nova em volta", "summon": "Invoca aliados", "barrage": "Rajada de projéteis",
	"charge": "Investida", "pull": "Puxão", "gust": "Rajada de vento", "cross": "Cruz de impacto",
	"donut": "Anel (o centro é seguro)", "line": "Linha de impacto", "meteor": "Chuva de meteoros", "zone": "Zona de dano",
}


static func thresholds(encounter_class: String) -> Array:
	return THRESHOLDS.get(encounter_class, THRESHOLDS["common"]) as Array


## Nível de conhecimento (0 a 5) pelo número de abates.
static func level(kills: int, encounter_class: String) -> int:
	var result := 0
	for needed: int in thresholds(encounter_class):
		if kills >= needed:
			result += 1
	return result


## Abates para o próximo nível (-1 quando já está no máximo).
static func next_threshold(kills: int, encounter_class: String) -> int:
	for needed: int in thresholds(encounter_class):
		if kills < needed:
			return needed
	return -1


static func percent(value: float) -> String:
	if value >= 0.1:
		return "%.0f%%" % (value * 100.0)
	if value >= 0.01:
		return "%.1f%%" % (value * 100.0)
	return "%.2f%%" % (value * 100.0)
