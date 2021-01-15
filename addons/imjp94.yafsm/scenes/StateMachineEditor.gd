tool
extends "res://addons/imjp94.yafsm/scenes/flowchart/FlowChart.gd"
const StateMachinePlayer = preload("../src/StateMachinePlayer.gd")
const StateMachine = preload("../src/states/StateMachine.gd")
const Transition = preload("../src/transitions/Transition.gd")
const State = preload("../src/states/State.gd")
const StateNode = preload("state_nodes/StateNode.tscn")
const TransitionLine = preload("transition_editors/TransitionLine.tscn")
const StateNodeScript = preload("state_nodes/StateNode.gd")
const StateMachineEditorLayer = preload("StateMachineEditorLayer.gd")
const PathViewer = preload("PathViewer.gd")

signal inspector_changed(property) # Inform plugin to refresh inspector

const ENTRY_STATE_MISSING_MSG = {
	"key": "entry_state_missing",
	"text": "Entry State missing, it will never get started. Right-click -> \"Add Entry\"."
}
const EXIT_STATE_MISSING_MSG = {
	"key": "exit_state_missing",
	"text": "Exit State missing, it will never exit from nested state. Right-click -> \"Add Exit\"."
}

onready var context_menu = $ContextMenu
onready var state_node_context_menu = $StateNodeContextMenu
onready var convert_to_state_confirmation = $ConvertToStateConfirmation
onready var save_dialog = $SaveDialog
onready var create_new_state_machine_container = $MarginContainer
onready var create_new_state_machine = $MarginContainer/CreateNewStateMachine
var path_viewer = HBoxContainer.new()
var condition_visibility = TextureButton.new()
var unsaved_indicator = Label.new()
var message_box = VBoxContainer.new()

var editor_accent_color = Color.white
var transition_arrow_icon

var undo_redo

var state_machine_player setget set_state_machine_player
var state_machine setget set_state_machine

var _reconnecting_connection
var _last_index = 0
var _last_path = ""
var _message_box_dict = {}
var _context_node
var _to_free


func _init():
	_to_free = []

	path_viewer.mouse_filter = MOUSE_FILTER_IGNORE
	path_viewer.set_script(PathViewer)
	path_viewer.connect("dir_pressed", self, "_on_path_viewer_dir_pressed")
	top_bar.add_child(path_viewer)

	condition_visibility.hint_tooltip = "Hide/Show Conditions on Transition Line"
	condition_visibility.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	condition_visibility.toggle_mode = true
	condition_visibility.size_flags_vertical = SIZE_SHRINK_CENTER
	condition_visibility.focus_mode = FOCUS_NONE
	condition_visibility.connect("pressed", self, "_on_condition_visibility_pressed")
	condition_visibility.pressed = true
	gadget.add_child(condition_visibility)

	unsaved_indicator.size_flags_vertical = SIZE_SHRINK_CENTER
	unsaved_indicator.focus_mode = FOCUS_NONE
	gadget.add_child(unsaved_indicator)

	message_box.set_anchors_and_margins_preset(PRESET_BOTTOM_WIDE)
	message_box.grow_vertical = GROW_DIRECTION_BEGIN
	add_child(message_box)

	content.get_child(0).name = "root"

func _ready():
	create_new_state_machine_container.visible = false
	create_new_state_machine.connect("pressed", self, "_on_create_new_state_machine_pressed")
	context_menu.connect("index_pressed", self, "_on_context_menu_index_pressed")
	state_node_context_menu.connect("index_pressed", self, "_on_state_node_context_menu_index_pressed")
	convert_to_state_confirmation.connect("confirmed", self, "_on_convert_to_state_confirmation_confirmed")
	save_dialog.connect("confirmed", self, "_on_save_dialog_confirmed")

func _on_path_viewer_dir_pressed(path, index):
	path_viewer.remove_dir_until(index) # Before select_layer, so path_viewer will be updated in _on_layer_selected
	select_layer(get_layer(path))

	if _last_index > index:
		# Going backward
		var end_state_parent_path = StateMachinePlayer.path_backward(_last_path)
		var end_state_name = StateMachinePlayer.path_end_dir(_last_path)
		var layer = content.get_node(end_state_parent_path)
		var node = layer.content_nodes.get_node(end_state_name)
		if not node.state.states:
			# Convert state machine node back to state node
			convert_to_state(layer, node)

	_last_index = index
	_last_path = path

func _on_context_menu_index_pressed(index):
	var new_node = StateNode.instance()
	new_node.theme.get_stylebox("focus", "FlowChartNode").border_color = editor_accent_color
	match index:
		0: # Add State
			new_node.name = "State"
		1: # Add Entry
			if State.ENTRY_STATE in current_layer.state_machine.states:
				push_warning("Entry node already exist")
				return
			new_node.name = State.ENTRY_STATE
		2: # Add Exit
			if State.EXIT_STATE in current_layer.state_machine.states:
				push_warning("Exit node already exist")
				return
			new_node.name = State.EXIT_STATE
	new_node.rect_position = content_position(get_local_mouse_position())
	add_node(new_node)

func _on_state_node_context_menu_index_pressed(index):
	if not _context_node:
		return

	match index:
		0: # Copy
			_copying_nodes = [_context_node]
			_context_node = null
		1: # Duplicate
			duplicate_nodes([_context_node])
			_context_node = null
		2: # Separator
			_context_node = null
		3: # Convert
			convert_to_state_confirmation.popup_centered()

func _on_convert_to_state_confirmation_confirmed():
	convert_to_state(current_layer, _context_node)
	_context_node.update() # Update outlook of node
	# Remove layer
	var path = str(path_viewer.get_cwd(), "/", _context_node.name)
	var layer = get_layer(path)
	if layer:
		layer.queue_free()
	_context_node = null

func _on_save_dialog_confirmed():
	save()

func _on_create_new_state_machine_pressed():
	var new_state_machine = StateMachine.new()
	state_machine_player.state_machine = new_state_machine
	set_state_machine(new_state_machine)
	create_new_state_machine_container.visible = false
	check_has_entry()
	emit_signal("inspector_changed", "state_machine")

func _on_condition_visibility_pressed():
	for line in current_layer.content_lines.get_children():
		line.label.visible = condition_visibility.pressed

func _on_state_machine_player_changed(new_state_machine_player):
	if new_state_machine_player:
		create_new_state_machine_container.visible = !new_state_machine_player.state_machine
	else:
		create_new_state_machine_container.visible = false

func _on_state_machine_changed(new_state_machine):
	clear_graph()
	# Reset layers & path viewer
	var to_remove = []
	var root_layer = get_layer("root")
	for child in root_layer.get_children():
		if child is FlowChartLayer:
			root_layer.remove_child(child)
			child.queue_free()
	path_viewer.remove_dir_until(0) # Before select_layer, so path_viewer will be updated in _on_layer_selected
	select_layer(root_layer)
	if new_state_machine:
		current_layer.state_machine = state_machine
		draw_graph()
		check_has_entry()

func _gui_input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_RIGHT:
				if event.pressed:
					context_menu.set_item_disabled(1, current_layer.state_machine.has_entry())
					context_menu.set_item_disabled(2, current_layer.state_machine.has_exit())
					context_menu.rect_position = get_viewport().get_mouse_position()
					context_menu.popup()

func _input(event):
	# Intercept save action
	if visible and event is InputEventKey:
		match event.scancode:
			KEY_S:
				if event.control and event.pressed:
					save_request()

func _on_state_node_gui_input(event, node):
	if node.state.is_entry() or node.state.is_exit():
		return

	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_LEFT:
				if event.pressed:
					if event.doubleclick:
						if node.name_edit.get_rect().has_point(event.position):
							# Edit State name if within LineEdit
							node.enable_name_edit(true)
							accept_event()
						else:
							# Create/Move to new layer
							var new_state_machine = convert_to_state_machine(current_layer, node)
							# Determine current layer path
							var parent_path = path_viewer.get_cwd()
							var path = str(parent_path, "/", node.name)
							var layer = get_layer(path)
							path_viewer.add_dir(node.state.name) # Before select_layer, so path_viewer will be updated in _on_layer_selected
							if layer:
								# Layer already spawned
								select_layer(layer)
							else:
								# New layer to spawn
								layer = add_layer_to(get_layer(parent_path))
								layer.name = node.state.name
								layer.state_machine = new_state_machine
								select_layer(layer)
								draw_graph()
							_last_index = path_viewer.get_child_count()-1
							_last_path = path
							accept_event()
			BUTTON_RIGHT:
				if event.pressed:
					# State node context menu
					_context_node = node
					state_node_context_menu.rect_position = get_viewport().get_mouse_position()
					state_node_context_menu.popup()
					state_node_context_menu.set_item_disabled(3, not (node.state is StateMachine))
					accept_event()

func convert_to_state_machine(layer, node):
	# Convert State to StateMachine
	var new_state_machine
	if node.state is StateMachine:
		new_state_machine = node.state
	else:
		new_state_machine = StateMachine.new()
		new_state_machine.name = node.state.name
		new_state_machine.graph_offset = node.state.graph_offset
		layer.state_machine.remove_state(node.state.name)
		layer.state_machine.add_state(new_state_machine)
		node.state = new_state_machine
	return new_state_machine

func convert_to_state(layer, node):
	# Convert StateMachine to State
	var new_state
	if node.state is StateMachine:
		new_state = State.new()
		new_state.name = node.state.name
		new_state.graph_offset = node.state.graph_offset
		layer.state_machine.remove_state(node.state.name)
		layer.state_machine.add_state(new_state)
		node.state = new_state
	else:
		new_state = node.state
	return new_state

func create_layer_instance():
	var layer = Control.new()
	layer.set_script(StateMachineEditorLayer)
	return layer

func create_line_instance():
	var line = TransitionLine.instance()
	line.theme.get_stylebox("focus", "FlowChartLine").shadow_color = editor_accent_color
	line.theme.set_icon("arrow", "FlowChartLine", transition_arrow_icon)
	return line

# Request to save current editing StateMachine
func save_request():
	if not can_save():
		return

	save_dialog.dialog_text = "Saving StateMachine to %s" % state_machine.resource_path
	save_dialog.popup_centered()

# Save current editing StateMachine
func save():
	if not can_save():
		return
	
	unsaved_indicator.text = ""
	ResourceSaver.save(state_machine.resource_path, state_machine)

# Clear editor
func clear_graph():
	clear_connections()
	for child in current_layer.content_nodes.get_children():
		if child is StateNodeScript:
			current_layer.content_nodes.remove_child(child)
			_to_free.append(child)
	unsaved_indicator.text = "" # Clear graph is not action by user

# Intialize editor with current editing StateMachine
func draw_graph():
	for state_key in current_layer.state_machine.states.keys():
		var state = current_layer.state_machine.states[state_key]
		var new_node = StateNode.instance()
		new_node.theme.get_stylebox("focus", "FlowChartNode").border_color = editor_accent_color
		new_node.name = state_key # Set before add_node to let engine handle duplicate name
		add_node(new_node)
		# Set after add_node to make sure UIs are initialized
		new_node.state = state
		new_node.state.name = state_key
		new_node.rect_position = state.graph_offset
	for state_key in current_layer.state_machine.states.keys():
		var from_transitions = current_layer.state_machine.transitions.get(state_key)
		if from_transitions:
			for transition in from_transitions.values():
				connect_node(transition.from, transition.to)
				current_layer._connections[transition.from][transition.to].line.transition = transition
	update()
	unsaved_indicator.text = "" # Draw graph is not action by user

# Add message to message_box(overlay text at bottom of editor)
func add_message(key, text):
	var label = Label.new()
	label.text = text
	_message_box_dict[key] = label
	message_box.add_child(label)
	return label

# Remove message from message_box
func remove_message(key):
	var control = _message_box_dict.get(key)
	if control:
		_message_box_dict.erase(key)
		message_box.remove_child(control)
		# Weird behavior of VBoxContainer, only sort children properly after changing grow_direction
		message_box.grow_vertical = GROW_DIRECTION_END
		message_box.grow_vertical = GROW_DIRECTION_BEGIN
		return true
	return false

# Check if current editing StateMachine has entry, warns user if entry state missing
func check_has_entry():
	if not current_layer.state_machine:
		return
	if not current_layer.state_machine.has_entry():
		if not (ENTRY_STATE_MISSING_MSG.key in _message_box_dict):
			add_message(ENTRY_STATE_MISSING_MSG.key, ENTRY_STATE_MISSING_MSG.text)
	else:
		if ENTRY_STATE_MISSING_MSG.key in  _message_box_dict:
			remove_message(ENTRY_STATE_MISSING_MSG.key)

# Check if current editing StateMachine is nested and has exit, warns user if exit state missing
func check_has_exit():
	if not current_layer.state_machine:
		return
	if not path_viewer.get_cwd() == "root": # Nested state
		if not current_layer.state_machine.has_exit():
			if not (EXIT_STATE_MISSING_MSG.key in _message_box_dict):
				add_message(EXIT_STATE_MISSING_MSG.key, EXIT_STATE_MISSING_MSG.text)
			return
	if EXIT_STATE_MISSING_MSG.key in _message_box_dict:
		remove_message(EXIT_STATE_MISSING_MSG.key)

func _on_layer_selected(layer):
	if layer:
		layer.show_content()
		check_has_entry()
		check_has_exit()

func _on_layer_deselected(layer):
	if layer:
		layer.hide_content()

func _on_node_dragged(node, dragged):
	node.state.graph_offset = node.rect_position
	_on_edited()

func _on_node_added(new_node):
	new_node.undo_redo = undo_redo
	new_node.state.name = new_node.name
	new_node.state.graph_offset = new_node.rect_position
	new_node.connect("name_edit_entered", self, "_on_node_name_edit_entered", [new_node])
	new_node.connect("gui_input", self, "_on_state_node_gui_input", [new_node])
	current_layer.state_machine.add_state(new_node.state)
	check_has_entry()
	check_has_exit()
	_on_edited()

func _on_node_removed(node_name):
	var path = str(path_viewer.get_cwd(), "/", node_name)
	var layer = get_layer(path)
	if layer:
		# Remove root's direct children layers
		layer.queue_free()
	var result = current_layer.state_machine.remove_state(node_name)
	check_has_entry()
	check_has_exit()
	_on_edited()
	return result

func _on_node_connected(from, to):
	if _reconnecting_connection:
		# Reconnection will trigger _on_node_connected after _on_node_reconnect_end/_on_node_reconnect_failed
		if _reconnecting_connection.from_node.name == from and _reconnecting_connection.to_node.name == to:
			_reconnecting_connection = null
			return
	if current_layer.state_machine.transitions.has(from):
		if current_layer.state_machine.transitions[from].has(to):
			return # Already existed as it is loaded from file

	var line = current_layer._connections[from][to].line
	var new_transition = Transition.new(from, to)
	line.transition = new_transition
	current_layer.state_machine.add_transition(new_transition)
	clear_selection()
	select(line)
	_on_edited()

func _on_node_disconnected(from, to):
	current_layer.state_machine.remove_transition(from, to)
	_on_edited()

func _on_node_reconnect_begin(from, to):
	_reconnecting_connection = current_layer._connections[from][to]
	current_layer.state_machine.remove_transition(from, to)

func _on_node_reconnect_end(from, to):
	var transition = _reconnecting_connection.line.transition
	transition.to = to
	current_layer.state_machine.add_transition(transition)
	clear_selection()
	select(_reconnecting_connection.line)

func _on_node_reconnect_failed(from, to):
	var transition = _reconnecting_connection.line.transition
	current_layer.state_machine.add_transition(transition)
	clear_selection()
	select(_reconnecting_connection.line)

func _request_connect_from(from):
	if from == State.EXIT_STATE:
		return false
	return true

func _request_connect_to(to):
	if to == State.ENTRY_STATE:
		return false
	return true

func _on_duplicated(old_nodes, new_nodes):
	# Duplicate condition as well
	for i in old_nodes.size():
		var from_node = old_nodes[i]
		for connection_pair in get_connection_list():
			if from_node.name == connection_pair.from:
				for j in old_nodes.size():
					var to_node = old_nodes[j]
					if to_node.name == connection_pair.to:
						var old_connection = current_layer._connections[connection_pair.from][connection_pair.to]
						var new_connection = current_layer._connections[new_nodes[i].name][new_nodes[j].name]
						for condition in old_connection.line.transition.conditions.values():
							new_connection.line.transition.add_condition(condition.duplicate())
	_on_edited()

func _on_node_name_edit_entered(new_name, node):
	var old = node.state.name
	var new = new_name
	if old == new:
		return
	if "/" in new or "\\" in new: # No back/forward-slash
		push_warning("Illegal State Name: / and \\ are not allowed in State name(%s)" % new)
		node.name_edit.text = old
		return

	if current_layer.state_machine.change_state_name(old, new):
		rename_node(node.name, new)
		node.name = new
		# Rename layer as well
		var path = str(path_viewer.get_cwd(), "/", node.name)
		var layer = get_layer(path)
		if layer:
			layer.name = new
		for child in path_viewer.get_children():
			if child.text == old:
				child.text = new
				break
		_on_edited()
	else:
		node.name_edit.text = old

func _on_edited():
	unsaved_indicator.text = "*"

# Return if current editing StateMachine can be saved, ignore built-in resource
func can_save():
	if not state_machine:
		return false
	var resource_path = state_machine.resource_path
	if resource_path.empty():
		return false
	if ".scn" in resource_path or ".tscn" in resource_path: # Built-in resource will be saved by scene
		return false
	return true

func set_state_machine_player(smp):
	if state_machine_player != smp:
		state_machine_player = smp
		_on_state_machine_player_changed(smp)

func set_state_machine(sm):
	if state_machine != sm:
		state_machine = sm
		_on_state_machine_changed(sm)
