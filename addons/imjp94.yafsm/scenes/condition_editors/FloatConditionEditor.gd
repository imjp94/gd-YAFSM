tool
extends "ValueConditionEditor.gd"

onready var FloatValue = $MarginContainer/FloatValue

var _old_value = 0.0

func _ready():
	FloatValue.connect("text_entered", self, "_on_FloatValue_text_entered")
	FloatValue.connect("focus_entered", self, "_on_FloatValue_focus_entered")
	FloatValue.connect("focus_exited", self, "_on_FloatValue_focus_exited")
	set_process_input(false)

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if get_focus_owner() == FloatValue:
				var local_event = FloatValue.make_input_local(event)
				if not FloatValue.get_rect().has_point(local_event.position):
					FloatValue.release_focus()

func _on_value_changed(new_value):
	FloatValue.text = str(stepify(new_value, 0.01)).pad_decimals(2)

func _on_FloatValue_text_entered(new_text):
	change_value_action(_old_value, float(new_text))
	FloatValue.release_focus()

func _on_FloatValue_focus_entered():
	set_process_input(true)
	_old_value = float(FloatValue.text)

func _on_FloatValue_focus_exited():
	set_process_input(false)
	change_value_action(_old_value, float(FloatValue.text))

func _on_condition_changed(new_condition):
	._on_condition_changed(new_condition)
	if new_condition:
		FloatValue.text = str(stepify(new_condition.value, 0.01)).pad_decimals(2)
