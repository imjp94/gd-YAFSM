tool
extends "res://addons/imjp94.yafsm/scenes/flowchart/FlowChartLayer.gd"

const Utils = preload("res://addons/imjp94.yafsm/scripts/Utils.gd")
const StateNode = preload("res://addons/imjp94.yafsm/scenes/state_nodes/StateNode.tscn")
const StateNodeScript = preload("res://addons/imjp94.yafsm/scenes/state_nodes/StateNode.gd")
const StateDirectory = preload("../src/StateDirectory.gd")

var editor_accent_color = Color.white setget set_editor_accent_color
var editor_complementary_color = Color.white

var state_machine
var tween = Tween.new()


func _init():
	add_child(tween)
	tween.connect("tree_entered", self, "_on_tween_tree_entered")

func _on_tween_tree_entered():
	tween.start()

func debug_update(current_state, parameters, local_parameters):
	if not state_machine:
		return
	var current_dir = StateDirectory.new(current_state)
	var transitions = state_machine.transitions.get(current_state, {})
	if current_dir.is_nested():
		transitions = state_machine.transitions.get(current_dir.get_end(), {})
	for transition in transitions.values():
		var line = content_lines.get_node_or_null("%s>%s" % [transition.from, transition.to])
		if line:
			# Blinking alpha of TransitionLine
			var color1 = Color.white
			color1.a = 0.1
			var color2 = Color.white
			color2.a = 0.5
			if line.self_modulate == color1:
				tween.interpolate_property(line, "self_modulate", null, color2, 1)
			elif line.self_modulate == color2:
				tween.interpolate_property(line, "self_modulate", null, color1, 1)
			elif line.self_modulate == Color.white:
				tween.interpolate_property(line, "self_modulate", null, color2, 1)
			# Update TransitionLine condition labels
			for condition in transition.conditions.values():
				if not ("value" in condition): # Ignore trigger
					continue
				var value = parameters.get(condition.name)
				value = str(value) if value != null else "?"
				var label = line.vbox.get_node_or_null(condition.name)
				var override_template_var = line._template_var.get(condition.name)
				if override_template_var == null:
					override_template_var = {}
					line._template_var[condition.name] = override_template_var
				override_template_var["value"] = str(value)
				line.update_label()
				# Condition label color based on comparation
				if condition.compare(parameters.get(condition.name)) or condition.compare(local_parameters.get(condition.name)):
					if label.self_modulate != Color.green:
						tween.interpolate_property(label, "self_modulate", null, Color.green.lightened(0.5), 0.1)
				else:
					if label.self_modulate != Color.red:
						tween.interpolate_property(label, "self_modulate", null, Color.red.lightened(0.5), 0.1)
	tween.start()

func debug_transit_out(from, to):
	var from_dir = StateDirectory.new(from)
	var to_dir = StateDirectory.new(to)
	var from_node = content_nodes.get_node_or_null(from_dir.get_end())
	if from_node:
		from_node.self_modulate = editor_complementary_color
		tween.interpolate_property(from_node, "self_modulate", null, Color.white, 0.5)
	var transitions = state_machine.transitions.get(from, {})
	if from_dir.is_nested():
		transitions = state_machine.transitions.get(from_dir.get_end(), {})
	# Fade out color of StateNode
	for transition in transitions.values():
		var line = content_lines.get_node_or_null("%s>%s" % [transition.from, transition.to])
		if line:
			line.template = "{condition_name} {condition_comparation} {condition_value}"
			line.update_label()
			tween.remove(line, "self_modulate")
			if transition.to == to_dir.get_end():
				line.self_modulate = editor_complementary_color
				tween.interpolate_property(line, "self_modulate", null, Color.white, 2, Tween.TRANS_EXPO, Tween.EASE_IN)
			else:
				tween.interpolate_property(line, "self_modulate", null, Color.white, 0.1)
			# Revert color of TransitionLine condition labels
			for condition in transition.conditions.values():
				if not ("value" in condition): # Ignore trigger
					continue
				var label = line.vbox.get_node_or_null(condition.name)
				if label.self_modulate != Color.white:
					tween.interpolate_property(label, "self_modulate", null, Color.white, 0.5)
	if from_dir.is_nested() and from_dir.is_exit():
		# Transition from nested state
		transitions = state_machine.transitions.get(from_dir.get_base(), {})
		for transition in transitions.values():
			var line = content_lines.get_node_or_null("%s>%s" % [transition.from, transition.to])
			if line:
				tween.interpolate_property(line, "self_modulate", null, editor_complementary_color.lightened(0.5), 0.5)
		yield(tween, "tween_completed")
		for transition in transitions.values():
			var line = content_lines.get_node_or_null("%s>%s" % [transition.from, transition.to])
			if line:
				tween.interpolate_property(line, "self_modulate", null, Color.white, 0.5)
	tween.start()

func debug_transit_in(from, to):
	var to_dir = StateDirectory.new(to)
	var to_node = content_nodes.get_node_or_null(to_dir.get_end())
	if to_node:
		tween.interpolate_property(to_node, "self_modulate", null, editor_complementary_color, 0.5)
	var transitions = state_machine.transitions.get(to, {})
	if to_dir.is_nested():
		transitions = state_machine.transitions.get(to_dir.get_end(), {})
	# Change string template for current TransitionLines
	for transition in transitions.values():
		var line = content_lines.get_node_or_null("%s>%s" % [transition.from, transition.to])
		line.template = "{condition_name} {condition_comparation} {condition_value}({value})"
	tween.start()

func set_editor_accent_color(color):
	editor_accent_color = color
	editor_complementary_color = Utils.get_complementary_color(color)
