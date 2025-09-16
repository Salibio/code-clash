extends Node2D

var sema := Semaphore.new()

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	print("hold: ", Input.is_action_pressed("jump"), ", just: ", Input.is_action_just_pressed("jump"))


func _on_button_pressed() -> void:
	var ev := InputEventAction.new()
	ev.action = "jump"
	ev.pressed = true
	Input.parse_input_event(ev)
	#await get_tree().create_timer(0.0).timeout
	#ev.pressed = false
	#Input.parse_input_event(ev)
