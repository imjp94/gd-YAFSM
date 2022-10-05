@tool
extends "res://addons/imjp94.yafsm/scenes/condition_editors/ValueConditionEditor.gd"


@onready var string_value = $MarginContainer/StringValue

var _old_value = 0


func _ready():
	super._ready()
	
	string_value.text_submitted.connect(_on_string_value_text_submitted)
	string_value.focus_entered.connect(_on_string_value_focus_entered)
	string_value.focus_exited.connect(_on_string_value_focus_exited)
	set_process_input(false)

func _input(event):
	super._input(event)
	
	if event is InputEventMouseButton:
		if event.pressed:
			if get_viewport().gui_get_focus_owner() == string_value:
				var local_event = string_value.make_input_local(event)
				if not string_value.get_rect().has_point(local_event.position):
					string_value.release_focus()

func _on_value_changed(new_value):
	string_value.text = new_value

func _on_string_value_text_submitted(new_text):
	change_value_action(_old_value, new_text)
	string_value.release_focus()

func _on_string_value_focus_entered():
	set_process_input(true)
	_old_value = string_value.text

func _on_string_value_focus_exited():
	set_process_input(false)
	change_value_action(_old_value, string_value.text)

func _on_condition_changed(new_condition):
	super._on_condition_changed(new_condition)
	if new_condition:
		string_value.text = new_condition.value
