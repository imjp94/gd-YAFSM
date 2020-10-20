tool
extends "State.gd"
const State = preload("State.gd")

signal transition_added(transition) # Transition added
signal transition_removed(to_state) # Transition removed

export(Dictionary) var states setget ,get_states # States within this StateMachine, keyed by State.name
export(Dictionary) var transitions setget ,get_transitions # Transitions from this state, keyed by Transition.to


func _init(p_name="", p_transitions={}, p_states={}):
	._init(p_name)
	transitions = p_transitions
	states = p_states

# Attempt to transit with parameters given
func transit(current_state, param={}):
	var from_transitions = transitions.get(current_state)
	if from_transitions:
		for transition in from_transitions.values():
			var next_state = transition.transit(param)
			if next_state:
				return next_state
	return null

# Add state, state name must be unique within this StateMachine, return state added if succeed else reutrn null
func add_state(state):
	if not state:
		return null
	if state.name in states:
		return null

	states[state.name] = state
	return state

# Remove state by its name
func remove_state(state):
	return states.erase(state)

# Change existing state key in states(Dictionary), return true if success
func change_state_name(from, to):
	if not (from in states) or to in states:
		return false

	for state_key in states.keys():
		var state = states[state_key]
		var is_name_changing_state = state_key == from
		if is_name_changing_state:
			state.name = to
			states[to] = state
			states.erase(from)
		for from_key in transitions.keys():
			var from_transitions = transitions[from_key]
			if from_key == from:
				transitions.erase(from)
				transitions[to] = from_transitions
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
	if not (transition.from or transition.to):
		push_warning("Transition missing from/to (%s/%s)" % [transition.from, transition.to])
		return

	var from_transitions
	if transition.from in transitions:
		from_transitions = transitions[transition.from]
	else:
		from_transitions = {}
		transitions[transition.from] = from_transitions

	from_transitions[transition.to] = transition
	emit_signal("transition_added", transition)

# Remove transition with Transition.to(name of state transiting to)
func remove_transition(from_state, to_state):
	var from_transitions = transitions.get(from_state)
	if from_transitions:
		if to_state in from_transitions:
			from_transitions.erase(to_state)
			if from_transitions.empty():
				transitions.erase(from_state)
			emit_signal("transition_removed", from_state, to_state)

func get_entries():
	return transitions[State.ENTRY_KEY].values()
	
func get_exits():
	return transitions[State.EXIT_KEY].values()

func has_entry():
	return State.ENTRY_KEY in states

func has_exit():
	return State.EXIT_KEY in states

# Get duplicate of states dictionary
func get_states():
	return states.duplicate()

# Get duplicate of transitions dictionary
func get_transitions():
	return transitions.duplicate()

