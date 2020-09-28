tool
extends EditorPlugin
const StateMachine = preload("src/StateMachine.gd")
const State = preload("src/State.gd")
const Transition = preload("src/Transition.gd")
const Condition = preload("src/Condition.gd")
const ValueCondition = preload("src/ValueCondition.gd")
const BooleanCondition = preload("src/BooleanCondition.gd")
const IntegerCondition = preload("src/IntegerCondition.gd")
const FloatCondition = preload("src/FloatCondition.gd")

const GraphEditor = preload("scenes/GraphEdit.tscn")

var graph_editor


func _enter_tree():
	var editor_base_control = get_editor_interface().get_base_control()
	var node_icon = editor_base_control.get_icon("Node", "EditorIcons")
	var resource_icon = editor_base_control.get_icon("ResourcePreloader", "EditorIcons")
	add_custom_type("StateMachine", "Node", StateMachine, node_icon)
	add_custom_type("State", "Resource", State, resource_icon)
	add_custom_type("Transition", "Resource", Transition, resource_icon)
	add_custom_type("Condition", "Resource", Condition, resource_icon)
	add_custom_type("ValueCondition", "Resource", ValueCondition, resource_icon)
	add_custom_type("BooleanCondition", "Resource", BooleanCondition, resource_icon)
	add_custom_type("IntegerCondition", "Resource", IntegerCondition, resource_icon)
	add_custom_type("FloatCondition", "Resource", FloatCondition, resource_icon)

	graph_editor = GraphEditor.instance()
	add_control_to_bottom_panel(graph_editor, "YAFSM")

func _exit_tree():
	if graph_editor:
		graph_editor.queue_free()

func handles(object):
	if object is Transition:
		make_visible(true)
		return true
	make_visible(false)
	return false

func edit(object):
	if graph_editor:
		graph_editor.focused_object = object

func make_visible(visible):
	if graph_editor:
		graph_editor.visible = visible