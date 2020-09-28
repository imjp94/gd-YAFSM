tool
extends Resource

const ENTRY_KEY = "Entry"
const EXIT_KEY = "Exit"

export(String) var from
export(String) var to
export(Array, Resource) var conditions
export(Dictionary) var states = {}


func _init(p_from="", p_to=""):
	from = p_from
	to = p_to

func transit(params={}):
	if not conditions:
		return to

	for condition in conditions:
		var value = params.get(condition.name)
		if value:
			if "value" in condition:
				if condition.compare(value):
					return to
			else: # Condition without value property is a trigger
				return to

func add_state(state, state_struct=null):
	if states.has(state):
		return null

	var new_state = state_struct if state_struct else STATE_STRUCT.duplicate(true)
	states[state] = new_state
	return new_state

func remove_state(state):
	return states.erase(state)

func add_transition(from_state, transition):
	var state = states.get(from_state)
	if not state:
		state = add_state(from_state)
	state.transitions.append(transition)

func remove_transition(from_state, to_state):
	if not (from_state in states):
		return false

	var state = states[from_state]
	for transition in state.transitions:
		if transition.from == from_state and transition.to == to_state:
			state.transitions.erase(transition)
			return true

# Change existing state key in states(Dictionary), return true if success
func change_state_name(from, to):
	if not (from in states) or to in states:
		return false

	for state_key in states.keys():
		var state = states[state_key]
		var is_name_changing_state = state_key == from
		if is_name_changing_state:
			states[to] = state
			states.erase(from)
		for transition in state.transitions:
			if is_name_changing_state:
				if transition.from == from:
					transition.from = to
			else:
				if transition.to == from:
					transition.to = to
	return true

func get_current_transitions(current_state):
	return states[current_state].transitions

func get_entry():
	return get_entries()[0] # TODO: Should no assume one entry

func get_exit():
	return get_exits()[0] # TODO: Should no assume one exit

func get_entries():
	return states[ENTRY_KEY].transitions
	
func get_exits():
	return states[EXIT_KEY].transitions

# Data struct for State, remember to duplicate(true) for deep copy as it contains array
const STATE_STRUCT = {
	"offset": Vector2.ZERO, # GraphNode.offset 
	"transitions": []
}
