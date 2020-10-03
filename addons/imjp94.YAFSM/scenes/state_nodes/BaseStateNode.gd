tool
extends GraphNode
const Transition = preload("../../src/transitions/Transition.gd")
const State = preload("../../src/states/State.gd")
const TransitionEditor = preload("../transition_editors/TransitionEditor.tscn")

onready var Transitions = $MarginContainer/Transitions

var undo_redo

var state setget set_state


func _init():
	set_state(State.new())

func _ready():
	connect("offset_changed", self, "_on_offset_changed")
	connect("dragged", self, "_on_dragged")

func _on_dragged(from, to):
	drag_action(from, to)

func _on_offset_changed():
	state.graph_offset = offset

func connect_node(from, from_slot, to, to_slot):
	get_parent().connect_node(from, from_slot, to, to_slot)
	var editor = TransitionEditor.instance()
	var transition = get_parent().create_transition(from, to)
	add_transition_editor(editor, transition)

func disconnect_node(from, from_slot, to, to_slot):
	get_parent().disconnect_node(from, from_slot, to, to_slot)
	var editor = Transitions.get_node(to)
	remove_transition_editor(editor)

func connect_action(from, from_slot, to, to_slot):
	get_parent().connect_node(from, from_slot, to, to_slot)
	var editor = TransitionEditor.instance()
	var transition = get_parent().create_transition(from, to)
	add_transition_editor_action(editor, transition)

func disconnect_action(from, from_slot, to, to_slot):
	get_parent().disconnect_node(from, from_slot, to, to_slot)
	var editor = Transitions.get_node(to)
	remove_transition_editor_action(editor)

func add_transition_editor(editor, transition):
	get_parent().connect_node(transition.from, 0, transition.to, 0)
	editor.undo_redo = undo_redo
	Transitions.add_child(editor)
	editor.transition = transition
	editor.name = transition.to
	if not (transition.to in state.transitions): # Transition may be added when loaded from file
		state.add_transition(transition)

func remove_transition_editor(editor):
	var transition = editor.transition
	get_parent().disconnect_node(transition.from, 0, transition.to, 0)
	Transitions.remove_child(editor)
	rect_size = Vector2.ZERO
	state.remove_transition(editor.transition.to)

func add_transition_editor_action(editor, transition):
	undo_redo.create_action("Connect")
	undo_redo.add_do_method(self, "add_transition_editor", editor, transition)
	undo_redo.add_undo_method(self, "remove_transition_editor", editor)
	undo_redo.commit_action()

func remove_transition_editor_action(editor):
	undo_redo.create_action("Disconnect")
	undo_redo.add_do_method(self, "remove_transition_editor", editor)
	undo_redo.add_undo_method(self, "add_transition_editor", editor, editor.transition)
	undo_redo.commit_action()

func drag_action(from, to):
	undo_redo.create_action("Drag State Node")
	undo_redo.add_do_property(self, "offset", to)
	undo_redo.add_undo_property(self, "offset", from)
	undo_redo.commit_action()

func set_state(s):
	if state != s:
		state = s
		offset = state.graph_offset

