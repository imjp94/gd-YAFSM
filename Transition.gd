extends Resource

export(String) var from
export(String) var to
export(Array, Resource) var transitions setget set_transitions
# export var conditions

var from_state_dict = {}


func _init(p_from="", p_to="", p_transitions=[]):
	from = p_from
	to = p_to
	transitions = p_transitions

func update_from_state_dict():
	for transition in transitions:
		var pair = from_state_dict.get(transition.from)
		if not pair:
			pair = []
			from_state_dict[transition.from] = pair
		pair.append(transition)

func set_transitions(arr):
	transitions = arr
	update_from_state_dict()
