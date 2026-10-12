"""Resume an interrupted full build study, recovering completed log summaries.

Recovery keeps rounded measurements and stage-5 gear; missing earlier gear is
explicitly null, never inferred. Game balance is not modified.
"""

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / "data/beta/beta_content.json"
AUTO = ["auto_foco", "auto_lanca", "auto_manoplas", "auto_bastao"]
POWER = re.compile(r"^POWER (\S+) d([2-5]) (.+)$")
EVAL = re.compile(r"^EVAL (\S+) d([1-5]) floor=(\d+) (.+)$")


def validate(report):
    for level in range(1, 6):
        rows = report["evaluation"][str(level)]
        if {row["floor"] for row in rows} != {16, 51, 100, 30, 75, 99} or len(rows) != 6:
            raise ValueError("Incomplete checkpoints: " + report["subject"])
    for level in range(2, 6):
        power = report["stages"][str(level)]["power"]
        if not {"boss", "pack", "boss_share", "pack_share", "health"} <= power.keys():
            raise ValueError("Old measurement schema: " + report["subject"])
    if not report["stages"]["5"]["build"]:
        raise ValueError("Missing final gear: " + report["subject"])


def recover_logs(directory, existing, catalog):
    recovered = {}
    definitions = {gem["id"]: gem for gem in catalog["active_gems"]}
    for path in sorted(directory.glob("part_*.log")):
        pending = {}
        for line in path.read_text().splitlines():
            match = POWER.match(line)
            if match:
                subject, level, fields = match.groups()
                power = {key: float(value) for key, value in (entry.split("=", 1) for entry in fields.split())}
                pending.setdefault(subject, {"subject": subject, "stages": {}, "evaluation": {}})["stages"][level] = {"build": None, "power": power}
                continue
            if line.startswith("BUILD "):
                _, subject, payload = line.split(" ", 2)
                report = pending.setdefault(subject, {"subject": subject, "stages": {}, "evaluation": {}})
                build = json.loads(payload)
                report["stages"]["5"]["build"] = build
                report["character"] = build["character"]
                report["element"] = definitions.get(subject, {}).get("element") or ("arcane" if subject == "auto_foco" else "physical")
                continue
            match = EVAL.match(line)
            if match:
                subject, level, _, payload = match.groups()
                pending[subject]["evaluation"].setdefault(level, []).append(json.loads(payload))
                continue
            if line.startswith("DONE "):
                subject = line.split()[1]
                if subject in existing or subject in recovered:
                    continue
                report = pending[subject]
                validate(report)
                report["provenance"] = {"source": str(path), "kind": "recovered_log", "rounded_power": True,
                                        "missing_stage_gear": [2, 3, 4]}
                recovered[subject] = report
    return recovered


def save(path, rows):
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(rows, ensure_ascii=False, indent=1) + "\n")
    temporary.replace(path)


def measurement_hash():
    digest = hashlib.sha256()
    paths = list((ROOT / "src").rglob("*.gd")) + list((ROOT / "data").rglob("*.json"))
    paths.append(ROOT / "tools/bench/build_lab.gd")
    for path in sorted(paths):
        digest.update(str(path.relative_to(ROOT)).encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("previous", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--plan", action="store_true")
    args = parser.parse_args()
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    catalog = json.loads(CONTENT.read_text())
    fingerprint = measurement_hash()
    manifest_path = args.out / "manifest.json"
    if manifest_path.exists():
        previous_manifest = json.loads(manifest_path.read_text())
        saved_fingerprint = previous_manifest.get("measurement_sha256")
        if saved_fingerprint and saved_fingerprint != fingerprint:
            parser.error("Measurement inputs changed; use a new --out directory instead of mixing runs")
    expected = [gem["id"] for gem in catalog["active_gems"]] + AUTO
    reports = {}
    sources = [args.previous]
    if args.out.exists():
        sources.append(args.out)
    for directory in sources:
        for path in sorted(directory.glob("part_*.json")):
            for report in json.loads(path.read_text()):
                validate(report)
                reports[report["subject"]] = report
    recovered = recover_logs(args.previous, reports, catalog)
    reports.update(recovered)
    recovered_ids = [subject for subject, report in reports.items() if report.get("provenance", {}).get("kind") == "recovered_log"]
    missing = [subject for subject in expected if subject not in reports]
    print(f"COVERAGE full_json={len(reports) - len(recovered_ids)} recovered_logs={len(recovered_ids)} pending={len(missing)}", flush=True)
    print("PENDING " + ",".join(missing), flush=True)
    if args.plan:
        return
    args.out.mkdir(parents=True, exist_ok=True)
    save(args.out / "part_existing.json", list(reports.values()))
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    save(args.out / "manifest.json", {"revision": revision, "previous": str(args.previous), "subjects": expected,
                                     "pending_at_start": missing, "recovered_logs": recovered_ids, "fast": False,
                                     "measurement_sha256": fingerprint,
                                     "content_sha256": hashlib.sha256(CONTENT.read_bytes()).hexdigest()})

    def run(subject):
        output = args.out.resolve() / ("part_" + subject + ".json")
        log = output.with_suffix(".log")
        with log.open("w") as stream:
            result = subprocess.run(["godot", "--headless", "--path", str(ROOT), "--script", "tools/bench/build_probe.gd", "--",
                                     "--subjects=" + subject, "--out=" + str(output)], cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
        text = log.read_text()
        if result.returncode or "SCRIPT ERROR" in text or "ERROR:" in text or "BUILD_PROBE_OK 1 subjects" not in text:
            raise RuntimeError("Study failed: " + subject + "; see " + str(log))
        rows = json.loads(output.read_text())
        if len(rows) != 1 or rows[0]["subject"] != subject:
            raise ValueError("Unexpected result: " + subject)
        validate(rows[0])
        rows[0]["provenance"] = {"kind": "resumed_full_study", "revision": revision, "source": str(log)}
        save(output, rows)
        return rows[0]

    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        tasks = {pool.submit(run, subject): subject for subject in missing}
        for task in as_completed(tasks):
            report = task.result()
            reports[report["subject"]] = report
            print(f"RESUMED_DONE {report['subject']} coverage={len(reports)}/{len(expected)}", flush=True)
    if measurement_hash() != fingerprint:
        raise RuntimeError("Game or measurement inputs changed during the study; do not consolidate mixed data")
    save(args.out / "combined.json", [reports[subject] for subject in expected])
    print("RESUME_BUILD_PROBE_OK " + str(len(reports)), flush=True)


if __name__ == "__main__":
    main()
