extends RefCounted

## Single-writer store. Temporary files share the destination filesystem.
## ERR_UNAVAILABLE from a validator means a newer format: never roll it back.

static func read(path: String, validator: Callable = Callable()) -> Dictionary:
	var primary := _read_one(path, validator)
	if primary["error"] == OK:
		return primary
	if primary["error"] not in [ERR_FILE_NOT_FOUND, ERR_FILE_CORRUPT]:
		return primary
	var backup := _read_one(path + ".bak", validator)
	if backup["error"] == OK:
		backup["recovered"] = true
		return backup
	return primary


static func write(path: String, data: Dictionary, validator: Callable = Callable()) -> Error:
	var validation := _validate(data, validator)
	if validation != OK:
		return validation
	var previous := _read_one(path, validator)
	if previous["error"] not in [OK, ERR_FILE_NOT_FOUND, ERR_FILE_CORRUPT]:
		return previous["error"] as Error
	var temporary := path + ".tmp"
	var error := _write_checked(temporary, data, validator)
	if error != OK:
		return error
	# A corrupt primary must not replace the last good backup.
	if previous["error"] == OK or not FileAccess.file_exists(path + ".bak"):
		var backup_data: Dictionary = previous["data"] if previous["error"] == OK else data
		error = _write_checked(path + ".bak.tmp", backup_data, validator)
		if error == OK:
			error = DirAccess.rename_absolute(path + ".bak.tmp", path + ".bak")
		if error != OK:
			DirAccess.remove_absolute(temporary)
			return error
	# Never delete the primary before replacing it.
	error = DirAccess.rename_absolute(temporary, path)
	if error != OK:
		DirAccess.remove_absolute(temporary)
	return error


static func _write_checked(path: String, data: Dictionary, validator: Callable) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	return _read_one(path, validator)["error"] as Error


static func _read_one(path: String, validator: Callable) -> Dictionary:
	var result := {"error": OK, "data": {}, "source": path, "recovered": false}
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
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		result["error"] = ERR_FILE_CORRUPT
		return result
	result["error"] = _validate(json.data, validator)
	if result["error"] == OK:
		result["data"] = json.data
	return result


static func _validate(data: Dictionary, validator: Callable) -> Error:
	return validator.call(data) as Error if validator.is_valid() else OK
