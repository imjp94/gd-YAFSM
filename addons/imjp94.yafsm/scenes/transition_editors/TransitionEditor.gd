tool
extends VBoxContainer
const Condition = preload("../../src/conditions/Condition.gd")
const Utils = preload("../../scripts/Utils.gd")
const ValueCondition = preload("../../src/conditions/ValueCondition.gd")
const BooleanCondition = preload("../../src/conditions/BooleanCondition.gd")
const IntegerCondition = preload("../../src/conditions/IntegerCondition.gd")
const FloatCondition = preload("../../src/conditions/FloatCondition.gd")
const StringCondition = preload("../../src/conditions/StringCondition.gd")
const ConditionEditor = preload("../condition_editors/ConditionEditor.tscn")
const BoolConditionEditor = preload("../condition_editors/BoolConditionEditor.tscn")
const IntegerConditionEditor = preload("../condition_editors/IntegerConditionEditor.tscn")
const FloatConditionEditor = preload("../condition_editors/FloatConditionEditor.tscn")
const StringConditionEditor = preload("../condition_editors/StringConditionEditor.tscn")

onready var header = $HeaderContainer/Header
onready var title = $HeaderContainer/Header/Title
onready var title_icon = $HeaderContainer/Header/Title/Icon
onready var from = $HeaderContainer/Header/Title/From
onready var to = $HeaderContainer/Header/Title/To
onready var condition_count_icon = $HeaderContainer/Header/ConditionCount/Icon
onready var condition_count_label = $HeaderContainer/Header/ConditionCount/Label
onready var add = $HeaderContainer/Header/HBoxContainer/Add
onready var add_popup_menu = $HeaderContainer/Header/HBoxContainer/Add/PopupMenu
onready var content_container = $MarginContainer
onready var condition_list = $MarginContainer/Conditions

var undo_redo

var transition setget set_transition

var _to_free


func _init():
	_to_free = []

func _ready():
	header.connect("gui_input", self, "_on_header_gui_input")
	add.connect("pressed", self, "_on_add_pressed")
	add_popup_menu.connect("index_pressed", self, "_on_add_popup_menu_index_pressed")

func _on_header_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			toggle_conditions()

func _on_add_pressed():
	Utils.popup_on_target(add_popup_menu, add)

func _on_add_popup_menu_index_pressed(index):
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
		4: # String
			condition = StringCondition.new()
		_:
			push_error("Unexpected index(%d) from PopupMenu" % index)
	var editor = create_condition_editor(condition)
	condition.name = transition.get_unique_name("Param")
	add_condition_editor_action(editor, condition)

func _on_ConditionEditorRemove_pressed(editor):
	remove_condition_editor_action(editor)

func _on_transition_changed(new_transition):
	if not new_transition:
		return

	for condition in transition.conditions.values():
		var editor = create_condition_editor(condition)
		add_condition_editor(editor, condition)
	update_title()
	update_condition_count()

func _on_condition_editor_added(editor):
	editor.undo_redo = undo_redo
	if not editor.remove.is_connected("pressed", self, "_on_ConditionEditorRemove_pressed"):
		editor.remove.connect("pressed", self, "_on_ConditionEditorRemove_pressed", [editor])
	transition.add_condition(editor.condition)
	update_condition_count()

func add_condition_editor(editor, condition):
	condition_list.add_child(editor)
	editor.condition = condition # Must be assigned after enter tree, as assignment would trigger ui code
	_on_condition_editor_added(editor)

func remove_condition_editor(editor):
	transition.remove_condition(editor.condition.name)
	condition_list.remove_child(editor)
	_to_free.append(editor) # Freeing immediately after removal will break undo/redo
	update_condition_count()

func update_title():
	from.text = transition.from
	to.text = transition.to

func update_condition_count():
	var count = transition.conditions.size()
	condition_count_label.text = str(count)
	if count == 0:
		hide_conditions()
	else:
		show_conditions()

func show_conditions():
	content_container.visible = true

func hide_conditions():
	content_container.visible = false

func toggle_conditions():
	content_container.visible = !content_container.visible

func create_condition_editor(condition):
	var editor
	if condition is BooleanCondition:
		editor = BoolConditionEditor.instance()
	elif condition is IntegerCondition:
		editor = IntegerConditionEditor.instance()
	elif condition is FloatCondition:
		editor = FloatConditionEditor.instance()
	elif condition is StringCondition:
		editor = StringConditionEditor.instance()
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

# Free nodes cached in UndoRedo stack
func free_node_from_undo_redo():
	for node in _to_free:
		if is_instance_valid(node):
			node.queue_free()
	_to_free.clear()
