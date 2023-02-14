@tool
@icon("../../assets/icons/state_machine_icon.png")
extends State
class_name StateMachine

signal transition_added(transition) # Transition added
signal transition_removed(to_state) # Transition removed

@export var states: Dictionary:  # States within this StateMachine, keyed by State.name
	get = get_states,
	set = set_states
@export var transitions: Dictionary:  # Transitions from this state, keyed by Transition.to
	get = get_transitions,
	set = set_transitions

var _states
var _transitions


func _init(p_name="", p_transitions={}, p_states={}):
	super._init(p_name)
	_transitions = p_transitions
	_states = p_states

# Attempt to transit with global/local parameters, where local_params override params
func transit(current_state, params={}, local_params={}):
	var nested_states = current_state.split("/")
	var is_nested = nested_states.size() > 1
	var end_state_machine = self
	var base_path = ""
	for i in nested_states.size() - 1: # Ignore last one, to get its parent StateMachine
		var state = nested_states[i]
		# Construct absolute base path
		base_path = join_path(base_path, [state])
		if end_state_machine != self:
			end_state_machine = end_state_machine.states[state]
		else:
			end_state_machine = _states[state] # First level state

	# Nested StateMachine in Exit state
	if is_nested:
		var is_nested_exit = nested_states[nested_states.size()-1] == State.EXIT_STATE
		if is_nested_exit:
			# Normalize path to transit again with parent of end_state_machine
			var end_state_machine_parent_path = ""
			for i in nested_states.size() - 2: # Ignore last two state(which is end_state_machine/end_state)
				end_state_machine_parent_path = join_path(end_state_machine_parent_path, [nested_states[i]])
			var end_state_machine_parent = get_state(end_state_machine_parent_path)
			var normalized_current_state = end_state_machine.name
			var next_state = end_state_machine_parent.transit(normalized_current_state, params)
			if next_state:
				# Construct next state into absolute path
				next_state = join_path(end_state_machine_parent_path, [next_state])
			return next_state
	
	# Transit with current running nested state machine
	var from_transitions = end_state_machine.transitions.get(nested_states[nested_states.size()-1])
	if from_transitions:
		var from_transitions_array = from_transitions.values()
		from_transitions_array.sort_custom(func(a, b): Transition.sort(a, b))
		
		for transition in from_transitions_array:
			var next_state = transition.transit(params, local_params)
			if next_state:
				if "states" in end_state_machine.states[next_state]:
					# Next state is a StateMachine, return entry state of the state machine in absolute path
					next_state = join_path(base_path, [next_state, State.ENTRY_STATE])
				else:
					# Construct next state into absolute path
					next_state = join_path(base_path, [next_state])
				return next_state
	return null

# Get state from absolute path, for exmaple, "path/to/state" (root == empty string)
# *It is impossible to get parent state machine with path like "../sibling", as StateMachine is not structed as a Tree
func get_state(path):
	var state
	if path.is_empty():
		state = self
	else:
		var nested_states = path.split("/")
		for i in nested_states.size():
			var dir = nested_states[i]
			if state:
				state = state.states[dir]
			else:
				state = _states[dir] # First level state
	return state

# Add state, state name must be unique within this StateMachine, return state added if succeed else return null
func add_state(state):
	if not state:
		return null
	if state.name in _states:
		return null

	_states[state.name] = state
	return state

# Remove state by its name
func remove_state(state):
	return _states.erase(state)

# Change existing state key in states(Dictionary), return true if success
func change_state_name(from, to):
	if not (from in _states) or to in _states:
		return false

	for state_key in _states.keys():
		var state = _states[state_key]
		var is_name_changing_state = state_key == from
		if is_name_changing_state:
			state.name = to
			_states[to] = state
			_states.erase(from)
		for from_key in _transitions.keys():
			var from_transitions = _transitions[from_key]
			if from_key == from:
				_transitions.erase(from)
				_transitions[to] = from_transitions
			for to_key in from_transitions.keys():
				var transition = from_transitions[to_key]
				if transition.from == from:
					transition.from = to
				elif transition.to == from:
					transition.to = to
					if not is_name_changing_state:
						# Transitions to name changed state needs to be updated
						from_transitions.erase(from)
						from_transitions[to] = transition
	return true

# Add transition, Transition.from must be equal to this state's name and Transition.to not added yet
func add_transition(transition):
	if transition.from == "" or transition.to == "":
		push_warning("Transition missing from/to (%s/%s)" % [transition.from, transition.to])
		return

	var from_transitions
	if transition.from in _transitions:
		from_transitions = _transitions[transition.from]
	else:
		from_transitions = {}
		_transitions[transition.from] = from_transitions

	from_transitions[transition.to] = transition
	emit_signal("transition_added", transition)

# Remove transition with Transition.to(name of state transiting to)
func remove_transition(from_state, to_state):
	var from_transitions = _transitions.get(from_state)
	if from_transitions:
		if to_state in from_transitions:
			from_transitions.erase(to_state)
			if from_transitions.is_empty():
				_transitions.erase(from_state)
			emit_signal("transition_removed", from_state, to_state)

func get_entries():
	return _transitions[State.ENTRY_STATE].values()
	
func get_exits():
	return _transitions[State.EXIT_STATE].values()

func has_entry():
	return State.ENTRY_STATE in _states

func has_exit():
	return State.EXIT_STATE in _states

# Get duplicate of states dictionary
func get_states():
	return _states.duplicate()

func set_states(val):
	_states = val

# Get duplicate of transitions dictionary
func get_transitions():
	return _transitions.duplicate()

func set_transitions(val):
	_transitions = val

static func join_path(base, dirs):
	var path = base
	for dir in dirs:
		if path.is_empty():
			path = dir
		else:
			path = str(path, "/", dir)
	return path

# Validate state machine resource to identify and fix error
static func validate(state_machine):
	var validated = false
	for from_key in state_machine.transitions.keys():
		# Non-existing state found in StateMachine.transitions
		# See https://github.com/imjp94/gd-YAFSM/issues/6
		if not (from_key in state_machine.states):
			validated = true
			push_warning("gd-YAFSM ValidationError: Non-existing state(%s) found in transition" % from_key)
			state_machine.transitions.erase(from_key)
			continue

		var from_transition = state_machine.transitions[from_key]
		for to_key in from_transition.keys():
			# Non-existing state found in StateMachine.transitions
			# See https://github.com/imjp94/gd-YAFSM/issues/6
			if not (to_key in state_machine.states):
				validated = true
				push_warning("gd-YAFSM ValidationError: Non-existing state(%s) found in transition(%s -> %s)" % [to_key, from_key, to_key])
				from_transition.erase(to_key)
				continue

			# Mismatch of StateMachine.transitions with Transition.to 
			# See https://github.com/imjp94/gd-YAFSM/issues/6
			var to_transition = from_transition[to_key]
			if to_key != to_transition.to:
				validated = true
				push_warning("gd-YAFSM ValidationError: Mismatch of StateMachine.transitions key(%s) with Transition.to(%s)" % [to_key, to_transition.to])
				to_transition.to = to_key

			# Self connecting transition
			# See https://github.com/imjp94/gd-YAFSM/issues/5
			if to_transition.from == to_transition.to:
				validated = true
				push_warning("gd-YAFSM ValidationError: Self connecting transition(%s -> %s)" % [to_transition.from, to_transition.to])
				from_transition.erase(to_key)
	return validated
