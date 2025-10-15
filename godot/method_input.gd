class_name MethodInput
extends Resource

var object_name: String
var method_name: String
var action_name: StringName = ActionNames.none
var path: String
# key = action, value = duration
var actions: Dictionary[String, float]
# return true to pause _env
var callable: Callable
var one_shot: bool

var params_schema: Array[Dictionary] = []

var _env: JSEnvironment
signal entered
signal exited


func _init(env: JSEnvironment) -> void:
	_env = env


#func resume() -> void:
	#_env.resume()


func enter() -> void:
	entered.emit()
	for ref: Dictionary in entered.get_connections():
		entered.disconnect(ref.get("callable") as Callable)


func exit() -> void:
	exited.emit()
