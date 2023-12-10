extends Node

signal pushed(to) # When item pushed to stack
signal popped(from) # When item popped from stack

# Enum to specify how reseting state stack should trigger event(transit, push, pop etc.)
enum ResetEventTrigger {
	NONE = -1, # No event
	ALL = 0, # All removed state will emit event
	LAST_TO_DEST = 1 # Only last state and destination will emit event
}

var current:  # Current item on top of stack
	get = get_current
var stack:
	set = _set_stack,
	get = _get_stack

var _stack


func _init():
	_stack = []

# Push an item to the top of stack
func push(to):
	var from = get_current()
	_stack.push_back(to)
	_on_pushed(from, to)
	emit_signal("pushed", to)

# Remove the current item on top of stack
func pop():
	var to = get_previous()
	var from = _stack.pop_back()
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
	assert(to > -2 and to < _stack.size(), "Reset to index out of bounds")
	var last_index = _stack.size() - 1
	var first_state = ""
	var num_to_pop = last_index - to

	if num_to_pop > 0:
		for i in range(num_to_pop):
			first_state = get_current() if i == 0 else first_state
			match event:
				ResetEventTrigger.LAST_TO_DEST:
					_stack.pop_back()
					if i == num_to_pop - 1:
						_stack.push_back(first_state)
						pop()
				ResetEventTrigger.ALL:
					pop()
				_:
					_stack.pop_back()
	elif num_to_pop == 0:
		match event:
			ResetEventTrigger.NONE:
				_stack.pop_back()
			_:
				pop()

func _set_stack(val):
	push_warning("Attempting to edit read-only state stack directly. " \
		+ "Control state machine from setting parameters or call update() instead")

# Get duplicate of the stack being played
func _get_stack():
	return _stack.duplicate()

func get_current():
	return _stack.back() if not _stack.is_empty() else null

func get_previous():
	return _stack[_stack.size() - 2] if _stack.size() > 1 else null
