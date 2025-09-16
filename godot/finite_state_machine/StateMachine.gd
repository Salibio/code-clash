class_name StateMachine
extends Node


## The initial state of the state machine. If not set, the first child node is used.
@export
var initial_state: State = null

@onready
var _states: Dictionary

## The current state of the state machine.
@onready
var state: State

## The main actor this state machine controls. Defaults to parent node if not set.
@export
var actor: Node = null

## Shared context passed to all _states for storing and accessing data.
@onready
var ctx: Context = Context.new()


## Initializes the state machine by collecting all child State nodes,
## connecting signals, assigning the actor, and entering the initial state.
func _ready() -> void:
	if actor == null:
		actor = get_parent()

	for state_node: State in find_children("*", "State"):
		if state_node.event_name.is_empty():
			state_node.event_name = name
		_states[state_node.event_name] = state_node
		state_node.fsm = self
		state_node.ctx = ctx
		state_node._setup(actor)

	if initial_state == null:
		if get_child_count() == 0:
			push_error(name, " must have _states.")
			return
		if get_child(0) is State:
			state = get_child(0)
		else:
			push_error(name, ".get_child(0) must be type State.")
			return
	else:
		state = initial_state

	state._enter(actor, null)
	state.entered.emit()


## Transitions from the current state to the target state
## using the provided event name. Handles exit/enter calls
## and emits the appropriate signals.
func _transition_to_next_state(event_name: String) -> void:
	if not _states.has(event_name):
		printerr(actor.name + ": Trying to transition to state '" + event_name + "' but it does not exist.")
		return

	var previous_state := state

	state._exit(actor)
	state.exited.emit()

	state = _states.get(event_name)

	print("enter: ", state.name)
	state._enter(actor, previous_state)
	state.entered.emit()


### Updates the current state every frame (non-physics).
#func _process(delta: float) -> void:
	#state._update(actor, delta)
#
#
### Updates the current state every physics frame.
#func _physics_process(delta: float) -> void:
	#state._physics_update(actor, delta)
#
#
### Forwards unhandled input events to the current state.
#func _unhandled_input(event: InputEvent) -> void:
	#state._handle_input(actor, event)
#
#
### Forwards unhandled key input events to the current state.
#func _unhandled_key_input(event: InputEvent) -> void:
	#state._handle_key_input(actor, event)
