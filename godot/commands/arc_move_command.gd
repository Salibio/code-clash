class_name ArcMoveCommand
extends Command

var distance: float
var time_to_accelerate: float
var time_to_decelerate: float
var direction: Vector2

var acceleration_up: float
var acceleration_down: float
var initial_velocity: float
var going_up: bool = true


func initialize(actor: CharacterBody2D, msg: Dictionary = {}) -> void:
	assert(msg.has("distance") and msg["distance"] is float)
	assert(msg.has("time_to_accelerate") and msg["time_to_accelerate"] is float)
	assert(msg.has("time_to_decelerate") and msg["time_to_decelerate"] is float)
	assert(msg.has("direction") and msg["direction"] is Vector2)

	distance = msg["distance"]
	time_to_accelerate = msg["time_to_accelerate"]
	time_to_decelerate = msg["time_to_decelerate"]
	direction = (msg["direction"] as Vector2).normalized()

	# Kinematics
	acceleration_up = (2.0 * distance) / (time_to_accelerate * time_to_accelerate)
	acceleration_down = (2.0 * distance) / (time_to_decelerate * time_to_decelerate)
	initial_velocity = (2.0 * distance) / time_to_accelerate

	# Start movement
	actor.velocity = direction * initial_velocity
	going_up = true
	_to_active()


func execute(actor: CharacterBody2D, delta: float) -> void:
	if not is_active(actor):
		return

	if going_up:
		# Decelerate along direction
		actor.velocity -= direction * acceleration_up * delta
		if actor.velocity.dot(direction) <= 0.0:
			going_up = false
	else:
		# Accelerate opposite direction
		actor.velocity -= direction * acceleration_down * delta

		if actor.is_on_floor():
			_to_idle()


func complete(actor: CharacterBody2D) -> void:
	actor.velocity = Vector2.ZERO
	going_up = false
	_to_complete()
