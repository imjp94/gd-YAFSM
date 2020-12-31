tool
extends Resource

signal name_changed(old, new)
signal display_string_changed(new)

export(String) var name = "" setget set_name # Name of condition, unique to Transition


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
