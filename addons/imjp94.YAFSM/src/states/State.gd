tool
extends Resource

const ENTRY_KEY = "Entry"
const EXIT_KEY = "Exit"

const META_GRAPH_OFFSET = "graph_offset"

signal transition_added(transition)
signal transition_removed(to_state)

export(String) var name = ""
export(Dictionary) var transitions

var graph_offset setget set_graph_offset, get_graph_offset


func _init(p_name="", p_transitions={}):
	name = p_name
	transitions = p_transitions

func transit(param={}):
	for transition in transitions.values():
		var next_state = transition.transit(param)
		if next_state:
			return next_state
	return null

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

func is_entry():
	return name == ENTRY_KEY

func is_exit():
	return name == EXIT_KEY

func set_graph_offset(offset):
	set_meta(META_GRAPH_OFFSET, offset)

func get_graph_offset():
	return get_meta(META_GRAPH_OFFSET) if has_meta(META_GRAPH_OFFSET) else Vector2.ZERO
