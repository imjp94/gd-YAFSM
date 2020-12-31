tool
extends "ValueConditionEditor.gd"

onready var boolean_value = $MarginContainer/BooleanValue

func _ready():
	boolean_value.connect("pressed", self, "_on_boolean_value_pressed")

func _on_value_changed(new_value):
	if boolean_value.pressed != new_value:
		boolean_value.pressed = new_value

func _on_boolean_value_pressed():
	change_value_action(condition.value, boolean_value.pressed)

func _on_condition_changed(new_condition):
	._on_condition_changed(new_condition)
	if new_condition:
		boolean_value.pressed = new_condition.value