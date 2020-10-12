tool
extends "ConditionEditor.gd"
const Utils = preload("../../scripts/Utils.gd")
const ValueCondition = preload("../../src/conditions/ValueCondition.gd")

onready var Comparation = $Comparation
onready var ComparationPopupMenu = $Comparation/PopupMenu

# Dumb method to convert comparation to menu index
const COMPARATION_TO_MENU = {
	ValueCondition.Comparation.LESSER: 2,
	ValueCondition.Comparation.EQUAL: 0,
	ValueCondition.Comparation.GREATER: 1
}


func _ready():
	Comparation.connect("pressed", self, "_on_Comparation_pressed")
	ComparationPopupMenu.connect("index_pressed", self, "_on_ComparationPopupMenu_index_changed")

func _on_Comparation_pressed():
	Utils.popup_on_target(ComparationPopupMenu, Comparation)

func _on_ComparationPopupMenu_index_changed(index):
	change_comparation_action(index)

func _on_condition_changed(new_condition):
	._on_condition_changed(new_condition)
	if new_condition:
		Comparation.text = ComparationPopupMenu.get_item_text(COMPARATION_TO_MENU[new_condition.comparation])

func _on_value_changed(new_value):
	pass

func change_comparation(index):
	match index:
		0: # Equal
			condition.comparation = ValueCondition.Comparation.EQUAL
		1: # Greater
			condition.comparation = ValueCondition.Comparation.GREATER
		2: # Lesser
			condition.comparation = ValueCondition.Comparation.LESSER
		_:
			push_error("Unexpected index(%d) from PopupMenu" % index)
	Comparation.text = ComparationPopupMenu.get_item_text(index)

func change_comparation_action(index):
	var from = COMPARATION_TO_MENU[condition.comparation]
	var to = index
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