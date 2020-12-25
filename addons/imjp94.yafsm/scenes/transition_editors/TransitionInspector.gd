tool
extends EditorInspectorPlugin
const Transition = preload("res://addons/imjp94.yafsm/src/transitions/Transition.gd")

const TransitionEditor = preload("res://addons/imjp94.yafsm/scenes/transition_editors/TransitionEditor.tscn")

var undo_redo


func can_handle(object):
	return object is Transition

func parse_property(object, type, path, hint, hint_text, usage):
	if path == "conditions":
		var transition_editor = TransitionEditor.instance() # Will be freed by editor
		transition_editor.undo_redo = undo_redo
		add_custom_control(transition_editor)
		transition_editor.connect("ready", self, "_on_transition_editor_tree_entered", [transition_editor, object])
		return true
	return false

func _on_transition_editor_tree_entered(editor, transition):
	editor.transition = transition
