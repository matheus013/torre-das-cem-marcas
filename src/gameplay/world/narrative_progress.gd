extends RefCounted

const CATALOG_PATH := "res://data/narrative/first_route.json"
const OPENING_PATH := "res://data/narrative/village_opening.json"
const STAGES := ["available", "active", "evidence_found", "report_ready", "completed"]
var stage := "available"
var return_outcome := ""
var opening_known := false
var rescue_state := "waiting"
var rescue_progress := 0.0
var route_choice := ""
var fissure_found := false
var cicatrization_state := "unseen"
var cicatrization_remaining := 0.0
var _catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH)) as Dictionary
var _opening: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OPENING_PATH)) as Dictionary

func acknowledge_crisis() -> bool:
	if opening_known:
		return false
	opening_known = true
	return true

func catalog() -> Dictionary:
	return _catalog.duplicate(true)

func accept() -> bool:
	if stage != "available":
		return false
	stage = "active"
	return true

func inspect() -> bool:
	if stage != "active":
		return false
	stage = "evidence_found"
	return true

# The observation belongs to the party; a confirmed field return delivers it.
func record_return(outcome: String) -> void:
	if stage == "evidence_found" and outcome in ["retreat", "defeat"]:
		stage = "report_ready"
		return_outcome = outcome

func report() -> bool:
	if stage != "report_ready":
		return false
	stage = "completed"
	return true

func snapshot() -> Dictionary:
	return {"quest_id": _catalog["id"], "stage": stage, "return_outcome": return_outcome, "opening_known": opening_known, "rescue_state": rescue_state, "rescue_progress": rescue_progress, "route_choice": route_choice, "fissure_found": fissure_found, "cicatrization_state": cicatrization_state, "cicatrization_remaining": cicatrization_remaining}

static func valid(raw: Variant) -> bool:
	if not raw is Dictionary:
		return false
	if raw.is_empty():
		return true
	if raw.has("opening_known") and not raw["opening_known"] is bool:
		return false
	if raw.has("cicatrization_state") or raw.has("cicatrization_remaining"):
		if raw.get("cicatrization_state") not in ["unseen", "warning", "closed"]:
			return false
		var remaining: Variant = raw.get("cicatrization_remaining")
		if not (remaining is float or remaining is int) or not is_finite(float(remaining)) or float(remaining) < 0 or float(remaining) > 5:
			return false
		if raw["cicatrization_state"] != "warning" and float(remaining) != 0:
			return false
		if raw.get("stage") == "available" and raw["cicatrization_state"] != "unseen":
			return false
	if raw.has("route_choice") or raw.has("fissure_found"):
		if raw.get("route_choice") not in ["", "safe", "fissure"] or not raw.get("fissure_found") is bool:
			return false
		if raw["fissure_found"] and raw["route_choice"] != "fissure" or raw.get("stage") == "available" and raw["route_choice"] != "":
			return false
	if raw.has("rescue_state") or raw.has("rescue_progress"):
		if raw.get("rescue_state") not in ["waiting", "escorting", "rescued"]:
			return false
		var progress: Variant = raw.get("rescue_progress")
		if not (progress is float or progress is int) or not is_finite(float(progress)) or float(progress) < 0 or float(progress) > 1:
			return false
		if raw["rescue_state"] == "waiting" and float(progress) != 0 or raw["rescue_state"] == "rescued" and float(progress) != 1:
			return false
		if raw["rescue_state"] == "escorting" and float(progress) >= 1:
			return false
		if raw.get("stage") == "available" and raw["rescue_state"] != "waiting":
			return false
	if raw.get("quest_id") != "registro_da_primeira_rota" or not raw.get("stage") is String or raw["stage"] not in STAGES:
		return false
	if not raw.get("return_outcome") is String or raw["return_outcome"] not in ["", "retreat", "defeat"]:
		return false
	return (not String(raw["return_outcome"]).is_empty()) == (raw["stage"] in ["report_ready", "completed"])

func restore(raw: Dictionary) -> void:
	stage = String(raw.get("stage", "available"))
	return_outcome = String(raw.get("return_outcome", ""))
	opening_known = bool(raw.get("opening_known", false))
	rescue_state = String(raw.get("rescue_state", "waiting"))
	rescue_progress = float(raw.get("rescue_progress", 0.0))
	route_choice = String(raw.get("route_choice", ""))
	fissure_found = bool(raw.get("fissure_found", false))
	cicatrization_state = String(raw.get("cicatrization_state", "unseen"))
	cicatrization_remaining = float(raw.get("cicatrization_remaining", 0.0))

func view() -> Dictionary:
	var model: Dictionary = (_catalog["stages"][stage] as Dictionary).duplicate(true)
	model.merge({"id": _catalog["id"], "npc_id": _catalog["npc_id"], "title": _catalog["title"], "stage": stage, "reward": _catalog["reward"].duplicate(true)})
	model["npc_name"] = "Nara Quiral"
	model["contract_objective"] = model["objective"]
	model["opening_known"] = opening_known
	model["rescue_state"] = rescue_state
	model["route_choice"] = route_choice
	model["fissure_found"] = fissure_found
	model["cicatrization_state"] = cicatrization_state
	model["cicatrization_remaining"] = cicatrization_remaining
	if stage == "available" and not opening_known:
		model["objective"] = _opening["objective"]
	model["target_npc"] = (String(_opening["npc_id"]) if not opening_known else String(_catalog["npc_id"])) if stage == "available" else (String(_catalog["npc_id"]) if stage == "report_ready" else "")
	model["preparation_text"] = String(_opening["preparation"]) + "\n\n" + String(_opening["risk"])
	model["reactions"] = _opening["reactions"].duplicate(true)
	if stage == "active":
		model["secondary_action"] = "prepare_first_floor"
		model["secondary_action_label"] = "Escolher andar 1 para a proxima entrada"
	var journal: Array[String] = []
	if opening_known:
		journal.append(String(_opening["journal"]))
	if stage in ["evidence_found", "report_ready", "completed"]:
		journal.append(String(_catalog["evidence_text"]))
	if not return_outcome.is_empty():
		journal.append("Retorno apos derrota: a observacao foi preservada." if return_outcome == "defeat" else "Retorno de campo confirmado.")
	if stage == "completed":
		journal.append("Relato entregue. Um Musgo de Orientacao foi armazenado nas reservas de expedicao.")
	model["journal"] = journal
	var route: Dictionary = _catalog["route_choice"]
	if route_choice == "safe":
		journal.append(String(route["safe_journal"]))
	elif route_choice == "fissure":
		journal.append(String(route["exploring_journal"]))
	if fissure_found:
		journal.append(String(route["evidence"]))
		model["dialogue"] += "\n\n" + String(route["reaction"])
	var cicatrization: Dictionary = _catalog["cicatrization"]
	if cicatrization_state == "warning":
		journal.append(String(cicatrization["warning_journal"]))
	elif cicatrization_state == "closed":
		journal.append(String(cicatrization["evidence"]))
		model["dialogue"] += "\n\n" + String(cicatrization["reaction"])
	if rescue_state == "escorting":
		journal.append("Um trabalhador pediu ajuda no Patio das Marcas. Acompanhe sua retirada ate o portal; ele espera sem companhia ou com inimigos por perto.")
	elif rescue_state == "rescued":
		journal.append("O trabalhador alcancou o portal pela rota registrada. O resgate foi confirmado; o relato nao esclarece a origem da renovacao.")
		model["dialogue"] += "\n\nO trabalhador chegou ao portal. Obrigada por acompanhar a retirada; vou registrar que o trecho ainda permite passagem."
	var conversations: Dictionary = (_opening["conversations"] as Dictionary).duplicate(true)
	for npc_id: String in conversations:
		var dialogue: Dictionary = conversations[npc_id]
		dialogue["npc_id"] = npc_id
		if npc_id == String(_opening["npc_id"]) and opening_known:
			dialogue["dialogue"] = dialogue["summary"]
			dialogue.erase("action")
			dialogue.erase("action_label")
	model["conversations"] = conversations
	return model
