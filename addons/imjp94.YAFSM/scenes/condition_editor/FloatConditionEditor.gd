tool
extends "ValueConditionEditor.gd"

onready var FloatValue = $MarginContainer/FloatValue


func _ready():
	FloatValue.connect("text_entered", self, "_on_FloatValue_text_entered")
	FloatValue.connect("focus_exited", self, "_on_FloatValue_focus_exited")

func _on_FloatValue_text_entered(new_text):
	change_integer(int(new_text))

func _on_FloatValue_focus_exited():
	change_integer(int(FloatValue.text))

func _on_condition_changed(new_condition):
	._on_condition_changed(new_condition)
	if new_condition:
		FloatValue.text = str(new_condition.value)

func change_integer(v):
	condition.value = v
