tool
extends "res://addons/imjp94.yafsm/scenes/flowchart/FlowChartLayer.gd"

const StateNode = preload("res://addons/imjp94.yafsm/scenes/state_nodes/StateNode.tscn")
const StateNodeScript = preload("res://addons/imjp94.yafsm/scenes/state_nodes/StateNode.gd")

var editor_accent_color = Color.white

var state_machine
