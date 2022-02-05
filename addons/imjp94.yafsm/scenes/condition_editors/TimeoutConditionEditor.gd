tool
extends HBoxContainer

onready var timeout_edit = $Timeout
onready var remove = $Remove

var undo_redo

var condition setget set_condition
var _old_timeout = 0.0

func _ready():
	timeout_edit.connect("value_changed", self, "_on_timeout_value_changed")
	timeout_edit.connect("focus_entered", self, "_on_timeout_focus_entered")
	timeout_edit.connect("focus_exited", self, "_on_timeout_focus_exited")
	set_process_input(false)

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if get_focus_owner() == timeout_edit:
				var local_event = timeout_edit.make_input_local(event)
				if not timeout_edit.get_rect().has_point(local_event.position):
					timeout_edit.release_focus()

func set_timeout(v):
	if condition.timeout != v:
		condition.timeout = v
		timeout_edit.value = v

func change_timeout_action(from, to):
	if from == to:
		return
	undo_redo.create_action("Change Condition Timeout")
	undo_redo.add_do_method(self, "set_timeout", to)
	undo_redo.add_undo_method(self, "set_timeout", from)
	undo_redo.commit_action()

func _on_timeout_value_changed(timeout):
	change_timeout_action(_old_timeout, timeout)
	timeout_edit.release_focus()

func _on_timeout_focus_entered():
	set_process_input(true)
	_old_timeout = timeout_edit.value

func _on_timeout_focus_exited():
	set_process_input(false)
	change_timeout_action(_old_timeout, timeout_edit.value)

func _on_condition_changed(new_condition):
	if new_condition:
		timeout_edit.value = new_condition.timeout

func set_condition(c):
	if condition != c:
		condition = c
		_on_condition_changed(c)
