extends Resource

const ENTRY_KEY = "_entry"
const EXIT_KEY = "_exit"

export(String) var from
export(String) var to
export(Array, Resource) var conditions
export(Dictionary) var states = {
	ENTRY_KEY: STATE_STRUCT.duplicate(),
	EXIT_KEY: STATE_STRUCT.duplicate()
}


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

func add_transition(from_state, transition):
	var state = states.get(from_state)
	if not state:
		state = STATE_STRUCT.duplicate()
		states[from_state] = state
	state.transitions.append(transition)

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

const STATE_STRUCT = {
	"offset": Vector2.ZERO, # GraphNode.offset 
	"transitions":[]
}
