tool
extends VBoxContainer

onready var To = $Header/To

var transition setget set_transition


func _on_transition_changed(new_transition):
	To.text = transition.to

func set_transition(t):
	if transition != t:
		transition = t
		_on_transition_changed(t)