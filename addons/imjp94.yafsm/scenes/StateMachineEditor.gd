tool
extends "res://addons/imjp94.yafsm/scenes/flowchart/FlowChart.gd"
const StateMachine = preload("../src/states/StateMachine.gd")
const Transition = preload("../src/transitions/Transition.gd")
const State = preload("../src/states/State.gd")
const StateNode = preload("state_nodes/StateNode.tscn")
const TransitionLine = preload("transition_editors/TransitionLine.tscn")
const StateNodeScript = preload("state_nodes/StateNode.gd")

signal inspector_changed(property)

onready var ContextMenu = $ContextMenu
onready var SaveDialog = $SaveDialog
onready var CreateNewStateMachineContainer = $MarginContainer
onready var CreateNewStateMachine = $MarginContainer/CreateNewStateMachine

var editor_accent_color = Color.white
var transition_arrow_icon

var undo_redo

var condition_visibility = TextureButton.new()

var state_machine_player setget set_state_machine_player
export(Resource) var state_machine setget set_state_machine

var _to_free


func _init():
	_to_free = []

func _ready():
	condition_visibility.hint_tooltip = "Hide/Show Conditions on Transition Line"
	condition_visibility.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	condition_visibility.toggle_mode = true
	condition_visibility.size_flags_vertical = SIZE_SHRINK_CENTER
	condition_visibility.focus_mode = FOCUS_NONE
	condition_visibility.connect("pressed", self, "_on_condition_visibility_pressed")
	condition_visibility.pressed = true
	gadget.add_child(condition_visibility)

	CreateNewStateMachineContainer.visible = false
	CreateNewStateMachine.connect("pressed", self, "_on_CreateNewStateMachine_pressed")
	ContextMenu.connect("index_pressed", self, "_on_ContextMenu_index_pressed")
	SaveDialog.connect("confirmed", self, "_on_SaveDialog_confirmed")

func _on_condition_visibility_pressed():
	for line in content_lines.get_children():
		line.label.visible = condition_visibility.pressed
		if line.label.visible:
			line.update_label()

func _on_state_machine_player_changed(new_state_machine_player):
	if new_state_machine_player:
		CreateNewStateMachineContainer.visible = !new_state_machine_player.state_machine
	else:
		CreateNewStateMachineContainer.visible = false

func _on_CreateNewStateMachine_pressed():
	var new_state_machine = StateMachine.new()
	state_machine_player.state_machine = new_state_machine
	state_machine = new_state_machine
	CreateNewStateMachineContainer.visible = false
	emit_signal("inspector_changed", "state_machine")

func set_state_machine_player(smp):
	if state_machine_player != smp:
		state_machine_player = smp
		_on_state_machine_player_changed(smp)

func _gui_input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_RIGHT:
				if event.pressed:
					ContextMenu.set_item_disabled(1, state_machine.has_entry())
					ContextMenu.set_item_disabled(2, state_machine.has_exit())
					ContextMenu.rect_position = get_viewport().get_mouse_position()
					ContextMenu.popup()

	if visible and event is InputEventKey:
		if event.control:
			if event.scancode == KEY_S and event.pressed:
				save_request()

func create_line_instance():
	var line = TransitionLine.instance()
	line.theme.get_stylebox("focus", "FlowChartLine").shadow_color = editor_accent_color
	line.theme.set_icon("arrow", "FlowChartLine", transition_arrow_icon)
	return line

func save_request():
	if not can_save():
		return

	SaveDialog.dialog_text = "Saving StateMachine to %s" % state_machine.resource_path
	SaveDialog.popup_centered()

func save():
	if not can_save():
		return
	
	ResourceSaver.save(state_machine.resource_path, state_machine)

func clear_graph():
	clear_connections()
	for child in content_nodes.get_children():
		if child is StateNodeScript:
			content_nodes.remove_child(child)
			_to_free.append(child)
	
func draw_graph():
	for state_key in state_machine.states.keys():
		# TODO: Add State.is_exit()/is_entry()
		# var is_entry = state_key == State.ENTRY_KEY
		# var is_exit = state_key == State.EXIT_KEY
		var state = state_machine.states[state_key]
		var new_node = StateNode.instance()
		# if is_entry:
		# 	new_node = EntryStateNode.instance()
		# elif is_exit:
		# 	new_node = ExitStateNode.instance()
		# else:
		# 	new_node = StateNode.instance()
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

func _on_ContextMenu_index_pressed(index):
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

func _on_SaveDialog_confirmed():
	save()

func _on_node_dragged(node, dragged):
	node.state.graph_offset = node.rect_position

func _on_node_added(new_node):
	new_node.undo_redo = undo_redo
	new_node.state.name = new_node.name
	new_node.state.graph_offset = new_node.rect_position
	new_node.connect("name_edit_entered", self, "_on_node_name_edit_entered", [new_node])
	state_machine.add_state(new_node.state)

func _on_node_removed(node_name):
	return state_machine.remove_state(node_name)

func _on_connect_node(from, to):
	if state_machine.transitions.has(from):
		if state_machine.transitions[from].has(to):
			return # Already existed as it is loaded from file

	var line = _connections[from][to].line
	var new_transition = Transition.new(from, to)
	line.transition = new_transition
	state_machine.add_transition(new_transition)

func _on_disconnect_node(from, to):
	state_machine.remove_transition(from, to)

func _on_state_machine_changed(new_state_machine):
	clear_graph()
	if new_state_machine:
		draw_graph()

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

func can_save():
	if not state_machine:
		return false
	var resource_path = state_machine.resource_path
	if ".scn" in resource_path or ".tscn" in resource_path: # Built-in resource will be saved by scene
		return false
	return true

func set_state_machine(sm):
	if state_machine != sm:
		state_machine = sm
		_on_state_machine_changed(sm)
