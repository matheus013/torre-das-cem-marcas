extends RefCounted

const OFFERS := {
	"cassio_rotavela": [{"id": "comprar_suprimento", "name": "Comprar suprimento", "description": "Adiciona 1 suprimento de cura para a expedicao.", "price": 18, "materials": {}, "effect": "supply", "quantity": 1}],
	"maura_salvedra": [{"id": "tratamento", "name": "Receber tratamento", "description": "Restaura Vida e folego e remove ferimentos.", "price": 0, "materials": {}, "effect": "heal"}],
	"sira_botanica": [{"id": "preparar_remedios", "name": "Preparar remedios", "description": "Prepara 3 suprimentos de cura com as reservas comunitarias.", "price": 12, "materials": {"alimentos": 6, "madeira": 2}, "effect": "supply", "quantity": 3}],
	"dalia_ferral": [{"id": "reparar_equipamento", "name": "Reparar equipamento", "description": "Restaura a integridade de todas as pecas equipadas e do inventario.", "price": 30, "materials": {"minerio": 4}, "effect": "repair"}],
	"lior_campelo": [{"id": "retirar_racao", "name": "Preparar racao de viagem", "description": "Converte 3 alimentos do armazem em 1 suprimento de cura.", "price": 0, "materials": {"alimentos": 3}, "effect": "supply", "quantity": 1}],
}

static func offers(npc_id: String) -> Array:
	return (OFFERS.get(npc_id, []) as Array).duplicate(true)

static func offer(npc_id: String, offer_id: String) -> Dictionary:
	for entry: Dictionary in offers(npc_id):
		if String(entry["id"]) == offer_id:
			return entry
	return {}
