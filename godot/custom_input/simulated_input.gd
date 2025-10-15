class_name SimulateInput
extends CustomInput

# this epsilon is too big, but using 0.01 doesn't work.
var EPSILON: float = 0.1

var _env: JSEnvironment = JSEnvironment.new()

var _actions: Dictionary[String, MethodInput] = {}
var _one_shot_actions_count := 0
signal one_shot_action_finished
var _timers: Array[Timer] = []

# required variables.
var _sync: Syncronizer

var state_can_resume := true


var env: JSEnvironment:
	get: return _env


func _init(sync: Syncronizer) -> void:
	_sync = sync
	env.finished.connect(func() -> void:
		clear())
	var entry := new_action()

	# ==================
	# Persistent Actions
	# ==================
	entry = new_action()
	entry.action_name = ActionNames.idle
	entry.path = "hero.dev.idle"
	entry.callable = func(info: MethodInput, args: Dictionary) -> bool:
		print_rich("[color=green]idle[/color]")
		clear()
		_action_pressed(ActionNames.idle, info)
		info.entered.connect(func() -> void:
			clear()
			_env.resume()
			print("entered"))
		return true
	_env.add_method_v2(entry)

	entry = new_action()
	entry.action_name = ActionNames.walk
	entry.path = "hero.dev.walk"
	entry.callable = func(info: MethodInput, args: Dictionary) -> bool:
		print_rich("[color=green]walk[/color]")
		_action_pressed(ActionNames.walk, info)
		info.entered.connect(_env.resume.bind())
		return true
	_env.add_method_v2(entry)

	entry = new_action()
	entry.action_name = ActionNames.left
	entry.path = "hero.dev.face_left"
	entry.callable = func(info: MethodInput, args: Dictionary) -> bool:
		print_rich("[color=green]face_left[/color]")
		action_release(ActionNames.right)
		_action_pressed(ActionNames.left, info)
		info.entered.connect(_env.resume.bind())
		return true
	_env.add_method_v2(entry)

	entry = new_action()
	entry.action_name = ActionNames.right
	entry.path = "hero.dev.face_right"
	entry.callable = func(info: MethodInput, args: Dictionary) -> bool:
		print_rich("[color=green]face_right[/color]")
		action_release(ActionNames.left)
		_action_pressed(ActionNames.right, info)
		info.entered.connect(_env.resume.bind())
		return true
	_env.add_method_v2(entry)

	entry = new_action()
	entry.action_name = ActionNames.run
	entry.path = "hero.dev.run"
	entry.callable = func(info: MethodInput, args: Dictionary) -> bool:
		print_rich("[color=green]run[/color]")
		_action_pressed(ActionNames.run, info)
		info.entered.connect(_env.resume.bind())
		return true
	_env.add_method_v2(entry)

	# ================
	# One-Shot Actions
	# ================
	entry = new_action()
	entry.action_name = ActionNames.jump
	entry.one_shot = true
	entry.path = "hero.dev.jump"
	entry.callable = func(info: MethodInput, args: Dictionary) -> bool:
		print_rich("[color=green]jump[/color]")
		_action_pressed(ActionNames.jump, info)
		info.entered.connect(_env.resume.bind())
		return true
	_env.add_method_v2(entry)

	entry = new_action()
	entry.action_name = ActionNames.dash
	entry.one_shot = true
	entry.path = "hero.dev.dash"
	entry.callable = func(info: MethodInput, args: Dictionary) -> bool:
		print_rich("[color=green]dash[/color]")
		_action_pressed(ActionNames.dash, info)
		info.entered.connect(_env.resume.bind())
		info.entered.connect(print.bind("dash resume"))
		return true
	_env.add_method_v2(entry)

	# ================
	# Non-Actions
	# ================
	entry = new_action()
	entry.path = "hero.dev.print"
	entry.params_schema = [{
		"name": "str",
		"type": "String",
		# "default": 1.0,
	}]
	entry.callable = func(info: MethodInput, args: Dictionary) -> void:
		print_rich("[color=green]USER[/color]: ", args["str"])
	_env.add_method_v2(entry)

	entry = new_action()
	entry.path = "hero.dev.wait_for_action"
	entry.callable = func(info: MethodInput, args: Dictionary) -> bool:
		print_rich("[color=green]wait_for_action[/color]")
		if not has_one_shot_actions():
			return false
		print_rich("[color=green]connect[/color]")
		one_shot_action_finished.connect.call_deferred(func() -> void:
			_env.resume(), ConnectFlags.CONNECT_ONE_SHOT)
		return true
	_env.add_method_v2(entry)

	entry = new_action()
	entry.params_schema = [{
		"name": "duration",
		"type": "float",
		# "default": 1.0,
	}]
	entry.path = "hero.dev.wait"
	entry.callable = func(info: MethodInput, args: Dictionary) -> bool:
		if not args.has("duration"):
			push_error("missing argument 'duration' for method {0}".format(info.path))
			return false
		state_can_resume = false
		print_rich("[color=green]wait[/color]")

		var duration: float = maxf(args.get("duration", 0.0) as float, EPSILON)
		get_tree().create_timer(duration).timeout.connect(func() -> void:
			_env.resume()
			state_can_resume = true
		)
		return true
	_env.add_method_v2(entry)


func new_action() -> MethodInput:
	var action := MethodInput.new(_env)

	return action


func clear() -> void:
	# TODO: how about the timers?
	_actions.clear()


func _action_pressed(action: StringName, input: MethodInput) -> void:
	_actions.set(action, input)
	if input.one_shot:
		_one_shot_actions_count += 1


func get_action(action: StringName) -> MethodInput:
	if OS.is_debug_build() and _actions.has(action):
		push_warning("action named '{0}' not found.".format([action]))
	return _actions.get(action, MethodInput.new(_env))


func has_one_shot_actions() -> bool:
	return _one_shot_actions_count > 0

# === Overrides ===

func action_release(action: StringName) -> void:
	print_rich("[color=cyan]action_release[/color](", action, ")")
	if not _actions.has(action):
		return
	var info := _actions[action]
	if info.one_shot:
		_one_shot_actions_count = max(0, _one_shot_actions_count - 1)
		if _one_shot_actions_count == 0:
			one_shot_action_finished.emit()
	_actions[action].exit()
	_actions.erase(action)


func all_action_release(actions: Array[StringName]) -> void:
	for action: StringName in actions:
		action_release(action)


func is_action_pressed(action: StringName) -> bool:
	return _actions.has(action)


func is_any_action_pressed(actions: Array[StringName]) -> bool:
	return actions.any(func(a: StringName) -> bool: return is_action_pressed(a))


func get_axis(negative_action: StringName, positive_action: StringName) -> float:
	return float(is_action_pressed(positive_action)) - float(is_action_pressed(negative_action))
