@tool
extends "ValueConditionEditor.gd"

@onready var boolean_value = $MarginContainer/BooleanValue

func _ready():
	super._ready()
	
	boolean_value.pressed.connect(_on_boolean_value_pressed)


func _on_value_changed(new_value):
	if boolean_value.button_pressed != new_value:
		boolean_value.button_pressed = new_value

func _on_boolean_value_pressed():
	change_value_action(condition.value, boolean_value.button_pressed)

func _on_condition_changed(new_condition):
	super._on_condition_changed(new_condition)
	if new_condition:
		boolean_value.button_pressed = new_condition.value
