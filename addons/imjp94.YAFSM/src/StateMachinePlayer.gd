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

# Enum to specify how reseting state stack should trigger event(state_changed, state_entered, state_exited etc.)
enum ResetEventTrigger {
	NONE = -1, # No event
	ALL = 0, # All removed state will emit event
	LAST_TO_DEST = 1 # Only last state and destination will emit event
}

export(Resource) var state_machine
export(bool) var active setget set_active
export(ProcessMode) var process_mode = ProcessMode.IDLE setget set_process_mode

var current_state setget ,get_current_state
var state_stack setget set_state_stack, get_state_stack

var _parameters
var _is_update_locked = false
var _was_transited = false # If last transition was successful


func _init():
	_parameters = {}
	state_stack = []

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

	_on_active_changed()
	_on_process_mode_changed()
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
	var to = get_previous_state()
	_exit(to)
	var from = state_stack.pop_back()
	_enter(from)
	emit_signal("state_changed", from, to)

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

# Only get called in 2 condition, _parameters edited or last transition was successful
func _transition():
	if not active:
		return

	var next_state = state_machine.states[get_current_state()].transit(_parameters)
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
	if not active:
		return

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

func _on_active_changed():
	if Engine.editor_hint:
		return

	print("active changed")
	if active:
		_flush_trigger()
		_on_process_mode_changed()
		_transition()
	else:
		set_physics_process(false)
		set_process(false)

func update(delta):
	if not active:
		return

	if _was_transited: # Attempt to transit if last transition was successful
		_transition()
	if process_mode != ProcessMode.MANUAL:
		assert(not _is_update_locked, "Attempting to update manually with ProcessMode.%s" % ProcessMode.keys()[process_mode])
	var current_state = get_current_state()
	_on_update(current_state, delta)
	emit_signal("state_update", current_state, delta)

func reset(to=0, event=ResetEventTrigger.LAST_TO_DEST):
	assert(to > -1 and to < state_stack.size(), "Reset to index(%d) out of bounds(%d)" % [to, state_stack.size()])
	var last_index = state_stack.size() - 1
	var first_state = ""
	var num_to_pop = last_index - to

	if num_to_pop > 0:
		for i in range(num_to_pop):
			first_state = get_current_state() if i == 0 else first_state
			match event:
				ResetEventTrigger.LAST_TO_DEST:
					state_stack.pop_back()
					if i == num_to_pop - 1:
						state_stack.push_back(first_state)
						_pop_state()
				ResetEventTrigger.ALL:
					_pop_state()
				_:
					state_stack.pop_back()
	elif num_to_pop == 0:
		match event:
			ResetEventTrigger.NONE:
				state_stack.pop_back()
			_:
				_pop_state()

func _flush_trigger():
	for param_key in _parameters.keys():
		var value = _parameters[param_key]
		if value == null: # Param with null as value is treated as trigger
			_parameters.erase(param_key)

func _on_param_edited():
	_transition()

func set_trigger(name):
	_parameters[name] = null
	_on_param_edited()

func set_param(name, value):
	_parameters[name] = value
	_on_param_edited()

func erase_param(name):
	var result = _parameters.erase(name)
	_on_param_edited()
	return result

func clear_param():
	_parameters.clear()
	_on_param_edited()

func get_param(name):
	return _parameters[name]

func get_params():
	return _parameters.duplicate()

func set_state_stack(stack):
	push_warning("Attempting to edit read-only state stack directly. " \
		+ "Control state machine from setting parameters or call update() instead")

func get_state_stack():
	return state_stack.duplicate()

func get_current_state():
	return state_stack.back() if not state_stack.empty() else State.ENTRY_KEY

func get_previous_state():
	return state_stack[state_stack.size() - 2] if state_stack.size() > 1 else State.ENTRY_KEY

func set_active(v):
	if active != v:
		active = v
		_on_active_changed()

func set_process_mode(mode):
	if process_mode != mode:
		process_mode = mode
		_on_process_mode_changed()

func get_class():
	return "StateMachinePlayer"

func is_class(type):
	return type == "StateMachinePlayer" or .is_class(type)
