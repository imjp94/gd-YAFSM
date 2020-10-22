tool
extends GraphEdit
const Transition = preload("../src/transitions/Transition.gd")
const State = preload("../src/states/State.gd")
const StateMachine = preload("../src/states/StateMachine.gd")
const StateNode = preload("state_nodes/StateNode.tscn")
const EntryStateNode = preload("state_nodes/EntryStateNode.tscn")
const ExitStateNode = preload("state_nodes/ExitStateNode.tscn")
const TransitionEditor = preload("transition_editors/TransitionEditor.tscn")

const CONTEXT_MENU_ADD_ENTRY_INDEX = 1
const CONTEXT_MENU_ADD_EXIT_INDEX = 2
const DEFAULT_NODE_NAME = "State"
const DEFAULT_NODE_OFFSET = Vector2.ZERO

enum GraphRequestType {
	CONNECTION,
	DISCONNECTION,
	DELETE,
	COPY,
	DUPLICATE,
	PASTE,
	POPUP
}

onready var ContextMenu = $ContextMenu
onready var Confirmation = $ConfirmationDialog
onready var OverlayContainer = $OverlayContainer
onready var CreateStateMachine = $OverlayContainer/CenterContainer/CreateStateMachine

var focused_state_machine setget set_focused_state_machine
var undo_redo

var selected_nodes = {}

var _request_stack = [] # Stack of request waited to be confirmed, currently only handle CONNECTION/DISCONNECTION
var _requesting_transition # Transition that is on hold before connection request confirmed
var _to_free = []


func _init():
	# Allow connection from both side
	add_valid_connection_type(0, 1)
	add_valid_connection_type(1, 0)
	# Only allow disconnection from right slot(0)
	add_valid_right_disconnect_type(0)

func _exit_tree():
	undo_redo.clear_history()
	free_node_from_undo_redo()

func _ready():
	connect("visibility_changed", self, "_on_visibility_changed")
	connect("connection_request", self, "_on_connection_request")
	connect("disconnection_request", self, "_on_disconnection_request")
	connect("popup_request", self, "_on_popup_request")
	connect("delete_nodes_request", self, "_on_delete_nodes_request")
	connect("node_selected", self, "_on_node_selected")
	connect("node_unselected", self, "_on_node_unselected")
	ContextMenu.connect("index_pressed", self, "_on_ContextMenu_index_pressed")
	Confirmation.connect("confirmed", self, "_on_Confirmation_confirmed")

func _gui_input(event):
	if event is InputEventMouseButton:
		if (event.button_index == BUTTON_LEFT or event.button_index == BUTTON_RIGHT) and not event.pressed:
			if not _request_stack.empty():
				_on_connection_request_confirmed()

func _unhandled_input(event):
	if not visible:
		return

	if event is InputEventKey:
		if event.control:
			if event.scancode == KEY_S and event.pressed:
				_on_save_request()

func _on_visibility_changed():
	if visible:
		if focused_state_machine:
			OverlayContainer.hide()
		else:
			OverlayContainer.show()

func _on_save_request():
	var resource_path = focused_state_machine.resource_path
	if ".scn" in resource_path or ".tscn" in resource_path: # Built-in resource will be saved by scene
		return

	Confirmation.dialog_text = "Saving StateMachine to %s" % resource_path
	Confirmation.popup_centered()

# Confirm request when left/right mouse button released, while _request_stack is not empty
func _on_connection_request_confirmed():
	# TODO: Reconnection should not be added to undo/redo stack
	for request in _request_stack:
		var args = request.args
		if request.type == GraphRequestType.CONNECTION:
			connect_action(args.from, args.from_slot, args.to, args.to_slot)
		elif request.type == GraphRequestType.DISCONNECTION:
			disconnect_action(args.from, args.from_slot, args.to, args.to_slot)
	_requesting_transition = null
	_request_stack.clear()

func _on_connection_request(from, from_slot, to, to_slot):
	if from == to:
		# TODO: Revert disconnection
		push_warning("Connection rejected, attempting to connect to self(%s)" % from)
		return

	connect_node(from, from_slot, to, to_slot) # Visually connect
	_request_stack.append(GraphRequest.new(GraphRequestType.CONNECTION, {
		"from": from,
		"from_slot": from_slot, 
		"to": to, 
		"to_slot": to_slot
	}))

func _on_disconnection_request(from, from_slot, to, to_slot):
	disconnect_node(from, from_slot, to, to_slot) # Visually disconnect
	_requesting_transition = focused_state_machine.transitions[from][to]
	_request_stack.append(GraphRequest.new(GraphRequestType.DISCONNECTION, {
		"from": from,
		"from_slot": from_slot, 
		"to": to, 
		"to_slot": to_slot
	}))

func _on_delete_nodes_request():
	for node in selected_nodes.values():
		for connection in get_connection_list():
			if connection.from == node.state.name or connection.to == node.state.name:
				disconnect_action(connection.from, connection.from_port, connection.to, connection.to_port)
		delete_node_action(node)
	selected_nodes.clear()

func _on_node_selected(node):
	selected_nodes[node.name] = node

func _on_node_unselected(node):
	selected_nodes.erase(node.name)

func _on_popup_request(position):
	ContextMenu.set_item_disabled(CONTEXT_MENU_ADD_ENTRY_INDEX, focused_state_machine.has_entry())
	ContextMenu.set_item_disabled(CONTEXT_MENU_ADD_EXIT_INDEX, focused_state_machine.has_exit())
	ContextMenu.rect_position = get_viewport().get_mouse_position()
	ContextMenu.popup()

func _on_ContextMenu_index_pressed(index):
	var node
	var node_name = DEFAULT_NODE_NAME
	var offset = get_local_mouse_position() + scroll_offset
	match index: # TODO: Proper way to handle menu items
		0: # Add State
			node = StateNode.instance()
		1: # Add Entry
			if State.ENTRY_KEY in focused_state_machine.states:
				push_warning("Entry node already exist")
				return
			node = EntryStateNode.instance()
			node_name = State.ENTRY_KEY
		2: # Add Exit
			if State.EXIT_KEY in focused_state_machine.states:
				push_warning("Exit node already exist")
				return
			node = ExitStateNode.instance()
			node_name = State.EXIT_KEY
	node.state.name = node_name
	node.offset = offset
	add_node_action(node)

func _on_Confirmation_confirmed():
	save()

func _on_new_node_added(node):
	node.undo_redo = undo_redo
	node.name = node.state.name
	node.state.name = node.name
	focused_state_machine.add_state(node.state)

func _on_focused_state_machine_changed(new_state_machine):
	if new_state_machine:
		clear_graph()
		draw_graph()
		OverlayContainer.hide()
	else:
		clear_graph()
		OverlayContainer.show()

func draw_graph():
	for state_key in focused_state_machine.states.keys():
		var is_entry = state_key == State.ENTRY_KEY
		var is_exit = state_key == State.EXIT_KEY
		var state = focused_state_machine.states[state_key]
		var new_node
		if is_entry:
			new_node = EntryStateNode.instance()
		elif is_exit:
			new_node = ExitStateNode.instance()
		else:
			new_node = StateNode.instance()

		new_node.state = state
		new_node.state.name = state_key
		new_node.offset = state.graph_offset
		add_node(new_node)
		var from_transitions = focused_state_machine.transitions.get(state_key)
		if from_transitions:
			for transition in from_transitions.values():
				# Reflecting state node, so only required to add new transition editor
				connect_node(transition.from, 0, transition.to, 0)
				new_node.add_transition_editor(TransitionEditor.instance(), transition)

func clear_graph():
	clear_connections()
	for child in get_children():
		if child is GraphNode:
			remove_child(child)
			_to_free.append(child)

func add_node(node):
	add_child(node)
	_on_new_node_added(node)

func delete_node(node):
	remove_node_connections(node.name)
	remove_child(node)
	_to_free.append(node)
	focused_state_machine.remove_state(node.name)

func remove_node_connections(node_name):
	var node = get_node(node_name)
	for connection in get_connection_list():
		if connection.from == node_name or connection.to == node_name:
			disconnect_node(connection.from, 0, connection.to, 0)
			node.remove_transition_editor(node.get_transition_editor(connection.to))

func save():
	if not focused_state_machine:
		return
	var resource_path = focused_state_machine.resource_path
	if ".scn" in resource_path or ".tscn" in resource_path: # Built-in resource will be saved by scene
		return
	
	ResourceSaver.save(resource_path, focused_state_machine)

func create_transition(from, to):
	var new_transition = _requesting_transition if _requesting_transition else Transition.new()
	new_transition.from = from
	new_transition.to = to
	return new_transition

func add_node_action(node):
	undo_redo.create_action("Add State Node")
	undo_redo.add_do_method(self, "add_node", node)
	undo_redo.add_undo_method(self, "delete_node", node)
	undo_redo.commit_action()

func delete_node_action(node):
	undo_redo.create_action("Delete State Node")
	undo_redo.add_do_method(self, "delete_node", node)
	undo_redo.add_undo_method(self, "add_node", node)
	undo_redo.commit_action()

func set_focused_state_machine(state_machine):
	if focused_state_machine != state_machine:
		focused_state_machine = state_machine
		_on_focused_state_machine_changed(state_machine)

func connect_action(from, from_slot, to, to_slot):
	undo_redo.create_action("Connect")
	undo_redo.add_do_method(self, "connect_node", from, from_slot, to, to_slot)
	undo_redo.add_undo_method(self, "disconnect_node", from, from_slot, to, to_slot)
	var node = get_node(from)
	var editor = TransitionEditor.instance()
	var transition = create_transition(from, to)
	undo_redo.add_do_method(node, "add_transition_editor", editor, transition)
	undo_redo.add_undo_method(node, "remove_transition_editor", editor)
	undo_redo.add_do_method(focused_state_machine, "add_transition", transition)
	undo_redo.add_undo_method(focused_state_machine, "remove_transition", from, to)
	undo_redo.commit_action()

func disconnect_action(from, from_slot, to, to_slot):
	undo_redo.create_action("Disconnect")
	undo_redo.add_do_method(self, "disconnect_node", from, from_slot, to, to_slot)
	undo_redo.add_undo_method(self, "connect_node", from, from_slot, to, to_slot)
	var node = get_node(from)
	var editor = node.Transitions.get_node(to)
	var transition = editor.transition
	undo_redo.add_do_method(node, "remove_transition_editor", editor)
	undo_redo.add_undo_method(node, "add_transition_editor", editor, transition)
	undo_redo.add_do_method(focused_state_machine, "remove_transition", from, to)
	undo_redo.add_undo_method(focused_state_machine, "add_transition", transition)
	undo_redo.commit_action()

# Free nodes cached in UndoRedo stack
func free_node_from_undo_redo():
	for node in _to_free:
		if is_instance_valid(node):
			if node.has_method("free_node_from_undo_redo"):
				node.free_node_from_undo_redo()
			node.queue_free()
	_to_free.clear()

# Data holder for request emitted by GraphEdit
class GraphRequest:
	var type
	var args

	func _init(p_type=-1, p_args={}):
		type = p_type
		args = p_args
