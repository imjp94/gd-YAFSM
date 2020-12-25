tool
extends EditorPlugin
const YAFSM = preload("YAFSM.gd")
const StackPlayer = YAFSM.StackPlayer
const StateMachinePlayer = YAFSM.StateMachinePlayer
const StateMachine = YAFSM.StateMachine
const State = YAFSM.State

const StateMachineEditorContainer = preload("scenes/StateMachineEditorContainer.tscn")
const TransitionInspector = preload("scenes/transition_editors/TransitionInspector.gd")

var state_machine_editor_container
var state_machine_editor

var focused_object setget set_focused_object # Can be StateMachine/StateMachinePlayer
var editor_selection

var transition_inspector = TransitionInspector.new()


func _enter_tree():
	editor_selection = get_editor_interface().get_selection()
	editor_selection.connect("selection_changed", self, "_on_EditorSelection_selection_changed")
	var editor_base_control = get_editor_interface().get_base_control()
	var node_icon = editor_base_control.get_icon("Node", "EditorIcons")
	var control_icon = editor_base_control.get_icon("Control", "EditorIcons")
	var resource_icon = editor_base_control.get_icon("ResourcePreloader", "EditorIcons")
	add_custom_type("StackPlayer", "Node", StackPlayer, node_icon)
	add_custom_type("StateMachinePlayer", "Node", StateMachinePlayer, node_icon)
	add_custom_type("StateMachine", "Resource", StateMachine, resource_icon)

	state_machine_editor_container = StateMachineEditorContainer.instance()
	state_machine_editor = state_machine_editor_container.get_node("StateMachineEditor")
	state_machine_editor.undo_redo = get_undo_redo()
	# Force anti-alias for default font
	var font = get_editor_interface().get_base_control().get_font("main", "EditorFonts")
	font.use_filter = true
	state_machine_editor_container.connect("inspector_changed", self, "_on_inspector_changed")
	state_machine_editor.connect("node_selected", self, "_on_StateMachineEditor_node_selected")
	state_machine_editor.connect("node_deselected", self, "_on_StateMachineEditor_node_deselected")

	transition_inspector.undo_redo = get_undo_redo()
	add_inspector_plugin(transition_inspector)

func _exit_tree():
	if state_machine_editor_container:
		state_machine_editor_container.queue_free()

func handles(object):
	if object is StateMachine:
		return true
	return false

func edit(object):
	set_focused_object(object)

func show_state_machine_editor_container():
	if focused_object and state_machine_editor_container:
		if not state_machine_editor_container.is_inside_tree():
			add_control_to_bottom_panel(state_machine_editor_container, "StateMachine")
		make_bottom_panel_item_visible(state_machine_editor_container)

func hide_state_machine_editor_container():
	if state_machine_editor_container.is_inside_tree():
		state_machine_editor.state_machine = null
		remove_control_from_bottom_panel(state_machine_editor_container)

func _on_EditorSelection_selection_changed():
	var selected_nodes = editor_selection.get_selected_nodes()
	if selected_nodes.size() == 1:
		var selected_node = selected_nodes[0]
		if selected_node is StateMachinePlayer:
			set_focused_object(selected_node)
			return
	set_focused_object(null)

func _on_focused_object_changed(new_obj):
	if new_obj:
		# Must be shown first, otherwise StateMachineEditor can't execute ui action as it is not added to scene tree
		show_state_machine_editor_container()
		var state_machine
		if focused_object is StateMachinePlayer:
			state_machine = focused_object.state_machine
			state_machine_editor_container.state_machine_player = focused_object
		elif focused_object is StateMachine:
			state_machine = focused_object
		state_machine_editor.state_machine = state_machine
	else:
		hide_state_machine_editor_container()

func _on_inspector_changed(property):
	get_editor_interface().get_inspector().refresh()

func _on_StateMachineEditor_node_selected(node):
	var to_inspect
	if "state" in node:
		to_inspect = node.state
	elif "transition" in node:
		to_inspect = node.transition
	get_editor_interface().inspect_object(to_inspect)

func _on_StateMachineEditor_node_deselected(node):
	get_editor_interface().inspect_object(null)

func set_focused_object(obj):
	if focused_object != obj:
		focused_object = obj
		_on_focused_object_changed(obj)
