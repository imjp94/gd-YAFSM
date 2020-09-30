tool
extends EditorPlugin
const StateMachinePlayer = preload("src/StateMachinePlayer.gd")
const StateMachine = preload("src/states/StateMachine.gd")
const State = preload("src/states/State.gd")
const Transition = preload("src/transitions/Transition.gd")
const Condition = preload("src/conditions/Condition.gd")
const ValueCondition = preload("src/conditions/ValueCondition.gd")
const BooleanCondition = preload("src/conditions/BooleanCondition.gd")
const IntegerCondition = preload("src/conditions/IntegerCondition.gd")
const FloatCondition = preload("src/conditions/FloatCondition.gd")

const StateMachineEditor = preload("scenes/StateMachineEditor.tscn")

var state_machine_editor

var focused_object


func _enter_tree():
	var editor_base_control = get_editor_interface().get_base_control()
	var node_icon = editor_base_control.get_icon("Node", "EditorIcons")
	var resource_icon = editor_base_control.get_icon("ResourcePreloader", "EditorIcons")
	add_custom_type("StateMachinePlayer", "Node", StateMachinePlayer, node_icon)
	add_custom_type("StateMachine", "Resource", StateMachine, resource_icon)
	add_custom_type("State", "Resource", State, resource_icon)
	add_custom_type("Transition", "Resource", Transition, resource_icon)
	add_custom_type("Condition", "Resource", Condition, resource_icon)
	add_custom_type("ValueCondition", "Resource", ValueCondition, resource_icon)
	add_custom_type("BooleanCondition", "Resource", BooleanCondition, resource_icon)
	add_custom_type("IntegerCondition", "Resource", IntegerCondition, resource_icon)
	add_custom_type("FloatCondition", "Resource", FloatCondition, resource_icon)

	state_machine_editor = StateMachineEditor.instance()

func _exit_tree():
	if state_machine_editor:
		state_machine_editor.queue_free()

func handles(object):
	if object is StateMachine:
		return true
	return false

func edit(object):
	focused_object = object

func make_visible(visible):
	if state_machine_editor:
		if visible:
			show_state_machine_editor()
		else:
			hide_state_machine_editor()

func show_state_machine_editor():
	if focused_object and state_machine_editor:
		if not state_machine_editor.is_inside_tree():
			add_control_to_bottom_panel(state_machine_editor, "StateMachine")
		make_bottom_panel_item_visible(state_machine_editor)
		state_machine_editor.focused_object = focused_object

func hide_state_machine_editor():
	if state_machine_editor.is_inside_tree():
		state_machine_editor.focused_object = null
		remove_control_from_bottom_panel(state_machine_editor)