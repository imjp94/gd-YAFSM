@tool
extends "res://addons/imjp94.yafsm/scenes/flowchart/FlowChartLine.gd"
const Transition = preload("../../src/transitions/Transition.gd")
const ValueCondition = preload("../../src/conditions/ValueCondition.gd")

const hi_res_font: Font = preload("res://addons/imjp94.yafsm/assets/fonts/sans_serif.tres")

@export var upright_angle_range: = 5.0

@onready var label_margin = $MarginContainer
@onready var vbox = $MarginContainer/VBoxContainer

var undo_redo

var transition:
	set = set_transition
var template = "{condition_name} {condition_comparation} {condition_value}"

var _template_var = {}

func _init():
	super._init()
	
	set_transition(Transition.new())

func _draw():
	super._draw()

	var abs_rotation = abs(rotation)
	var is_flip = abs_rotation > deg_to_rad(90.0)
	var is_upright = (abs_rotation > (deg_to_rad(90.0) - deg_to_rad(upright_angle_range))) and (abs_rotation < (deg_to_rad(90.0) + deg_to_rad(upright_angle_range)))

	if is_upright:
		var x_offset = label_margin.size.x / 2
		var y_offset = -label_margin.size.y
		label_margin.position = Vector2((size.x - x_offset) / 2, 0)
	else:
		var x_offset = label_margin.size.x
		var y_offset = -label_margin.size.y
		if is_flip:
			label_margin.rotation = deg_to_rad(180)
			label_margin.position = Vector2((size.x + x_offset) / 2, 0)
		else:
			label_margin.rotation = deg_to_rad(0)
			label_margin.position = Vector2((size.x - x_offset) / 2, y_offset)

# Update overlay text
func update_label():
	if transition:
		var template_var = {"condition_name": "", "condition_comparation": "", "condition_value": null}
		for label in vbox.get_children():
			if not (str(label.name) in transition.conditions.keys()):  # Names of nodes are now of type StringName, not simple strings!
				vbox.remove_child(label)
				label.queue_free()
		for condition in transition.conditions.values():
			var label = vbox.get_node_or_null(NodePath(condition.name))
			if not label:
				label = Label.new()
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.add_theme_font_override("font", hi_res_font)
				label.name = condition.name
				vbox.add_child(label)
			if "value" in condition:
				template_var["condition_name"] = condition.name
				template_var["condition_comparation"] = ValueCondition.COMPARATION_SYMBOLS[condition.comparation]
				template_var["condition_value"] = condition.get_value_string()
				label.text = template.format(template_var)
				var override_template_var = _template_var.get(condition.name)
				if override_template_var:
					label.text = label.text.format(override_template_var)
			else:
				label.text = condition.name
	queue_redraw()

func _on_transition_changed(new_transition):
	if not is_inside_tree():
		return

	if new_transition:
		new_transition.condition_added.connect(_on_transition_condition_added)
		new_transition.condition_removed.connect(_on_transition_condition_removed)
		for condition in new_transition.conditions.values():
			condition.name_changed.connect(_on_condition_name_changed)
			condition.display_string_changed.connect(_on_condition_display_string_changed)
	update_label()

func _on_transition_condition_added(condition):
	condition.name_changed.connect(_on_condition_name_changed)
	condition.display_string_changed.connect(_on_condition_display_string_changed)
	update_label()

func _on_transition_condition_removed(condition):
	condition.name_changed.disconnect(_on_condition_name_changed)
	condition.display_string_changed.disconnect(_on_condition_display_string_changed)
	update_label()

func _on_condition_name_changed(from, to):
	var label = vbox.get_node_or_null(NodePath(from))
	if label:
		label.name = to
	update_label()

func _on_condition_display_string_changed(display_string):
	update_label()

func set_transition(t):
	if transition != t:
		if transition:
			if transition.condition_added.is_connected(_on_transition_condition_added):
				transition.condition_added.disconnect(_on_transition_condition_added)
		transition = t
		_on_transition_changed(transition)
