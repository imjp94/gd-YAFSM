tool
extends VBoxContainer
const Utils = preload("../scripts/Utils.gd")
const Condition = preload("../src/Condition.gd")
const ValueCondition = preload("../src/ValueCondition.gd")
const BooleanCondition = preload("../src/BooleanCondition.gd")
const IntegerCondition = preload("../src/IntegerCondition.gd")
const FloatCondition = preload("../src/FloatCondition.gd")
const ConditionEditor = preload("condition_editor/ConditionEditor.tscn")
const BoolConditionEditor = preload("condition_editor/BoolConditionEditor.tscn")
const IntegerConditionEditor = preload("condition_editor/IntegerConditionEditor.tscn")
const FloatConditionEditor = preload("condition_editor/FloatConditionEditor.tscn")

onready var To = $Header/To
onready var Add = $Header/HBoxContainer/Add
onready var AddPopupMenu = $Header/HBoxContainer/Add/PopupMenu
onready var Conditions = $Conditions

var transition setget set_transition


func _ready():
	Add.connect("pressed", self, "_on_Add_pressed")
	AddPopupMenu.connect("index_pressed", self, "_on_AddPopupMenu_index_pressed")

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
	
	add_condition_editor(editor, condition)
	condition.name = "Param"
	transition.conditions.append(condition)

func _on_ConditionEditorRemove_pressed(editor):
	transition.conditions.erase(editor.condition)
	$Conditions.remove_child(editor)
	editor.queue_free()

func _on_transition_changed(new_transition):
	To.text = transition.to
	for condition in transition.conditions:
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

func _on_condition_editor_added(editor):
	editor.Remove.connect("pressed", self, "_on_ConditionEditorRemove_pressed", [editor])

func add_condition_editor(editor, condition):
	Conditions.add_child(editor)
	_on_condition_editor_added(editor)
	editor.condition = condition

func set_transition(t):
	if transition != t:
		transition = t
		_on_transition_changed(t)