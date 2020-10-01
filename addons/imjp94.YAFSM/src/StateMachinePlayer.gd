tool
extends Node
const State = preload("states/State.gd")

signal entry(state_machine)
signal exit(state_machine)
signal state_changed(from, to)
signal state_entered(to)
signal state_exited(from)
signal state_update(state, delta)

enum ProcessMode {
	PHYSICS,
	IDLE,
	MANUAL
}

enum RESET_EVENT_TRIGGER {
	NONE = -1,
	ALL = 0,
	LAST_TO_DEST = 1
}

export(Resource) var state_machine
export(Dictionary) var parameters
export(ProcessMode) var process_mode = ProcessMode.IDLE setget set_process_mode

var current_state setget , get_current_state
var state_stack = []

var _is_update_locked = false
var _was_transited = false # If last transition was successful


func _init(p_parameters={}):
	parameters = p_parameters

func _get_configuration_warning():
	if state_machine:
		if not state_machine.has_entry():
			return "State Machine will not function properly without Entry node"
	else:
		return "State Machine Player is not going anywhere without default State Machine"
	return ""

func _ready():
	if Engine.editor_hint:
		return

	_on_process_mode_changed()
	_push_state(state_machine.get_entry().to)
	_transition()

func _process(delta):
	if Engine.editor_hint:
		return

	_update_start()
	update(delta)
	_update_end()

func _physics_process(delta):
	if Engine.editor_hint:
		return

	_update_start()
	update(delta)
	_update_end()

func _push_state(to):
	var from = get_current_state()
	_exit(to)
	state_stack.push_back(to)
	_enter(from)
	emit_signal("state_changed", from, to)

func _pop_state():
	if state_stack.size() == 1:
		_on_pop_last_state()
		return

	var to = get_previous_state()
	_exit(to)
	var from = state_stack.pop_back()
	_enter(from)
	emit_signal("state_changed", from, to)

func _on_pop_last_state():
	pass

func _enter(from):
	var to = get_current_state()
	if to:
		if to == State.EXIT_KEY:
			emit_signal("exit", state_machine)
		emit_signal("state_entered", from, to)

func _exit(to):
	var from = get_current_state()
	if from:
		if from == State.ENTRY_KEY:
			emit_signal("entry", state_machine)
		emit_signal("state_exited", from)

# Only get called in 2 condition, parameters edited or last transition was successful
func _transition():
	var next_state = state_machine.states[get_current_state()].transit(parameters)
	if next_state:
		if state_stack.has(next_state):
			reset(state_stack.find(next_state))
		else:
			_push_state(next_state)
	_was_transited = !!next_state
	_flush_trigger()

func _update_start():
	_is_update_locked = false

func _update_end():
	_is_update_locked = true

# Called after update() which is dependant on process_mode, override to process current state
func _on_update(delta, state):
	pass

func _on_process_mode_changed():
	match process_mode:
		ProcessMode.PHYSICS:
			set_physics_process(true)
			set_process(false)
		ProcessMode.IDLE:
			set_physics_process(false)
			set_process(true)
		ProcessMode.MANUAL:
			set_physics_process(false)
			set_process(false)

func update(delta):
	if _was_transited: # Attempt to transit if last transition was successful
		_transition()
	if process_mode != ProcessMode.MANUAL:
		assert(not _is_update_locked, "Attempting to update manually with ProcessMode.%s" % ProcessMode.keys()[process_mode])
	var current_state = get_current_state()
	_on_update(current_state, delta)
	emit_signal("state_update", current_state, delta)

func reset(to=0, event=RESET_EVENT_TRIGGER.LAST_TO_DEST):
	assert(to > -1)
	var last_index = state_stack.size() - 1
	var first_state = ""
	var num_to_pop = last_index - to

	if num_to_pop > 0:
		for i in range(num_to_pop):
			first_state = get_current_state() if i == 0 else first_state
			match event:
				RESET_EVENT_TRIGGER.LAST_TO_DEST:
					state_stack.pop_back()
					if i == num_to_pop - 1:
						state_stack.push_back(first_state)
						_pop_state()
				RESET_EVENT_TRIGGER.ALL:
					_pop_state()
				_:
					state_stack.pop_back()
	elif num_to_pop == 0:
		match event:
			RESET_EVENT_TRIGGER.NONE:
				state_stack.pop_back()
			_:
				_pop_state()
	else:
		print("Error: state_stack_last_index(%d) - to_index(%d) < 0(%d)" % [last_index, to, num_to_pop])
		assert(num_to_pop >= 0)

func _flush_trigger():
	for param_key in parameters.keys():
		var value = parameters[param_key]
		if value == null: # Param with null as value is treated as trigger
			parameters.erase(param_key)

func _on_param_edited():
	_transition()

func set_trigger(name):
	parameters[name] = null
	_on_param_edited()

func set_param(name, value):
	parameters[name] = value
	_on_param_edited()

func erase_param(name):
	var result = parameters.erase(name)
	_on_param_edited()
	return result

func clear_param():
	parameters.clear()
	_on_param_edited()

func get_param(name):
	return parameters[name]

func get_current_state():
	return state_stack.back() if not state_stack.empty() else State.ENTRY_KEY

func get_previous_state():
	return state_stack[state_stack.size() - 2] if state_stack.size() > 1 else State.ENTRY_KEY

func set_process_mode(mode):
	if process_mode != mode:
		process_mode = mode
		_on_process_mode_changed()

func get_class():
	return "StateMachinePlayer"

func is_class(type):
	return type == "StateMachinePlayer" or .is_class(type)
