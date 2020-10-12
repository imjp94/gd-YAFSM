tool
extends "ValueCondition.gd"

export(float) var value setget set_value, get_value


func set_value(v):
	if not is_equal_approx(value, v):
		value = v
		emit_signal("value_changed", v)

func get_value():
	return value

func compare(v):
	if typeof(v) != TYPE_REAL:
		return false
	return .compare(v)