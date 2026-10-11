extends RefCounted

## Paragon da conta (épico E1, fase 5; G8.8; documento 76, seção 7; decisões 597 e 607). Depois do
## nível 100, a EXP das dificuldades 3 a 5 (x1,5 na 4 e x2 na 5) vira níveis Paragon, até 200. Nível
## e EXP são do jogador (perfil local, fora do save do mundo) e somam todas as personagens e mundos.
## Cada personagem tem o próprio tabuleiro com todos os pontos da conta, em quatro trilhas; a cada
## 10 pontos numa trilha abre um nó notável com mecânica. Os nós usam o motor de passivas de itens.

const MAX_LEVEL := 200
const REQUIRED_CHARACTER_LEVEL := 100
const MIN_DIFFICULTY := 3
## Multiplicador da EXP Paragon por dificuldade (índice 0 = dificuldade 1).
const EXP_MULT: Array[float] = [0.0, 0.0, 1.0, 1.5, 2.0]
const RESPEC_SILVER_PER_POINT := 50
const TRACKS: Array[String] = ["ofensiva", "defensiva", "utilidade", "elemental"]
const TRACK_NAMES := {"ofensiva": "Ofensiva", "defensiva": "Defensiva", "utilidade": "Utilidade", "elemental": "Elemental"}
## Bônus por ponto (`_mult` vira 1 + valor x pontos; o resto soma).
const PER_POINT := {
	"ofensiva": {"power_mult": 0.015, "crit_damage_add": 0.004},
	"defensiva": {"max_health_mult": 0.015, "resist_all_add": 0.0025},
	"utilidade": {"max_breath_add": 1.0, "cooldown_mult": -0.004, "move_speed_mult": 0.005, "light_radius_mult": 0.01},
	"elemental": {"power_magic_mult": 0.015, "penetration_add": 0.004},
}
const PER_POINT_TEXT := {
	"ofensiva": "+1,5% de dano e +0,4% de dano critico por ponto",
	"defensiva": "+1,5% de Vida maxima e +0,25% de resistencia a tudo por ponto",
	"utilidade": "+1 de Folego, -0,4% de recarga, +0,5% de velocidade e +1% de raio de luz por ponto",
	"elemental": "+1,5% de dano magico e +0,4% de penetracao por ponto",
}
## Nós notáveis: abrem com 10, 20, 30, 40 e 50 pontos na trilha.
const NOTABLES := {
	"ofensiva": [
		{"id": "golpe_certeiro", "name": "Golpe Certeiro", "description": "Chance critica +5%.", "mods": {"crit_chance_add": 0.05}},
		{"id": "brasas_do_abate", "name": "Brasas do Abate", "description": "Abates explodem em brasas: 30 de dano de fogo em volta.", "triggers": [{"on": "kill", "actions": [{"do": "burst", "radius": 90, "power": 30, "element": "fire"}]}]},
		{"id": "penetrante", "name": "Penetrante", "description": "Penetracao de resistencia +10%.", "mods": {"penetration_add": 0.1}},
		{"id": "execucao", "name": "Execucao", "description": "Acertos executam inimigos abaixo de 10% da Vida (chefes nao).", "triggers": [{"on": "hit", "actions": [{"do": "execute", "below": 0.1}]}]},
		{"id": "furia_final", "name": "Furia Final", "description": "Dano +25%.", "mods": {"power_mult": 1.25}},
	],
	"defensiva": [
		{"id": "pele_grossa", "name": "Pele Grossa", "description": "Vida maxima +10%.", "mods": {"max_health_mult": 1.1}},
		{"id": "luz_excedente", "name": "Luz Excedente", "description": "Cura acima da Vida maxima vira barreira.", "mods": {"overheal_barrier": 1.0}},
		{"id": "muralha", "name": "Muralha", "description": "Dano recebido -10%.", "mods": {"damage_taken_mult": 0.9}},
		{"id": "manto_elemental", "name": "Manto Elemental", "description": "Resistencia a tudo +10%.", "mods": {"resist_all_add": 0.1}},
		{"id": "ultimo_suspiro", "name": "Ultimo Suspiro", "description": "O golpe fatal deixa de pe com 40% da Vida e 2 s de invulnerabilidade (a cada 120 s).", "triggers": [{"on": "lethal", "cooldown": 120.0, "actions": [{"do": "revive", "ratio": 0.4, "invulnerable": 2.0}]}]},
	],
	"utilidade": [
		{"id": "folego_fundo", "name": "Folego Fundo", "description": "Folego maximo +30.", "mods": {"max_breath_add": 30.0}},
		{"id": "passo_leve", "name": "Passo Leve", "description": "Velocidade +10%.", "mods": {"move_speed_mult": 1.1}},
		{"id": "lanterna", "name": "Lanterna", "description": "Raio de luz +30%.", "mods": {"light_radius_mult": 1.3}},
		{"id": "ciclo", "name": "Ciclo", "description": "Recargas -10%.", "mods": {"cooldown_mult": 0.9}},
		{"id": "tempo_emprestado", "name": "Tempo Emprestado", "description": "Abates tem 20% de chance de adiantar todas as recargas em 1 s.", "triggers": [{"on": "kill", "chance": 0.2, "actions": [{"do": "refund", "scope": "all", "seconds": 1.0}]}]},
	],
	"elemental": [
		{"id": "quebra_elemental", "name": "Quebra Elemental", "description": "Acertos de gema tem 20% de chance de quebrar 15% da resistencia ao elemento da gema por 4 s.", "triggers": [{"on": "hit", "source": "gem", "chance": 0.2, "actions": [{"do": "break", "element": "hit", "amount": 0.15, "duration": 4.0}]}]},
		{"id": "fogo_e_gelo", "name": "Fogo e Gelo", "description": "Dano de fogo e gelo +15%.", "mods": {"power_fire_mult": 1.15, "power_ice_mult": 1.15}},
		{"id": "tempestade_interior", "name": "Tempestade Interior", "description": "Dano de raio, acido e natureza +15%.", "mods": {"power_lightning_mult": 1.15, "power_acid_mult": 1.15, "power_nature_mult": 1.15}},
		{"id": "sombra_e_luz", "name": "Sombra e Luz", "description": "Dano de trevas, sagrado, terra e arcano +15%.", "mods": {"power_dark_mult": 1.15, "power_holy_mult": 1.15, "power_earth_mult": 1.15, "power_arcane_mult": 1.15}},
		{"id": "convergencia", "name": "Convergencia", "description": "Penetracao +10% e dano magico +10%.", "mods": {"penetration_add": 0.1, "power_magic_mult": 1.1}},
	],
}
const NOTABLE_STEP := 10


## EXP para passar do nível Paragon `level` ao seguinte.
static func required(level: int) -> int:
	return 1500 + 150 * level


static func empty() -> Dictionary:
	return {"level": 0, "experience": 0, "boards": {}}


## Dados vindos de disco ou de um cliente: limites, tipos e tabuleiros que cabem nos pontos.
static func sanitize(raw: Variant) -> Dictionary:
	var result := empty()
	if not raw is Dictionary:
		return result
	var data := raw as Dictionary
	result["level"] = clampi(int(data.get("level", 0)), 0, MAX_LEVEL)
	result["experience"] = clampi(int(data.get("experience", 0)), 0, required(int(result["level"])) - 1) if int(result["level"]) < MAX_LEVEL else 0
	var boards := {}
	if data.get("boards", {}) is Dictionary:
		for character: Variant in data["boards"]:
			if String(character).length() <= 32 and data["boards"][character] is Dictionary:
				boards[String(character)] = sanitize_board(data["boards"][character], int(result["level"]))
	result["boards"] = boards
	return result


static func sanitize_board(raw: Variant, level: int) -> Dictionary:
	var board := {}
	var left := level
	for track in TRACKS:
		var points := clampi(int((raw as Dictionary).get(track, 0)) if raw is Dictionary else 0, 0, left)
		board[track] = points
		left -= points
	return board


static func spent(board: Dictionary) -> int:
	var total := 0
	for track in TRACKS:
		total += int(board.get(track, 0))
	return total


## Soma EXP; devolve quantos níveis subiu.
static func gain(data: Dictionary, amount: int) -> int:
	var levels := 0
	if amount <= 0:
		return levels
	data["experience"] = int(data.get("experience", 0)) + amount
	while int(data["level"]) < MAX_LEVEL and int(data["experience"]) >= required(int(data["level"])):
		data["experience"] = int(data["experience"]) - required(int(data["level"]))
		data["level"] = int(data["level"]) + 1
		levels += 1
	if int(data["level"]) >= MAX_LEVEL:
		data["experience"] = 0
	return levels


## Tabuleiro em texto curto ("12,5,0,3") para a rede, na ordem de TRACKS.
static func board_text(board: Dictionary) -> String:
	return ",".join(PackedStringArray(TRACKS.map(func(track: String) -> String: return str(int(board.get(track, 0))))))


static func parse_board(text: String) -> Dictionary:
	var parts := text.split(",")
	var board := {}
	for index in range(TRACKS.size()):
		board[TRACKS[index]] = int(parts[index]) if index < parts.size() and parts[index].is_valid_int() else 0
	return board


## Passivas do tabuleiro: bônus por ponto de cada trilha e os nós notáveis abertos.
static func passives(board: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for track in TRACKS:
		var points := int(board.get(track, 0))
		if points <= 0:
			continue
		var mods := {}
		var per_point := PER_POINT[track] as Dictionary
		for key: String in per_point:
			mods[key] = 1.0 + float(per_point[key]) * points if key.ends_with("_mult") else float(per_point[key]) * points
		result.append({"name": "Paragon %s" % TRACK_NAMES[track], "mods": mods, "item_id": "paragon_" + track})
		for notable: Dictionary in unlocked_notables(track, points):
			var entry := notable.duplicate(true)
			entry["item_id"] = "paragon_" + String(notable["id"])
			result.append(entry)
	return result


static func unlocked_notables(track: String, points: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var list := NOTABLES.get(track, []) as Array
	for index in range(mini(list.size(), points / NOTABLE_STEP)):
		result.append(list[index])
	return result
