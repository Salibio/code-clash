extends State


@export
var jump_cmd: JumpCommand
@export
var move_cmd: MoveCommand
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
	actor.env.add_new_method(
		"hero", "jump", self, arc_move_cmd, "to_jump", [])


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


func _update(actor: EntityPlayer, delta: float) -> void:
	if OS.is_debug_build() and not arc_move_cmd.is_active(actor) and ctx.get_var("is_keyboard", false):
		transition_to("to_idle")
	if not arc_move_cmd.is_active(actor):
		return

	arc_move_cmd.execute(actor, delta)

	if not arc_move_cmd.going_up and sprite.animation == "jump":
		sprite.play("fall")
	if arc_move_cmd.is_completed(actor):
		transition_to("to_idle")

	if stats:
		move_cmd.initialize(actor, {
			"direction": Input.get_axis("left", "right"),
			"duration": stats.move_duration,
			"speed": stats.speed,
		})


func _exit(actor: EntityPlayer) -> void:
	if jump_cmd:
		jump_cmd.complete(actor)
	arc_move_cmd.complete(actor)
