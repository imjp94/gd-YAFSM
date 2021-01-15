tool
extends Resource

signal name_changed(new_name)

# Reserved state name for Entry/Exit
const ENTRY_STATE = "Entry"
const EXIT_STATE = "Exit"

const META_GRAPH_OFFSET = "graph_offset" # Meta key for graph_offset

export(String) var name = "" setget set_name # Name of state, unique within StateMachine

var graph_offset setget set_graph_offset, get_graph_offset # Position in FlowChart stored as meta, for editor only


func _init(p_name=""):
	name = p_name

func is_entry():
	return name == ENTRY_STATE

func is_exit():
	return name == EXIT_STATE

func set_graph_offset(offset):
	set_meta(META_GRAPH_OFFSET, offset)

func get_graph_offset():
	return get_meta(META_GRAPH_OFFSET) if has_meta(META_GRAPH_OFFSET) else Vector2.ZERO

func set_name(n):
	if name != n:
		name = n
		emit_signal("name_changed", name)
