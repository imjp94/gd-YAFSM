@tool
extends "ValueConditionEditor.gd"

@onready var float_value = $MarginContainer/FloatValue

var _old_value = 0.0

func _ready():
	super._ready()
	
	float_value.text_submitted.connect(_on_float_value_text_submitted)
	float_value.focus_entered.connect(_on_float_value_focus_entered)
	float_value.focus_exited.connect(_on_float_value_focus_exited)
	set_process_input(false)

func _input(event):
	super._input(event)
	
	if event is InputEventMouseButton:
		if event.pressed:
			if get_viewport().gui_get_focus_owner() == float_value:
				var local_event = float_value.make_input_local(event)
				if not float_value.get_rect().has_point(local_event.position):
					float_value.release_focus()

func _on_value_changed(new_value):
	float_value.text = str(snapped(new_value, 0.01)).pad_decimals(2)

func _on_float_value_text_submitted(new_text):
	change_value_action(_old_value, float(new_text))
	float_value.release_focus()

func _on_float_value_focus_entered():
	set_process_input(true)
	_old_value = float(float_value.text)

func _on_float_value_focus_exited():
	set_process_input(false)
	change_value_action(_old_value, float(float_value.text))

func _on_condition_changed(new_condition):
	super._on_condition_changed(new_condition)
	if new_condition:
		float_value.text = str(snapped(new_condition.value, 0.01)).pad_decimals(2)
