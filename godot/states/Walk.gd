# is this really walk?
extends State


@export
var move_cmd: MoveInputCommand
@export
var stats: EntityStats
@export
var sprite: AnimatedSprite2D

var direction: Vector2


func _setup(actor: EntityPlayer) -> void:
	#actor.env.add_new_method(
		#"hero", "walk_left", self, move_cmd, "to_walk", [
			#{"name": "step", "default_value": 1, "type": type_string(TYPE_INT)},
		#])
	#actor.env.add_new_method(
		#"hero", "walk_right", self, move_cmd, "to_walk", [
			#{"name": "step", "default_value": 1, "type": type_string(TYPE_INT)},
		#])
	pass

# TODO: running animation always reset, in keyboard input.
# TODO: combining user script and keyboard input can lead to unexpected result.
func _enter(actor: EntityPlayer, previous_state: State) -> void:
	if move_cmd and stats:
		var args: Dictionary = ctx.get_var("args", {})
		var method_name: String = ctx.get_var("method_name")

		if method_name == "walk_right":
			direction = Vector2.RIGHT
		elif method_name == "walk_left":
			direction = Vector2.LEFT

		move_cmd.initialize(actor, {
			"direction": direction,
			"speed": stats.speed,
		})


func _physics_update(actor: EntityPlayer, delta: float) -> void:
	move_cmd.execute(actor, delta)

	if is_zero_approx(Input.get_axis("left", "right")):
		transition_to("to_idle")
	else:
		ctx.populate_from_dict({
			"method_name": "walk_right" if Input.get_axis("left", "right") > 0.0 else "walk_left"
		})
		transition_to("to_walk")

	if Input.is_action_pressed("jump"):
		transition_to("to_jump")


func _exit(actor: EntityPlayer) -> void:
	move_cmd.complete(actor)
	actor.input.env.poll()
