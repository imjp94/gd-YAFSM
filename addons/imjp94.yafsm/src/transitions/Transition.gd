tool
extends Resource

signal condition_added(condition)
signal condition_removed(condition)

export(String) var from # Name of state transiting from
export(String) var to # Name of state transiting to
export(Dictionary) var conditions setget ,get_conditions # Conditions to transit successfuly, keyed by Condition.name


func _init(p_from="", p_to="", p_conditions={}):
	from = p_from
	to = p_to
	conditions = p_conditions

# Attempt to transit with parameters given, return name of next state if succeeded else null
func transit(params={}):
	var can_transit = conditions.size() > 0
	for condition in conditions.values():
		if not (condition.name in params):
			can_transit = false
			continue

		var value = params.get(condition.name)
		if value == null: # null value is treated ass trigger
			can_transit = can_transit and true
		else:
			if "value" in condition:
				can_transit = can_transit and condition.compare(value)
	if can_transit or conditions.size() == 0:
		return to
	return null

# Add condition, return true if succeeded
func add_condition(condition):
	if condition.name in conditions:
		return false

	conditions[condition.name] = condition
	emit_signal("condition_added", condition)
	return true

# Remove condition by name of condition
func remove_condition(name):
	var condition = conditions.get(name)
	if condition:
		conditions.erase(name)
		emit_signal("condition_removed", condition)
		return true
	return false

# Change condition name, return true if succeeded
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

# Get duplicate of conditions dictionary
func get_conditions():
	return conditions.duplicate()
