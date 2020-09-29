tool
extends Resource

const ENTRY_KEY = "Entry"
const EXIT_KEY = "Exit"

signal transition_added(transition)
signal transition_removed(to_state)

export(String) var name = ""
export(Dictionary) var transitions = {}
export(Vector2) var offset = Vector2.ZERO
export(Dictionary) var states = {}


func _init(p_name="", p_transitions={}, p_offset=Vector2.ZERO):
	name = p_name
	transitions = p_transitions
	offset = p_offset

func add_transition(transition):
	if not (transition.from or transition.to):
		push_warning("Transition missing from/to (%s/%s)" % [transition.from, transition.to])
		return
	if transition.to in transitions:
		push_warning("Transition(%s, %s)) already exist in state %s" % [transition.from, transition.to, name])
		return

	if transition.from != name:
		transition.from = name
	
	transitions[transition.to] = transition
	emit_signal("transition_added", transition)

func remove_transition(to_state):
	if to_state in transitions:
		transitions.erase(to_state)
		emit_signal("transition_removed", to_state)

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
	return states[ENTRY_KEY].transitions.values()
	
func get_exits():
	return states[EXIT_KEY].transitions.values()
