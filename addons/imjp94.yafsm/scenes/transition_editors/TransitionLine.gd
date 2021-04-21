tool
extends "res://addons/imjp94.yafsm/scenes/flowchart/FlowChartLine.gd"
const Transition = preload("../../src/transitions/Transition.gd")
const ValueCondition = preload("../../src/conditions/ValueCondition.gd")

export var upright_angle_range = 10.0

onready var label_margin = $MarginContainer
onready var vbox = $MarginContainer/VBoxContainer

var undo_redo

var transition setget set_transition
var template = "{condition_name} {condition_comparation} {condition_value}"

var _template_var = {}

func _init():
	set_transition(Transition.new())

func _draw():
	._draw()

	var abs_rect_rotation = abs(rect_rotation)
	var is_flip = abs_rect_rotation > 90.0
	var is_upright = abs_rect_rotation > 90.0 - upright_angle_range and abs_rect_rotation < 90.0 + upright_angle_range
	if is_upright:
		var x_offset = label_margin.rect_size.x / 2
		var y_offset = -label_margin.rect_size.y
		label_margin.rect_rotation = -rect_rotation
		if rect_rotation > 0:
			label_margin.rect_position = Vector2((rect_size.x - x_offset) / 2, 0)
		else:
			label_margin.rect_position = Vector2((rect_size.x + x_offset) / 2, y_offset * 2)
	else:
		var x_offset = label_margin.rect_size.x
		var y_offset = -label_margin.rect_size.y
		if is_flip:
			label_margin.rect_rotation = 180
			label_margin.rect_position = Vector2((rect_size.x + x_offset) / 2, 0)
		else:
			label_margin.rect_rotation = 0
			label_margin.rect_position = Vector2((rect_size.x - x_offset) / 2, y_offset)

# Update overlay text
func update_label():
	if transition:
		var template_var = {"condition_name": "", "condition_comparation": "", "condition_value": null}
		for label in vbox.get_children():
			if not (label.name in transition.conditions.keys()):
				vbox.remove_child(label)
				label.queue_free()
		for condition in transition.conditions.values():
			var label = vbox.get_node_or_null(condition.name)
			if not label:
				label = Label.new()
				label.align = label.ALIGN_CENTER
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
	update()

func _on_transition_changed(new_transition):
	if not is_inside_tree():
		return

	if new_transition:
		new_transition.connect("condition_added", self, "_on_transition_condition_added")
		new_transition.connect("condition_removed", self, "_on_transition_condition_removed")
		for condition in new_transition.conditions.values():
			condition.connect("name_changed", self, "_on_condition_name_changed")
			condition.connect("display_string_changed", self, "_on_condition_display_string_changed")
	update_label()

func _on_transition_condition_added(condition):
	condition.connect("name_changed", self, "_on_condition_name_changed")
	condition.connect("display_string_changed", self, "_on_condition_display_string_changed")
	update_label()

func _on_transition_condition_removed(condition):
	condition.disconnect("name_changed", self, "_on_condition_name_changed")
	condition.disconnect("display_string_changed", self, "_on_condition_display_string_changed")
	update_label()

func _on_condition_name_changed(from, to):
	var label = vbox.get_node_or_null(from)
	if label:
		label.name = to
	update_label()

func _on_condition_display_string_changed(display_string):
	update_label()

func set_transition(t):
	if transition != t:
		if transition:
			if transition.is_connected("condition_added", self, "_on_transition_condition_added"):
				transition.disconnect("condition_added", self, "_on_transition_condition_added")
		transition = t
		_on_transition_changed(transition)
