tool
extends "ValueConditionEditor.gd"

onready var integer_value = $MarginContainer/IntegerValue

var _old_value = 0


func _ready():
	integer_value.connect("text_entered", self, "_on_integer_value_text_entered")
	integer_value.connect("focus_entered", self, "_on_integer_value_focus_entered")
	integer_value.connect("focus_exited", self, "_on_integer_value_focus_exited")
	set_process_input(false)

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if get_focus_owner() == integer_value:
				var local_event = integer_value.make_input_local(event)
				if not integer_value.get_rect().has_point(local_event.position):
					integer_value.release_focus()

func _on_value_changed(new_value):
	integer_value.text = str(new_value)

func _on_integer_value_text_entered(new_text):
	change_value_action(_old_value, int(new_text))
	integer_value.release_focus()

func _on_integer_value_focus_entered():
	set_process_input(true)
	_old_value = int(integer_value.text)

func _on_integer_value_focus_exited():
	set_process_input(false)
	change_value_action(_old_value, int(integer_value.text))

func _on_condition_changed(new_condition):
	._on_condition_changed(new_condition)
	if new_condition:
		integer_value.text = str(new_condition.value)
