@tool
extends EntityState


#
# FUNCTIONS TO INHERIT IN YOUR STATES
#

# This function is called when the state enters
# XSM enters the root first, the the children
func _on_enter(_args) -> void:
	super(_args)
	agent.anim_tree_fsm.travel(&"dash")
	agent.anim_tree["parameters/dash/TimeScale/scale"] = agent.stats.dash_duration

	agent.dash_cmd.initialize(agent, {
		"magnitude": agent.stats.dash_distance,
		"time_to_peak": agent.stats.dash_duration,
		"direction": Vector2(agent._face_direction, 0.0),
		"preserve_velocity": true,
	})

	#agent.dash_cmd.actived.connect(
		#agent.gsc.set_expression_property.bind(&"is_dash_applied", true),
		#ConnectFlags.CONNECT_ONE_SHOT)
	#agent.dash_cmd.completed.connect(
		#agent.gsc.set_expression_property.bind(&"is_dash_applied", false),
		#ConnectFlags.CONNECT_ONE_SHOT)


# This function is called just after the state enters
# XSM after_enters the children first, then the parent
func _after_enter(_args) -> void:
	agent.input.get_action(ActionNames.dash).enter()


# This function is called each frame if the state is ACTIVE
# XSM updates the root first, then the children
func _on_update(_delta: float) -> void:
	agent.dash_cmd.execute(agent, _delta)

	if agent.dash_cmd.is_completed(self):
		if next_state.is_empty():
			change_state(&"Idle")
		else:
			change_to_next()
			next_state = ^""


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
	agent.input.action_release(ActionNames.dash)
	agent.anim_tree["parameters/dash/TimeScale/scale"] = 1.0


# when StateAutomaticTimer timeout()
func _state_timeout() -> void:
	pass


# Called when any other Timer times out
func _on_timeout(_name) -> void:
	pass
