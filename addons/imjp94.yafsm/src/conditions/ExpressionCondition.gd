tool
extends "Condition.gd"

var expression = Expression.new()

func _ready():
	pass # Replace with function body.

func execute(params = {}, local_params = {}):
	var execute_params = params.duplicate()
	for local_param_key in local_params.keys():
		execute_params[local_param_key] = local_params[local_param_key]
	
	var trigger_instance = TriggerInstance.new(execute_params)
	
	var expression_input_names = execute_params.keys()
	var expression_input_values = execute_params.values()
	
	var error = expression.parse(name, expression_input_names)
	if error != OK:
		print(expression.get_error_text())
		return false
	
	var result = expression.execute(expression_input_values, trigger_instance, true)
	if not expression.has_execute_failed():
		return result
	else:
		return false

class TriggerInstance:
	var execute_params
	
	func _init(execute_params = {}):
		self.execute_params = execute_params.duplicate()
	
	func trigger(property):
		return property in execute_params
	
	func t(property):
		return trigger(property)
