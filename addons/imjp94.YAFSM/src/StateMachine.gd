tool
extends "State.gd"
const State = preload("State.gd")

export(Dictionary) var states = {}


func _init(p_name="", p_offset=Vector2.ZERO):
	name = p_name
	offset = p_offset

func add_state(state):
	if not state:
		return null
	if state.name in states:
		return null

	states[state.name] = state
	return state

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
	return true

func get_entry():
	return get_entries()[0] # TODO: Should no assume one entry

func get_exit():
	return get_exits()[0] # TODO: Should no assume one exit

func get_entries():
	return states[State.ENTRY_KEY].transitions.values()
	
func get_exits():
	return states[State.EXIT_KEY].transitions.values()
