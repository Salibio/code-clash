class_name JumpCommand
extends Command

var jump_gravity: float


func initialize(actor: CharacterBody2D, msg: Dictionary = {}) -> void:
	assert(msg.has("height") and msg["height"] is float)
	assert(msg.has("time_to_peak") and msg["time_to_peak"] is float)
	var height: float = msg["height"]
	var time_to_peak: float = msg["time_to_peak"]

	jump_gravity = (2.0 * height) / (time_to_peak * time_to_peak)
	actor.velocity.y = ((2.0 * height) / time_to_peak) * -1.0
	_to_active()


func execute(actor: CharacterBody2D, delta: float) -> void:
	if actor.velocity.y < 0.0:
		actor.velocity.y += jump_gravity * delta
	else:
		_to_complete()
