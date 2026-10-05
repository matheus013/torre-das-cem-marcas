#!/bin/sh
set -eu

cd "$(dirname "$0")/../.."
GODOT_BIN="${GODOT_BIN:-godot}"
if [ -d node_modules ]; then
    touch node_modules/.gdignore
fi
log="$(mktemp -t aresta-import.XXXXXX)"
trap 'rm -f "$log"' EXIT INT TERM
status=0
"$GODOT_BIN" --headless --path . --import >"$log" 2>&1 || status=$?
cat "$log"
if [ "$status" -ne 0 ]; then
    exit "$status"
fi
# Godot can report parser/import failures without a nonzero exit status.
if grep -Eq '(^|[[:space:]])(SCRIPT ERROR|ERROR):' "$log"; then
    printf 'Importacao reprovada: erros no log do Godot.\n' >&2
    exit 1
fi
