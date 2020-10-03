tool
extends "ValueConditionEditor.gd"

onready var FloatValue = $MarginContainer/FloatValue

var _old_value = 0.0

func _ready():
	FloatValue.connect("text_entered", self, "_on_FloatValue_text_entered")
	FloatValue.connect("focus_entered", self, "_on_FloatValue_focus_entered")
	FloatValue.connect("focus_exited", self, "_on_FloatValue_focus_exited")

func _on_value_changed(new_value):
	FloatValue.text = str(stepify(new_value, 0.01)).pad_decimals(2)

func _on_FloatValue_text_entered(new_text):
	change_value_action(_old_value, float(new_text))

func _on_FloatValue_focus_entered():
	_old_value = float(FloatValue.text)

func _on_FloatValue_focus_exited():
	change_value_action(_old_value, float(FloatValue.text))

func _on_condition_changed(new_condition):
	._on_condition_changed(new_condition)
	if new_condition:
		FloatValue.text = str(stepify(new_condition.value, 0.01)).pad_decimals(2)
