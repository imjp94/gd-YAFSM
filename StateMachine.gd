tool
extends Node

signal state_changed(from, to, push)
signal state_entered(from, to, push)
signal state_exited(from, to, push)
signal state_update(state, delta)

export(Resource) var transition
export(Dictionary) var parameters = {}

enum RESET_EVENT_TRIGGER {
	NONE = -1,
	ALL = 0,
	LAST_TO_DEST = 1
}

var current_state setget , get_current_state
var state_stack = []

func _get_configuration_warning():
	if not transition:
		return "State Machine is not going anywhere without default transition"
	return ""

func _ready():
	if Engine.editor_hint:
		return

	_push_state(transition.get_entry().to)

func _process(delta):
	if Engine.editor_hint:
		return

	_update(delta)
	_transition()

func _push_state(to):
	var from = get_current_state()
	_exit(to, true)
	state_stack.push_back(to)
	_enter(from, true)
	emit_signal("state_changed", from, to, true)

func _pop_state():
	if state_stack.size() == 1:
		_on_pop_last_state()
		return

	var to = get_previous_state()
	_exit(to, false)
	var from = state_stack.pop_back()
	_enter(from, false)
	emit_signal("state_changed", from, to, false)

func _on_pop_last_state():
	pass

func _enter(from, push):
	var to = get_current_state()
#	print("%s enter to %s" % [from, to])
	if to:
		emit_signal("state_entered", from, to, push)

func _exit(to, push):
	var from = get_current_state()
#	print("%s exit to %s" % [from, to])
	if from:
		emit_signal("state_exited", from, to, push)

func _update(delta):
	emit_signal("state_update", get_current_state(), delta)

func _transition():
	var transitions = transition.from_state_dict[get_current_state()]
	if not transitions:
		return
	
	for t in transitions:
		var next_state = t.transit(parameters)
		if not next_state:
			continue
			
		if state_stack.has(next_state):
			reset(state_stack.find(next_state))
		else:
			_push_state(next_state)
		return

func reset(to=0, event=RESET_EVENT_TRIGGER.LAST_TO_DEST):
	assert(to > -1)
	var last_index = state_stack.size() - 1
	var first_state = null
	var num_to_pop = last_index - to

	if num_to_pop > 0:
		for i in range(num_to_pop):
			first_state = get_current_state() if i == 0 else first_state
			match event:
				RESET_EVENT_TRIGGER.LAST_TO_DEST:
					state_stack.pop_back()
					if i == num_to_pop - 1:
						state_stack.push_back(first_state)
						_pop_state()
				RESET_EVENT_TRIGGER.ALL:
					_pop_state()
				_:
					state_stack.pop_back()
	elif num_to_pop == 0:
		match event:
			RESET_EVENT_TRIGGER.NONE:
				state_stack.pop_back()
			_:
				_pop_state()
	else:
		print("Error: state_stack_last_index(%d) - to_index(%d) < 0(%d)" % [last_index, to, num_to_pop])
		assert(num_to_pop >= 0)

func get_current_state():
	return state_stack.back() if not state_stack.empty() else null

func get_previous_state():
	return state_stack[state_stack.size() - 2] if state_stack.size() > 1 else null

func get_class():
	return "StateMachine"

func is_class(type):
	return type == "StateMachine" or .is_class(type)
