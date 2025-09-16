extends State


@export
var stats: EntityStats
@export
var sprite: AnimatedSprite2D


func _enter(actor: EntityPlayer, previous_state: State) -> void:
	sprite.play(&"idle")


func _physics_update(actor: EntityPlayer, delta: float) -> void:
	if not is_zero_approx(Input.get_axis("left", "right")):
		ctx.set_var(&"args", {})
		ctx.set_var(&"method_name", "walk_left" if Input.is_action_pressed("left") else "walk_right")
		transition_to("to_walk")
	if Input.is_action_pressed("jump") and actor.is_on_floor():
		transition_to("to_jump")

	if not actor.is_on_floor():
		transition_to("to_fall")
