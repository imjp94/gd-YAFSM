@tool
extends HBoxContainer

@onready var name_edit = $Name
@onready var remove = $Remove

var undo_redo

var condition:
	set = set_condition


func _ready():
	name_edit.text_submitted.connect(_on_name_edit_text_submitted)
	name_edit.focus_entered.connect(_on_name_edit_focus_entered)
	name_edit.focus_exited.connect(_on_name_edit_focus_exited)
	name_edit.text_changed.connect(_on_name_edit_text_changed)
	set_process_input(false)

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if get_viewport().gui_get_focus_owner() == name_edit:
				var local_event = name_edit.make_input_local(event)
				if not name_edit.get_rect().has_point(local_event.position):
					name_edit.release_focus()

func _on_name_edit_text_changed(new_text):
	# name_edit.release_focus()
	if condition.name == new_text: # Avoid infinite loop
		return

	rename_edit_action(new_text)

func _on_name_edit_focus_entered():
	set_process_input(true)

func _on_name_edit_focus_exited():
	set_process_input(false)
	if condition.name == name_edit.text:
		return

	rename_edit_action(name_edit.text)

func _on_name_edit_text_submitted(new_text):
	name_edit.tooltip_text = new_text

func change_name_edit(from, to):
	var transition = get_parent().get_parent().get_parent().transition # TODO: Better way to get Transition object
	if transition.change_condition_name(from, to):
		if name_edit.text != to: # Manually update name_edit.text, in case called from undo_redo
			name_edit.text = to
	else:
		name_edit.text = from
		push_warning("Change Condition name_edit from (%s) to (%s) failed, name_edit existed" % [from, to])

func rename_edit_action(new_name_edit):
	var old_name_edit = condition.name
	undo_redo.create_action("Rename_edit Condition")
	undo_redo.add_do_method(self, "change_name_edit", old_name_edit, new_name_edit)
	undo_redo.add_undo_method(self, "change_name_edit", new_name_edit, old_name_edit)
	undo_redo.commit_action()

func _on_condition_changed(new_condition):
	if new_condition:
		name_edit.text = new_condition.name
		name_edit.tooltip_text = name_edit.text

func set_condition(c):
	if condition != c:
		condition = c
		_on_condition_changed(c)
