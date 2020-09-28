tool
extends Resource

signal transition_added(transition)
signal transition_removed()

export(String) var name = ""
export(Dictionary) var transitions = {}
export(Vector2) var offset = Vector2.ZERO


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
		emit_signal("transition_removed")
