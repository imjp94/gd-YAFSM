tool
extends HBoxContainer

onready var Name = $Name
onready var Remove = $Remove

var undo_redo

var condition setget set_condition


func _ready():
	Name.connect("text_entered", self, "_on_Name_text_entered")
	Name.connect("focus_entered", self, "_on_Name_focus_entered")
	Name.connect("focus_exited", self, "_on_Name_focus_exited")
	Name.connect("text_changed", self, "_on_Name_text_changed")
	set_process_input(false)

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if get_focus_owner() == Name:
				var local_event = Name.make_input_local(event)
				if not Name.get_rect().has_point(local_event.position):
					Name.release_focus()

func _on_Name_text_entered(new_text):
	Name.release_focus()
	if condition.name == new_text: # Avoid infinite loop
		return

	rename_action(new_text)

func _on_Name_focus_entered():
	set_process_input(true)

func _on_Name_focus_exited():
	set_process_input(false)
	if condition.name == Name.text:
		return

	rename_action(Name.text)

func _on_Name_text_changed(new_text):
	Name.hint_tooltip = new_text

func change_name(from, to):
	var transition = get_parent().get_parent().get_parent().transition # TODO: Better way to get Transition object
	if transition.change_condition_name(from, to):
		if Name.text != to: # Manually update Name.text, in case called from undo_redo
			Name.text = to
	else:
		Name.text = from
		push_warning("Change Condition name from (%s) to (%s) failed, name existed" % [from, to])

func rename_action(new_name):
	var old_name = condition.name
	undo_redo.create_action("Rename Condition")
	undo_redo.add_do_method(self, "change_name", old_name, new_name)
	undo_redo.add_undo_method(self, "change_name", new_name, old_name)
	undo_redo.commit_action()

func _on_condition_changed(new_condition):
	if new_condition:
		Name.text = new_condition.name
		Name.hint_tooltip = Name.text

func set_condition(c):
	if condition != c:
		condition = c
		_on_condition_changed(c)
