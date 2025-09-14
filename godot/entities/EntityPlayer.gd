class_name EntityPlayer
extends Entity

@export
var code_edit: TextEdit
var env: ScriptEnvironment = ScriptEnvironment.new()


func _ready() -> void:
	env.finished.connect(func():
		$StateMachine._transition_to_next_state("to_idle")
	)


func _physics_process(delta: float) -> void:
	move_and_slide()


func _on_run_pressed() -> void:
	env.eval_async(code_edit.text)
