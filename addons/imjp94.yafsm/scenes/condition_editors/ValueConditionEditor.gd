tool
extends "ConditionEditor.gd"
const Utils = preload("../../scripts/Utils.gd")
const ValueCondition = preload("../../src/conditions/ValueCondition.gd")

onready var Comparation = $Comparation
onready var ComparationPopupMenu = $Comparation/PopupMenu


func _ready():
	Comparation.connect("pressed", self, "_on_Comparation_pressed")
	ComparationPopupMenu.connect("id_pressed", self, "_on_ComparationPopupMenu_id_pressed")

func _on_Comparation_pressed():
	Utils.popup_on_target(ComparationPopupMenu, Comparation)

func _on_ComparationPopupMenu_id_pressed(id):
	change_comparation_action(id)

func _on_condition_changed(new_condition):
	._on_condition_changed(new_condition)
	if new_condition:
		Comparation.text = ComparationPopupMenu.get_item_text(new_condition.comparation)

func _on_value_changed(new_value):
	pass

func change_comparation(id):
	if id > ValueCondition.Comparation.size() - 1:
		push_error("Unexpected id(%d) from PopupMenu" % id)
		return
	condition.comparation = id
	Comparation.text = ComparationPopupMenu.get_item_text(id)

func change_comparation_action(id):
	var from = condition.comparation
	var to = id
	undo_redo.create_action("Change Condition Comparation")
	undo_redo.add_do_method(self, "change_comparation", to)
	undo_redo.add_undo_method(self, "change_comparation", from)
	undo_redo.commit_action()

func set_value(v):
	if condition.value != v:
		condition.value = v
		_on_value_changed(v)

func change_value_action(from, to):
	if from == to:
		return
	undo_redo.create_action("Change Condition Value")
	undo_redo.add_do_method(self, "set_value", to)
	undo_redo.add_undo_method(self, "set_value", from)
	undo_redo.commit_action()