tool
extends GraphEdit
const GraphContextMenu = preload("GraphContextMenu.tscn")
const CustomGraphNode = preload("GraphNode.tscn")

onready var ContextMenu = $ContextMenu

var selected_nodes = {}


func _init():
	add_valid_connection_type(0, 1)
	add_valid_connection_type(1, 0)
	add_valid_left_disconnect_type(1)
	add_valid_right_disconnect_type(0)

func _ready():
	connect("connection_request", self, "_on_connection_request")
	connect("disconnection_request", self, "_on_disconnection_request")
	connect("popup_request", self, "_on_popup_request")
	connect("delete_nodes_request", self, "_on_delete_nodes_request")
	connect("node_selected", self, "_on_node_selected")
	connect("node_unselected", self, "_on_node_unselected")
	ContextMenu.connect("index_pressed", self, "_on_ContextMenu_index_pressed")

func _on_connection_request(from, from_slot, to, to_slot):
	connect_node(from, from_slot, to, to_slot)

func _on_disconnection_request(from, from_slot, to, to_slot):
	disconnect_node(from, from_slot, to, to_slot)

func _on_delete_nodes_request():
	for node in selected_nodes.values():
		remove_node_connections(node.name)
		remove_child(node)
	selected_nodes.clear()

func _on_node_selected(node):
	selected_nodes[node.name] = node

func _on_node_unselected(node):
	selected_nodes.erase(node.name)

func _on_node_renamed(node):
	node.title = node.name # Respect the name in scene tree

func _on_popup_request(position):
	ContextMenu.rect_position = get_viewport().get_mouse_position()
	ContextMenu.popup()

func _on_ContextMenu_index_pressed(index):
	match index: # TODO: Proper way to handle menu items
		0: # Add State
			var node = CustomGraphNode.instance()
			add_child(node)
			_on_new_node_added(node)

func _on_new_node_added(node):
	node.connect("renamed", self, "_on_node_renamed", [node])
	node.name = "State"
	node.offset = get_local_mouse_position() + scroll_offset

func remove_node_connections(node_name):
	for connection in get_connection_list():
		if connection.from == node_name or connection.to == node_name:
			disconnect_node(connection.from, 0, connection.to, 0)
