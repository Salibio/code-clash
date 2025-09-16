extends State


@export
var move_cmd: MoveInputCommand
@export
var arc_move_cmd: ArcMoveCommand
@export
var stats: EntityStats
@export
var fall_state: State
@export
var sprite: AnimatedSprite2D

var upward: bool = false


func _setup(actor: EntityPlayer) -> void:
	#actor.env.add_new_method(
		#"hero", "jump", self, arc_move_cmd, "to_jump", [])
	pass


func _enter(actor: EntityPlayer, previous_state: State) -> void:
	if arc_move_cmd and stats:
		arc_move_cmd.initialize(actor, {
			"distance": stats.jump_height,
			"time_to_accelerate": stats.jump_time_to_peak,
			"time_to_decelerate": stats.jump_time_to_descent,
			"direction": Vector2.UP,
		})
		upward = true
		sprite.play("jump")


func _physics_update(actor: EntityPlayer, delta: float) -> void:
	arc_move_cmd.execute(actor, delta)

	if not arc_move_cmd.going_up and sprite.animation == "jump":
		sprite.play("fall")
	if arc_move_cmd.is_idle(actor):
		transition_to("to_idle")

	if stats:
		move_cmd.initialize(actor, {
			"direction": Vector2(Input.get_axis("left", "right"), 0),
			"duration": stats.move_duration,
			"speed": stats.speed,
		})


func _exit(actor: EntityPlayer) -> void:
	arc_move_cmd.complete(actor)
	actor.input.env.poll()
