tool
extends "BaseStateNode.gd"

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

func _on_node_name_changed(old, new):
	# Set resource data
	get_parent().focused_state_machine.change_state_name(old, new)
	# Update GraphEdit connection & TransitionEditor
	for connection in get_parent().get_connection_list():
		var node
		var transition_editor
		if connection.from == old:
			node = self
			transition_editor = node.Transitions.get_node(connection.to)
			transition_editor.name = connection.to # Update name in scene tree
			transition_editor.update_title()
			transition_editor.update_condition_count()
			get_parent().disconnect_node(old, 0, connection.to, 0)
			get_parent().connect_node(new, 0, connection.to, 0)
		elif connection.to == old:
			node = get_parent().get_node(connection.from)
			transition_editor = node.Transitions.get_node(old)
			transition_editor.name = new # Update name in scene tree
			transition_editor.update_title()
			transition_editor.update_condition_count()
			get_parent().disconnect_node(connection.from, 0, old, 0)
			get_parent().connect_node(connection.from, 0, new, 0)

# Change name through Name ui, but always respect the naming system of scene tree
func change_name(new_name):
	var old = name
	if new_name.nocasecmp_to(State.ENTRY_KEY) == 0 or new_name.nocasecmp_to(State.EXIT_KEY) == 0:
		push_warning("Failed to change state name to %s/%s keyword" % [State.ENTRY_KEY, State.EXIT_KEY])
		Name.text = old
		return

	name = new_name
	_on_node_name_changed(old, new_name)

func rename_action(new_name):
	var old_name = name
	undo_redo.create_action("Rename State Node")
	undo_redo.add_do_method(self, "change_name", new_name)
	undo_redo.add_undo_method(self, "change_name", old_name)
	undo_redo.commit_action()
