extends RefCounted

const AtomicFile := preload("res://src/core/persistence/atomic_file.gd")

## ERR_UNAVAILABLE from a validator means a newer format: never roll it back.

static func read(path: String, validator: Callable = Callable()) -> Dictionary:
	var result := AtomicFile.read(path, _validate_text.bind(validator))
	result["data"] = JSON.parse_string(result["text"]) if result["error"] == OK else {}
	result.erase("text")
	return result


static func write(path: String, data: Dictionary, validator: Callable = Callable()) -> Error:
	if validator.is_valid():
		var error: Error = validator.call(data)
		if error != OK:
			return error
	return AtomicFile.write(path, JSON.stringify(data), _validate_text.bind(validator))


static func _validate_text(text: String, validator: Callable) -> Error:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return ERR_FILE_CORRUPT
	return validator.call(json.data) as Error if validator.is_valid() else OK
