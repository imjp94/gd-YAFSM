tool
extends EditorPlugin
const GraphEditor = preload("scenes/GraphEdit.tscn")

var graph_editor


func _enter_tree():
	var graph_editor = GraphEditor.instance()
	add_control_to_bottom_panel(graph_editor, "YAFSM")

func _exit_tree():
	if graph_editor:
		graph_editor.queue_free()
