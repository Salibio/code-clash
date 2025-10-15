@tool
extends EntityState


#
# FUNCTIONS TO INHERIT IN YOUR STATES
#

# This function is called when the state enters
# XSM enters the root first, the the children
func _on_enter(_args) -> void:
	super(_args)
	agent.anim_tree_fsm.travel(ActionNames.walk)

	agent.move_cmd.initialize(agent, {
		"speed": agent.stats.speed,
		"direction": agent._face_direction,
	})

	agent.sprite.scale.x = agent._face_direction


# This function is called just after the state enters
# XSM after_enters the children first, then the parent
func _after_enter(_args) -> void:
	var info := agent.input.get_action(ActionNames.walk)
	info.enter()


# This function is called each frame if the state is ACTIVE
# XSM updates the root first, then the children
func _on_update(_delta: float) -> void:
	if agent.should_change_face_direction():
		return
	if agent.input.is_action_pressed(ActionNames.run):
		change_state(&"Run")
		return
	if agent.input.is_action_pressed(ActionNames.jump):
		change_state(&"Jump")
		return
	if agent.input.is_action_pressed(ActionNames.dash):
		get_state(&"Dash").next_state = get_state(&"Walk").get_path()
		change_state(&"Dash")
		return

	agent.move_cmd.execute(agent, _delta)
	if not agent.input.is_action_pressed(ActionNames.walk):
		change_state(&"Idle")
		return


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
	pass


# when StateAutomaticTimer timeout()
func _state_timeout() -> void:
	pass


# Called when any other Timer times out
func _on_timeout(_name) -> void:
	pass
