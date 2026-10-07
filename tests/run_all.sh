#!/bin/sh
set -u

# Executa todos os testes headless e as provas de rede em processos separados.
# Sai com erro se qualquer teste falhar ou imprimir SCRIPT ERROR. Uso: sh tests/run_all.sh

cd "$(dirname "$0")/.." || exit 1
LOG="$(mktemp -t aresta-tests.XXXXXX)"
trap 'rm -f "$LOG"' EXIT INT TERM
failed=0
passed=0

for test in tests/*.gd; do
	name="$(basename "$test" .gd)"
	if godot --headless --path . --script "$test" >"$LOG" 2>&1 && ! grep -q "SCRIPT ERROR" "$LOG"; then
		passed=$((passed + 1))
		printf 'ok    %s\n' "$name"
	else
		failed=$((failed + 1))
		printf 'FAIL  %s\n' "$name"
		grep -E "ERROR|_fail|push_error" "$LOG" | head -5
	fi
done

for script in tests/network_smoke.sh tests/village_online_smoke.sh tests/narrative_online_smoke.sh; do
	name="$(basename "$script" .sh)"
	if sh "$script" >"$LOG" 2>&1; then
		passed=$((passed + 1))
		printf 'ok    %s\n' "$name"
	else
		failed=$((failed + 1))
		printf 'FAIL  %s\n' "$name"
		tail -15 "$LOG"
	fi
done

printf '\n%d ok, %d falharam\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
