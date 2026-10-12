"""Calcula fatores de potencia por gema a partir da sonda de builds (decisao 610) e atualiza
data/combat/gem_balance.json.

Para cada gema de dano (marcador `damage`), o poder do melhor set e a media geometrica do dano no
chefe e na matilha, nas dificuldades 2 e 5. Gemas fora da faixa [mediana / BAND, mediana x BAND]
sao trazidas para a borda da faixa; o fator novo multiplica o anterior. Gemas de utilidade (sem
`damage`) nao entram: a build delas vive do autoataque.

Uso: python3 tools/bench/balance_factors.py parte1.json parte2.json ... [--band=2] [--dry]
"""

import json
import math
import statistics
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTENT = json.loads((ROOT / "data/beta/beta_content.json").read_text())
BALANCE = ROOT / "data/combat/gem_balance.json"
REFERENCE_HEALTH = 1.0e7
PACK = 6


def effective(power, kind):
    targets = 1 if kind == "boss" else PACK
    return power[kind] + power.get(kind + "_share", 0.0) * REFERENCE_HEALTH * targets


def score(report, level):
    power = report["stages"][str(level)]["power"]
    return math.sqrt(max(effective(power, "boss"), 1.0) * max(effective(power, "pack"), 1.0))


def main(argv):
    band = 2.0
    dry = False
    paths = []
    for arg in argv:
        if arg.startswith("--band="):
            band = float(arg.split("=", 1)[1])
        elif arg == "--dry":
            dry = True
        else:
            paths.append(arg)
    reports = []
    for path in paths:
        reports.extend(json.loads(Path(path).read_text()))
    damage = {gem["id"] for gem in CONTENT["active_gems"] if "damage" in gem.get("tags", [])}
    rows = [r for r in reports if r["subject"] in damage]
    factors = {}
    for level in (2, 5):
        values = [score(r, level) for r in rows]
        median = statistics.median(values)
        for report, value in zip(rows, values):
            low, high = median / band, median * band
            target = low if value < low else high if value > high else value
            factors.setdefault(report["subject"], []).append(target / value)
    balance = json.loads(BALANCE.read_text())
    table = balance.setdefault("power", {})
    changes = []
    for subject, values in sorted(factors.items()):
        factor = math.sqrt(values[0] * values[1])
        factor = min(10.0, max(0.1, factor))
        if abs(factor - 1.0) < 0.05:
            continue
        old = float(table.get(subject, 1.0))
        table[subject] = round(old * factor, 3)
        changes.append((subject, old, table[subject]))
    for subject, old, new in changes:
        print("FACTOR %-24s %6.3f -> %6.3f" % (subject, old, new))
    if not dry:
        BALANCE.write_text(json.dumps(balance, ensure_ascii=False, indent=2, sort_keys=True) + "\n")
    print("BALANCE_FACTORS_OK %d changes%s" % (len(changes), " (dry)" if dry else ""))


if __name__ == "__main__":
    main(sys.argv[1:])
