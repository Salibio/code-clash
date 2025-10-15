@tool
extends EntityState

var _jumping := false

#
# FUNCTIONS TO INHERIT IN YOUR STATES
#

# This function is called when the state enters
# XSM enters the root first, the the children
func _on_enter(_args) -> void:
	super(_args)

	_jumping = true
	agent.anim_tree_fsm.travel(&"jump")
	agent.anim_tree.get_animation(&"jump").length = agent.stats.jump_time_to_peak
	agent.jump_cmd.initialize(agent, {
		"magnitude": agent.stats.jump_height,
		"time_to_peak": agent.stats.jump_time_to_peak,
		"direction": Vector2.UP,
		"preserve_velocity": true,
	})


# This function is called just after the state enters
# XSM after_enters the children first, then the parent
func _after_enter(_args) -> void:
	agent.input.get_action(ActionNames.jump).enter()

# This function is called each frame if the state is ACTIVE
# XSM updates the root first, then the children
func _on_update(_delta: float) -> void:
	if _jumping:
		agent.jump_cmd.execute(agent, _delta)

		if agent.jump_cmd.is_completed(agent):
			agent.anim_tree_fsm.travel(&"fall")
			agent.anim_tree.get_animation(&"fall").length = agent.stats.jump_time_to_descent
			agent.fall_cmd.initialize(agent, {
				"height": agent.stats.jump_height,
				"time_to_descent": agent.stats.jump_time_to_descent,
			})
			_jumping = false
	else:
		var v := agent.jump_cmd.is_completed(agent)
		agent.fall_cmd.execute(agent, _delta)

		if agent.fall_cmd.is_completed(agent):
			change_state(&"Ground")


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
	agent.input.action_release(ActionNames.jump)


# when StateAutomaticTimer timeout()
func _state_timeout() -> void:
	pass


# Called when any other Timer times out
func _on_timeout(_name) -> void:
	pass
