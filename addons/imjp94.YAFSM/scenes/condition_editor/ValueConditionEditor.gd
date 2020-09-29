tool
extends "ConditionEditor.gd"
const ValueCondition = preload("../../src/ValueCondition.gd")

onready var ComparationOption = $ComparationOption


func _ready():
	$ComparationOption.connect("item_selected", self, "_on_ComparationOption_item_selected")

func _on_ComparationOption_item_selected(index):
	match index:
		0: # Equal
			condition.comparation = ValueCondition.COMPARATION.EQUAL
		1: # Greater
			condition.comparation = ValueCondition.COMPARATION.GREATER
		2: # Lesser
			condition.comparation = ValueCondition.COMPARATION.LESSER
		_:
			push_error("Unexpected index(%d) from PopupMenu" % index)

func _on_condition_changed(new_condition):
	._on_condition_changed(new_condition)
	if new_condition:
		match new_condition.comparation:
			-1:
				ComparationOption.selected = 2
			0:
				ComparationOption.selected = 0
			1:
				ComparationOption.selected = 1