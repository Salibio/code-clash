class_name MoveInputCommand
extends Command


var _sprite: AnimatedSprite2D
var _speed: float = 0
var _direction: float = 0


func _init(sprite: AnimatedSprite2D) -> void:
	_sprite = sprite


func initialize(actor: CharacterBody2D, msg: Dictionary = {}) -> void:
	_speed = get_var(msg, "speed", typeof(_speed))
	_direction = get_var(msg, "direction", typeof(_direction))

	_to_active()


func execute(actor: EntityPlayer, delta: float) -> void:
	var direction: float = signf(_direction)

	if direction:
		actor.velocity.x = move_toward(actor.velocity.x, _direction * _speed, _speed * 0.5)
	else:
		actor.velocity.x = move_toward(actor.velocity.x, 0, _speed * 0.2)
		if is_zero_approx(actor.velocity.x):
			_to_complete()


func change_direction(direction: float) -> void:
	_direction = signf(direction)
