"""Junta as partes da sonda de builds e escreve docs/balanceamento/avaliacao-de-builds.md (decisao 610).

Uso: python3 tools/bench/build_report.py parte1.json parte2.json ...
"""

import json
import statistics
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTENT = json.loads((ROOT / "data/beta/beta_content.json").read_text())
OUT = ROOT / "docs/balanceamento/avaliacao-de-builds.md"
OUT_JSON = ROOT / "docs/balanceamento/avaliacao-de-builds.json"
NAMES = {item["id"]: item["name"] for item in CONTENT["items"]}
NAMES.update({gem["id"]: gem["name"] for gem in CONTENT["active_gems"]})
NAMES.update({gem["id"]: gem["name"] for gem in CONTENT["support_gems"]})
EVOLUTIONS = {}
for gem in CONTENT["active_gems"]:
    for level, options in gem.get("evolutions", {}).items():
        for option in options:
            EVOLUTIONS[option["id"]] = option["name"]
AUTO = {"auto_foco": "Autoataque: Foco (Eloa)", "auto_lanca": "Autoataque: Lanca (Sena)",
        "auto_manoplas": "Autoataque: Manoplas (Cira)", "auto_bastao": "Autoataque: Bastao (Rui)"}
SLOT_ORDER = ["weapon", "offhand", "amulet", "armor", "gloves", "boots", "pants", "ring0", "ring1", "relic"]


def name(subject):
    return AUTO.get(subject, NAMES.get(subject, subject))


def human(value):
    for limit, suffix in ((1e12, " tri"), (1e9, " bi"), (1e6, " mi"), (1e3, " mil")):
        if value >= limit:
            return ("%.1f" % (value / limit)).replace(".", ",") + suffix
    return "%.0f" % value


def cell(verdicts):
    passed = sum(1 for v in verdicts if v["pass"])
    if passed == len(verdicts):
        return "OK"
    gaps = [v["dps_gap"] for v in verdicts if not v["kill"]]
    worst = max(gaps) if gaps else 0
    survive = all(v["survive"] for v in verdicts)
    text = "%d/%d" % (passed, len(verdicts))
    if gaps:
        text += " · dano x%s" % human(worst)
    if not survive:
        text += " · morre"
    return text


def main(paths):
    reports = []
    for path in paths:
        reports.extend(json.loads(Path(path).read_text()))
    reports.sort(key=lambda r: (r["subject"].startswith("auto_"), name(r["subject"])))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(reports, ensure_ascii=False, indent=1) + "\n")
    lines = ["# Avaliacao de builds por dificuldade", "",
             "Gerado por `tools/bench/build_probe_all.sh` (sonda `tools/bench/build_lab.gd`, decisao 610). Para cada gema",
             "ativa e cada autoataque a sonda monta o melhor set por simulacao (evolucoes de maestria, par de suportes,",
             "arma, lendarios e divinos encaixe a encaixe, Paragon) e o avalia com o poder esperado em cada dificuldade:",
             "1 nivel do andar e equipamento inicial; 2 nivel 100, unica e lendarios; 3 + Paragon 50; 4 + Paragon 100 e",
             "1 divino; 5 + Paragon 175 e set completo. Pontos de controle: chefes dos andares 16, 51 e 100 (matar antes",
             "da furia e aguentar 3 golpes da maior habilidade) e matilhas de 6 comuns nos andares 30, 75 e 99 (limpar",
             "em ate 20 s e aguentar o contato de 3 comuns por esse tempo). Dano medido em arena de alvos fixos, sem esquiva",
             "nem posicionamento fino: e uma estimativa, nao uma partida.", "",
             "Celula: `OK` passa em todos os 6 pontos; senao `aprovados/6`, quantas vezes falta de dano no pior ponto",
             "(`dano x12` = precisa de 12 vezes mais dano) e `morre` se algum ponto falha por sobrevivencia.", "",
             "## Resumo", "",
             "| Build | Dano no chefe (d5) | Dano na matilha (d5) | Dif. 1 | Dif. 2 | Dif. 3 | Dif. 4 | Dif. 5 |",
             "|---|---|---|---|---|---|---|---|"]
    totals = {str(level): 0 for level in range(1, 6)}
    for report in reports:
        power = report["stages"]["5"]["power"]
        row = [name(report["subject"]), human(power["boss"]), human(power["pack"])]
        for level in range(1, 6):
            verdicts = report["evaluation"][str(level)]
            row.append(cell(verdicts))
            if all(v["pass"] for v in verdicts):
                totals[str(level)] += 1
        lines.append("| " + " | ".join(row) + " |")
    lines += ["", "**Builds que vencem tudo:** " + ", ".join("dificuldade %s: %d de %d" % (level, totals[level], len(reports)) for level in totals), ""]
    lines += ["## Falta de dano por dificuldade", "",
              "Mediana e pior caso de quantas vezes mais dano seria preciso (1 = no limite) e motivo das falhas.", "",
              "| Dificuldade | Mediana chefe | Pior chefe | Mediana matilha | Pior matilha | Falhas por sobrevivencia |", "|---|---|---|---|---|---|"]
    for level in range(1, 6):
        boss = [v["dps_gap"] for r in reports for v in r["evaluation"][str(level)] if v["kind"] == "boss"]
        pack = [v["dps_gap"] for r in reports for v in r["evaluation"][str(level)] if v["kind"] == "pack"]
        deaths = sum(1 for r in reports for v in r["evaluation"][str(level)] if not v["survive"])
        lines.append("| %d | x%s | x%s | x%s | x%s | %d |" % (level, human(statistics.median(boss)), human(max(boss)), human(statistics.median(pack)), human(max(pack)), deaths))
    lines += ["", "## Melhor set de cada build (dificuldade 5)", ""]
    for report in reports:
        build = report["stages"]["5"]["build"]
        lines.append("### " + name(report["subject"]))
        lines.append("")
        lines.append("- **Personagem:** %s" % build["character"].capitalize())
        if build.get("evolutions"):
            lines.append("- **Evolucoes:** " + ", ".join("%s %s" % (level, EVOLUTIONS.get(choice, choice)) for level, choice in sorted(build["evolutions"].items(), key=lambda item: int(item[0]))))
        if build.get("supports"):
            lines.append("- **Suportes:** " + ", ".join(NAMES.get(s, s) for s in build["supports"]))
        gear = build.get("gear", {})
        lines.append("- **Equipamento:** " + ", ".join(NAMES.get(gear[slot], gear[slot]) for slot in SLOT_ORDER if slot in gear))
        lines.append("- **Paragon %d:** %s" % (build.get("paragon_level", 0), ", ".join("%s %d" % (track, points) for track, points in build.get("paragon", {}).items())))
        powers = " · ".join("d%s chefe %s / matilha %s" % (level, human(report["stages"][level]["power"]["boss"]), human(report["stages"][level]["power"]["pack"])) for level in ["2", "3", "4", "5"])
        lines.append("- **Dano por segundo:** " + powers)
        lines.append("")
    OUT.write_text("\n".join(lines) + "\n")
    print("BUILD_REPORT_OK %d builds -> %s" % (len(reports), OUT))


if __name__ == "__main__":
    main(sys.argv[1:])
