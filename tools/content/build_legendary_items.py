"""Gera os itens lendarios genericos (`lendario_*`) e a passiva do Lastro Partido em
data/beta/beta_content.json, a partir de tools/content/legendary_passives.py (decisao 580).

So essas linhas de `items` sao reescritas; o resto do catalogo fica intacto. Idempotente.
Uso: python3 tools/content/build_legendary_items.py [--check]
"""

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from legendary_passives import LASTRO_PARTIDO, legendary_items, unique_passives  # noqa: E402
from build_unique_weapons import NAMES  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / "data/beta/beta_content.json"
PREFIX = "lendario_"
LASTRO = "reliquia_lastro_partido"
DOC = ROOT / "docs/itens-lendarios.md"
SLOTS = {"amulet": "Amuleto", "armor": "Armadura", "gloves": "Luvas", "boots": "Botas", "pants": "Calca",
         "ring": "Anel", "offhand": "Mao secundaria", "relic": "Reliquia"}


def write_doc(content, items):
    gems = {gem["id"]: gem for gem in content["active_gems"]}
    passives = unique_passives()
    out = ["# Itens lendarios e armas unicas", "",
           "Gerado por `tools/content/build_legendary_items.py` a partir de `tools/content/legendary_passives.py`",
           "(decisao 580). Toda peca lendaria tem uma passiva exclusiva, executada por",
           "`src/gameplay/items/item_passives.gd`. Meta: uma unica peca basta para levar a personagem ate o fim",
           "da historia; as dificuldades do pos-jogo (backlog G6) vao exigi-las. Valores provisorios para playtest.", "",
           "## Lendarios genericos", "", "| Item | Encaixe | Passiva |", "|---|---|---|"]
    lastro = next(item for item in content["items"] if item["id"] == LASTRO)
    for item in items + [dict(lastro, passive=LASTRO_PARTIDO)]:
        passive = item["passive"]
        out.append("| %s | %s | **%s**: %s |" % (item["name"], SLOTS.get(item["slot"], item["slot"]), passive["name"], passive["description"]))
    out += ["", "## Armas unicas (uma por gema)", "",
            "Alem da passiva, cada arma da +50% a potencia principal da gema, -25% de recarga e uma assinatura da mecanica.", "",
            "| Arma | Gema | Passiva |", "|---|---|---|"]
    for gem_id, passive in passives.items():
        out.append("| %s | %s | **%s**: %s |" % (NAMES[gem_id], gems[gem_id]["name"], passive["name"], passive["description"]))
    return "\n".join(out) + "\n"


def render(text, items):
    lines = text.split("\n")
    start = lines.index('  "items": [')
    end = next(i for i in range(start + 1, len(lines)) if lines[i].startswith("  ]"))
    body = []
    for line in lines[start + 1:end]:
        line = line.rstrip(",")
        if f'"id":"{PREFIX}' in line:
            continue
        if f'"id":"{LASTRO}"' in line:
            lastro = json.loads(line)
            lastro.pop("mechanics", None)
            lastro["passive"] = LASTRO_PARTIDO
            line = "    " + json.dumps(lastro, ensure_ascii=False, separators=(",", ":"))
        body.append(line)
    # Antes das armas unicas (que build_unique_weapons.py poe no fim): os dois geradores ficam estaveis.
    rendered = ["    " + json.dumps(item, ensure_ascii=False, separators=(",", ":")) for item in items]
    first_unique = next((i for i, line in enumerate(body) if '"id":"unica_' in line), len(body))
    body = body[:first_unique] + rendered + body[first_unique:]
    body = [line + "," for line in body[:-1]] + body[-1:]
    return "\n".join(lines[:start + 1] + body + lines[end:])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="falha se o catalogo estiver desatualizado")
    args = parser.parse_args()
    text = CONTENT.read_text()
    items = legendary_items()
    updated = render(text, items)
    doc = write_doc(json.loads(updated), items)
    if args.check:
        if updated != text or not DOC.exists() or DOC.read_text() != doc:
            sys.exit("beta_content.json desatualizado: rode tools/content/build_legendary_items.py")
        print("LEGENDARY_ITEMS_OK")
        return
    CONTENT.write_text(updated)
    DOC.write_text(doc)
    print("LEGENDARY_ITEMS_WRITTEN: %d" % len(items))


if __name__ == "__main__":
    main()
