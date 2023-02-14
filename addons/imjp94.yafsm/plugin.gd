@tool
extends EditorPlugin
const YAFSM = preload("YAFSM.gd")
const StackPlayer = YAFSM.StackPlayer
const StateMachinePlayer = YAFSM.StateMachinePlayer

const StateMachineEditor = preload("scenes/StateMachineEditor.tscn")
const TransitionInspector = preload("scenes/transition_editors/TransitionInspector.gd")
const StateInspector = preload("scenes/state_nodes/StateInspector.gd")

const StackPlayerIcon = preload("assets/icons/stack_player_icon.png")
const StateMachinePlayerIcon = preload("assets/icons/state_machine_player_icon.png")

var state_machine_editor = StateMachineEditor.instantiate()
var transition_inspector = TransitionInspector.new()
var state_inspector = StateInspector.new()

var focused_object:  # Can be StateMachine/StateMachinePlayer
	set = set_focused_object
var editor_selection

var _handled_and_ready_to_edit = false  # forces _handles => _edit flow

func _enter_tree():
	editor_selection = get_editor_interface().get_selection()
	editor_selection.selection_changed.connect(_on_EditorSelection_selection_changed)
	var editor_base_control = get_editor_interface().get_base_control()
	add_custom_type("StackPlayer", "Node", StackPlayer, StackPlayerIcon)
	add_custom_type("StateMachinePlayer", "Node", StateMachinePlayer, StateMachinePlayerIcon)
	
	state_machine_editor.selection_stylebox.bg_color = editor_base_control.get_theme_color("box_selection_fill_color", "Editor")
	state_machine_editor.selection_stylebox.border_color = editor_base_control.get_theme_color("box_selection_stroke_color", "Editor")
	state_machine_editor.zoom_minus.icon = editor_base_control.get_theme_icon("ZoomLess", "EditorIcons")
	state_machine_editor.zoom_reset.icon = editor_base_control.get_theme_icon("ZoomReset", "EditorIcons")
	state_machine_editor.zoom_plus.icon = editor_base_control.get_theme_icon("ZoomMore", "EditorIcons")
	state_machine_editor.snap_button.icon = editor_base_control.get_theme_icon("SnapGrid", "EditorIcons")
	state_machine_editor.condition_visibility.texture_pressed = editor_base_control.get_theme_icon("GuiVisibilityVisible", "EditorIcons")
	state_machine_editor.condition_visibility.texture_normal = editor_base_control.get_theme_icon("GuiVisibilityHidden", "EditorIcons")
	state_machine_editor.editor_accent_color = editor_base_control.get_theme_color("accent_color", "Editor")
	state_machine_editor.current_layer.editor_accent_color = state_machine_editor.editor_accent_color
	state_machine_editor.transition_arrow_icon = editor_base_control.get_theme_icon("TransitionImmediateBig", "EditorIcons")
	state_machine_editor.inspector_changed.connect(_on_inspector_changed)
	state_machine_editor.node_selected.connect(_on_StateMachineEditor_node_selected)
	state_machine_editor.node_deselected.connect(_on_StateMachineEditor_node_deselected)
	state_machine_editor.debug_mode_changed.connect(_on_StateMachineEditor_debug_mode_changed)
	# Force anti-alias for default font, so rotated text will looks smoother
	var font = editor_base_control.get_theme_font("main", "EditorFonts")
	# font.use_filter = true

	transition_inspector.undo_redo = get_undo_redo()
	transition_inspector.transition_icon = editor_base_control.get_theme_icon("ToolConnect", "EditorIcons")
	add_inspector_plugin(transition_inspector)
	add_inspector_plugin(state_inspector)

func _exit_tree():
	remove_custom_type("StackPlayer")
	remove_custom_type("StateMachinePlayer")

	remove_inspector_plugin(transition_inspector)
	remove_inspector_plugin(state_inspector)

	if state_machine_editor:
		state_machine_editor.queue_free()

func _handles(object):
	if object is StateMachine:
		_handled_and_ready_to_edit = true  # this should not be necessary, but it seemingly is (Godot 4.0-rc1)
		return true  # when return true from _handles, _edit can proceed.
	if object is StateMachinePlayer:
		if object.get_class() == "EditorDebuggerRemoteObject":
			set_focused_object(object)
			state_machine_editor.debug_mode = true
			return false
	return false

func _edit(object):
	if _handled_and_ready_to_edit:  # Forces _handles => _edit flow. This should not be necessary, but it seemingly is (Godot 4.0-rc1)
		_handled_and_ready_to_edit = false
		set_focused_object(object)

func show_state_machine_editor():
	if focused_object and state_machine_editor:
		if not state_machine_editor.is_inside_tree():
			add_control_to_bottom_panel(state_machine_editor, "StateMachine")
		make_bottom_panel_item_visible(state_machine_editor)

func hide_state_machine_editor():
	if state_machine_editor.is_inside_tree():
		state_machine_editor.state_machine = null
		remove_control_from_bottom_panel(state_machine_editor)

func _on_EditorSelection_selection_changed():
	if editor_selection == null:
		return
	
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
		show_state_machine_editor()
		var state_machine
		if focused_object is StateMachinePlayer:
			if focused_object.get_class() == "EditorDebuggerRemoteObject":
				state_machine = focused_object.get("Members/state_machine")
			else:
				state_machine = focused_object.state_machine
			state_machine_editor.state_machine_player = focused_object
		elif focused_object is StateMachine:
			state_machine = focused_object
			state_machine_editor.state_machine_player = null
		state_machine_editor.state_machine = state_machine
	else:
		hide_state_machine_editor()

func _on_inspector_changed(property):
	#get_editor_interface().get_inspector().refresh()
	notify_property_list_changed()

func _on_StateMachineEditor_node_selected(node):
	var to_inspect
	if "state" in node:
		if node.state is StateMachine: # Ignore, inspect state machine will trigger edit()
			return
		to_inspect = node.state
	elif "transition" in node:
		to_inspect = node.transition
	get_editor_interface().inspect_object(to_inspect)

func _on_StateMachineEditor_node_deselected(node):
	# editor_selection.remove_node(node)
	get_editor_interface().inspect_object(state_machine_editor.state_machine)

func _on_StateMachineEditor_debug_mode_changed(new_debug_mode):
	if not new_debug_mode:
		state_machine_editor.debug_mode = false
		state_machine_editor.state_machine_player = null
		set_focused_object(null)
		hide_state_machine_editor()

func set_focused_object(obj):
	if focused_object != obj:
		focused_object = obj
		_on_focused_object_changed(obj)
