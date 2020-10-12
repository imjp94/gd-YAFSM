tool
extends "State.gd"
const State = preload("State.gd")

export(Dictionary) var states setget ,get_states # States within this StateMachine, keyed by State.name


func _init(p_name="", p_transitions={}, p_states={}):
	._init(p_name, p_transitions)
	states = p_states

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
		for transition in state.transitions.values():
			if is_name_changing_state:
				if transition.from == from:
					transition.from = to
			else:
				if transition.to == from:
					transition.to = to
					# Transitions to name changed state needs to be updated
					state.transitions.erase(from)
					state.transitions[to] = transition
	return true

func get_entry():
	return get_entries()[0] # TODO: Should no assume one entry

func get_exit():
	return get_exits()[0] # TODO: Should no assume one exit

func get_entries():
	return states[State.ENTRY_KEY].transitions.values()
	
func get_exits():
	return states[State.EXIT_KEY].transitions.values()

func has_entry():
	return State.ENTRY_KEY in states

func has_exit():
	return State.EXIT_KEY in states

# Get duplicate of states dictionary
func get_states():
	return states.duplicate()
