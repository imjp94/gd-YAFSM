tool
extends "res://addons/imjp94.yafsm/scenes/flowchart/FlowChart.gd"
const StateMachine = preload("../src/states/StateMachine.gd")
const Transition = preload("../src/transitions/Transition.gd")
const State = preload("../src/states/State.gd")
const StateNode = preload("state_nodes/StateNode.tscn")
const TransitionLine = preload("transition_editors/TransitionLine.tscn")
const StateNodeScript = preload("state_nodes/StateNode.gd")

signal inspector_changed(property) # Inform plugin to refresh inspector

const ENTRY_STATE_MISSING_MSG = {
	"key": "entry_state_missing",
	"text": "Entry State is required for StateMachine to work properly. Right-click then select \"Add Entry\"."
}

onready var context_menu = $ContextMenu
onready var save_dialog = $SaveDialog
onready var create_new_state_machine_container = $MarginContainer
onready var create_new_state_machine = $MarginContainer/CreateNewStateMachine
var condition_visibility = TextureButton.new()
var message_box = VBoxContainer.new()

var editor_accent_color = Color.white
var transition_arrow_icon

var undo_redo

var state_machine_player setget set_state_machine_player
var state_machine setget set_state_machine

var _message_box_dict = {}
var _to_free


func _init():
	_to_free = []

	condition_visibility.hint_tooltip = "Hide/Show Conditions on Transition Line"
	condition_visibility.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	condition_visibility.toggle_mode = true
	condition_visibility.size_flags_vertical = SIZE_SHRINK_CENTER
	condition_visibility.focus_mode = FOCUS_NONE
	condition_visibility.connect("pressed", self, "_on_condition_visibility_pressed")
	condition_visibility.pressed = true
	gadget.add_child(condition_visibility)

	message_box.set_anchors_and_margins_preset(PRESET_BOTTOM_WIDE)
	message_box.grow_vertical = GROW_DIRECTION_BEGIN
	add_child(message_box)

func _ready():
	create_new_state_machine_container.visible = false
	create_new_state_machine.connect("pressed", self, "_on_create_new_state_machine_pressed")
	context_menu.connect("index_pressed", self, "_on_context_menu_index_pressed")
	save_dialog.connect("confirmed", self, "_on_save_dialog_confirmed")

func _on_context_menu_index_pressed(index):
	var new_node = StateNode.instance()
	new_node.theme.get_stylebox("focus", "FlowChartNode").border_color = editor_accent_color
	match index:
		0: # Add State
			new_node.name = "State"
		1: # Add Entry
			if State.ENTRY_KEY in state_machine.states:
				push_warning("Entry node already exist")
				return
			new_node.name = State.ENTRY_KEY
		2: # Add Exit
			if State.EXIT_KEY in state_machine.states:
				push_warning("Exit node already exist")
				return
			new_node.name = State.EXIT_KEY
	new_node.rect_position = content_position(get_local_mouse_position())
	add_node(new_node)

func _on_save_dialog_confirmed():
	save()

func _on_create_new_state_machine_pressed():
	var new_state_machine = StateMachine.new()
	state_machine_player.state_machine = new_state_machine
	state_machine = new_state_machine
	create_new_state_machine_container.visible = false
	check_has_entry()
	emit_signal("inspector_changed", "state_machine")

func _on_condition_visibility_pressed():
	for line in content_lines.get_children():
		line.label.visible = condition_visibility.pressed

func _on_state_machine_player_changed(new_state_machine_player):
	if new_state_machine_player:
		create_new_state_machine_container.visible = !new_state_machine_player.state_machine
	else:
		create_new_state_machine_container.visible = false

func _on_state_machine_changed(new_state_machine):
	clear_graph()
	if new_state_machine:
		draw_graph()
		check_has_entry()

func _gui_input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_RIGHT:
				if event.pressed:
					context_menu.set_item_disabled(1, state_machine.has_entry())
					context_menu.set_item_disabled(2, state_machine.has_exit())
					context_menu.rect_position = get_viewport().get_mouse_position()
					context_menu.popup()

	if visible and event is InputEventKey:
		match event.scancode:
			KEY_S:
				if event.control and event.pressed:
						save_request()

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
	
	ResourceSaver.save(state_machine.resource_path, state_machine)

# Clear editor
func clear_graph():
	clear_connections()
	for child in content_nodes.get_children():
		if child is StateNodeScript:
			content_nodes.remove_child(child)
			_to_free.append(child)

# Intialize editor with current editing StateMachine
func draw_graph():
	for state_key in state_machine.states.keys():
		var state = state_machine.states[state_key]
		var new_node = StateNode.instance()
		new_node.theme.get_stylebox("focus", "FlowChartNode").border_color = editor_accent_color

		new_node.name = state_key # Set before add_node to let engine handle duplicate name
		add_node(new_node)
		# Set after add_node to make sure UIs are initialized
		new_node.state = state
		new_node.state.name = state_key
		new_node.rect_position = state.graph_offset
	for state_key in state_machine.states.keys():
		var from_transitions = state_machine.transitions.get(state_key)
		if from_transitions:
			for transition in from_transitions.values():
				connect_node(transition.from, transition.to)
				_connections[transition.from][transition.to].line.transition = transition
	update()

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
		return true
	return false

# Check if current editing StateMachine has entry, warns user if entry state missing
func check_has_entry():
	if not state_machine.has_entry():
		if not (ENTRY_STATE_MISSING_MSG.key in _message_box_dict):
			add_message(ENTRY_STATE_MISSING_MSG.key, ENTRY_STATE_MISSING_MSG.text)
	else:
		if ENTRY_STATE_MISSING_MSG.key in  _message_box_dict:
			remove_message(ENTRY_STATE_MISSING_MSG.key)

func _on_node_dragged(node, dragged):
	node.state.graph_offset = node.rect_position

func _on_node_added(new_node):
	new_node.undo_redo = undo_redo
	new_node.state.name = new_node.name
	new_node.state.graph_offset = new_node.rect_position
	new_node.connect("name_edit_entered", self, "_on_node_name_edit_entered", [new_node])
	state_machine.add_state(new_node.state)
	check_has_entry()

func _on_node_removed(node_name):
	var result = state_machine.remove_state(node_name)
	check_has_entry()
	return result

func _on_node_connected(from, to):
	if state_machine.transitions.has(from):
		if state_machine.transitions[from].has(to):
			return # Already existed as it is loaded from file

	var line = _connections[from][to].line
	var new_transition = Transition.new(from, to)
	line.transition = new_transition
	state_machine.add_transition(new_transition)

func _on_node_disconnected(from, to):
	state_machine.remove_transition(from, to)

func _on_duplicated(old_nodes, new_nodes):
	# Duplicate condition as well
	for i in old_nodes.size():
		var from_node = old_nodes[i]
		for connection_pair in get_connection_list():
			if from_node.name == connection_pair.from:
				for j in old_nodes.size():
					var to_node = old_nodes[j]
					if to_node.name == connection_pair.to:
						var old_connection = _connections[connection_pair.from][connection_pair.to]
						var new_connection = _connections[new_nodes[i].name][new_nodes[j].name]
						for condition in old_connection.line.transition.conditions.values():
							new_connection.line.transition.add_condition(condition.duplicate())

func _on_node_name_edit_entered(new_name, node):
	var old = node.state.name
	var new = new_name
	if old == new:
		return

	if state_machine.change_state_name(old, new):
		rename_node(node.name, new)
		node.name = new
	else:
		node.name_edit.text = old

# Return if current editing StateMachine can be saved, ignore built-in resource
func can_save():
	if not state_machine:
		return false
	var resource_path = state_machine.resource_path
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
