extends "ValueCondition.gd"

export(float) var value


func set_value(v):
	if not is_equal_approx(value, v):
		value = v
		emit_signal("value_changed", v)

func get_value():
	return value
