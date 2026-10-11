extends RefCounted

## Épico E1, fase 4 (G8.6 e G8.7; documento 76, seções 4 e 5; decisão 606): afixos de elite com
## comportamento, mutadores de andar e marés. Só dados e sorteios puros; a simulação aplica.
## Valores provisórios.

## Afixos de comportamento: terceiro espaço de afixo (decisão 602), além de prefixo e sufixo. Só
## aparecem da dificuldade 2 em diante, então a dificuldade 1 não muda.
const BEHAVIORS := {
	"refletor": {"name": "Refletor", "description": "Devolve 20% do dano de um tipo (ate 10% da Vida de quem bate)."},
	"absorvente": {"name": "Absorvente", "description": "Fica imune por 3 s ao ultimo tipo de dano que o feriu."},
	"vinculado": {"name": "Vinculado", "description": "Divide metade do dano com o aliado mais proximo."},
	"profanador": {"name": "Profanador", "description": "Aura que corta pela metade a cura de quem esta perto."},
	"cacador": {"name": "Cacador", "description": "Marca uma personagem e a persegue ignorando as outras."},
	"fissurador": {"name": "Fissurador", "description": "Deixa fendas que explodem depois de 2 s."},
	"escudeiro": {"name": "Escudeiro", "description": "Aliados em volta recebem 30% menos dano enquanto ele vive."},
}
const BEHAVIOR_HEALTH := 1.15
const BEHAVIOR_LOOT := 1.5
## Chance de um elite (e de membros de bando superior) ganhar o afixo de comportamento, por dificuldade.
const BEHAVIOR_CHANCE: Array[float] = [0.0, 0.35, 0.7, 1.0, 1.0]
const SUPERIOR_BEHAVIOR_CHANCE: Array[float] = [0.0, 0.0, 0.0, 0.5, 1.0]
const REFLECT_SHARE := 0.2
const REFLECT_CAP := 0.1
const ABSORB_SECONDS := 3.0
const LINK_RANGE := 300.0
const LINK_SHARE := 0.5
const DESECRATE_RADIUS := 220.0
const DESECRATE_HEALING := 0.5
const FISSURE_INTERVAL := 3.5
const FISSURE_DELAY := 2.0
const FISSURE_RADIUS := 70.0
const FISSURE_DAMAGE := 1.4
const SQUIRE_RADIUS := 220.0
const SQUIRE_REDUCTION := 0.3

## Mutadores de andar (dificuldade 3 em diante). Cada um soma ao saque do andar.
const MUTATORS := {
	"chao_vivo": {"name": "Chao Vivo", "cruel": false, "description": "Perigos do bioma duas vezes mais frequentes."},
	"ecos": {"name": "Ecos", "cruel": false, "description": "Todo golpe de monstro ecoa: +35% de dano corpo a corpo."},
	"fome": {"name": "Fome", "cruel": false, "description": "Cura recebida -40%."},
	"pressa": {"name": "Pressa", "cruel": false, "description": "Inimigos +25% de velocidade."},
	"blindagem": {"name": "Blindagem", "cruel": false, "description": "Inimigos +20% de resistencia fisica."},
	"tempestade": {"name": "Tempestade", "cruel": false, "description": "Raios caem sobre o grupo a cada 6 s."},
	"escuridao": {"name": "Escuridao", "cruel": false, "description": "O andar fica escuro mesmo de dia e a luz cai pela metade."},
	"enxertia": {"name": "Enxertia", "cruel": false, "description": "Inimigos mortos voltam uma vez com metade da Vida."},
	"sem_retorno": {"name": "Sem Retorno", "cruel": true, "description": "O portal de retorno so abre junto com a escada."},
	"cicatriz": {"name": "Cicatriz", "cruel": true, "description": "Cada queda tira o dobro da Vida maxima."},
	"divida": {"name": "Divida", "cruel": true, "description": "O Folego nao regenera; cada abate devolve 15%."},
}
## Mutadores normais e cruéis por dificuldade (decisão 598: na 5, 1 cruel obrigatório).
const MUTATOR_COUNTS: Array[Array] = [[0, 0], [0, 0], [1, 0], [2, 0], [2, 1]]
const NORMAL_LOOT := 0.15
const CRUEL_LOOT := 0.4
const HUNGER_HEALING := 0.6
const HASTE_SPEED := 1.25
const PLATING_RESIST := 0.2
const STORM_INTERVAL := 6.0
const DARKNESS_LIGHT := 0.5
const SCAR_WOUNDS := 2.0
const DEBT_REFUND := 0.15

## Marés (hordas especiais): aviso de 5 s, objetivo com tempo e recompensa própria.
const TIDES := {
	"enxame": {"name": "Enxame", "goal": "Derrote o enxame", "seconds": 60.0, "reward": "Bau do Enxame"},
	"cerco": {"name": "Cerco", "goal": "Quebre o anel de atiradores", "seconds": 60.0, "reward": "Fragmentos de gema"},
	"procissao": {"name": "Procissao", "goal": "Derrube o carregador antes que fuja", "seconds": 75.0, "reward": "Peca garantida do maior tier"},
	"avalanche": {"name": "Avalanche", "goal": "Contenha a avalanche", "seconds": 75.0, "reward": "Materiais de forja"},
	"vinculo": {"name": "Vinculo", "goal": "Derrote os pares vinculados", "seconds": 60.0, "reward": "Ambar da Mare"},
	"eclipse": {"name": "Eclipse", "goal": "Sobreviva ao escuro", "seconds": 45.0, "reward": "Orvalho Negro", "night_only": true},
}
## A Lua da Cicatriz encadeia todas as marés, uma depois da outra.
const SCAR_MOON_SEQUENCE: Array[String] = ["enxame", "cerco", "procissao", "avalanche", "vinculo", "eclipse"]
const WARNING_SECONDS := 5.0
const BREAK_SECONDS := 10.0
## Chance de maré por andar comum, por dificuldade; a noite soma.
const TIDE_CHANCE: Array[float] = [0.15, 0.2, 0.3, 0.4, 0.5]
const NIGHT_TIDE_BONUS := 0.15
## Quando a maré começa, contado do início do andar (antes da escada de 10 minutos).
const TIDE_WINDOW := [60.0, 360.0]


## Mutadores do andar: sorteio reproduzível por mundo, dificuldade e andar.
static func roll_mutators(seed: int, difficulty: int, floor_number: int) -> Array[String]:
	var result: Array[String] = []
	var counts := MUTATOR_COUNTS[clampi(difficulty, 1, MUTATOR_COUNTS.size()) - 1]
	if int(counts[0]) + int(counts[1]) <= 0:
		return result
	var random := RandomNumberGenerator.new()
	random.seed = hash([seed, difficulty, floor_number, "mutators"])
	for cruel in [false, true]:
		var pool: Array[String] = []
		for mutator_id: String in MUTATORS:
			if bool(MUTATORS[mutator_id]["cruel"]) == cruel:
				pool.append(mutator_id)
		for pick in range(int(counts[1 if cruel else 0])):
			if pool.is_empty():
				break
			result.append(pool.pop_at(random.randi_range(0, pool.size() - 1)))
	return result


## Multiplicador de saque dos mutadores.
static func mutator_loot(mutators: Array) -> float:
	var result := 1.0
	for mutator_id: Variant in mutators:
		result += CRUEL_LOOT if bool((MUTATORS.get(String(mutator_id), {}) as Dictionary).get("cruel", false)) else NORMAL_LOOT
	return result


## Maré do andar: {} sem maré; com maré, {"queue": [ids], "start": segundos}. A Lua da Cicatriz
## garante a sequência completa.
static func roll_tide(seed: int, difficulty: int, floor_number: int, night: bool, scar_moon: bool) -> Dictionary:
	var random := RandomNumberGenerator.new()
	random.seed = hash([seed, difficulty, floor_number, "tide"])
	var start := random.randf_range(float(TIDE_WINDOW[0]), float(TIDE_WINDOW[1]))
	if scar_moon:
		return {"queue": SCAR_MOON_SEQUENCE.duplicate(), "start": start, "scar_moon": true}
	var chance := TIDE_CHANCE[clampi(difficulty, 1, TIDE_CHANCE.size()) - 1] + (NIGHT_TIDE_BONUS if night else 0.0)
	if random.randf() >= chance:
		return {}
	var pool: Array[String] = []
	for tide_id: String in TIDES:
		if night or not bool((TIDES[tide_id] as Dictionary).get("night_only", false)):
			pool.append(tide_id)
	return {"queue": [pool[random.randi_range(0, pool.size() - 1)]], "start": start, "scar_moon": false}


static func mutator_names(mutators: Array) -> Array[String]:
	var result: Array[String] = []
	for mutator_id: Variant in mutators:
		result.append(String((MUTATORS.get(String(mutator_id), {}) as Dictionary).get("name", mutator_id)))
	return result
