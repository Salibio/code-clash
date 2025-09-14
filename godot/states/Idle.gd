extends State


@export
var stats: EntityStats
@export
var sprite: AnimatedSprite2D


func _enter(actor: EntityPlayer, previous_state: State) -> void:
	sprite.play(&"idle")


func _update(actor: EntityPlayer, delta: float) -> void:
	if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
		ctx.set_var(&"is_keyboard", true)
		ctx.set_var(&"args", {"step": 2})
		ctx.set_var(&"method_name", "walk_left" if Input.is_action_pressed("left") else "walk_right")
		transition_to("to_walk")
	if Input.is_action_pressed("jump"):
		ctx.set_var("is_keyboard", true)
		transition_to("to_jump")

	if not actor.is_on_floor():
		transition_to("to_fall")
