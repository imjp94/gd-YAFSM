extends "Condition.gd"

var expression = Expression.new()

func _ready():
	pass # Replace with function body.

func execute(params = {}, local_params = {}):
	var execute_params = params.duplicate()
	for local_param_key in local_params.keys():
		execute_params[local_param_key] = local_params[local_param_key]
	
	var trigger_variable = TriggerVariable.new(execute_params)
	
	var expression_input_names = execute_params.keys()
	expression_input_names.append("trigger")
	
	var expression_input_values = execute_params.values()
	expression_input_values.append(trigger_variable)
	
	var error = expression.parse(name, expression_input_names)
	if error != OK:
		print(expression.get_error_text())
		return false
	
	var result = expression.execute(expression_input_values, null, true)
	if not expression.has_execute_failed():
		return result
	else:
		return false

class TriggerVariable:
	var execute_params
	
	func _init(execute_params = {}):
		self.execute_params = execute_params.duplicate()
	
	func _get(property):
		return property in execute_params
