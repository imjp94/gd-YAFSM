tool
extends "ValueCondition.gd"

export(String) var value setget set_value, get_value


func set_value(v):
	if value != v:
		value = v
		emit_signal("value_changed", v)
		emit_signal("display_string_changed", display_string())

func get_value():
	return value

func get_value_string():
	return "\"%s\"" % value

func compare(v):
	if typeof(v) != TYPE_STRING:
		return false
	return .compare(v)
