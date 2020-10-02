tool
extends "ValueConditionEditor.gd"

onready var IntegerValue = $MarginContainer/IntegerValue

var _old_value = 0


func _ready():
	IntegerValue.connect("text_entered", self, "_on_IntegerValue_text_entered")
	IntegerValue.connect("focus_entered", self, "_on_IntegerValue_focus_entered")
	IntegerValue.connect("focus_exited", self, "_on_IntegerValue_focus_exited")

func _on_value_changed(new_value):
	print(new_value)
	IntegerValue.text = str(new_value)

func _on_IntegerValue_text_entered(new_text):
	change_value_action(_old_value, int(new_text))

func _on_IntegerValue_focus_entered():
	_old_value = int(IntegerValue.text)

func _on_IntegerValue_focus_exited():
	change_value_action(_old_value, int(IntegerValue.text))

func _on_condition_changed(new_condition):
	._on_condition_changed(new_condition)
	if new_condition:
		IntegerValue.text = str(new_condition.value)
