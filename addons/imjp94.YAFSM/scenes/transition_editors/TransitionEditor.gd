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

var transition setget set_transition


func _ready():
	Header.connect("gui_input", self, "_on_Header_gui_input")
	Add.connect("pressed", self, "_on_Add_pressed")
	AddPopupMenu.connect("index_pressed", self, "_on_AddPopupMenu_index_pressed")

func _on_Header_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			toggle_conditions()
			if not ContentContainer.visible:
				get_parent().owner.rect_size = Vector2.ZERO

func _on_Add_pressed():
	Utils.popup_on_target(AddPopupMenu, Add)

func _on_AddPopupMenu_index_pressed(index):
	var editor
	var condition
	match index:
		0: # Trigger
			editor = ConditionEditor.instance()
			condition = Condition.new()
		1: # Boolean
			editor = BoolConditionEditor.instance()
			condition = BooleanCondition.new()
		2: # Integer
			editor = IntegerConditionEditor.instance()
			condition = IntegerCondition.new()
		3: # Float
			editor = FloatConditionEditor.instance()
			condition = FloatCondition.new()
		_:
			push_error("Unexpected index(%d) from PopupMenu" % index)

	condition.name = transition.get_unique_name("Param")
	add_condition_editor(editor, condition)

func _on_ConditionEditorRemove_pressed(editor):
	transition.remove_condition(editor.condition.name)
	Conditions.remove_child(editor)
	editor.queue_free()
	update_condition_count()
	get_parent().owner.rect_size = Vector2.ZERO

func _on_transition_changed(new_transition):
	for condition in transition.conditions.values():
		var editor
		if condition is BooleanCondition:
			editor = BoolConditionEditor.instance()
		elif condition is IntegerCondition:
			editor = IntegerConditionEditor.instance()
		elif condition is FloatCondition:
			editor = FloatConditionEditor.instance()
		else:
			editor = ConditionEditor.instance()
		add_condition_editor(editor, condition)
	update_title()
	update_condition_count()

func _on_condition_editor_added(editor):
	editor.Remove.connect("pressed", self, "_on_ConditionEditorRemove_pressed", [editor])

func add_condition_editor(editor, condition):
	Conditions.add_child(editor)
	_on_condition_editor_added(editor)
	editor.condition = condition
	transition.add_condition(condition)
	update_condition_count()

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

func set_transition(t):
	if transition != t:
		transition = t
		_on_transition_changed(t)