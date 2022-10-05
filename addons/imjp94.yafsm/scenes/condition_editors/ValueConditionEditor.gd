@tool
extends "ConditionEditor.gd"
const Utils = preload("../../scripts/Utils.gd")
const Comparation = preload("../../src/conditions/ValueCondition.gd").Comparation

@onready var comparation_button = $Comparation
@onready var comparation_popup_menu = $Comparation/PopupMenu


func _ready():
	super._ready()
	
	comparation_button.pressed.connect(_on_comparation_button_pressed)
	comparation_popup_menu.id_pressed.connect(_on_comparation_popup_menu_id_pressed)

func _on_comparation_button_pressed():
	Utils.popup_on_target(comparation_popup_menu, comparation_button)

func _on_comparation_popup_menu_id_pressed(id):
	change_comparation_action(id)

func _on_condition_changed(new_condition):
	super._on_condition_changed(new_condition)
	if new_condition:
		comparation_button.text = comparation_popup_menu.get_item_text(new_condition.comparation)

func _on_value_changed(new_value):
	pass

func change_comparation(id):
	if id > Comparation.size() - 1:
		push_error("Unexpected id(%d) from PopupMenu" % id)
		return
	condition.comparation = id
	comparation_button.text = comparation_popup_menu.get_item_text(id)

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
