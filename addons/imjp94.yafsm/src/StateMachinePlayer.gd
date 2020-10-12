tool
extends "StackPlayer.gd"
const State = preload("states/State.gd")

signal transit_in(to) # Transit to state
signal transit_out(from) # Transit from state
signal entry(state_machine) # Entry of state machine
signal exit(state_machine) # Exit of state machine
signal update(state, delta) # Update of state machine, only emitted if process_mode is PHYSICS/IDLE

# Enum to define how state machine should be updated
enum ProcessMode {
	PHYSICS,
	IDLE,
	MANUAL
}

export(Resource) var state_machine # StateMachine being played 
export(bool) var active = true setget set_active # Activeness of player
export(ProcessMode) var process_mode = ProcessMode.IDLE setget set_process_mode # ProcessMode of player

var _parameters # Parameters to be passed to condition
var _is_update_locked = false
var _was_transited = false # If last transition was successful
var _is_param_edited = false


func _init():
	if Engine.editor_hint:
		return

	_parameters = {}
	push(State.ENTRY_KEY)
	_was_transited = true # Trigger _transition on _ready

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

	call_deferred("_deferred_ready")

# Setup initial process based on active, then call first _transition().
# All this happened after _ready, so parent or child node will receive all transition signals even connects during _ready 
func _deferred_ready():
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

func _on_push(from, to):
	_transit_out(from)
	_transit_in(to)

func _on_pop(from, to):
	_transit_out(from)
	_transit_in(to)

func _transit_in(to):
	emit_signal("transit_in", to)
	if to == State.EXIT_KEY:
		emit_signal("exit", state_machine)

func _transit_out(from):
	emit_signal("transit_out", from)
	if from == State.ENTRY_KEY:
		emit_signal("entry", state_machine)

# Only get called in 2 condition, _parameters edited or last transition was successful
func _transition():
	if not active:
		return
	# Attempt to transit if parameter edited or last transition was successful
	if not _is_param_edited and not _was_transited:
		return

	var next_state = state_machine.states[get_current()].transit(_parameters)
	if next_state:
		if stack.has(next_state):
			reset(stack.find(next_state))
		else:
			push(next_state)
	_was_transited = !!next_state
	_is_param_edited = false
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

	if active:
		_flush_trigger()
		_on_process_mode_changed()
		_transition()
	else:
		set_physics_process(false)
		set_process(false)

# Remove all trigger(param with null value) in _parameters, only get called after _transition
func _flush_trigger():
	for param_key in _parameters.keys():
		var value = _parameters[param_key]
		if value == null: # Param with null as value is treated as trigger
			_parameters.erase(param_key)

func reset(to=0, event=ResetEventTrigger.LAST_TO_DEST):
	assert(to > 0, "StateMachinePlayer's stack must not be emptied")
	.reset(to, event)

func update(delta):
	if not active:
		return

	_transition()
	if process_mode != ProcessMode.MANUAL:
		assert(not _is_update_locked, "Attempting to update manually with ProcessMode.%s" % ProcessMode.keys()[process_mode])
	var current_state = get_current()
	_on_update(current_state, delta)
	emit_signal("update", current_state, delta)

# Set trigger to be tested with condition, then trigger _transition on next update
func set_trigger(name):
	_parameters[name] = null
	_is_param_edited = true

# Set param(null value treated as trigger) to be tested with condition, then trigger _transition on next update
func set_param(name, value):
	_parameters[name] = value
	_is_param_edited = true

# Remove param, then trigger _transition on next update
func erase_param(name):
	var result = _parameters.erase(name)
	_is_param_edited = true
	return result

# Clear all param , then trigger _transition on next update
func clear_param():
	_parameters.clear()
	_is_param_edited = true

# Get value of param
func get_param(name):
	return _parameters[name]

# Get duplicate of whole parameter dictionary
func get_params():
	return _parameters.duplicate()

func set_active(v):
	if active != v:
		active = v
		_on_active_changed()

func set_process_mode(mode):
	if process_mode != mode:
		process_mode = mode
		_on_process_mode_changed()
