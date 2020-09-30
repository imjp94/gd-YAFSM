extends "Condition.gd"

signal comparation_changed(new_comparation)
signal value_changed(new_value)

enum COMPARATION {
	LESSER = -1,
	EQUAL = 0,
	GREATER = 1
}

export(COMPARATION) var comparation = COMPARATION.EQUAL setget set_comparation

func _init(p_name="", p_comparation=COMPARATION.EQUAL):
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
		COMPARATION.LESSER:
			return v < get_value()
		COMPARATION.EQUAL:
			return v == get_value()
		COMPARATION.GREATER:
			return v > get_value()
