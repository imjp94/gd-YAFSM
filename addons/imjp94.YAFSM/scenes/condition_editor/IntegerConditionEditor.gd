tool
extends "ValueConditionEditor.gd"

onready var IntegerValue = $MarginContainer/IntegerValue


func _ready():
	IntegerValue.connect("text_entered", self, "_on_IntegerValue_text_entered")
	IntegerValue.connect("focus_exited", self, "_on_IntegerValue_focus_exited")

func _on_IntegerValue_text_entered(new_text):
	change_integer(int(new_text))

func _on_IntegerValue_focus_exited():
	change_integer(int(IntegerValue.text))

func _on_condition_changed(new_condition):
	._on_condition_changed(new_condition)
	if new_condition:
		IntegerValue.text = str(new_condition.value)

func change_integer(v):
	condition.value = v