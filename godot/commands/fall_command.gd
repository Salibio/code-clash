class_name FallCommand
extends Command

var fall_gravity: float


func initialize(actor: CharacterBody2D, msg: Dictionary = {}) -> void:
	assert(msg.has("height") and msg["height"] is float)
	assert(msg.has("time_to_descent") and msg["time_to_descent"] is float)

	var height: float = msg["height"]
	var time_to_descent: float = msg["time_to_descent"]

	fall_gravity = (2.0 * height) / (time_to_descent * time_to_descent)
	_to_active()


func execute(actor: CharacterBody2D, delta: float) -> void:
	if actor.is_on_floor():
		_to_complete()
	else:
		actor.velocity.y += fall_gravity * delta
