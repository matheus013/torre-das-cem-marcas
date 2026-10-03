#!/bin/sh
set -eu

PORT="${1:-17879}"
HOST_LOG="$(mktemp -t aresta-host.XXXXXX)"
CLIENT_LOG="$(mktemp -t aresta-client.XXXXXX)"
HOST_PID=""

cleanup() {
	if [ -n "$HOST_PID" ] && kill -0 "$HOST_PID" 2>/dev/null; then
		kill "$HOST_PID" 2>/dev/null || true
	fi
	rm -f "$HOST_LOG" "$CLIENT_LOG"
}
trap cleanup EXIT INT TERM

godot --headless --path . -- --server --port="$PORT" --test-duration=6 >"$HOST_LOG" 2>&1 &
HOST_PID=$!

attempt=0
while ! grep -q "NETWORK_HOST_READY" "$HOST_LOG"; do
	attempt=$((attempt + 1))
	if [ "$attempt" -ge 50 ]; then
		cat "$HOST_LOG"
		exit 1
	fi
	sleep 0.1
done

godot --headless --path . -- --client=127.0.0.1 --port="$PORT" --test-duration=2 >"$CLIENT_LOG" 2>&1
wait "$HOST_PID"
HOST_PID=""

grep -q "NETWORK_CLIENT_CONNECTED" "$CLIENT_LOG"
grep -q "NETWORK_TEST_DONE.*players=2" "$CLIENT_LOG"
grep -q "NETWORK_PEER_JOINED.*players=2" "$HOST_LOG"

printf '%s\n' "NETWORK_SMOKE_OK: host accepted client and replicated two players"
