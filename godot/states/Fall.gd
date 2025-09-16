extends State


@export
var fall_cmd: FallCommand
@export
var move_cmd: MoveInputCommand
@export
var stats: EntityStats


func _enter(actor: EntityPlayer, previous_state: State) -> void:
	fall_cmd.initialize(actor, {
		"height": stats.jump_height,
		"time_to_descent": stats.jump_time_to_descent,
	})


func _physics_update(actor: EntityPlayer, delta: float) -> void:
	if actor.is_on_floor():
		transition_to("to_idle")
	else:
		fall_cmd.execute(actor, delta)


func _exit(actor: EntityPlayer) -> void:
	fall_cmd.complete(actor)
