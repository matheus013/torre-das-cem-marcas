extends SceneTree

## Sonda de builds (balanceamento do épico E1; decisão 610): para cada gema ativa e cada
## autoataque, monta o melhor set por simulação e avalia nas cinco dificuldades (lógica em
## tools/bench/build_lab.gd).
## Uso: godot --headless --path . --script tools/bench/build_probe.gd -- [--subjects=a,b]
##   [--out=user://build_probe.json] [--fast]
## Imprime BUILD (set escolhido), POWER (medidas) e EVAL (dificuldade x ponto de controle).

const BuildLab := preload("res://tools/bench/build_lab.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var lab: RefCounted = BuildLab.new()
	var only: Array[String] = []
	var out := "user://build_probe.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--subjects="):
			for id in arg.trim_prefix("--subjects=").split(","):
				only.append(id)
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg == "--fast":
			lab.set("fast", true)
	var results: Array = []
	for subject: String in lab.call("subjects"):
		if not only.is_empty() and subject not in only:
			continue
		var started := Time.get_ticks_msec()
		results.append(lab.call("study", subject))
		print("DONE %s in %.0fs" % [subject, (Time.get_ticks_msec() - started) / 1000.0])
	var file := FileAccess.open(out, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(results, "  "))
		print("BUILD_PROBE_OK %d subjects -> %s" % [results.size(), ProjectSettings.globalize_path(out)])
	quit(0)
