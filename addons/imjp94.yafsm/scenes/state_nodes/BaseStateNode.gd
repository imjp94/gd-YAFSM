tool
extends GraphNode
const Transition = preload("../../src/transitions/Transition.gd")
const State = preload("../../src/states/State.gd")
const TransitionEditor = preload("../transition_editors/TransitionEditor.tscn")

onready var Transitions = $MarginContainer/Transitions

var undo_redo

var state setget set_state

var _to_free


func _init():
	_to_free = []
	set_state(State.new())

func _ready():
	connect("offset_changed", self, "_on_offset_changed")
	connect("dragged", self, "_on_dragged")

func _on_dragged(from, to):
	drag_action(from, to)

func _on_offset_changed():
	state.graph_offset = offset

func add_transition_editor(editor, transition):
	editor.undo_redo = undo_redo
	Transitions.add_child(editor)
	editor.transition = transition
	editor.name = transition.to

func remove_transition_editor(editor):
	var transition = editor.transition
	Transitions.remove_child(editor)
	_to_free.append(editor)
	rect_size = Vector2.ZERO

func get_transition_editor(to):
	return Transitions.get_node(to)

func drag_action(from, to):
	undo_redo.create_action("Drag State Node")
	undo_redo.add_do_property(self, "offset", to)
	undo_redo.add_undo_property(self, "offset", from)
	undo_redo.commit_action()

# Free nodes cached in UndoRedo stack
func free_node_from_undo_redo():
	for transition_editor in _to_free:
		transition_editor.free_node_from_undo_redo()

func set_state(s):
	if state != s:
		state = s
		offset = state.graph_offset

