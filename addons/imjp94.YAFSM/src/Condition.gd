extends Resource

signal name_changed(old, new)

export(String) var name = "" setget set_name


func _init(p_name=""):
	name = p_name

func set_name(n):
	if name != n:
		var old = name
		name = n
		emit_signal("name_changed", old, n)
