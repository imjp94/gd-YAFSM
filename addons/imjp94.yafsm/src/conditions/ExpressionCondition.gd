extends "Condition.gd"

# Get unique variable: before escape (?!\"|')(?!(and)|(or)|(false)|(true)|\d|\.\b)\b(\w+)\b(?![\"|'])(?!.*\5) 
const PATTERN_UNIQUE_PARAM = "(?!\\\"|\')(?!(and)|(or)|(false)|(true)|\\d|\\.\\b)\\b(\\w+)\\b(?![\\\"|\'])(?!.*\\5)"

var expression = Expression.new()
var regex = RegEx.new()

var _expression_params = []

func _init():
	regex.compile(PATTERN_UNIQUE_PARAM)
	self.connect("name_changed", self, "_on_name_changed")

func execute(params = {}, local_expression_params = {}):
	var execute_expression_params = params.duplicate()
	for local_param_key in local_expression_params.keys():
		execute_expression_params[local_param_key] = local_expression_params[local_param_key]

	var values = []
	for param in _expression_params:
		var value = execute_expression_params.get(param, false)
		values.append(true if value == null else value) # null == trigger
	
	var error = expression.parse(name, _expression_params)
	if error != OK:
		print(expression.get_error_text())
		return false
	
	var result = expression.execute(values, null, true)
	if not expression.has_execute_failed():
		return result
	else:
		return false

func _on_name_changed(old, new):
	var results = regex.search_all(name)
	if results:
		for result in results:
			_expression_params.append(result.get_string())
