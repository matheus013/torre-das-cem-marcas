extends RefCounted

const CATALOG_PATH := "res://data/narrative/first_route.json"
const OPENING_PATH := "res://data/narrative/village_opening.json"
const STAGES := ["available", "active", "evidence_found", "report_ready", "completed"]
var stage := "available"
var return_outcome := ""
var opening_known := false
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
	return {"quest_id": _catalog["id"], "stage": stage, "return_outcome": return_outcome, "opening_known": opening_known}

static func valid(raw: Variant) -> bool:
	if not raw is Dictionary:
		return false
	if raw.is_empty():
		return true
	if raw.has("opening_known") and not raw["opening_known"] is bool:
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

func view() -> Dictionary:
	var model: Dictionary = (_catalog["stages"][stage] as Dictionary).duplicate(true)
	model.merge({"id": _catalog["id"], "npc_id": _catalog["npc_id"], "title": _catalog["title"], "stage": stage, "reward": _catalog["reward"].duplicate(true)})
	model["npc_name"] = "Nara Quiral"
	model["contract_objective"] = model["objective"]
	model["opening_known"] = opening_known
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
