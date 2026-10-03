extends SceneTree

## Mede o custo do host com quatro jogadores no Pátio e hordas crescentes: tempo médio e pior
## quadro de `step` + `view_snapshot`, e tamanho do snapshot serializado enviado a 20 Hz.
## Uso: godot --headless --path . --script tools/bench/world_simulation_bench.gd

const SimulationScript := preload("res://src/gameplay/world/world_simulation.gd")
const FRAMES := 240
const DELTA := 1.0 / 60.0


func _init() -> void:
	for horde in [8, 40, 80, 160]:
		_measure(horde)
	quit(0)


func _measure(horde: int) -> void:
	var sim: RefCounted = SimulationScript.new()
	sim.call("setup", 4242)
	for peer_id in [1, 2, 3, 4]:
		sim.call("add_player", peer_id)
		sim.call("enter_tower", peer_id)
	var enemies := sim.get("enemies") as Array
	var template := (enemies[0] as Dictionary).duplicate(true)
	var random := RandomNumberGenerator.new()
	random.seed = horde
	while enemies.size() < horde:
		var clone := template.duplicate(true)
		clone["position"] = Vector2(random.randf_range(260.0, 1100.0), random.randf_range(120.0, 620.0))
		clone["health"] = 1.0e9
		clone["max_health"] = 1.0e9
		enemies.append(clone)
	for state: Dictionary in (sim.get("players") as Dictionary).values():
		state["health"] = 1.0e9
	var total := 0
	var worst := 0
	var snapshot_bytes := 0
	var compressed_bytes := 0
	var compress_us := 0
	for frame in range(FRAMES):
		for peer_id in [1, 2, 3, 4]:
			var state := sim.call("player", peer_id) as Dictionary
			state["health"] = 1.0e9
			sim.call("set_move_target", peer_id, Vector2(400.0 + 60.0 * peer_id, 300.0 + 80.0 * sin(frame * 0.05 + peer_id)))
			if frame % 30 == peer_id:
				sim.call("use_skill", peer_id, frame % 4, Vector2(700.0, 360.0))
		var started := Time.get_ticks_usec()
		sim.call("step", DELTA)
		var snapshot: Dictionary = sim.call("view_snapshot")
		sim.call("drain_events")
		var elapsed := Time.get_ticks_usec() - started
		total += elapsed
		worst = maxi(worst, elapsed)
		if frame == FRAMES - 1:
			var raw := var_to_bytes(snapshot)
			snapshot_bytes = raw.size()
			var compress_started := Time.get_ticks_usec()
			compressed_bytes = raw.compress(FileAccess.COMPRESSION_ZSTD).size()
			compress_us = Time.get_ticks_usec() - compress_started
	print("BENCH horde=%d enemies=%d avg_ms=%.3f worst_ms=%.3f snapshot_bytes=%d zstd_bytes=%d zstd_ms=%.3f kbps_per_client=%.1f" % [
		horde, (sim.get("enemies") as Array).size(), float(total) / FRAMES / 1000.0, float(worst) / 1000.0,
		snapshot_bytes, compressed_bytes, float(compress_us) / 1000.0, float(compressed_bytes) * 20.0 * 8.0 / 1000.0,
	])
