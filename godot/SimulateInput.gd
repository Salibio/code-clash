class_name SimulateInput
extends Node

# this epsilon is too big, but using 0.01 doesn't work.
var EPSILON: float = 0.1

var env: ScriptEnvironment = ScriptEnvironment.new()
@export
var fsm: StateMachine
@export
var code_edit: TextEdit


func _ready() -> void:
	var action := MethodInput.new()
	action.object_name = "hero"
	action.method_name = "jump"
	action.action_name = "jump"
	action.duration = 0.0
	action.callable = func(info: MethodInput, args: Dictionary) -> void:
		fsm.ctx.populate_from_dict({
			"args": args,
			"method_name": info.method_name,
		})
		action_pressed(info.action_name, info.duration)
	env.add_method(action)


	action = MethodInput.new()
	action.object_name = "hero"
	action.method_name = "walk_left"
	action.action_name = "left"
	action.duration = 1
	action.callable = func(info: MethodInput, args: Dictionary) -> void:
		fsm.ctx.populate_from_dict({
			"args": args,
			"method_name": info.method_name,
		})
		action_pressed(info.action_name, info.duration)
	env.add_method(action)


	action = MethodInput.new()
	action.object_name = "hero"
	action.method_name = "walk_right"
	action.action_name = "right"
	action.duration = 1
	action.callable = func(info: MethodInput, args: Dictionary) -> void:
		fsm.ctx.populate_from_dict({
			"args": args,
			"method_name": info.method_name,
		})
		action_pressed(info.action_name, info.duration)
	env.add_method(action)


func action_pressed(action_name: StringName, duration: float) -> void:
	Input.action_press(action_name)
	if duration < 0.0:
		duration = 0.0
	if is_zero_approx(duration):
		duration += EPSILON
	# TODO: what's better way to do this?
	await get_tree().create_timer(duration).timeout
	Input.action_release(action_name)


func _on_run_pressed() -> void:
	env.eval_async(code_edit.text)
