#!/bin/sh
set -u

# Abre quatro janelas de Aresta na mesma máquina, em grade 2×2: um host e três clientes,
# cada um com uma personagem e um agente (--autopilot) jogando. Feche com Ctrl+C.
# Uso: sh tools/play_local_coop.sh [porta]
#      WIDTH=960 HEIGHT=540 sh tools/play_local_coop.sh   # janelas menores (pixels físicos)
#      AGENTS=0 sh tools/play_local_coop.sh               # quatro janelas sem agentes

cd "$(dirname "$0")/.." || exit 1
PORT="${1:-7777}"
# Tamanhos em pixels físicos (em Retina 2×, 1280×720 vira 640×360); a posição é a do conteúdo, abaixo da barra de título.
WIDTH="${WIDTH:-1280}"
HEIGHT="${HEIGHT:-720}"
TOP="${TOP:-106}"
GAP="${GAP:-60}"
SCENE="res://src/prototype/village/village_exploration.tscn"
AGENT_FLAG="--autopilot"
if [ "${AGENTS:-1}" = "0" ]; then
	AGENT_FLAG=""
fi
PIDS=""

cleanup() {
	for pid in $PIDS; do
		kill "$pid" 2>/dev/null || true
	done
}
trap cleanup EXIT INT TERM

launch() {
	# $1 coluna, $2 linha, $3 personagem, $4 papel na sessão
	x=$(($1 * WIDTH))
	y=$((TOP + $2 * (HEIGHT + GAP)))
	godot --path . --position "$x,$y" --resolution "${WIDTH}x${HEIGHT}" "$SCENE" -- \
		$4 --session-port="$PORT" --character="$3" --profile="local-$3" $AGENT_FLAG &
	PIDS="$PIDS $!"
}

launch 0 0 eloa --host-session
sleep 2
launch 1 0 sena --join-session=127.0.0.1
launch 0 1 cira --join-session=127.0.0.1
launch 1 1 rui --join-session=127.0.0.1

printf '%s\n' "Quatro jogadores abertos (host: Eloa; clientes: Sena, Cira, Rui). Ctrl+C fecha todos."
wait
