tool
extends Resource
const State = preload("State.gd")

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

func get_current_transitions(current_state):
	return states[current_state].transitions.values()

func get_entry():
	return get_entries()[0] # TODO: Should no assume one entry

func get_exit():
	return get_exits()[0] # TODO: Should no assume one exit

func get_entries():
	return states[ENTRY_KEY].transitions.values()
	
func get_exits():
	return states[EXIT_KEY].transitions.values()

func equals(obj):
	if obj == null:
		return false
	if not ("from" in obj and "to" in obj):
		return false

	return from == obj.from and to == obj.to
