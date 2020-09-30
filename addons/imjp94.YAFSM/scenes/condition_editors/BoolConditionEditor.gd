tool
extends "ValueConditionEditor.gd"

onready var BooleanValue = $MarginContainer/BooleanValue

func _ready():
	BooleanValue.connect("toggled", self, "_on_BooleanValue_toggled")

func _on_BooleanValue_toggled(button_pressed):
	condition.value = button_pressed

func _on_condition_changed(new_condition):
	._on_condition_changed(new_condition)
	if new_condition:
		BooleanValue.pressed = new_condition.value