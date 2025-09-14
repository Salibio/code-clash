class_name EntityPlayer
extends Entity

@export
var code_edit: TextEdit
var env: ScriptEnvironment = ScriptEnvironment.new()

var run: bool = false


func _physics_process(delta: float) -> void:
	move_and_slide()
	if not env.is_running() and run:
		$StateMachine._transition_to_next_state("to_idle")
		run = false


func _on_run_pressed() -> void:
	run = true
	env.run_async(code_edit.text)
