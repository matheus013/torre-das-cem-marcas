"""Gera os itens divinos (`divino_*`) em data/beta/beta_content.json (epico E1, fase 5; G8.9;
documento 76, secao 6; decisoes 600 e 608).

Raridade acima de lendario, so da dificuldade 4 em diante. Na criacao da peca (simulacao) os
atributos-base saem Magistrais, com 1 afixo fixo do encaixe e 7 aleatorios, todos no maximo. Aqui
ficam nome, encaixe, atributos-base e 1 ou 2 linhas de passiva divina, cada uma quebrando uma regra.
Ficam antes dos lendarios no catalogo, para os geradores de lendarios e de unicas seguirem estaveis.
Uso: python3 tools/content/build_divine_items.py [--check]
"""

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / "data/beta/beta_content.json"
PREFIX = "divino_"


def divine(item_id, name, slot, item_type, stats, description, passives, style, **extra):
    item = {"id": PREFIX + item_id, "name": name, "item_type": item_type, "slot": slot, "tier": "divine", "power": 70,
            "stats": stats, "description": description, "style": style, "passives": passives}
    item.update(extra)
    return item


DIVINES = [
    divine("coroa_sem_fim", "Coroa Sem Fim", "amulet", "accessory", {"intelligence": 16, "wisdom": 14, "cooldown_recovery": 6},
           "Coroa sem emenda, que nunca para de girar.", [
               {"name": "Sem Fim", "description": "Gemas nao tem recarga.", "mods": {"no_cooldown": 1}},
               {"name": "Tributo", "description": "Cada lancamento custa 5% da Vida maxima.", "mods": {"cast_health_ratio": 0.05}},
           ], "conjuradores"),
    divine("lanca_das_nove_mares", "Lanca das Nove Mares", "weapon", "weapon", {"strength": 14, "intelligence": 14, "critical_chance": 4},
           "Lanca que muda de cor a cada golpe. Assume a forma da arma de quem a empunha.", [
               {"name": "Nove Mares", "description": "Cada acerto alterna entre os nove elementos e quebra 10% da resistencia do alvo a esse elemento por 4 s.", "mods": {"element_cycle": 1}},
           ], "elementos", weapon_type="spear", adaptive_shape=True),
    divine("manto_da_peste_eterna", "Manto da Peste Eterna", "armor", "armor", {"health": 70, "vitality": 12, "intelligence": 10},
           "Manto tecido com fios de esporo que nunca secam.", [
               {"name": "Peste Eterna", "description": "Venenos nunca expiram enquanto o alvo vive.", "mods": {"poison_eternal": 1}},
               {"name": "Contagio", "description": "Todo acerto de gema envenena: 25% do golpe ao longo de 4 s.",
                "triggers": [{"on": "hit", "source": "gem", "actions": [{"do": "poison", "ratio": 0.25, "duration": 4.0}]}]},
           ], "veneno"),
    divine("cetro_da_legiao", "Cetro da Legiao", "relic", "relic", {"wisdom": 16, "intelligence": 12, "health": 40},
           "Cetro que guarda o nome de cada criatura que chamou.", [
               {"name": "Legiao", "description": "Invocacoes nao expiram.", "mods": {"summon_duration_mult": 99.0}},
               {"name": "Exercito", "description": "O limite de invocacoes de cada gema dobra.", "mods": {"summon_limit_mult": 2.0}},
           ], "invocacao"),
    divine("punho_da_primeira_lei", "Punho da Primeira Lei", "gloves", "armor", {"strength": 14, "agility": 14, "attack_speed": 10},
           "Manoplas que nao conhecem a palavra alvo.", [
               {"name": "Primeira Lei", "description": "O autoataque acerta todos os inimigos ao alcance da arma.", "mods": {"auto_hits_all": 1}},
           ], "autoataque"),
    divine("egide_imovel", "Egide Imovel", "offhand", "offhand", {"defense": 30, "health": 60, "vitality": 12},
           "Escudo que ninguem viu recuar.", [
               {"name": "Imovel", "description": "Nenhum golpe tira mais de 10% da Vida maxima.", "mods": {"damage_cap_ratio": 0.1}},
               {"name": "Muralha Eterna", "description": "Barreiras nao expiram com o tempo.", "mods": {"barrier_permanent": 1}},
           ], "defesa"),
    divine("filamento_do_circuito_eterno", "Filamento do Circuito Eterno", "ring", "accessory", {"intelligence": 14, "wisdom": 10, "breath": 20},
           "Anel de Eloa: um fio que nunca termina.", [
               {"name": "Circuito Eterno", "description": "Elo Residual salta 6 vezes a mais com +30% de potencia.",
                "gem_transforms": {"elo_residual": {"modifiers": {"chain_count_add": 6, "power_multiplier": 1.3}}}},
               {"name": "Corrente de Retorno", "description": "Cada acerto do Elo Residual devolve 2 de Folego.",
                "triggers": [{"on": "hit", "gem": "elo_residual", "actions": [{"do": "breath", "amount": 2}]}]},
           ], "eloa"),
    divine("agulha_do_horizonte", "Agulha do Horizonte", "ring", "accessory", {"agility": 16, "strength": 8, "critical_chance": 5},
           "Anel de Sena: a mira alcanca a linha do horizonte.", [
               {"name": "Horizonte", "description": "A Agulha de Lastro atravessa tudo, dispara +2 projeteis e volta a mao.",
                "gem_transforms": {"agulha_lastro": {"modifiers": {"projectile_count_add": 2}, "transform": {"pierce": 99, "return_projectile": True}}}},
           ], "sena"),
    divine("coracao_da_cicatriz_viva", "Coracao da Cicatriz Viva", "pants", "armor", {"vitality": 16, "strength": 10, "health": 50},
           "Calca de Cira, costurada sobre uma cicatriz que ainda pulsa.", [
               {"name": "Cicatriz Viva", "description": "O Pulso Cicatriz recarrega 4 vezes mais rapido.",
                "gem_transforms": {"pulso_cicatriz": {"modifiers": {"cooldown_multiplier": 0.25}}}},
               {"name": "Pulso que Cura", "description": "Cada Pulso Cicatriz cura 3% da Vida maxima.",
                "triggers": [{"on": "cast", "gem": "pulso_cicatriz", "actions": [{"do": "heal", "ratio": 0.03}]}]},
           ], "cira"),
    divine("botas_da_obra_infinita", "Botas da Obra Infinita", "boots", "armor", {"wisdom": 14, "strength": 10, "movement_speed": 8},
           "Botas de Rui: cada passo marca onde a obra continua.", [
               {"name": "Obra Infinita", "description": "Mina de Lastro mantem ate 12 minas, que perseguem os inimigos.",
                "gem_transforms": {"mina_de_lastro": {"transform": {"deploy_limit": 12, "seek_speed": 260}}}},
           ], "rui"),
    divine("lanterna_do_fim_do_mundo", "Lanterna do Fim do Mundo", "relic", "relic", {"wisdom": 14, "vitality": 10, "breath": 25},
           "Lanterna que ainda brilha onde a Torre termina.", [
               {"name": "Ultima Luz", "description": "O raio de luz da personagem dobra.", "mods": {"light_radius_mult": 2.0}},
               {"name": "Luz que Fere", "description": "No escuro, inimigos na sua luz recebem +30% de dano.", "mods": {"lit_damage_bonus": 0.3}},
           ], "noite"),
    divine("anel_do_tempo_partido", "Anel do Tempo Partido", "ring", "accessory", {"agility": 12, "wisdom": 12, "cooldown_recovery": 6},
           "Anel rachado no meio de um segundo.", [
               {"name": "Tempo Partido", "description": "Cada abate zera todas as recargas (no maximo uma vez por segundo).",
                "triggers": [{"on": "kill", "cooldown": 1.0, "actions": [{"do": "refund", "scope": "all", "seconds": 99}]}]},
           ], "recarga"),
]


def render(text, items):
    lines = text.split("\n")
    start = lines.index('  "items": [')
    end = next(i for i in range(start + 1, len(lines)) if lines[i].startswith("  ]"))
    body = [line.rstrip(",") for line in lines[start + 1:end] if f'"id":"{PREFIX}' not in line]
    rendered = ["    " + json.dumps(item, ensure_ascii=False, separators=(",", ":")) for item in items]
    first = next((i for i, line in enumerate(body) if '"id":"lendario_' in line or '"id":"unica_' in line), len(body))
    body = body[:first] + rendered + body[first:]
    body = [line + "," for line in body[:-1]] + body[-1:]
    return "\n".join(lines[:start + 1] + body + lines[end:])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="falha se o catalogo estiver desatualizado")
    args = parser.parse_args()
    text = CONTENT.read_text()
    updated = render(text, DIVINES)
    json.loads(updated)
    if args.check:
        if updated != text:
            sys.exit("beta_content.json desatualizado: rode tools/content/build_divine_items.py")
        print("DIVINE_ITEMS_OK")
        return
    CONTENT.write_text(updated)
    print("DIVINE_ITEMS_WRITTEN: %d" % len(DIVINES))


if __name__ == "__main__":
    main()
