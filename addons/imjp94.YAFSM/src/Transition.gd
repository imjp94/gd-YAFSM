tool
extends Resource
const State = preload("State.gd")

export(String) var from
export(String) var to
export(Dictionary) var conditions


func _init(p_from="", p_to="", p_conditions={}):
	from = p_from
	to = p_to
	conditions = p_conditions

func transit(params={}):
	var can_transit = true
	for condition in conditions.values():
		var value = params.get(condition.name)
		if value:
			if "value" in condition:
				can_transit = can_transit and condition.compare(value)
			else: # Condition without value property is a trigger
				can_transit = can_transit and true
	if can_transit:
		return to
	return null

func add_condition(condition):
	if condition.name in conditions:
		return false

	conditions[condition.name] = condition

func remove_condition(name):
	return conditions.erase(name)

func change_condition_name(from, to):
	if not (from in conditions) or to in conditions:
		return false

	var condition = conditions[from]
	condition.name = to
	conditions.erase(from)
	conditions[to] = condition
	return true

func get_unique_name(name):
	var new_name = name
	var i = 1
	while new_name in conditions:
		new_name = name + str(i)
		i += 1
	return new_name

func equals(obj):
	if obj == null:
		return false
	if not ("from" in obj and "to" in obj):
		return false

	return from == obj.from and to == obj.to
