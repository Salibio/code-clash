class_name ImpulseCommand
extends Command

var acceleration: float
var direction: Vector2
var last_velocity: Vector2

func initialize(actor: CharacterBody2D, msg: Dictionary = {}) -> void:
	assert(msg.has("magnitude") and msg["magnitude"] is float)
	assert(msg.has("time_to_peak") and msg["time_to_peak"] is float)
	assert(msg.has("direction") and msg["direction"] is Vector2)

	var magnitude: float = msg["magnitude"] # how far to travel in that direction
	var time_to_peak: float = msg["time_to_peak"]
	var preserve_velocity: bool = msg.get("preserve_velocity", false)
	direction = (msg["direction"] as Vector2).normalized()

	acceleration = (2.0 * magnitude) / (time_to_peak * time_to_peak)
	if preserve_velocity:
		last_velocity = actor.velocity
	else:
		last_velocity = Vector2.ZERO
	actor.velocity += direction * ((2.0 * magnitude) / time_to_peak)

	_to_active()


func execute(actor: CharacterBody2D, delta: float) -> void:
	# apply deceleration opposite to the impulse direction
	if actor.velocity.dot(direction) - last_velocity.length() > 0.0:
		actor.velocity -= direction * acceleration * delta
	else:
		_to_complete()

# TODO: internals: maybe a bug, after making the `Command.execute` to be non-abstract, somehow, the code analyzer still recognize it as abstract.
# probably its because of many classes implemented `Command.execute`.
