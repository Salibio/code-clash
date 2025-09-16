class_name Context
extends RefCounted


var _variables: Dictionary = {}


func set_var(var_name: StringName, value: Variant) -> void:
	_variables[var_name] = value


func get_var(var_name: StringName, default: Variant = null, complain: bool = true) -> Variant:
	if not _variables.has(var_name) and default == null:
		push_error("Context: Variable \"{0}\" not found.".format([var_name]))
	return _variables.get(var_name, default)


func erase_var(var_name: StringName) -> void:
	if not _variables.has(var_name):
		push_error("Context: Can't unset variable that doesn't exist (name: {0})".format([var_name]))
		return
	_variables.erase(var_name)


func populate_from_dict(dict: Dictionary, overwrite: bool = true) -> void:
	var is_str_all := dict.values().all(
		func(e) -> bool:
			return e is String or e is StringName)
	if not is_str_all:
		push_error("Context: Invalid key type in dictionary to populate context. Must be StringName or String.")
		return
	_variables.merge(dict, overwrite)


func has_var(var_name: StringName) -> bool:
	return _variables.has(var_name)


func as_dict() -> Dictionary:
	return _variables


func list_vars() -> Array[StringName]:
	return _variables.keys()


func list_values() -> Array[Variant]:
	return _variables.values()


func clear() -> void:
	_variables.clear()
