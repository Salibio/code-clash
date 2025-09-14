class_name MoveCommand
extends Command

var direction: float = 0.0
var duration: float = 0.0
var elapsed: float = 0.0
var speed: float

var _actor: CharacterBody2D


func initialize(actor: CharacterBody2D, msg: Dictionary = {}) -> void:
	assert(msg.has("direction") and msg["direction"] is float)
	assert(msg.has("duration") and msg["duration"] is float)
	assert(msg.has("speed") and msg["speed"] is float)

	if is_zero_approx(msg["direction"]):
		return

	direction = sign(msg["direction"])
	duration = msg["duration"]
	speed = msg["speed"]
	elapsed = 0.0

	_actor = actor
	_to_active()


func execute(actor: CharacterBody2D, delta: float):
	if not is_active(actor):
		return

	elapsed += delta
	actor.position.x += direction * speed * delta

	if elapsed >= duration:
		_to_idle()


func _physics_process(delta: float) -> void:
	execute(_actor, delta)


func complete(actor: CharacterBody2D) -> void:
	elapsed = duration
	_to_complete()
