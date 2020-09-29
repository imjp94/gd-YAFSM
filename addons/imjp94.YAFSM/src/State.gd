tool
extends Resource

const ENTRY_KEY = "Entry"
const EXIT_KEY = "Exit"

signal transition_added(transition)
signal transition_removed(to_state)

export(String) var name = ""
export(Dictionary) var transitions
export(Vector2) var offset = Vector2.ZERO


func _init(p_name="", p_transitions={}, p_offset=Vector2.ZERO):
	name = p_name
	transitions = p_transitions
	offset = p_offset

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