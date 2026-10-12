"""Gera os Selos da Cicatriz (`selo_*`) em data/beta/beta_content.json (balanceamento, decisao 610).

O Selo ocupa um encaixe proprio e e a principal fonte de poder das dificuldades 2 a 5: cada selo so
cai na dificuldade dele (chefes de andar; o primeiro chefe vencido garante um para quem ainda nao tem)
e multiplica todo o dano da personagem e a Vida maxima, alem de reduzir o dano recebido. A Forja
lapida o selo ate +5 (+10% de dano e +5% de Vida por nivel). Valores calibrados pela sonda de builds.

Ficam antes dos divinos no catalogo, para os outros geradores seguirem estaveis.
Uso: python3 tools/content/build_seals.py [--check]
"""

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / "data/beta/beta_content.json"
PREFIX = "selo_"

# (id, nome, dificuldade, dano, Vida, dano recebido, descricao)
SEALS = [
    ("veterano", "Selo Veterano", 2, 14.0, 1.3, 0.95, "Primeira marca de quem venceu a Torre inteira."),
    ("mestre", "Selo Mestre", 3, 230.0, 1.6, 0.9, "Marca gravada a fogo pelos guardioes da dificuldade Mestra."),
    ("mitico", "Selo Mitico", 4, 300.0, 2.5, 0.85, "Pedra viva que pulsa no ritmo dos guardioes ascendidos."),
    ("da_cicatriz", "Selo da Cicatriz", 5, 2600.0, 4.0, 0.8, "O ultimo selo: a propria Cicatriz, presa a quem a enfrentou."),
]


def seal(key, name, difficulty, damage, health, taken, flavor):
    description = "Todo o seu dano x%s e Vida maxima x%s; dano recebido -%d%%. Cai so na dificuldade %d." % (
        ("%g" % damage).replace(".", ","), ("%g" % health).replace(".", ","), round((1 - taken) * 100), difficulty)
    return {"id": PREFIX + key, "name": name, "item_type": "seal", "slot": "seal", "tier": "legendary", "power": 0,
            "difficulty": difficulty, "seal": {"damage": damage, "health": health, "taken": taken},
            "description": flavor,
            "passive": {"name": name, "description": description,
                        "mods": {"all_damage_mult": damage, "max_health_mult": health, "damage_taken_mult": taken}}}


def render(text, items):
    lines = text.split("\n")
    start = lines.index('  "items": [')
    end = next(i for i in range(start + 1, len(lines)) if lines[i].startswith("  ]"))
    body = [line.rstrip(",") for line in lines[start + 1:end] if f'"id":"{PREFIX}' not in line]
    rendered = ["    " + json.dumps(item, ensure_ascii=False, separators=(",", ":")) for item in items]
    first = next((i for i, line in enumerate(body) if '"id":"divino_' in line or '"id":"lendario_' in line or '"id":"unica_' in line), len(body))
    body = body[:first] + rendered + body[first:]
    body = [line + "," for line in body[:-1]] + body[-1:]
    return "\n".join(lines[:start + 1] + body + lines[end:])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="falha se o catalogo estiver desatualizado")
    args = parser.parse_args()
    text = CONTENT.read_text()
    updated = render(text, [seal(*entry) for entry in SEALS])
    json.loads(updated)
    if args.check:
        if updated != text:
            sys.exit("beta_content.json desatualizado: rode tools/content/build_seals.py")
        print("SEALS_OK")
        return
    CONTENT.write_text(updated)
    print("SEALS_WRITTEN: %d" % len(SEALS))


if __name__ == "__main__":
    main()
