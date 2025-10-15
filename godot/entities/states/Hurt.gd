@tool
extends EntityState


#
# FUNCTIONS TO INHERIT IN YOUR STATES
#

# This function is called when the state enters
# XSM enters the root first, the the children
func _on_enter(_args) -> void:
	super(_args)
	# TODO: delaying sending event to gsc by one frame will fix the issue of immidiately switching to to_idle animation.
	# will be using .start for temporary fix.
	agent.anim_tree_fsm.start(&"hurt")
	agent.velocity = Vector2.ZERO


# This function is called just after the state enters
# XSM after_enters the children first, then the parent
func _after_enter(_args) -> void:
	#agent.input.resume_if_waiting()
	#agent.input.action_as_active()
	pass


# This function is called each frame if the state is ACTIVE
# XSM updates the root first, then the children
func _on_update(_delta: float) -> void:
	if agent.anim_tree_fsm.get_current_node() == "idle":
		change_state(&"Idle")


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
	#agent.input.action_as_inactive()
	pass


# when StateAutomaticTimer timeout()
func _state_timeout() -> void:
	pass


# Called when any other Timer times out
func _on_timeout(_name) -> void:
	pass
