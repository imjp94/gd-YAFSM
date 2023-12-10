@tool
extends VBoxContainer
const Utils = preload("../../scripts/Utils.gd")
const ConditionEditor = preload("../condition_editors/ConditionEditor.tscn")
const BoolConditionEditor = preload("../condition_editors/BoolConditionEditor.tscn")
const IntegerConditionEditor = preload("../condition_editors/IntegerConditionEditor.tscn")
const FloatConditionEditor = preload("../condition_editors/FloatConditionEditor.tscn")
const StringConditionEditor = preload("../condition_editors/StringConditionEditor.tscn")

@onready var header = $HeaderContainer/Header
@onready var title = $HeaderContainer/Header/Title
@onready var title_icon = $HeaderContainer/Header/Title/Icon
@onready var from = $HeaderContainer/Header/Title/From
@onready var to = $HeaderContainer/Header/Title/To
@onready var condition_count_icon = $HeaderContainer/Header/ConditionCount/Icon
@onready var condition_count_label = $HeaderContainer/Header/ConditionCount/Label
@onready var priority_icon = $HeaderContainer/Header/Priority/Icon
@onready var priority_spinbox = $HeaderContainer/Header/Priority/SpinBox
@onready var add = $HeaderContainer/Header/HBoxContainer/Add
@onready var add_popup_menu = $HeaderContainer/Header/HBoxContainer/Add/PopupMenu
@onready var content_container = $MarginContainer
@onready var condition_list = $MarginContainer/Conditions

var undo_redo

var transition:
	set = set_transition

var _to_free


func _init():
	_to_free = []

func _ready():
	header.gui_input.connect(_on_header_gui_input)
	priority_spinbox.value_changed.connect(_on_priority_spinbox_value_changed)
	add.pressed.connect(_on_add_pressed)
	add_popup_menu.index_pressed.connect(_on_add_popup_menu_index_pressed)

	condition_count_icon.texture = get_theme_icon("MirrorX", "EditorIcons")
	priority_icon.texture = get_theme_icon("AnimationTrackGroup", "EditorIcons")

func _exit_tree():
	free_node_from_undo_redo() # Managed by EditorInspector

func _on_header_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			toggle_conditions()

func _on_priority_spinbox_value_changed(val: int) -> void:
	set_priority(val)

func _on_add_pressed():
	Utils.popup_on_target(add_popup_menu, add)

func _on_add_popup_menu_index_pressed(index):
	## Handle condition name duplication (4.x changed how duplicates are
	## automatically handled and gave a random index instead of a progressive one)
	var default_new_condition_name = "Param"
	var condition_dup_index = 0
	var new_name = default_new_condition_name
	for condition_editor in condition_list.get_children():
		var condition_name = condition_editor.condition.name
		if (condition_name == new_name):
			condition_dup_index += 1
			new_name = "%s%s" % [default_new_condition_name, condition_dup_index]
	var condition
	match index:
		0: # Trigger
			condition = Condition.new(new_name)
		1: # Boolean
			condition = BooleanCondition.new(new_name)
		2: # Integer
			condition = IntegerCondition.new(new_name)
		3: # Float
			condition = FloatCondition.new(new_name)
		4: # String
			condition = StringCondition.new(new_name)
		_:
			push_error("Unexpected index(%d) from PopupMenu" % index)
	var editor = create_condition_editor(condition)
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
	update_priority_spinbox_value()

func _on_condition_editor_added(editor):
	editor.undo_redo = undo_redo
	if not editor.remove.pressed.is_connected(_on_ConditionEditorRemove_pressed):
		editor.remove.pressed.connect(_on_ConditionEditorRemove_pressed.bind(editor))
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

func update_priority_spinbox_value():
	priority_spinbox.value = transition.priority
	priority_spinbox.apply()
	
func set_priority(value):
	transition.priority = value

func show_conditions():
	content_container.visible = true

func hide_conditions():
	content_container.visible = false

func toggle_conditions():
	content_container.visible = !content_container.visible

func create_condition_editor(condition):
	var editor
	if condition is BooleanCondition:
		editor = BoolConditionEditor.instantiate()
	elif condition is IntegerCondition:
		editor = IntegerConditionEditor.instantiate()
	elif condition is FloatCondition:
		editor = FloatConditionEditor.instantiate()
	elif condition is StringCondition:
		editor = StringConditionEditor.instantiate()
	else:
		editor = ConditionEditor.instantiate()
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
			var history_id = undo_redo.get_object_history_id(node)
			undo_redo.get_history_undo_redo(history_id).clear_history(false) # TODO: Should be handled by plugin.gd (Temporary solution as only TransitionEditor support undo/redo)
			node.queue_free()

	_to_free.clear()
