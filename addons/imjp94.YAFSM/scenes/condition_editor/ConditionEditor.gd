tool
extends HBoxContainer

onready var Name = $Name
onready var Remove = $Remove

var condition setget set_condition


func _ready():
	Name.connect("text_entered", self, "_on_Name_text_entered")
	Name.connect("focus_exited", self, "_on_Name_focus_exited")

func _on_Name_text_entered(new_text):
	if condition.name == new_text: # Avoid infinite loop
		return

	change_name(condition.name, new_text)

func _on_Name_focus_exited():
	if condition.name == Name.text:
		return

	change_name(condition.name, Name.text)

func change_name(from, to):
	var transition = get_parent().get_parent().transition # TODO: Better way to get Transition object
	if not transition.change_condition_name(from, to):
		Name.text = from
		push_warning("Change Condition name from (%s) to (%s) failed, name existed" % [from, to])

func _on_condition_changed(new_condition):
	if new_condition:
		Name.text = new_condition.name

func set_condition(c):
	if condition != c:
		condition = c
		_on_condition_changed(c)
