tool
extends GraphNode
const Transition = preload("../src/Transition.gd")

signal name_changed(old, new)

onready var Name = $Name

var state


func _init():
	state = Transition.STATE_STRUCT.duplicate(true)

func _ready():
	connect("renamed", self, "_on_renamed")
	connect("offset_changed", self, "_on_offset_changed")
	Name.connect("text_entered", self, "_on_Name_text_entered")
	Name.connect("focus_exited", self, "_on_Name_focus_exited")

func _on_renamed():
	Name.text = name # Sync Name ui text with Node.name

func _on_offset_changed():
	state.offset = offset

func _on_Name_text_entered(new_text):
	if name == new_text: # Avoid infinite loop
		return

	change_name(Name.text)

func _on_Name_focus_exited():
	if name == Name.text:
		return

	change_name(Name.text)

# Change name through Name ui, but always respect the naming system of scene tree
func change_name(new_name):
	var old = name
	name = new_name
	emit_signal("name_changed", old, name)