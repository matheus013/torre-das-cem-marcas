#!/bin/bash
# Processa sprites de art/process.json. Uso: tools/art/process.sh [grupo|chave ...]
set -e
cd "$(dirname "$0")/../.."
godot --headless --path . --script tools/art/import_character_animations.gd
if [ -f art/environment-remodel.json ]; then
  godot --headless --path . --script tools/art/import_environment_remodel.gd
fi
KEYS=$(python3 - "$@" <<'PY'
import json, sys
wanted = set(sys.argv[1:])
config = json.load(open("art/process.json"))
print(" ".join(s["key"] for s in config["sprites"] if not wanted or s["key"] in wanted or s.get("group") in wanted))
PY
)
exec godot --headless --path . --script tools/art/process_sprites.gd -- $KEYS
