@tool
extends "StackPlayer.gd"

signal transited(from, to) # Transition of state
signal entered(to) # Entry of state machine(including nested), empty string equals to root
signal exited(from) # Exit of state machine(including nested, empty string equals to root
signal updated(state, delta) # Time to update(based on process_mode), up to user to handle any logic, for example, update movement of KinematicBody

# Enum to define how state machine should be updated
enum UpdateProcessMode {
	PHYSICS,
	IDLE,
	MANUAL
}

@export var state_machine: StateMachine # StateMachine being played 
@export var active: = true:  # Activeness of player
	set = set_active
@export var autostart: = true # Automatically enter Entry state on ready if true
@export var update_process_mode: UpdateProcessMode = UpdateProcessMode.IDLE:  # ProcessMode of player
	set = set_update_process_mode

var _is_started = false
var _parameters # Parameters to be passed to condition
var _local_parameters
var _is_update_locked = true
var _was_transited = false # If last transition was successful
var _is_param_edited = false


func _init():
	super._init()
	
	if Engine.is_editor_hint():
		return

	_parameters = {}
	_local_parameters = {}
	_was_transited = true # Trigger _transit on _ready

func _get_configuration_warning():
	if state_machine:
		if not state_machine.has_entry():
			return "State Machine will not function properly without Entry node"
	else:
		return "State Machine Player is not going anywhere without default State Machine"
	return ""

func _ready():
	if Engine.is_editor_hint():
		return

	set_process(false)
	set_physics_process(false)
	call_deferred("_initiate") # Make sure connection of signals can be done in _ready to receive all signal callback

func _initiate():
	if autostart:
		start()
	_on_active_changed()
	_on_update_process_mode_changed()

func _process(delta):
	if Engine.is_editor_hint():
		return

	_update_start()
	update(delta)
	_update_end()

func _physics_process(delta):
	if Engine.is_editor_hint():
		return

	_update_start()
	update(delta)
	_update_end()

# Only get called in 2 condition, _parameters edited or last transition was successful
func _transit():
	if not active:
		return
	# Attempt to transit if parameter edited or last transition was successful
	if not _is_param_edited and not _was_transited:
		return

	var from = get_current()
	var local_params = _local_parameters.get(path_backward(from), {})
	var next_state = state_machine.transit(get_current(), _parameters, local_params)
	if next_state:
		if stack.has(next_state):
			reset(stack.find(next_state))
		else:
			push(next_state)
	var to = next_state
	_was_transited = next_state != null and next_state != ""
	_is_param_edited = false
	_flush_trigger(_parameters)
	_flush_trigger(_local_parameters, true)

	if _was_transited:
		_on_state_changed(from, to)

func _on_state_changed(from, to):
	match to:
		State.ENTRY_STATE:
			emit_signal("entered", "")
		State.EXIT_STATE:
			set_active(false) # Disable on exit
			emit_signal("exited", "")
	
	if to.ends_with(State.ENTRY_STATE) and to.length() > State.ENTRY_STATE.length():
		# Nexted Entry state
		var state = path_backward(get_current())
		emit_signal("entered", state)
	elif to.ends_with(State.EXIT_STATE) and to.length() > State.EXIT_STATE.length():
		# Nested Exit state, clear "local" params
		var state = path_backward(get_current())
		clear_param(state, false) # Clearing params internally, do not update
		emit_signal("exited", state)

	emit_signal("transited", from, to)

# Called internally if process_mode is PHYSICS/IDLE to unlock update()
func _update_start():
	_is_update_locked = false

# Called internally if process_mode is PHYSICS/IDLE to lock update() from external call
func _update_end():
	_is_update_locked = true

# Called after update() which is dependant on process_mode, override to process current state
func _on_updated(state, delta):
	pass

func _on_update_process_mode_changed():
	if not active:
		return

	match update_process_mode:
		UpdateProcessMode.PHYSICS:
			set_physics_process(true)
			set_process(false)
		UpdateProcessMode.IDLE:
			set_physics_process(false)
			set_process(true)
		UpdateProcessMode.MANUAL:
			set_physics_process(false)
			set_process(false)

func _on_active_changed():
	if Engine.is_editor_hint():
		return

	if active:
		_on_update_process_mode_changed()
		_transit()
	else:
		set_physics_process(false)
		set_process(false)

# Remove all trigger(param with null value) from provided params, only get called after _transit
# Trigger another call of _flush_trigger on first layer of dictionary if nested is true
func _flush_trigger(params, nested=false):
	for param_key in params.keys():
		var value = params[param_key]
		if nested and value is Dictionary:
			_flush_trigger(value)
		if value == null: # Param with null as value is treated as trigger
			params.erase(param_key)

func reset(to=-1, event=ResetEventTrigger.LAST_TO_DEST):
	super.reset(to, event)
	_was_transited = true # Make sure to call _transit on next update

# Manually start the player, automatically called if autostart is true
func start():
	push(State.ENTRY_STATE)
	emit_signal("entered", "")
	_was_transited = true
	_is_started = true

# Restart player
func restart(is_active=true, preserve_params=false):
	reset()
	set_active(is_active)
	if not preserve_params:
		clear_param("", false)
	start()

# Update player to, first initiate transition, then call _on_updated, finally emit "update" signal, delta will be given based on process_mode.
# Can only be called manually if process_mode is MANUAL, otherwise, assertion error will be raised.
# *delta provided will be reflected in signal updated(state, delta)
func update(delta=get_physics_process_delta_time()):
	if not active:
		return
	if update_process_mode != UpdateProcessMode.MANUAL:
		assert(not _is_update_locked, "Attempting to update manually with ProcessMode %s" % UpdateProcessMode.keys()[update_process_mode])

	_transit()
	var current_state = get_current()
	_on_updated(current_state, delta)
	emit_signal("updated", current_state, delta)
	if update_process_mode == UpdateProcessMode.MANUAL:
		# Make sure to auto advance even in MANUAL mode
		if _was_transited:
			call_deferred("update")

# Set trigger to be tested with condition, then trigger _transit on next update, 
# automatically call update() if process_mode set to MANUAL and auto_update true
# Nested trigger can be accessed through path "path/to/param_name", for example, "App/Game/is_playing"
func set_trigger(name, auto_update=true):
	set_param(name, null, auto_update)

func set_nested_trigger(path, name, auto_update=true):
	set_nested_param(path, name, null, auto_update)

# Set param(null value treated as trigger) to be tested with condition, then trigger _transit on next update, 
# automatically call update() if process_mode set to MANUAL and auto_update true
# Nested param can be accessed through path "path/to/param_name", for example, "App/Game/is_playing"
func set_param(name, value, auto_update=true):
	var path = ""
	if "/" in name:
		path = path_backward(name)
		name = path_end_dir(name)
	set_nested_param(path, name, value, auto_update)

func set_nested_param(path, name, value, auto_update=true):
	if path.is_empty():
		_parameters[name] = value
	else:
		var local_params = _local_parameters.get(path)
		if local_params is Dictionary:
			local_params[name] = value
		else:
			local_params = {}
			local_params[name] = value
			_local_parameters[path] = local_params
	_on_param_edited(auto_update)

# Remove param, then trigger _transit on next update, 
# automatically call update() if process_mode set to MANUAL and auto_update true
# Nested param can be accessed through path "path/to/param_name", for example, "App/Game/is_playing"
func erase_param(name, auto_update=true):
	var path = ""
	if "/" in name:
		path = path_backward(name)
		name = path_end_dir(name)
	return erase_nested_param(path, name, auto_update)

func erase_nested_param(path, name, auto_update=true):
	var result = false
	if path.is_empty():
		result = _parameters.erase(name)
	else:
		result = _local_parameters.get(path, {}).erase(name)
	_on_param_edited(auto_update)
	return result

# Clear params from specified path, empty string to clear all, then trigger _transit on next update, 
# automatically call update() if process_mode set to MANUAL and auto_update true
# Nested param can be accessed through path "path/to/param_name", for example, "App/Game/is_playing"
func clear_param(path="", auto_update=true):
	if path.is_empty():
		_parameters.clear()
	else:
		_local_parameters.get(path, {}).clear()
		# Clear nested params
		for param_key in _local_parameters.keys():
			if param_key.begins_with(path):
				_local_parameters.erase(param_key)

# Called when param edited, automatically call update() if process_mode set to MANUAL and auto_update true
func _on_param_edited(auto_update=true):
	_is_param_edited = true
	if update_process_mode == UpdateProcessMode.MANUAL and auto_update and _is_started:
		update()

# Get value of param
# Nested param can be accessed through path "path/to/param_name", for example, "App/Game/is_playing"
func get_param(name, default=null):
	var path = ""
	if "/" in name:
		path = path_backward(name)
		name = path_end_dir(name)
	return get_nested_param(path, name, default)

func get_nested_param(path, name, default=null):
	if path.is_empty():
		return _parameters.get(name, default)
	else:
		var local_params = _local_parameters.get(path, {})
		return local_params.get(name, default)

# Get duplicate of whole parameter dictionary
func get_params():
	return _parameters.duplicate()

# Return true if param exists
# Nested param can be accessed through path "path/to/param_name", for example, "App/Game/is_playing"
func has_param(name):
	var path = ""
	if "/" in name:
		path = path_backward(name)
		name = path_end_dir(name)
	return has_nested_param(path, name)

func has_nested_param(path, name):
	if path.is_empty():
		return name in _parameters
	else:
		var local_params = _local_parameters.get(path, {})
		return name in local_params

# Return if player started
func is_entered():
	return State.ENTRY_STATE in stack

# Return if player ended
func is_exited():
	return get_current() == State.EXIT_STATE

func set_active(v):
	if active != v:
		if v:
			if is_exited():
				push_warning("Attempting to make exited StateMachinePlayer active, call reset() then set_active() instead")
				return
		active = v
		_on_active_changed()

func set_update_process_mode(mode):
	if update_process_mode != mode:
		update_process_mode = mode
		_on_update_process_mode_changed()

func get_current():
	var v = super.get_current()
	return v if v else ""

func get_previous():
	var v = super.get_previous()
	return v if v else ""

# Convert node path to state path that can be used to query state with StateMachine.get_state.
# Node path, "root/path/to/state", equals to State path, "path/to/state"
static func node_path_to_state_path(node_path):
	var p = node_path.replace("root", "")
	if p.begins_with("/"):
		p = p.substr(1)
	return p

# Convert state path to node path that can be used for query node in scene tree.
# State path, "path/to/state", equals to Node path, "root/path/to/state"
static func state_path_to_node_path(state_path):
	var path = state_path
	if path.is_empty():
		path = "root"
	else:
		path = str("root/", path)
	return path

# Return parent path, "path/to/state" return "path/to"
static func path_backward(path):
	return path.substr(0, path.rfind("/"))

# Return end directory of path, "path/to/state" returns "state"
static func path_end_dir(path):
	# In Godot 4.x the old behaviour of String.right() can be achieved with
	# a negative length. Check the docs:
	# https://docs.godotengine.org/en/stable/classes/class_string.html#class-string-method-right
	return path.right(path.length()-1 - path.rfind("/"))
