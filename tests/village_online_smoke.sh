#!/bin/sh
set -eu

# Marco 1: host autoritativo de Aresta com três clientes em processos separados, piloto
# automático na Torre e verificação de personagens únicos, reconexão com a mesma personagem
# e salvamento consistente. O cliente 3 cai e reconecta no meio da sessão.
# Clientes têm 13 s: a vila maior (2880x1620 -> 3840x2400) deixou a caminhada até a Torre perto
# de 6 s, e no CI (2 núcleos, 5 processos Godot) 9 s não bastavam para conectar e chegar.

PORT="${1:-17991}"
SCENE="res://src/prototype/village/village_exploration.tscn"
LOG_DIR="$(mktemp -d -t aresta-online.XXXXXX)"
PIDS=""

cleanup() {
	for pid in $PIDS; do
		kill "$pid" 2>/dev/null || true
	done
	rm -rf "$LOG_DIR"
}
trap cleanup EXIT INT TERM

godot --headless --path . "$SCENE" -- --host-session --session-port="$PORT" --autopilot --test-duration=18 >"$LOG_DIR/host.log" 2>&1 &
HOST_PID=$!
PIDS="$HOST_PID"

attempt=0
while ! grep -q "VILLAGE_HOST_READY" "$LOG_DIR/host.log"; do
	attempt=$((attempt + 1))
	if [ "$attempt" -ge 100 ]; then
		cat "$LOG_DIR/host.log"
		exit 1
	fi
	sleep 0.1
done

for index in 1 2 3; do
	EXTRA=""
	if [ "$index" -eq 3 ]; then
		EXTRA="--reconnect-at=4"
	fi
	godot --headless --path . "$SCENE" -- --join-session=127.0.0.1 --session-port="$PORT" --profile="smoke-client-$index" --autopilot --test-duration=13 $EXTRA >"$LOG_DIR/client$index.log" 2>&1 &
	PIDS="$PIDS $!"
done

status=0
for pid in $PIDS; do
	wait "$pid" || status=1
done
PIDS=""

fail() {
	printf '%s\n' "VILLAGE_ONLINE_FAILED: $1"
	for log in "$LOG_DIR"/*.log; do
		printf '%s\n' "---- $log"
		grep -E "VILLAGE_|ERROR|SCRIPT" "$log" | head -20
	done
	exit 1
}

[ "$status" -eq 0 ] || fail "a process exited with an error"
[ "$(grep -c "VILLAGE_PEER_JOINED" "$LOG_DIR/host.log")" -eq 3 ] || fail "host did not accept three clients"
for index in 1 2 3; do
	grep -q "VILLAGE_CLIENT_DONE.*players=4" "$LOG_DIR/client$index.log" || fail "client $index did not see four players"
	grep -q "VILLAGE_CLIENT_DONE.*zone=tower\|VILLAGE_CLIENT_DONE.*zone=boss_room" "$LOG_DIR/client$index.log" || fail "client $index did not reach the Tower"
done
grep -q "VILLAGE_HOST_DONE.*peak_players=4 characters=cira,eloa,rui,sena" "$LOG_DIR/host.log" || fail "characters were not unique per session"
grep -q "VILLAGE_PEER_RECONNECTED.*profile=smoke-client-3" "$LOG_DIR/host.log" || fail "host did not restore the reserved character"
grep -q "VILLAGE_CLIENT_DONE.*reconnections=1" "$LOG_DIR/client3.log" || fail "client 3 did not reconnect"
CLIENT3_LINE="$(grep "VILLAGE_CLIENT_DONE" "$LOG_DIR/client3.log")"
CLIENT3_NOW="$(printf '%s' "$CLIENT3_LINE" | sed -n 's/.* character=\([a-z]*\) .*/\1/p')"
CLIENT3_FIRST="$(printf '%s' "$CLIENT3_LINE" | sed -n 's/.*first_character=\([a-z]*\).*/\1/p')"
[ -n "$CLIENT3_NOW" ] && [ "$CLIENT3_NOW" = "$CLIENT3_FIRST" ] || fail "reconnected client changed character ($CLIENT3_FIRST -> $CLIENT3_NOW)"
grep -q "VILLAGE_HOST_DONE.*save_roundtrip=ok" "$LOG_DIR/host.log" || fail "save roundtrip diverged"
if grep -q "SCRIPT ERROR" "$LOG_DIR"/*.log; then
	fail "script errors during the session"
fi

grep -h "VILLAGE_HOST_DONE\|VILLAGE_CLIENT_DONE" "$LOG_DIR"/*.log
printf '%s\n' "VILLAGE_ONLINE_OK: host plus three clients shared Aresta and the Tower with unique characters and a reconnection"
