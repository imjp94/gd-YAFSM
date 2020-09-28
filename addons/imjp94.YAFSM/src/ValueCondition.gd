extends "Condition.gd"

enum COMPARATION {
	LESSER = -1,
	EQUAL = 0,
	GREATER = 1
}

export(COMPARATION) var comparation = COMPARATION.EQUAL

func _init(p_name="", p_comparation=COMPARATION.EQUAL):
	._init(p_name)
	comparation = p_comparation

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
