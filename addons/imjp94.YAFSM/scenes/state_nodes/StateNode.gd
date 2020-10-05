tool
extends "BaseStateNode.gd"

signal name_changed(old, new)

onready var Name = $Name


func _ready():
	connect("renamed", self, "_on_renamed")
	Name.connect("text_entered", self, "_on_Name_text_entered")
	Name.connect("focus_exited", self, "_on_Name_focus_exited")

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			accept_event() # Consume right-click event

func _on_renamed():
	Name.text = name # Sync Name ui text with Node.name

func _on_Name_text_entered(new_text):
	if name == new_text: # Avoid infinite loop
		return

	rename_action(Name.text)

func _on_Name_focus_exited():
	if name == Name.text:
		return

	rename_action(Name.text)

# Change name through Name ui, but always respect the naming system of scene tree
func change_name(new_name):
	var old = name
	if new_name.nocasecmp_to(State.ENTRY_KEY) == 0 or new_name.nocasecmp_to(State.EXIT_KEY) == 0:
		push_warning("Failed to change state name to %s/%s keyword" % [State.ENTRY_KEY, State.EXIT_KEY])
		Name.text = old
		return

	name = new_name
	emit_signal("name_changed", old, name)

func rename_action(new_name):
	var old_name = name
	undo_redo.create_action("Rename State Node")
	undo_redo.add_do_method(self, "change_name", new_name)
	undo_redo.add_undo_method(self, "change_name", old_name)
	undo_redo.commit_action()