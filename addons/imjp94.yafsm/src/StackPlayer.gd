extends Node

signal pushed(to) # When item pushed to stack
signal popped(from) # When item popped from stack

# Enum to specify how reseting state stack should trigger event(transit, push, pop etc.)
enum ResetEventTrigger {
	NONE = -1, # No event
	ALL = 0, # All removed state will emit event
	LAST_TO_DEST = 1 # Only last state and destination will emit event
}

var current setget ,get_current # Current item on top of stack
var stack setget set_stack, get_stack


func _init():
	stack = []

# Push an item to the top of stack
func push(to):
	var from = get_current()
	stack.push_back(to)
	_on_pushed(from, to)
	emit_signal("pushed", to)

# Remove the current item on top of stack
func pop():
	var to = get_previous()
	var from = stack.pop_back()
	_on_popped(from, to)
	emit_signal("popped", from)

# Called when item pushed
func _on_pushed(from, to):
	pass

# Called when item popped
func _on_popped(from, to):
	pass

# Reset stack to given index, -1 to clear all item by default
# Use ResetEventTrigger to define how _on_popped should be called
func reset(to=-1, event=ResetEventTrigger.ALL):
	assert(to > -2 and to < stack.size(), "Reset to index(%d) out of bounds(%d)" % [to, stack.size()])
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

# Get duplicate of the stack being played
func get_stack():
	return stack.duplicate()

func get_current():
	return stack.back() if not stack.empty() else null

func get_previous():
	return stack[stack.size() - 2] if stack.size() > 1 else null
