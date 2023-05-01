@tool
extends Condition
class_name ValueCondition

signal comparation_changed(new_comparation) # Comparation hanged
signal value_changed(new_value) # Value changed

# Enum to define how to compare value
enum Comparation {
	EQUAL,
	INEQUAL,
	GREATER,
	LESSER,
	GREATER_OR_EQUAL,
	LESSER_OR_EQUAL
}
# Comparation symbols arranged in order as enum Comparation
const COMPARATION_SYMBOLS = [
	"==",
	"!=",
	">",
	"<",
	"≥",
	"≤"
]

@export var comparation: Comparation = Comparation.EQUAL:
	set = set_comparation

func _init(p_name="", p_comparation=Comparation.EQUAL):
	super._init(p_name)
	comparation = p_comparation

func set_comparation(c):
	if comparation != c:
		comparation = c
		emit_signal("comparation_changed", c)
		emit_signal("display_string_changed", display_string())

# To be overrided by child class and emit value_changed signal
func set_value(v):
	pass

# To be overrided by child class, as it is impossible to export(Variant)
func get_value():
	pass

# To be used in _to_string()
func get_value_string():
	return get_value()

# Compare value against this condition, return true if succeeded
func compare(v):
	if v == null:
		return false

	match comparation:
		Comparation.EQUAL:
			return v == get_value()
		Comparation.INEQUAL:
			return v != get_value()
		Comparation.GREATER:
			return v > get_value()
		Comparation.LESSER:
			return v < get_value()
		Comparation.GREATER_OR_EQUAL:
			return v >= get_value()
		Comparation.LESSER_OR_EQUAL:
			return v <= get_value()

# Return human readable display string, for example, "condition_name == True"
func display_string():
	return "%s %s %s" % [super.display_string(), COMPARATION_SYMBOLS[comparation], get_value_string()]
