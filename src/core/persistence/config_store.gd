extends RefCounted

const AtomicFile := preload("res://src/core/persistence/atomic_file.gd")
static var _reported: Dictionary = {}


static func read(path: String, validator: Callable = Callable()) -> Dictionary:
	var result := AtomicFile.read(path, _validate_text.bind(validator))
	var config := ConfigFile.new()
	if result["error"] == OK:
		config.parse(result["text"])
	result["config"] = config
	result.erase("text")
	var notice := "recovered" if result["recovered"] else str(result["error"])
	if _reported.get(path, "") != notice:
		_reported[path] = notice
		if result["recovered"]:
			push_warning("Configuracao recuperada do backup: %s" % path.get_file())
		elif result["error"] not in [OK, ERR_FILE_NOT_FOUND]:
			push_warning("Configuracao indisponivel (%d); arquivo preservado: %s" % [result["error"], path.get_file()])
	return result


static func update(path: String, sections: Dictionary, validator: Callable = Callable()) -> Error:
	var result := read(path, validator)
	# Without a recoverable config, never overwrite unrelated preferences.
	if result["error"] not in [OK, ERR_FILE_NOT_FOUND]:
		return result["error"] as Error
	var config: ConfigFile = result["config"]
	for section: String in sections:
		for key: String in sections[section]:
			config.set_value(section, key, sections[section][key])
	return AtomicFile.write(path, config.encode_to_text(), _validate_text.bind(validator))


static func _validate_text(text: String, validator: Callable) -> Error:
	var config := ConfigFile.new()
	if config.parse(text) != OK:
		return ERR_FILE_CORRUPT
	return validator.call(config) as Error if validator.is_valid() else OK
