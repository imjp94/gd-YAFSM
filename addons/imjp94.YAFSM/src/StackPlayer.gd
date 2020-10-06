extends Node

signal changed(from, to)

# Enum to specify how reseting state stack should trigger event(changed, push, pop etc.)
enum ResetEventTrigger {
	NONE = -1, # No event
	ALL = 0, # All removed state will emit event
	LAST_TO_DEST = 1 # Only last state and destination will emit event
}

var current setget ,get_current
var stack setget set_stack, get_stack


func _init():
	stack = []

func push(to):
	var from = get_current()
	stack.push_back(to)
	_on_push(from, to)
	emit_signal("changed", from, to)

func pop():
	var to = get_previous()
	var from = stack.pop_back()
	_on_pop(from, to)
	emit_signal("changed", from, to)

func _on_push(from, to):
	pass

func _on_pop(from, to):
	pass

func reset(to=0, event=ResetEventTrigger.LAST_TO_DEST):
	assert(to > -1 and to < stack.size(), "Reset to index(%d) out of bounds(%d)" % [to, stack.size()])
	var last_index = stack.size() - 1
	var first_state = ""
	var num_to_pop = last_index - to

	if num_to_pop > 0:
		for i in range(num_to_pop):
			first_state = get_current() if i == 0 else first_state
			match event:
				ResetEventTrigger.LAST_TO_DEST:
					stack.pop_back()
					if i == num_to_pop - 1:
						stack.push_back(first_state)
						pop()
				ResetEventTrigger.ALL:
					pop()
				_:
					stack.pop_back()
	elif num_to_pop == 0:
		match event:
			ResetEventTrigger.NONE:
				stack.pop_back()
			_:
				pop()

func set_stack(stack):
	push_warning("Attempting to edit read-only state stack directly. " \
		+ "Control state machine from setting parameters or call update() instead")

func get_stack():
	return stack.duplicate()

func get_current():
	return stack.back() if not stack.empty() else null

func get_previous():
	return stack[stack.size() - 2] if stack.size() > 1 else null
