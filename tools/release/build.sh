#!/bin/sh
set -eu

cd "$(dirname "$0")/../.."
GODOT_BIN="${GODOT_BIN:-godot}"
target="${1:-all}"
case "$target" in
    windows|linux|macos|all) ;;
    *) printf 'Uso: sh tools/release/build.sh [windows|linux|macos|all]\n' >&2; exit 2 ;;
esac

"$GODOT_BIN" --headless --path . --import
build_target() {
    folder="$1"
    preset="$2"
    filename="$3"
    mkdir -p "builds/$folder"
    "$GODOT_BIN" --headless --path . --export-release "$preset" "builds/$folder/$filename"
    test -s "builds/$folder/$filename"
    if [ "$folder" != macos ]; then
        test -s "builds/$folder/aresta.pck"
    fi
    git rev-parse HEAD > "builds/$folder/source-commit.txt"
    git status --porcelain > "builds/$folder/source-changes.txt"
    "$GODOT_BIN" --version > "builds/$folder/engine-version.txt"
    printf 'Build release: builds/%s/%s\n' "$folder" "$filename"
}

if [ "$target" = windows ] || [ "$target" = all ]; then
    build_target windows 'Windows Desktop' aresta.exe
fi
if [ "$target" = linux ] || [ "$target" = all ]; then
    build_target linux Linux aresta.x86_64
fi
if [ "$target" = macos ]; then
    build_target macos 'macOS QA' aresta.zip
fi
