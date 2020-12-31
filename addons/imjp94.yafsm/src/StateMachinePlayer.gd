tool
extends "StackPlayer.gd"
const State = preload("states/State.gd")

signal transit_in(to) # Transit to state, exclude Entry/Exit state
signal transit_out(from) # Transit from state, exclude Entry/Exit state
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
export(bool) var autostart = true # Automatically enter Entry state on ready if true
export(ProcessMode) var process_mode = ProcessMode.IDLE setget set_process_mode # ProcessMode of player

var _parameters # Parameters to be passed to condition
var _is_update_locked = true
var _was_transited = false # If last transition was successful
var _is_param_edited = false


func _init():
	if Engine.editor_hint:
		return

	_parameters = {}
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

	if autostart:
		start()
	_on_active_changed()
	_on_process_mode_changed()

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
	match to:
		State.ENTRY_KEY:
			emit_signal("entry", state_machine)
		State.EXIT_KEY:
			set_active(false) # Disable on exit
			emit_signal("exit", state_machine)
		"":
			return # Ignore empty state
		_:
			emit_signal("transit_in", to)

func _transit_out(from):
	match from:
		State.ENTRY_KEY:
			return
		State.EXIT_KEY:
			return
		"":
			return # Ignore empty state
		_:
			emit_signal("transit_out", from)

# Only get called in 2 condition, _parameters edited or last transition was successful
func _transition():
	if not active:
		return
	# Attempt to transit if parameter edited or last transition was successful
	if not _is_param_edited and not _was_transited:
		return

	var next_state = state_machine.transit(get_current(), _parameters)
	if next_state:
		if stack.has(next_state):
			reset(stack.find(next_state))
		else:
			push(next_state)
	_was_transited = !!next_state
	_is_param_edited = false
	_flush_trigger()

# Called internally if process_mode is PHYSICS/IDLE to unlock update()
func _update_start():
	_is_update_locked = false

# Called internally if process_mode is PHYSICS/IDLE to lock update() from external call
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

func reset(to=-1, event=ResetEventTrigger.LAST_TO_DEST):
	.reset(to, event)
	_was_transited = true # Make sure to call _transition on next update

# Manually start the player, automatically called if autostart is true
func start():
	push(State.ENTRY_KEY)
	_was_transited = true

# Restart player
func restart(is_active=true):
	reset()
	set_active(is_active)
	start()

# Update player to, first initiate transition, then call _on_update, finally emit "update" signal
# Can only be called manually if process_mode is MANUAL, otherwise, assertion error will be raised
func update(delta):
	if not active:
		return
	if process_mode != ProcessMode.MANUAL:
		assert(not _is_update_locked, "Attempting to update manually with ProcessMode.%s" % ProcessMode.keys()[process_mode])

	_transition()
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
func get_param(name, default=null):
	return _parameters.get(name, default)

# Get duplicate of whole parameter dictionary
func get_params():
	return _parameters.duplicate()

# Return if player started
func is_entered():
	return State.ENTRY_KEY in stack

# Return if player ended
func is_exited():
	return get_current() == State.EXIT_KEY

func set_active(v):
	if active != v:
		if v:
			if is_exited():
				push_warning("Attempting to make exited StateMachinePlayer active, call reset() then set_active() instead")
				return
		active = v
		_on_active_changed()

func set_process_mode(mode):
	if process_mode != mode:
		process_mode = mode
		_on_process_mode_changed()

func get_current():
	var v = .get_current()
	return v if v  else ""

func get_previous():
	var v = .get_previous()
	return v if v else ""
