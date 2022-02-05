tool
extends "Condition.gd"

signal timeout_changed(new_timeout)

export(float) var timeout setget set_timeout

func set_timeout(t):
	if not is_equal_approx(timeout, t):
		timeout = t
		emit_signal("timeout_changed", t)
		emit_signal("display_string_changed", display_string())

func display_string():
	return "Timeout: %.2fs" % timeout

func has_timed_out(t):
	return t >= timeout
