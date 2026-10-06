"""Gera uma arma única lendária por gema ativa em data/beta/beta_content.json.

Cada arma fortalece muito a sua gema quando equipada: potência principal +50%,
recarga -25% e uma assinatura da mecânica. Só as linhas `unica_*` de `items` são
reescritas; o resto do catálogo fica intacto. Idempotente.
Uso: python3 tools/content/build_unique_weapons.py [--check]
"""

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / "data/beta/beta_content.json"
WEAPONS = ROOT / "data/combat/weapon_profiles.json"
PREFIX = "unica_"

NAMES = {
    "agulha_lastro": "Fio do Primeiro Lastro",
    "passo_vetorial": "Vetor Sem Sombra",
    "pulso_cicatriz": "Batimento da Cicatriz",
    "prisao_gravitica": "Ancora do Peso Cativo",
    "muralha_refeita": "Pedra que se Refaz",
    "elo_residual": "Corrente Remanescente",
    "molde_vigilante": "Matriz do Vigia",
    "semeadura_vital": "Cajado da Primeira Colheita",
    "estilhacos_lunares": "Leque da Lua Partida",
    "lanca_ferral": "Presa de Ferral",
    "orbe_de_ruptura": "Coracao da Ruptura",
    "corte_vetorial": "Gume do Vetor",
    "salto_de_guarda": "Asa da Retirada",
    "anel_de_geada": "Halo da Geada Eterna",
    "ruptura_sismica": "Punho do Abalo",
    "brasa_persistente": "Tocha que Nao Apaga",
    "pantano_acido": "Raiz do Brejo Acre",
    "casca_reativa": "Carapaca Vingativa",
    "arco_voltaico": "Bobina do Arco",
    "dreno_em_rede": "Teia Sedenta",
    "sentinela_ferral": "Olho da Sentinela",
    "enxame_luminar": "Colmeia de Luz",
    "guardiao_de_lastro": "Juramento do Guardiao",
    "circulo_de_reparo": "Selo do Reparo",
    "abrigo_de_escora": "Viga do Abrigo",
    "ceifa_ampla": "Foice da Grande Ceifa",
    "sopro_criogenico": "Pulmao de Gelo",
    "raio_prismatico": "Prisma Absoluto",
    "fio_desintegrador": "Lamina Desfiada",
    "laminas_orbitais": "Eixo das Tres Laminas",
    "satelites_de_geada": "Orbita Invernal",
    "mina_de_lastro": "Detonador de Lastro",
    "semente_explosiva": "Semente do Estrondo",
    "chuva_ferral": "Ceu de Ferral",
    "cometa_de_vidro": "Cauda do Cometa",
    "disco_de_retorno": "Disco Sem Fim",
    "bola_de_fogo": "Brasa do Primeiro Lume",
    "bolha_corrosiva": "Fel da Bolha Acre",
    "cometa_sombrio": "Rastro da Noite Funda",
    "raizes_presas": "Enxerto das Raizes",
    "pilar_sagrado": "Coluna da Alvorada",
    "esfera_de_gelo": "Nucleo do Inverno",
    "trovao_descendente": "Voz do Trovao",
    "saraivada_de_flechas": "Arco das Tres Tempestades",
}

# Assinatura por mecânica, somada ao bônus universal. Usa a convenção dos suportes:
# `campo_multiplier` multiplica, `campo_add` soma.
SIGNATURES = {
    "projectile": ({"projectile_count_add": 1, "pierce_add": 2}, "+1 projetil e +2 perfuracoes"),
    "boomerang": ({"projectile_count_add": 1, "pierce_add": 2}, "+1 disco e +2 perfuracoes"),
    "dash": ({"distance_multiplier": 1.3}, "distancia +30%"),
    "nova": ({"radius_multiplier": 1.3}, "raio +30%"),
    "field": ({"radius_multiplier": 1.25, "duration_multiplier": 1.3}, "raio +25% e duracao +30%"),
    "barrier": ({"duration_multiplier": 1.3}, "duracao +30%"),
    "chain": ({"chain_count_add": 3}, "+3 saltos"),
    "summon": ({"summon_count_add": 1, "duration_multiplier": 1.3}, "+1 invocacao e duracao +30%"),
    "sanctuary": ({"radius_multiplier": 1.25, "duration_multiplier": 1.3}, "raio +25% e duracao +30%"),
    "cone": ({"angle_multiplier": 1.3, "radius_multiplier": 1.2}, "abertura +30% e alcance do corte +20%"),
    "beam": ({"width_multiplier": 1.4}, "largura +40%"),
    "orbit": ({"orbit_count_add": 1}, "+1 lamina orbital"),
    "mine": ({"radius_multiplier": 1.3}, "explosao +30%"),
    "meteor": ({"meteor_count_add": 2}, "+2 impactos"),
    "volley": ({"arrow_count_add": 12, "breath_on_kill_add": 2}, "+12 flechas por rajada e +2 de Folego por abate"),
}
POWER_MULTIPLIER = 1.5
COOLDOWN_MULTIPLIER = 0.75
WEAPON_POWER = 24


def primary_field(gem):
    mechanic = gem["mechanic"]
    if mechanic == "barrier":
        return "barrier", "barreira"
    if mechanic == "sanctuary":
        return "healing", "cura"
    if mechanic == "dash" and gem.get("trail_damage", 0) <= 0:
        return "arrival_barrier", "barreira de chegada"
    if mechanic == "dash":
        return "trail_damage", "dano do rastro"
    return "power", "potencia"


def weapon_type(gem, profiles):
    """Tipo cuja escala de ataque mais aproveita os atributos da gema."""
    best, best_score = "focus", -1.0
    for type_id in ("focus", "spear", "gauntlets", "staff"):
        scaling = profiles[type_id].get("scaling", {})
        score = sum(scaling.get(stat, 0.0) * weight for stat, weight in zip(gem.get("scaling", []), (1.0, 0.6)))
        if score > best_score:
            best, best_score = type_id, score
    return best


def unique_for(gem, profiles):
    field, field_label = primary_field(gem)
    signature, signature_text = SIGNATURES[gem["mechanic"]]
    modifiers = {field + "_multiplier": POWER_MULTIPLIER, "cooldown_multiplier": COOLDOWN_MULTIPLIER, **signature}
    return {
        "id": PREFIX + gem["id"],
        "name": NAMES[gem["id"]],
        "item_type": "weapon",
        "weapon_type": weapon_type(gem, profiles),
        "slot": "weapon",
        "tier": "legendary",
        "power": WEAPON_POWER,
        "unique_gem": gem["id"],
        "gem_modifiers": modifiers,
        "description": "Arma unica de %s: %s +%d%%, recarga -%d%%, %s." % (
            gem["name"], field_label, round((POWER_MULTIPLIER - 1) * 100), round((1 - COOLDOWN_MULTIPLIER) * 100), signature_text),
    }


def render(text, uniques):
    lines = text.split("\n")
    start = lines.index('  "items": [')
    end = next(i for i in range(start + 1, len(lines)) if lines[i].startswith("  ]"))
    body = [line.rstrip(",") for line in lines[start + 1:end] if f'"id":"{PREFIX}' not in line]
    body += ["    " + json.dumps(item, ensure_ascii=False, separators=(",", ":")) for item in uniques]
    body = [line + "," for line in body[:-1]] + body[-1:]
    return "\n".join(lines[:start + 1] + body + lines[end:])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="falha se o catalogo estiver desatualizado")
    args = parser.parse_args()
    text = CONTENT.read_text()
    content = json.loads(text)
    profiles = json.loads(WEAPONS.read_text())["types"]
    gems = content["active_gems"]
    missing = [gem["id"] for gem in gems if gem["id"] not in NAMES or gem["mechanic"] not in SIGNATURES]
    if missing:
        sys.exit("Gemas sem nome ou assinatura de arma unica: " + ", ".join(missing))
    updated = render(text, [unique_for(gem, profiles) for gem in gems])
    json.loads(updated)
    if args.check:
        if updated != text:
            sys.exit("beta_content.json desatualizado: rode tools/content/build_unique_weapons.py")
        print("UNIQUE_WEAPONS_OK")
        return
    CONTENT.write_text(updated)
    print("UNIQUE_WEAPONS_WRITTEN: %d" % len(gems))


if __name__ == "__main__":
    main()
