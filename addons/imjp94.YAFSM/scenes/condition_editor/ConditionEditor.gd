tool
extends HBoxContainer

onready var Name = $Name
onready var Remove = $Remove

var condition setget set_condition


func _ready():
	Name.connect("text_entered", self, "_on_Name_text_entered")
	Name.connect("focus_exited", self, "_on_Name_focus_exited")

func _on_Name_text_entered(new_text):
	if name == new_text: # Avoid infinite loop
		return

	condition.name = new_text

func _on_Name_focus_exited():
	if name == Name.text:
		return

	condition.name = Name.text

func _on_condition_changed(new_condition):
	if new_condition:
		Name.text = new_condition.name

func set_condition(c):
	if condition != c:
		condition = c
		_on_condition_changed(c)
