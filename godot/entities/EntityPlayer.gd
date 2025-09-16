class_name EntityPlayer
extends Entity

@export
var code_edit: TextEdit
@export
var input: SimulateInput
@export
var sprite: AnimatedSprite2D

@export
var fall_cmd: FallCommand
@export
var move_cmd: MoveInputCommand
@export
var jump_cmd: JumpCommand
@export
var stats: EntityStats
@export
var gsc: StateChart


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED


func _physics_process(delta: float) -> void:
	move_and_slide()


func _on_idle_state_entered() -> void:
	sprite.play(&"idle")

func _on_idle_state_physics_processing(delta: float) -> void:
	if signf(Input.get_axis("left", "right")) != 0.0:
		gsc.send_event("to_walking")


func _on_walk_state_entered() -> void:
	move_cmd.initialize(self, {
		"speed": stats.speed,
	})

func _on_walk_state_physics_processing(delta: float) -> void:
	move_cmd.execute(self, delta)

	if move_cmd.is_completed(self):
		gsc.send_event("to_idle")

func _on_walk_state_exited() -> void:
	input.env.poll()


func _on_grounded_state_physics_processing(delta: float) -> void:
	if Input.is_action_pressed("jump"):
		gsc.send_event("to_jump")

	if not is_on_floor():
		gsc.send_event("to_falling")


func _on_jump_state_entered() -> void:
	sprite.play(&"jump")
	print("_on_jump_state_entered enter")
	jump_cmd.initialize(self, {
		"height": stats.jump_height,
		"time_to_peak": stats.jump_time_to_peak,
	})

func _on_jump_state_physics_processing(delta: float) -> void:
	print("_on_jump_state_physics_processing enter")
	jump_cmd.execute(self, delta)

	if jump_cmd.is_completed(self):
		gsc.send_event("to_falling")


func _on_falling_state_entered() -> void:
	sprite.play(&"fall")
	fall_cmd.initialize(self, {
		"height": stats.jump_height,
		"time_to_descent": stats.jump_time_to_descent,
	})

func _on_falling_state_physics_processing(delta: float) -> void:
	fall_cmd.execute(self, delta)

	if fall_cmd.is_completed(self):
		gsc.send_event("to_grounded")

func _on_falling_state_exited() -> void:
	input.env.poll()
