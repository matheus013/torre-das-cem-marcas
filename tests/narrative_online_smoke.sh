#!/bin/sh
set -eu
PORT="${1:-17993}"
LOG_DIR="$(mktemp -d -t aresta-narrative.XXXXXX)"
PIDS=""
cleanup() {
	for pid in $PIDS; do kill "$pid" 2>/dev/null || true; done
	rm -rf "$LOG_DIR"
}
trap cleanup EXIT INT TERM
godot --headless --path . --script tools/qa/narrative_online_peer.gd -- --host-session --session-port="$PORT" --test-duration=16 >"$LOG_DIR/host.log" 2>&1 &
HOST=$!
PIDS="$HOST"
attempt=0
while ! grep -q VILLAGE_HOST_READY "$LOG_DIR/host.log"; do
	attempt=$((attempt + 1))
	if [ "$attempt" -ge 100 ]; then cat "$LOG_DIR/host.log"; exit 1; fi
	sleep 0.1
done
godot --headless --path . --script tools/qa/narrative_online_peer.gd -- --join-session=127.0.0.1 --session-port="$PORT" --profile=narrative-observer --test-duration=16 >"$LOG_DIR/client.log" 2>&1 &
CLIENT=$!
PIDS="$PIDS $CLIENT"
wait "$CLIENT" || { cat "$LOG_DIR/client.log"; cat "$LOG_DIR/host.log"; exit 1; }
# The same profile reconnects after completing the shared contract.
godot --headless --path . --script tools/qa/narrative_online_peer.gd -- --join-session=127.0.0.1 --session-port="$PORT" --profile=narrative-observer --test-duration=16 >"$LOG_DIR/reconnect.log" 2>&1 &
RECONNECT=$!
PIDS="$PIDS $RECONNECT"
wait "$RECONNECT" || { cat "$LOG_DIR/reconnect.log"; exit 1; }
godot --headless --path . --script tools/qa/narrative_online_peer.gd -- --join-session=127.0.0.1 --session-port="$PORT" --profile=narrative-late --test-duration=16 >"$LOG_DIR/late.log" 2>&1 &
LATE=$!
PIDS="$PIDS $LATE"
wait "$LATE" || { cat "$LOG_DIR/late.log"; exit 1; }
wait "$HOST" || { cat "$LOG_DIR/host.log"; exit 1; }
PIDS=""
for log in client reconnect late; do grep -q 'NARRATIVE_CLIENT_OK.*opening_known=true' "$LOG_DIR/$log.log"; done
grep -q NARRATIVE_HOST_OK "$LOG_DIR/host.log"
grep -q VILLAGE_PEER_RECONNECTED "$LOG_DIR/host.log"
if grep -q 'SCRIPT ERROR\|ERROR:' "$LOG_DIR"/*.log; then cat "$LOG_DIR"/*.log; exit 1; fi
printf '%s\n' "NARRATIVE_ONLINE_OK: client rescue/route/fissure intents, duplicate commands, completed journal, reconnect, late join and reward once"
