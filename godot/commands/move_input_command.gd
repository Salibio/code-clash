class_name MoveInputCommand
extends Command


@export
var sprite: AnimatedSprite2D
@export
var key_name: StringName
var speed: float = 0


func initialize(actor: CharacterBody2D, msg: Dictionary = {}) -> void:
	speed = get_var(msg, "speed", typeof(speed))

	sprite.play(key_name)
	_to_active()


func execute(actor: EntityPlayer, delta: float) -> void:
	var direction := Input.get_axis("left", "right")

	if direction:
		actor.velocity.x = direction * speed
	else:
		actor.velocity.x = move_toward(actor.velocity.x, 0, speed)
		if is_zero_approx(actor.velocity.x):
			_to_complete()

	if signf(actor.velocity.x) != 0:
		actor.sprite.flip_h = actor.velocity.x < 0
