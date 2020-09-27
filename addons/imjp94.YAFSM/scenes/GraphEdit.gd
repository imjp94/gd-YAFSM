tool
extends GraphEdit
const GraphContextMenu = preload("GraphContextMenu.tscn")
const CustomGraphNode = preload("GraphNode.tscn")

onready var ContextMenu = $ContextMenu


func _init():
	add_valid_connection_type(0, 1)
	add_valid_connection_type(1, 0)
	add_valid_left_disconnect_type(1)
	add_valid_right_disconnect_type(0)

func _ready():
	connect("connection_request", self, "_on_connection_request")
	connect("disconnection_request", self, "_on_disconnection_request")
	connect("popup_request", self, "_on_popup_request")
	ContextMenu.connect("index_pressed", self, "_on_ContextMenu_index_pressed")

func _on_connection_request(from, from_slot, to, to_slot):
	connect_node(from, from_slot, to, to_slot)

func _on_disconnection_request(from, from_slot, to, to_slot):
	disconnect_node(from, from_slot, to, to_slot)

func _on_popup_request(position):
	ContextMenu.rect_position = get_viewport().get_mouse_position()
	ContextMenu.popup()

func _on_ContextMenu_index_pressed(index):
	match index: # TODO: Proper way to handle menu items
		0: # Add State
			var graph_node = CustomGraphNode.instance()
			add_child(graph_node)
			_on_new_graph_node_added(graph_node)

func _on_new_graph_node_added(graph_node):
	graph_node.offset = get_local_mouse_position() + scroll_offset
