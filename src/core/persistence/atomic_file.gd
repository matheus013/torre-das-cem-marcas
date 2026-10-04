extends RefCounted

## Single writer; all replacements stay on the destination filesystem.
static func read(path: String, validator: Callable) -> Dictionary:
	var primary := _read_one(path, validator)
	if primary["error"] not in [ERR_FILE_NOT_FOUND, ERR_FILE_CORRUPT]:
		return primary
	var backup := _read_one(path + ".bak", validator)
	if backup["error"] == OK:
		backup["recovered"] = true
		return backup
	return primary


static func write(path: String, text: String, validator: Callable) -> Error:
	var error: Error = validator.call(text)
	if error != OK:
		return error
	var previous := _read_one(path, validator)
	if previous["error"] not in [OK, ERR_FILE_NOT_FOUND, ERR_FILE_CORRUPT]:
		return previous["error"] as Error
	var temporary := path + ".tmp"
	error = _write_checked(temporary, text, validator)
	if error != OK:
		return error
	# Invalid primary data must not replace a good backup.
	if previous["error"] == OK or not FileAccess.file_exists(path + ".bak"):
		var backup_text: String = previous["text"] if previous["error"] == OK else text
		error = _write_checked(path + ".bak.tmp", backup_text, validator)
		if error == OK:
			error = DirAccess.rename_absolute(path + ".bak.tmp", path + ".bak")
		if error != OK:
			DirAccess.remove_absolute(temporary)
			return error
	# Do not delete the primary before replacing it.
	error = DirAccess.rename_absolute(temporary, path)
	if error != OK:
		DirAccess.remove_absolute(temporary)
	return error


static func _write_checked(path: String, text: String, validator: Callable) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	return _read_one(path, validator)["error"] as Error


static func _read_one(path: String, validator: Callable) -> Dictionary:
	var result := {"error": OK, "text": "", "source": path, "recovered": false}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		result["error"] = FileAccess.get_open_error()
		return result
	var text := file.get_as_text()
	var error := file.get_error()
	file.close()
	if error not in [OK, ERR_FILE_EOF]:
		result["error"] = error
		return result
	result["error"] = validator.call(text)
	if result["error"] == OK:
		result["text"] = text
	return result
