class_name AppVersion
extends RefCounted


static func current() -> String:
	if FileAccess.file_exists("res://VERSION"):
		var version := FileAccess.get_file_as_string("res://VERSION").strip_edges()
		if not version.is_empty():
			return version
	return str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
