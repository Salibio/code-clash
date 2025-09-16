@abstract
class_name Command
extends Node

enum Status {
	Active,
	Idle,
	Complete,
}

signal actived
signal idled
signal completed

var _status: Status = Status.Complete


@abstract
func initialize(actor, msg: Dictionary = {}) -> void


func set_msg(actor, msg: Dictionary) -> void:
	push_error(name, ".set_msg() not implemented.")


func execute(actor, delta: float) -> void:
	pass


func complete(actor) -> void:
	_to_complete()


func is_active(actor) -> bool:
	return _status == Status.Active


func is_idle(actor) -> bool:
	return _status == Status.Idle

# TODO: rename this to is_complete
func is_completed(actor) -> bool:
	return _status == Status.Complete


func _to_active() -> void:
	_status = Status.Active
	actived.emit()


func _to_idle() -> void:
	_status = Status.Idle
	idled.emit()


func _to_complete() -> void:
	_status = Status.Complete
	completed.emit()


func get_var(msg: Dictionary, var_name: StringName, expected_type: Variant.Type) -> Variant:
	assert(msg.has(var_name), "{0} is expected.".format([var_name]))
	assert(typeof(msg[var_name]) == expected_type, "{0} is expected to be of type {1}, but got {2}."
		.format([var_name, expected_type, type_string(typeof(msg[var_name]))]))
	return msg[var_name]
