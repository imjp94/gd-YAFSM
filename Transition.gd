extends Resource

const ENTRY_KEY = "_entry"
const EXIT_KEY = "_exit"

export(String) var from
export(String) var to
export(Array, Resource) var conditions
export(Array, Resource) var transitions setget set_transitions

var from_state_dict = {
	ENTRY_KEY: [],
	EXIT_KEY: []
}


func _init(p_from="", p_to="", p_transitions=[]):
	from = p_from
	to = p_to
	transitions = p_transitions

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

func update_from_state_dict():
	for transition in transitions:
		var pair = from_state_dict.get(transition.from)
		if transition.from and transition.to:
			if not pair:
				pair = []
				from_state_dict[transition.from] = pair
		elif transition.from or transition.to:
			if transition.to:
				# Entry transition
				pair = from_state_dict[ENTRY_KEY]
			else:
				# Exit transition
				pair = from_state_dict[EXIT_KEY]
		elif not (transition.from and transition.to):
			push_warning("Empty Transition %s" % transition.resource_path)
			continue
		pair.append(transition)

func get_current_transitions(current_state):
	return from_state_dict[current_state]

func get_entry():
	return get_entries()[0] # TODO: Should no assume one entry

func get_exit():
	return get_exits()[0] # TODO: Should no assume one exit

func get_entries():
	return from_state_dict[ENTRY_KEY]
	
func get_exits():
	return from_state_dict[EXIT_KEY]

func set_transitions(arr):
	transitions = arr
	update_from_state_dict()
