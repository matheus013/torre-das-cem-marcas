extends SceneTree

const Lab := preload("res://tools/bench/build_lab.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var seconds := 30.0
	var seeds := 5
	var level := 100
	var only: PackedStringArray = []
	var out := "user://skill_parity.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):
			seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--seeds="):
			seeds = int(arg.trim_prefix("--seeds="))
		elif arg.begins_with("--level="):
			level = int(arg.trim_prefix("--level="))
		elif arg.begins_with("--subjects="):
			only = arg.trim_prefix("--subjects=").split(",")
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	if seconds <= 0.0 or not is_finite(seconds) or seeds < 1 or level < 1 or level > 100:
		push_error("Invalid parity probe parameters")
		quit(1)
		return
	var lab := Lab.new()
	for id in only:
		if id not in lab.subjects():
			push_error("Unknown parity subject: " + id)
			quit(1)
			return
	var rows: Array = []
	for subject in lab.subjects():
		var gem := lab._gem(subject)
		if "damage" not in gem.get("tags", []) or (not only.is_empty() and subject not in only):
			continue
		var build := lab._base_build(subject)
		build["level"] = level
		build["mastery"] = 1
		build["gear"] = {}
		var samples: Array = []
		for seed_index in range(seeds):
			build["seed"] = 9101 + seed_index * 7919
			var sample := {"seed": build["seed"]}
			for kind in ["boss", "pack"]:
				sample[kind] = lab.measurement(build, kind, Lab.DUMMY_HEALTH, seconds, true)
			samples.append(sample)
		rows.append({"subject": subject, "character": build["character"], "samples": samples})
		var file := FileAccess.open(out + ".tmp", FileAccess.WRITE)
		if file == null:
			push_error("Cannot save parity measurements")
			quit(1)
			return
		file.store_string(JSON.stringify({"schema": 1, "level": level, "mastery": 1, "isolated": true,
			"seconds": seconds, "seeds": seeds, "balance": FileAccess.get_file_as_string("res://data/combat/gem_balance.json"), "rows": rows}, "  "))
		file.close()
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(out + ".tmp"), ProjectSettings.globalize_path(out)) != OK:
			push_error("Cannot publish parity checkpoint")
			quit(1)
			return
		print("PARITY_DONE %s %d seeds" % [subject, seeds])
	print("SKILL_PARITY_OK %d subjects" % rows.size())
	quit(0)
