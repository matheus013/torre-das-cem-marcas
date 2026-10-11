class_name Resistances
extends RefCounted

## Resistências (épico E1, fase 1; documento 76, seção 2). Físico e nove elementos. Cada inimigo
## soma a resistência da raça e a do bioma (e, na fase 2, a da dificuldade), limitada de -50%
## (fraqueza) a +75%. Penetração só reduz resistência positiva; Quebra elemental reduz por alguns
## segundos; Adaptação (dificuldades 4 e 5) dá resistência ao tipo que mais feriu o inimigo.
## Personagens resistem por afixos, até o teto de 75%.

const TYPES: Array[String] = ["physical", "fire", "ice", "lightning", "acid", "nature", "dark", "holy", "earth", "arcane"]
const LABELS := {
	"physical": "Fisico", "fire": "Fogo", "ice": "Gelo", "lightning": "Raio", "acid": "Acido",
	"nature": "Natureza", "dark": "Trevas", "holy": "Sagrado", "earth": "Terra", "arcane": "Arcano",
}
const MINIMUM := -0.5
const MAXIMUM := 0.75
const PLAYER_CAP := 0.75
## Adaptação: o tipo que mais feriu nos últimos segundos ganha esta resistência extra.
const ADAPTATION_BONUS := 0.3
const ADAPTATION_DECAY := 0.25

## Resistências por raça (fração). Positivo resiste, negativo é fraqueza.
const RACE := {
	"juntideo": {"physical": -0.1, "nature": 0.2, "fire": -0.25},
	"calcario": {"physical": 0.3, "earth": 0.3, "acid": -0.25},
	"rebocado": {"physical": 0.15, "earth": 0.2, "lightning": -0.25},
	"moldado": {"arcane": 0.25, "physical": 0.1, "acid": -0.2},
	"enxertado": {"nature": 0.25, "acid": 0.25, "fire": -0.25},
	"ventania": {"lightning": 0.25, "physical": -0.15, "earth": -0.25},
	"micelar": {"nature": 0.4, "acid": 0.25, "fire": -0.4},
	"lodoso": {"physical": 0.25, "ice": 0.2, "lightning": -0.3},
	"carregado": {"lightning": 0.5, "ice": -0.25},
	"cartografo": {"arcane": 0.4, "holy": -0.25},
	"parasitario": {"dark": 0.3, "nature": 0.2, "holy": -0.35},
	"aderente": {"physical": 0.2, "fire": -0.2},
	"possivel": {"arcane": 0.25, "dark": 0.25, "physical": -0.15},
	"sem_autor": {"physical": 0.1, "fire": 0.1, "ice": 0.1, "lightning": 0.1, "acid": 0.1, "nature": 0.1, "dark": 0.1, "holy": 0.1, "earth": 0.1, "arcane": 0.1},
}
## Resistência que o bioma soma a todos os inimigos dele.
const BIOME := {
	"galerias": {"earth": 0.1},
	"bosque": {"lightning": 0.1},
	"manto": {"nature": 0.2, "fire": -0.1},
	"bacias": {"ice": 0.2, "fire": 0.1, "lightning": -0.1},
	"ermo": {"lightning": 0.25},
	"arquivo": {"arcane": 0.2},
	"planicie": {"physical": 0.15},
	"eixos": {"dark": 0.15, "arcane": 0.1},
	"campos": {"holy": 0.15, "dark": 0.15},
	"obra": {"physical": 0.1, "fire": 0.1, "ice": 0.1, "lightning": 0.1, "acid": 0.1, "nature": 0.1, "dark": 0.1, "holy": 0.1, "earth": 0.1, "arcane": 0.1},
}
## Tipo do dano corpo a corpo e dos projéteis de cada raça.
const RACE_DAMAGE := {
	"juntideo": "physical", "calcario": "earth", "rebocado": "physical", "moldado": "arcane", "enxertado": "acid",
	"ventania": "lightning", "micelar": "nature", "lodoso": "ice", "carregado": "lightning", "cartografo": "arcane",
	"parasitario": "dark", "aderente": "physical", "possivel": "arcane", "sem_autor": "dark",
}
## Tipo do dano dos perigos e habilidades de chefe de cada bioma.
const BIOME_DAMAGE := {
	"galerias": "earth", "bosque": "lightning", "manto": "nature", "bacias": "ice", "ermo": "lightning",
	"arquivo": "arcane", "planicie": "physical", "eixos": "dark", "campos": "holy", "obra": "arcane",
}
## Veneno por tipo de dano.
const POISON_DAMAGE := {"esporo": "nature", "toxina": "acid"}


## Perfil de um inimigo: raça + bioma + bônus por tipo (dificuldade), limitado à faixa.
static func enemy_profile(race_id: String, biome_id: String, bonus: float = 0.0) -> Dictionary:
	var result := {}
	var race := RACE.get(race_id, {}) as Dictionary
	var biome := BIOME.get(biome_id, {}) as Dictionary
	for kind in TYPES:
		var value := float(race.get(kind, 0.0)) + float(biome.get(kind, 0.0)) + bonus
		if not is_zero_approx(value):
			result[kind] = clampf(value, MINIMUM, MAXIMUM)
	return result


## Penetração reduz só a resistência positiva, nunca abaixo de zero; fraquezas ficam.
static func after_penetration(resistance: float, penetration: float) -> float:
	return maxf(0.0, resistance - maxf(0.0, penetration)) if resistance > 0.0 else resistance


## Tipo de um acerto: elemento explícito, veneno, elemento da gema ou o tipo de dano.
static func hit_type(hit: Dictionary, gem_element: String) -> String:
	if not String(hit.get("element", "")).is_empty():
		return String(hit["element"])
	if hit.has("poison"):
		return String(POISON_DAMAGE.get(String(hit["poison"]), "acid"))
	if not gem_element.is_empty():
		return gem_element
	return "physical" if String(hit.get("damage_type", "physical")) == "physical" else "arcane"


## Resistência efetiva de um inimigo a um tipo: perfil, quebras ativas, adaptação e penetração.
static func enemy_resistance(enemy: Dictionary, kind: String, penetration: float) -> float:
	var value := float((enemy.get("resistances", {}) as Dictionary).get(kind, 0.0))
	var breaks := enemy.get("breaks", {}) as Dictionary
	if breaks.has(kind):
		value -= float((breaks[kind] as Dictionary).get("amount", 0.0))
	if bool(enemy.get("adaptive", false)) and String(enemy.get("adapted_type", "")) == kind:
		value += ADAPTATION_BONUS
	return clampf(after_penetration(value, penetration), MINIMUM, MAXIMUM)


## Registra o dano para a Adaptação e escolhe o tipo dominante.
static func record_adaptation(enemy: Dictionary, kind: String, damage: float) -> void:
	if not bool(enemy.get("adaptive", false)):
		return
	var scores := enemy.get_or_add("adapt_scores", {}) as Dictionary
	scores[kind] = float(scores.get(kind, 0.0)) + damage
	var best := ""
	for key: String in scores:
		if best.is_empty() or float(scores[key]) > float(scores[best]):
			best = key
	enemy["adapted_type"] = best


## Passo de tempo: quebras expiram e a memória da Adaptação esfria.
static func step(enemy: Dictionary, delta: float) -> void:
	var breaks := enemy.get("breaks", {}) as Dictionary
	for kind: Variant in breaks.keys():
		var entry := breaks[kind] as Dictionary
		entry["timer"] = float(entry["timer"]) - delta
		if float(entry["timer"]) <= 0.0:
			breaks.erase(kind)
	var scores := enemy.get("adapt_scores", {}) as Dictionary
	for kind: Variant in scores.keys():
		scores[kind] = float(scores[kind]) * maxf(0.0, 1.0 - ADAPTATION_DECAY * delta)


## Quebra elemental: reduz a resistência ao tipo por alguns segundos (a maior quebra vale).
static func apply_break(enemy: Dictionary, kind: String, amount: float, duration: float) -> void:
	var breaks := enemy.get_or_add("breaks", {}) as Dictionary
	var current := breaks.get(kind, {}) as Dictionary
	breaks[kind] = {"amount": maxf(amount, float(current.get("amount", 0.0))), "timer": maxf(duration, float(current.get("timer", 0.0)))}


## Fraquezas e resistências mais fortes de um perfil, para HUD e bestiário.
static func summary(profile: Dictionary) -> Dictionary:
	var weak: Array[String] = []
	var strong: Array[String] = []
	var kinds := profile.keys()
	kinds.sort_custom(func(left: Variant, right: Variant) -> bool: return absf(float(profile[left])) > absf(float(profile[right])))
	for kind: Variant in kinds:
		var value := float(profile[kind])
		var text := "%s %+d%%" % [String(LABELS.get(String(kind), String(kind))), roundi(value * 100.0)]
		if value < 0.0:
			weak.append(text)
		elif value > 0.0:
			strong.append(text)
	return {"weak": weak, "strong": strong}
