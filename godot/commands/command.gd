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

func initialize(actor, msg: Dictionary = {}) -> void:
	pass


func execute(actor, delta: float):
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
