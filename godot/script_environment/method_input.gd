class_name MethodInput
extends Resource


var object_name: String
var method_name: String
var action_name: StringName
var callable: Callable
var duration: float = 0.0 # time_sec
var one_shot: bool:
	set(value):
		if value:
			duration = 0.0
	get:
		return is_zero_approx(duration)

var params_schema: Array[Dictionary] = []
