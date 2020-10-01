tool
extends "ConditionEditor.gd"
const Utils = preload("../../scripts/Utils.gd")
const ValueCondition = preload("../../src/conditions/ValueCondition.gd")

onready var Comparation = $Comparation
onready var ComparationPopupMenu = $Comparation/PopupMenu


func _ready():
	Comparation.connect("pressed", self, "_on_Comparation_pressed")
	ComparationPopupMenu.connect("index_pressed", self, "_on_ComparationPopupMenu_index_changed")

func _on_Comparation_pressed():
	Utils.popup_on_target(ComparationPopupMenu, Comparation)

func _on_ComparationPopupMenu_index_changed(index):
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

func _on_condition_changed(new_condition):
	._on_condition_changed(new_condition)
	if new_condition:
		match new_condition.comparation:
			-1:
				Comparation.text = ComparationPopupMenu.get_item_text(2)
			0:
				Comparation.text = ComparationPopupMenu.get_item_text(0)
			1:
				Comparation.text = ComparationPopupMenu.get_item_text(1)