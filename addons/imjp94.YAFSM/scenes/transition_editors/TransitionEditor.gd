tool
extends VBoxContainer
const Condition = preload("../../src/conditions/Condition.gd")
const Utils = preload("../../scripts/Utils.gd")
const ValueCondition = preload("../../src/conditions/ValueCondition.gd")
const BooleanCondition = preload("../../src/conditions/BooleanCondition.gd")
const IntegerCondition = preload("../../src/conditions/IntegerCondition.gd")
const FloatCondition = preload("../../src/conditions/FloatCondition.gd")
const ConditionEditor = preload("../condition_editors/ConditionEditor.tscn")
const BoolConditionEditor = preload("../condition_editors/BoolConditionEditor.tscn")
const IntegerConditionEditor = preload("../condition_editors/IntegerConditionEditor.tscn")
const FloatConditionEditor = preload("../condition_editors/FloatConditionEditor.tscn")

onready var Header = $HeaderContainer/Header
onready var Title = $HeaderContainer/Header/Title
onready var TitleLabel = $HeaderContainer/Header/Title/Label
onready var ConditionCountLabel = $HeaderContainer/Header/ConditionCount/Label
onready var Add = $HeaderContainer/Header/HBoxContainer/Add
onready var AddPopupMenu = $HeaderContainer/Header/HBoxContainer/Add/PopupMenu
onready var ContentContainer = $MarginContainer
onready var Conditions = $MarginContainer/Conditions

var undo_redo

var transition setget set_transition

var _to_free


func _init():
	_to_free = []

func _ready():
	Header.connect("gui_input", self, "_on_Header_gui_input")
	Add.connect("pressed", self, "_on_Add_pressed")
	AddPopupMenu.connect("index_pressed", self, "_on_AddPopupMenu_index_pressed")

func _exit_tree():
	for node in _to_free: # Free all orphan node in undo/redo
		if node:
			node.queue_free()

func _on_Header_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			toggle_conditions()
			get_parent().owner.rect_size = Vector2.ZERO

func _on_Add_pressed():
	Utils.popup_on_target(AddPopupMenu, Add)

func _on_AddPopupMenu_index_pressed(index):
	var condition
	match index:
		0: # Trigger
			condition = Condition.new()
		1: # Boolean
			condition = BooleanCondition.new()
		2: # Integer
			condition = IntegerCondition.new()
		3: # Float
			condition = FloatCondition.new()
		_:
			push_error("Unexpected index(%d) from PopupMenu" % index)
	var editor = create_condition_editor(condition)
	condition.name = transition.get_unique_name("Param")
	add_condition_editor_action(editor, condition)

func _on_ConditionEditorRemove_pressed(editor):
	remove_condition_editor_action(editor)

func _on_transition_changed(new_transition):
	for condition in transition.conditions.values():
		var editor = create_condition_editor(condition)
		add_condition_editor(editor, condition)
	update_title()
	update_condition_count()

func _on_condition_editor_added(editor):
	editor.undo_redo = undo_redo
	if not editor.Remove.is_connected("pressed", self, "_on_ConditionEditorRemove_pressed"):
		editor.Remove.connect("pressed", self, "_on_ConditionEditorRemove_pressed", [editor])
	transition.add_condition(editor.condition)
	update_condition_count()
	get_parent().owner.rect_size = Vector2.ZERO

func add_condition_editor(editor, condition):
	Conditions.add_child(editor)
	editor.condition = condition # Must be assigned after enter tree, as assignment would trigger ui code
	_on_condition_editor_added(editor)

func remove_condition_editor(editor):
	transition.remove_condition(editor.condition.name)
	Conditions.remove_child(editor)
	_to_free.append(editor) # Freeing immediately after removal will break undo/redo
	update_condition_count()
	get_parent().owner.rect_size = Vector2.ZERO

func update_title():
	TitleLabel.text = transition.to

func update_condition_count():
	var count = transition.conditions.size()
	ConditionCountLabel.text = str(count)
	if count == 0:
		hide_conditions()
	else:
		show_conditions()

func show_conditions():
	ContentContainer.visible = true

func hide_conditions():
	ContentContainer.visible = false

func toggle_conditions():
	ContentContainer.visible = !ContentContainer.visible

func create_condition_editor(condition):
	var editor
	if condition is BooleanCondition:
		editor = BoolConditionEditor.instance()
	elif condition is IntegerCondition:
		editor = IntegerConditionEditor.instance()
	elif condition is FloatCondition:
		editor = FloatConditionEditor.instance()
	else:
		editor = ConditionEditor.instance()
	return editor

func add_condition_editor_action(editor, condition):
	undo_redo.create_action("Add Transition Condition")
	undo_redo.add_do_method(self, "add_condition_editor", editor, condition)
	undo_redo.add_undo_method(self, "remove_condition_editor", editor)
	undo_redo.commit_action()

func remove_condition_editor_action(editor):
	undo_redo.create_action("Remove Transition Condition")
	undo_redo.add_do_method(self, "remove_condition_editor", editor)
	undo_redo.add_undo_method(self, "add_condition_editor", editor, editor.condition)
	undo_redo.commit_action()

func set_transition(t):
	if transition != t:
		transition = t
		_on_transition_changed(t)