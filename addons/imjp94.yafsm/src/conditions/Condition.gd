@tool
extends Resource
class_name Condition

signal name_changed(old, new)
signal display_string_changed(new)

@export var name: = "":  # Name of condition, unique to Transition
	set = set_name


func _init(p_name=""):
	name = p_name

func set_name(n):
	if name != n:
		var old = name
		name = n
		emit_signal("name_changed", old, n)
		emit_signal("display_string_changed", display_string())

func display_string():
	return name
