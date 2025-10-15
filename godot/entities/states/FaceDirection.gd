@tool
extends EntityState

#
# FUNCTIONS TO INHERIT IN YOUR STATES
#
var _direction_name: StringName

# This function is called when the state enters
# XSM enters the root first, the the children
func _on_enter(new_direction: float) -> void:
	super(new_direction)
	new_direction = sign(new_direction)
	_direction_name = ActionNames.left if new_direction < 0 else ActionNames.right
	agent._face_direction = new_direction

	agent.sprite.scale.x = new_direction
	agent.move_cmd.change_direction(new_direction)


# This function is called just after the state enters
# XSM after_enters the children first, then the parent
func _after_enter(_args) -> void:
	agent.input.get_action(_direction_name).enter()
	if next_state.is_empty():
		change_state(&"Idle")
	else:
		change_to_next()


# This function is called each frame if the state is ACTIVE
# XSM updates the root first, then the children
func _on_update(_delta: float) -> void:
	pass


# This function is called each frame after all the update calls
# XSM after_updates the children first, then the root
func _after_update(_delta: float) -> void:
	pass


# This function is called before the State exits
# XSM before_exits the root first, then the children
func _before_exit(_args) -> void:
	pass


# This function is called when the State exits
# XSM exits the children first, then the root
func _on_exit(_args) -> void:
	agent.input.action_release(_direction_name)


# when StateAutomaticTimer timeout()
func _state_timeout() -> void:
	pass


# Called when any other Timer times out
func _on_timeout(_name) -> void:
	pass
