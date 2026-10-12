extends SceneTree

## Lista os assuntos da sonda de builds (gemas ativas e autoataques), para o runner paralelo.

func _init() -> void:
	var lab: RefCounted = load("res://tools/bench/build_lab.gd").new()
	print("SUBJECTS " + ",".join(PackedStringArray(lab.call("subjects"))))
	quit(0)
