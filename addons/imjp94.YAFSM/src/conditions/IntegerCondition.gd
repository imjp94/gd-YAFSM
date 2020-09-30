extends "ValueCondition.gd"

export(int) var value


func set_value(v):
	if value != v:
		value = v
		emit_signal("value_changed", v)

func get_value():
	return value

func compare(v):
	if typeof(v) != TYPE_INT:
		return false
	return .compare(v)
