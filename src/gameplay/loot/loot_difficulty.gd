class_name LootDifficulty
extends RefCounted

## Saque cresce com a dificuldade da baixa (decisão 552). A dificuldade `D` soma classe de encontro,
## grau, afixos e tamanho do grupo; dela saem a quantidade (chance e tamanho das pilhas), a chance de
## um item bônus, o tier desse item e a fabricação dos equipamentos (documento 69).

const CLASS_WEIGHT := {"common": 0.0, "elite": 1.5, "boss": 4.0, "raid": 6.0}
const RANK_WEIGHT := {"nascente": 0.0, "maduro": 0.5, "evoluido": 1.0, "alfa": 1.5, "apice": 2.0}
const AFFIX_WEIGHT := 0.75
const TIERS: Array[String] = ["common", "uncommon", "rare", "epic", "legendary"]
## Fabricação da instância de equipamento e o fator aplicado aos seus bônus.
const FABRICATION_FACTORS := {"improvised": 0.85, "regular": 1.0, "refined": 1.15, "masterwork": 1.3}
const FABRICATION_LABELS := {"improvised": "Improvisada", "regular": "Regular", "refined": "Refinada", "masterwork": "Magistral"}


static func score(enemy: Dictionary, party_budget: float = 1.0) -> float:
	var value := float(CLASS_WEIGHT.get(String(enemy.get("encounter_class", "common")), 0.0))
	value += float(RANK_WEIGHT.get(String(enemy.get("rank_id", "maduro")), 0.5))
	for key in ["prefix_id", "suffix_id"]:
		if not String(enemy.get(key, "")).is_empty():
			value += AFFIX_WEIGHT
	value += maxf(0.0, party_budget - 1.0)
	return value


## Multiplica a chance de cada entrada da tabela (limitada a 100%).
static func chance_multiplier(difficulty: float) -> float:
	return 1.0 + 0.1 * difficulty


## Multiplica o tamanho de cada pilha; o resto fracionário vira sorteio.
static func quantity_multiplier(difficulty: float) -> float:
	return 1.0 + 0.12 * difficulty


static func scaled_quantity(quantity: int, difficulty: float, random: RandomNumberGenerator) -> int:
	var scaled := float(quantity) * quantity_multiplier(difficulty)
	var whole := int(floor(scaled))
	return whole + (1 if random.randf() < scaled - float(whole) else 0)


## Chance de um equipamento bônus além da tabela da criatura. A base garante que inimigos
## comuns também soltem equipamento (cerca de 2 a 3 por andar de 30 abates).
const BONUS_BASE_CHANCE := 0.08


static func bonus_chance(difficulty: float) -> float:
	return minf(0.75, BONUS_BASE_CHANCE + 0.04 * difficulty)


static func tier_weights(difficulty: float) -> Dictionary:
	return {
		"common": maxf(0.0, 8.0 - 1.5 * difficulty),
		"uncommon": 4.0 + 0.5 * difficulty,
		"rare": 1.0 + 0.6 * difficulty,
		"epic": maxf(0.0, 0.35 * (difficulty - 2.0)),
		"legendary": maxf(0.0, 0.12 * (difficulty - 5.0)),
	}


static func fabrication_weights(difficulty: float) -> Dictionary:
	return {
		"improvised": maxf(0.0, 3.0 - difficulty),
		"regular": 6.0,
		"refined": 1.0 + difficulty,
		"masterwork": maxf(0.0, 0.5 * (difficulty - 2.0)),
	}


static func pick_weighted(weights: Dictionary, random: RandomNumberGenerator) -> String:
	var total := 0.0
	for key: Variant in weights:
		total += float(weights[key])
	if total <= 0.0:
		return String(weights.keys()[0])
	var roll := random.randf() * total
	for key: Variant in weights:
		roll -= float(weights[key])
		if roll <= 0.0:
			return String(key)
	return String(weights.keys()[weights.size() - 1])


## Sorteia o equipamento bônus: primeiro o tier, depois uma peça desse tier (ou do mais próximo abaixo).
## Materiais e consumíveis ficam de fora, pois já vêm das tabelas. Relíquias só de chefe ou raid.
static func pick_bonus_item(items: Array[Dictionary], difficulty: float, allow_relics: bool, random: RandomNumberGenerator) -> String:
	var tier := pick_weighted(tier_weights(difficulty), random)
	for index in range(TIERS.find(tier), -1, -1):
		var pool: Array[String] = []
		for item in items:
			if String(item.get("tier", "common")) != TIERS[index]:
				continue
			var slot := String(item.get("slot", "none"))
			# Armas únicas têm sorteio próprio, direcionado às gemas de quem abateu.
			# Selos da Cicatriz têm fonte própria (chefes da dificuldade deles).
			if slot in ["none", "seal"] or (slot == "relic" and not allow_relics) or item.has("unique_gem"):
				continue
			pool.append(String(item.get("id", "")))
		if not pool.is_empty():
			return pool[random.randi_range(0, pool.size() - 1)]
	return ""


static func fabrication_factor(quality: String) -> float:
	return float(FABRICATION_FACTORS.get(quality, 1.0))
