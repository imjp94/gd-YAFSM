tool
extends "res://addons/imjp94.yafsm/scenes/flowchart/FlowChartContainer.gd"
const StateMachine = preload("../src/states/StateMachine.gd")

signal inspector_changed(property)


onready var StateMachineEditor = $StateMachineEditor
onready var CreateNewStateMachineContainer = $MarginContainer
onready var CreateNewStateMachine = $MarginContainer/CreateNewStateMachine

var state_machine_player setget set_state_machine_player


func _ready():
	CreateNewStateMachineContainer.visible = false
	CreateNewStateMachine.connect("pressed", self, "_on_CreateNewStateMachine_pressed")

func _on_state_machine_player_changed(new_state_machine_player):
	if new_state_machine_player:
		CreateNewStateMachineContainer.visible = !new_state_machine_player.state_machine
	else:
		CreateNewStateMachineContainer.visible = false

func _on_CreateNewStateMachine_pressed():
	var new_state_machine = StateMachine.new()
	state_machine_player.state_machine = new_state_machine
	StateMachineEditor.state_machine = new_state_machine
	CreateNewStateMachineContainer.visible = false
	emit_signal("inspector_changed", "state_machine")

func set_state_machine_player(smp):
	if state_machine_player != smp:
		state_machine_player = smp
		_on_state_machine_player_changed(smp)
