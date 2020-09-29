tool
extends Resource
const State = preload("State.gd")

export(String) var from
export(String) var to
export(Array, Resource) var conditions


func _init(p_from="", p_to=""):
	from = p_from
	to = p_to

func transit(params={}):
	var can_transit = true
	for condition in conditions:
		var value = params.get(condition.name)
		if value:
			if "value" in condition:
				can_transit = can_transit and condition.compare(value)
			else: # Condition without value property is a trigger
				can_transit = can_transit and true
	if can_transit:
		return to
	return null

func equals(obj):
	if obj == null:
		return false
	if not ("from" in obj and "to" in obj):
		return false

	return from == obj.from and to == obj.to
