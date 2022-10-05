@tool
extends Control
const StackPlayer = preload("../StackPlayer.gd")
const StackItem = preload("StackItem.tscn")

@onready var Stack = $MarginContainer/Stack


func _get_configuration_warning():
	if not (get_parent() is StackPlayer):
		return "Debugger must be child of StackPlayer"
	return ""

func _ready():
	if Engine.is_editor_hint():
		return

	get_parent().pushed.connect(_on_StackPlayer_pushed)
	get_parent().popped.connect(_on_StackPlayer_popped)
	sync_stack()

# Override to handle custom object presentation
func _on_set_label(label, obj):
	label.text = obj

func _on_StackPlayer_pushed(to):
	var stack_item = StackItem.instantiate()
	_on_set_label(stack_item.get_node("Label"), to)
	Stack.add_child(stack_item)
	Stack.move_child(stack_item, 0)

func _on_StackPlayer_popped(from):
	# Sync whole stack instead of just popping top item, as ResetEventTrigger passed to reset() may be varied
	sync_stack()

func sync_stack():
	var diff = Stack.get_child_count() - get_parent().stack.size()
	for i in abs(diff):
		if diff < 0:
			var stack_item = StackItem.instantiate()
			Stack.add_child(stack_item)
		else:
			var child = Stack.get_child(0)
			Stack.remove_child(child)
			child.queue_free()
	var stack = get_parent().stack
	for i in stack.size():
		var obj = stack[stack.size()-1 - i] # Descending order, to list from bottom to top in VBoxContainer
		var child = Stack.get_child(i)
		_on_set_label(child.get_node("Label"), obj)
