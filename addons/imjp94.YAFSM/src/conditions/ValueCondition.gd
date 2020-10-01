extends "Condition.gd"

signal comparation_changed(new_comparation)
signal value_changed(new_value)

enum Comparation {
	LESSER = -1,
	EQUAL = 0,
	GREATER = 1
}

export(Comparation) var comparation = Comparation.EQUAL setget set_comparation

func _init(p_name="", p_comparation=Comparation.EQUAL):
	._init(p_name)
	comparation = p_comparation

func set_comparation(c):
	if comparation != c:
		comparation = c
		emit_signal("comparation_changed", c)

func set_value(v):
	pass

# To be overrided by child class, as it is impossible to export(Variant)
func get_value():
	pass

func compare(v):
	if v == null:
		return false

	match comparation:
		Comparation.LESSER:
			return v < get_value()
		Comparation.EQUAL:
			return v == get_value()
		Comparation.GREATER:
			return v > get_value()
