tool
extends "ValueConditionEditor.gd"

onready var BooleanValue = $MarginContainer/BooleanValue

func _ready():
	BooleanValue.connect("pressed", self, "_on_BooleanValue_pressed")

func _on_value_changed(new_value):
	if BooleanValue.pressed != new_value:
		BooleanValue.pressed = new_value

func _on_BooleanValue_pressed():
	change_value_action(condition.value, BooleanValue.pressed)

func _on_condition_changed(new_condition):
	._on_condition_changed(new_condition)
	if new_condition:
		BooleanValue.pressed = new_condition.value