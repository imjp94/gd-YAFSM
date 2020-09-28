tool
extends GraphEdit
const Transition = preload("../src/Transition.gd")
const CustomGraphNode = preload("GraphNode.tscn")
const EntryGraphNode = preload("EntryGraphNode.tscn")
const ExitGraphNode = preload("ExitGraphNode.tscn")

const DEFAULT_NODE_NAME = "State"
const DEFAULT_NODE_OFFSET = Vector2.ZERO

onready var ContextMenu = $ContextMenu

var focused_object setget set_focused_object
var focused_transition setget set_focused_transition

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
	connect_state_node(from, from_slot, to, to_slot)

func _on_disconnection_request(from, from_slot, to, to_slot):
	disconnect_state_node(from, from_slot, to, to_slot)

# Always called after connect_node() to update data of focused_transition
func _on_connect_node(from, from_slot, to, to_slot):
	var new_transition = Transition.new()
	new_transition.from = from
	new_transition.to = to
	focused_transition.add_transition(from, new_transition)

# Always called after disconnect_node() to update data of focused_transition
func _on_disconnect_node(from, from_slot, to, to_slot):
	focused_transition.remove_transition(from, to)

func _on_delete_nodes_request():
	for node in selected_nodes.values():
		remove_node_connections(node.name)
		remove_child(node)
		focused_transition.remove_state(node.name)
	selected_nodes.clear()

func _on_node_selected(node):
	selected_nodes[node.name] = node

func _on_node_unselected(node):
	selected_nodes.erase(node.name)

func _on_node_name_changed(old, new):
	# Manually handle re-connections after rename
	for connection in get_connection_list():
		if connection.from == old:
			disconnect_state_node(connection.from, connection.from_port, connection.to, connection.to_port)
			connect_state_node(new, connection.from_port, connection.to, connection.to_port)
		elif connection.to == old:
			disconnect_state_node(connection.from, connection.from_port, connection.to, connection.to_port)
			connect_state_node(connection.from, connection.from_port, new, connection.to_port)

	focused_transition.change_state_name(old, new)

func _on_popup_request(position):
	ContextMenu.rect_position = get_viewport().get_mouse_position()
	ContextMenu.popup()

func _on_ContextMenu_index_pressed(index):
	var local_mouse_pos = get_local_mouse_position() + scroll_offset
	match index: # TODO: Proper way to handle menu items
		0: # Add State
			var node = CustomGraphNode.instance()
			add_node(node, DEFAULT_NODE_NAME, local_mouse_pos)
		1: # Add Entry
			if Transition.ENTRY_KEY in focused_transition.states:
				push_warning("Entry node already exist")
				return
			var node = EntryGraphNode.instance()
			add_node(node, Transition.ENTRY_KEY, local_mouse_pos)
		2: # Add Exit
			if Transition.EXIT_KEY in focused_transition.states:
				push_warning("Exit node already exist")
				return
			var node = ExitGraphNode.instance()
			add_node(node, Transition.EXIT_KEY, local_mouse_pos)

func _on_new_node_added(node, node_name=DEFAULT_NODE_NAME, offset=DEFAULT_NODE_OFFSET):
	if node.has_signal("name_changed"): # BaseGraphNode doesn't have name_changed signal
		node.connect("name_changed", self, "_on_node_name_changed")
	node.offset = offset
	node.name = node_name
	focused_transition.add_state(node.name, node.state)

func _on_focused_object_changed(new_obj):
	if new_obj == null:
		set_focused_object(null)
	if new_obj is Transition:
		set_focused_transition(new_obj)

func _on_focused_transition_changed(new_transition):
	if new_transition:
		clear_graph()
		draw_graph()
	else:
		clear_graph()

func connect_state_node(from, from_slot, to, to_slot):
	connect_node(from, from_slot, to, to_slot)
	_on_connect_node(from, from_slot, to, to_slot)

func disconnect_state_node(from, from_slot, to, to_slot):
	disconnect_node(from, from_slot, to, to_slot)
	_on_disconnect_node(from, from_slot, to, to_slot)

func draw_graph():
	for state_key in focused_transition.states.keys():
		var is_entry = state_key == Transition.ENTRY_KEY
		var is_exit = state_key == Transition.EXIT_KEY
		var state = focused_transition.states[state_key]
		var new_node
		if is_entry:
			new_node = EntryGraphNode.instance()
		elif is_exit:
			new_node = ExitGraphNode.instance()
		else:
			new_node = CustomGraphNode.instance()

		new_node.state = state
		add_node(new_node, state_key, state.offset)
		for transition in state.transitions:
			# Reflecting state node, so call connect_node instead
			connect_node(transition.from, 0, transition.to, 0) # TODO: Save port index to state

func clear_graph():
	clear_connections()
	for child in get_children():
		if child is GraphNode:
			remove_child(child)

func add_node(node, node_name=DEFAULT_NODE_NAME, offset=Vector2.ZERO):
	add_child(node)
	_on_new_node_added(node, node_name, offset)

func remove_node_connections(node_name):
	for connection in get_connection_list():
		if connection.from == node_name or connection.to == node_name:
			disconnect_state_node(connection.from, connection.from_port, connection.to, connection.to_port)

func set_focused_object(obj):
	if focused_object != obj:
		focused_object = obj
		_on_focused_object_changed(obj)

func set_focused_transition(transition):
	if focused_transition != transition:
		focused_transition = transition
		_on_focused_transition_changed(transition)