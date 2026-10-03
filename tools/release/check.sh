#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
    printf 'Uso: sh tools/release/check.sh /caminho/absoluto/ao/executavel\n' >&2
    exit 2
fi
case "$1" in
    /*) executable="$1" ;;
    *) printf 'Informe um caminho absoluto para testar fora do checkout.\n' >&2; exit 2 ;;
esac
log="$(mktemp -t aresta-release-check.XXXXXX)"
trap 'rm -f "$log"' EXIT INT TERM
cd "${TMPDIR:-/tmp}"
if "$executable" --headless --quit-after 120 -- --release-check > "$log" 2>&1 &&
    grep -q 'RELEASE_PACK_OK:' "$log" && ! grep -q 'ERROR:' "$log"; then
    cat "$log"
else
    cat "$log" >&2
    exit 1
fi
