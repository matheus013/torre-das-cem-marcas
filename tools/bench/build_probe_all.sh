#!/bin/sh
set -eu
# Roda a sonda de builds em paralelo (um processo por grupo de assuntos) e junta o resultado.
# Uso: sh tools/bench/build_probe_all.sh [processos] [--fast]
cd "$(dirname "$0")/../.." || exit 1
JOBS="${1:-8}"
EXTRA="${2:-}"
OUT="$(mktemp -d -t aresta-builds.XXXXXX)"
SUBJECTS="$(godot --headless --path . --script tools/bench/build_subjects.gd 2>/dev/null | grep '^SUBJECTS ' | cut -d' ' -f2)"
index=0
for group in $(printf '%s' "$SUBJECTS" | tr ',' '\n' | awk -v jobs="$JOBS" '{ groups[NR % jobs] = groups[NR % jobs] (groups[NR % jobs] == "" ? "" : ",") $0 } END { for (g in groups) print groups[g] }'); do
	godot --headless --path . --script tools/bench/build_probe.gd -- --subjects="$group" --out="$OUT/part_$index.json" $EXTRA > "$OUT/part_$index.log" 2>&1 &
	index=$((index + 1))
done
wait
python3 tools/bench/build_report.py "$OUT"/part_*.json
echo "logs: $OUT"
