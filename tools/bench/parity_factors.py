"""Paridade de DPS das magias de dano (plano docs/balanceamento/plano-paridade-dps.md; decisao 610).

Le as partes da sonda isolada (tools/bench/skill_parity_probe.gd), calcula o indice medio de cada
magia, 0,5 x chefe / referencia de chefe + 0,5 x horda / referencia de horda (referencias = mediana
das magias de dano), e atualiza data/combat/gem_balance.json para trazer quem esta fora da faixa
[LOW, HIGH] de volta ao centro. O fator novo multiplica o anterior e e limitado por lote.

Dano por fracao da Vida (esporos) e avaliado na Vida real de referencia, nao no boneco de 1e12.

Uso: python3 tools/bench/parity_factors.py parte1.json ... [--dry] [--report=caminho.md]
"""

import json
import statistics
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BALANCE = ROOT / "data/combat/gem_balance.json"
DUMMY_HEALTH = 1.0e12
PACK = 6
# Vida de referencia: chefe e comum do andar 100 na dificuldade 1 (x10 global ja incluido).
BOSS_HEALTH = 220000.0
COMMON_HEALTH = 8000.0
LOW, HIGH = 0.85, 1.15
# Excecoes documentadas: o dano vem de fracao da Vida do alvo e escala com ela por desenho
# (decisao 591); fica fora da referencia e dos fatores.
EXCEPTIONS = {"esporos": "fracao da Vida do alvo (decisao 591)"}
STEP = (0.25, 4.0)


def effective(sample, kind):
    count = 1 if kind == "boss" else PACK
    health = BOSS_HEALTH if kind == "boss" else COMMON_HEALTH
    total = 0.0
    for source, dps in sample[kind]["sources"].items():
        share = float(sample[kind].get("shares", {}).get(source, 0.0))
        fixed = max(0.0, dps - share * DUMMY_HEALTH * count)
        total += fixed + share * health * count
    return total


def load(paths):
    rows = []
    for path in paths:
        rows.extend(json.loads(Path(path).read_text())["rows"])
    table = {}
    for row in rows:
        if row["subject"] in EXCEPTIONS:
            continue
        boss = statistics.median(effective(sample, "boss") for sample in row["samples"])
        pack = statistics.median(effective(sample, "pack") for sample in row["samples"])
        starved = statistics.median(sample["boss"].get("starved_seconds", 0.0) for sample in row["samples"])
        table[row["subject"]] = {"boss": boss, "pack": pack, "character": row["character"], "starved": starved}
    return table


def main(argv):
    dry = "--dry" in argv
    report = next((arg.split("=", 1)[1] for arg in argv if arg.startswith("--report=")), "")
    paths = [arg for arg in argv if not arg.startswith("--")]
    table = load(paths)
    ref_boss = statistics.median(entry["boss"] for entry in table.values())
    ref_pack = statistics.median(entry["pack"] for entry in table.values())
    balance = json.loads(BALANCE.read_text())
    powers = balance.setdefault("power", {})
    lines = ["| Magia | Chefe | Horda | Indice | Fator anterior | Fator novo |", "|---|---|---|---|---|---|"]
    changes = 0
    for subject, entry in sorted(table.items(), key=lambda item: 0.5 * item[1]["boss"] / ref_boss + 0.5 * item[1]["pack"] / ref_pack):
        index = 0.5 * entry["boss"] / ref_boss + 0.5 * entry["pack"] / ref_pack
        old = float(powers.get(subject, 1.0))
        new = old
        if index > 0 and not LOW <= index <= HIGH:
            new = round(old * min(STEP[1], max(STEP[0], 1.0 / index)), 3)
            powers[subject] = new
            changes += 1
        if index <= 0:
            print("ZERO %s: sem dano medido, corrigir mecanica antes de fator" % subject)
        lines.append("| %s | %.0f | %.0f | %.2f | %.3f | %.3f |" % (subject, entry["boss"], entry["pack"], index, old, new))
        print("PARITY %-22s boss=%9.0f pack=%9.0f index=%5.2f factor %.3f -> %.3f" % (subject, entry["boss"], entry["pack"], index, old, new))
    print("REFERENCE boss=%.0f pack=%.0f" % (ref_boss, ref_pack))
    if not dry:
        BALANCE.write_text(json.dumps(balance, ensure_ascii=False, indent=2, sort_keys=True) + "\n")
    if report:
        Path(report).write_text("Referencia: chefe %.0f, horda %.0f DPS.\n\n" % (ref_boss, ref_pack) + "\n".join(lines) + "\n")
    print("PARITY_FACTORS_OK %d changes%s" % (changes, " (dry)" if dry else ""))


if __name__ == "__main__":
    main(sys.argv[1:])
