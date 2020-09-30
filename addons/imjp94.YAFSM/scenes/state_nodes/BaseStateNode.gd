tool
extends GraphNode
const Transition = preload("../../src/Transition.gd")
const State = preload("../../src/State.gd")
const TransitionEditor = preload("../transition_editors/TransitionEditor.tscn")

onready var Transitions = $MarginContainer/Transitions

var state setget set_state


func _init():
	set_state(State.new())

func _ready():
	connect("offset_changed", self, "_on_offset_changed")

func _on_offset_changed():
	state.offset = offset

func _on_state_transition_added(transition):
	var editor = TransitionEditor.instance()
	Transitions.add_child(editor)
	editor.transition = transition
	editor.name = transition.to

func _on_state_transition_removed(to_state):
	for child in Transitions.get_children():
		if child.name == to_state:
			Transitions.remove_child(child)
			child.queue_free()
			rect_size = Vector2.ZERO # Reset rect size
			break

func _on_state_changed(new_state):
	if new_state:
		new_state.connect("transition_added", self, "_on_state_transition_added")
		new_state.connect("transition_removed", self, "_on_state_transition_removed")

func set_state(s):
	if state != s:
		state = s
		offset = state.offset
		_on_state_changed(s)