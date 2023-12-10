@tool
extends "res://addons/imjp94.yafsm/scenes/flowchart/FlowChartLayer.gd"

const Utils = preload("res://addons/imjp94.yafsm/scripts/Utils.gd")
const StateNode = preload("res://addons/imjp94.yafsm/scenes/state_nodes/StateNode.tscn")
const StateNodeScript = preload("res://addons/imjp94.yafsm/scenes/state_nodes/StateNode.gd")
const StateDirectory = preload("../src/StateDirectory.gd")

var editor_accent_color: = Color.WHITE:
	set = set_editor_accent_color
var editor_complementary_color = Color.WHITE

var state_machine
var tween_lines
var tween_labels
var tween_nodes


func debug_update(current_state, parameters, local_parameters):
	_init_tweens()
	if not state_machine:
		return
	var current_dir = StateDirectory.new(current_state)
	var transitions = state_machine.transitions.get(current_state, {})
	if current_dir.is_nested():
		transitions = state_machine.transitions.get(current_dir.get_end(), {})
	for transition in transitions.values():
		# Check all possible transitions from current state, update labels, color them accordingly
		var line = content_lines.get_node_or_null(NodePath("%s>%s" % [transition.from, transition.to]))
		if line:
			# Blinking alpha of TransitionLine
			var color1 = Color.WHITE
			color1.a = 0.1
			var color2 = Color.WHITE
			color2.a = 0.5
			if line.self_modulate == color1:
				tween_lines.tween_property(line, "self_modulate", color2, 0.5)
			elif line.self_modulate == color2:
				tween_lines.tween_property(line, "self_modulate", color1, 0.5)
			elif line.self_modulate == Color.WHITE:
				tween_lines.tween_property(line, "self_modulate", color2, 0.5)
			# Update TransitionLine condition labels
			for condition in transition.conditions.values():
				if not ("value" in condition): # Ignore trigger
					continue
				var value = parameters.get(str(condition.name))
				value = str(value) if value != null else "?"
				var label = line.vbox.get_node_or_null(NodePath(str(condition.name)))
				var override_template_var = line._template_var.get(str(condition.name))
				if override_template_var == null:
					override_template_var = {}
					line._template_var[str(condition.name)] = override_template_var
				override_template_var["value"] = str(value)
				line.update_label()
				# Condition label color based on comparation
				var cond_1: bool = condition.compare(parameters.get(str(condition.name)))
				var cond_2: bool = condition.compare(local_parameters.get(str(condition.name)))
				if cond_1 or cond_2:
					tween_labels.tween_property(label, "self_modulate", Color.GREEN.lightened(0.5), 0.01)
				else:
					tween_labels.tween_property(label, "self_modulate", Color.RED.lightened(0.5), 0.01)
	_start_tweens()

func debug_transit_out(from, to):
	_init_tweens()
	var from_dir = StateDirectory.new(from)
	var to_dir = StateDirectory.new(to)
	var from_node = content_nodes.get_node_or_null(NodePath(from_dir.get_end()))
	if from_node != null:
		tween_nodes.tween_property(from_node, "self_modulate", editor_complementary_color, 0.01)
		tween_nodes.tween_property(from_node, "self_modulate", Color.WHITE, 1)
	var transitions = state_machine.transitions.get(from, {})
	if from_dir.is_nested():
		transitions = state_machine.transitions.get(from_dir.get_end(), {})
	# Fade out color of StateNode
	for transition in transitions.values():
		var line = content_lines.get_node_or_null(NodePath("%s>%s" % [transition.from, transition.to]))
		if line:
			line.template = "{condition_name} {condition_comparation} {condition_value}"
			line.update_label()
			if transition.to == to_dir.get_end():
				tween_lines.tween_property(line, "self_modulate", editor_complementary_color, 0.01)
				tween_lines.tween_property(line, "self_modulate", Color.WHITE, 1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
				# Highlight all the conditions of the transition that just happened
				for condition in transition.conditions.values():
					if not ("value" in condition): # Ignore trigger
						continue
					var label = line.vbox.get_node_or_null(NodePath(condition.name))
					tween_labels.tween_property(label, "self_modulate", editor_complementary_color, 0.01)
					tween_labels.tween_property(label, "self_modulate", Color.WHITE, 1)
			else:
				tween_lines.tween_property(line, "self_modulate", Color.WHITE, 0.1)
				# Revert color of TransitionLine condition labels
				for condition in transition.conditions.values():
					if not ("value" in condition): # Ignore trigger
						continue
					var label = line.vbox.get_node_or_null(NodePath(condition.name))
					if label.self_modulate != Color.WHITE:
						tween_labels.tween_property(label, "self_modulate", Color.WHITE, 0.5)
	if from_dir.is_nested() and from_dir.is_exit():
		# Transition from nested state
		transitions = state_machine.transitions.get(from_dir.get_base(), {})
		tween_lines.set_parallel(true)
		for transition in transitions.values():
			var line = content_lines.get_node_or_null(NodePath("%s>%s" % [transition.from, transition.to]))
			if line:
				tween_lines.tween_property(line, "self_modulate", editor_complementary_color.lightened(0.5), 0.1)
		for transition in transitions.values():
			var line = content_lines.get_node_or_null(NodePath("%s>%s" % [transition.from, transition.to]))
			if line:
				tween_lines.tween_property(line, "self_modulate", Color.WHITE, 0.1)
	_start_tweens()

func debug_transit_in(from, to):
	_init_tweens()
	var to_dir = StateDirectory.new(to)
	var to_node = content_nodes.get_node_or_null(NodePath(to_dir.get_end()))
	if to_node:
		tween_nodes.tween_property(to_node, "self_modulate", editor_complementary_color, 0.5)
	var transitions = state_machine.transitions.get(to, {})
	if to_dir.is_nested():
		transitions = state_machine.transitions.get(to_dir.get_end(), {})
	# Change string template for current TransitionLines
	for transition in transitions.values():
		var line = content_lines.get_node_or_null(NodePath("%s>%s" % [transition.from, transition.to]))
		line.template = "{condition_name} {condition_comparation} {condition_value}({value})"
	_start_tweens()

func set_editor_accent_color(color):
	editor_accent_color = color
	editor_complementary_color = Utils.get_complementary_color(color)


func _init_tweens():
	tween_lines = get_tree().create_tween()
	tween_lines.stop()
	tween_labels = get_tree().create_tween()
	tween_labels.stop()
	tween_nodes = get_tree().create_tween()
	tween_nodes.stop()


func _start_tweens():
	tween_lines.tween_interval(0.001)
	tween_lines.play()
	tween_labels.tween_interval(0.001)
	tween_labels.play()
	tween_nodes.tween_interval(0.001)
	tween_nodes.play()