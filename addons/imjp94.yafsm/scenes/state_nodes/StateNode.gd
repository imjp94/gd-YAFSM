@tool
extends "res://addons/imjp94.yafsm/scenes/flowchart/FlowChartNode.gd"
const State = preload("../../src/states/State.gd")
const StateMachine = preload("../../src/states/StateMachine.gd")

signal name_edit_entered(new_name) # Emits when focused exit or Enter pressed

@onready var name_edit = $MarginContainer/NameEdit

var undo_redo

var state:
	set = set_state


func _init():
	super._init()
	
	set_state(State.new())

func _ready():
	name_edit.focus_exited.connect(_on_NameEdit_focus_exited)
	name_edit.text_submitted.connect(_on_NameEdit_text_submitted)
	set_process_input(false) # _input only required when name_edit enabled to check mouse click outside

func _draw():
	if state is StateMachine:
		if selected:
			draw_style_box(get_theme_stylebox("nested_focus", "StateNode"), Rect2(Vector2.ZERO, size))
		else:
			draw_style_box(get_theme_stylebox("nested_normal", "StateNode"), Rect2(Vector2.ZERO, size))
	else:
		super._draw()

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			# Detect click outside rect
			if get_viewport().gui_get_focus_owner() == name_edit:
				var local_event = make_input_local(event)
				if not name_edit.get_rect().has_point(local_event.position):
					name_edit.release_focus()

func enable_name_edit(v):
	if v:
		set_process_input(true)
		name_edit.editable = true
		name_edit.selecting_enabled = true
		name_edit.mouse_filter = MOUSE_FILTER_PASS
		mouse_default_cursor_shape = CURSOR_IBEAM
		name_edit.grab_focus()
	else:
		set_process_input(false)
		name_edit.editable = false
		name_edit.selecting_enabled = false
		name_edit.mouse_filter = MOUSE_FILTER_IGNORE
		mouse_default_cursor_shape = CURSOR_ARROW
		name_edit.release_focus()

func _on_state_name_changed(new_name):
	name_edit.text = new_name
	size.x = 0 # Force reset horizontal size

func _on_state_changed(new_state):
	if state:
		state.name_changed.connect(_on_state_name_changed)
		if name_edit:
			name_edit.text = state.name

func _on_NameEdit_focus_exited():
	enable_name_edit(false)
	name_edit.deselect()
	emit_signal("name_edit_entered", name_edit.text)

func _on_NameEdit_text_submitted(new_text):
	enable_name_edit(false)
	emit_signal("name_edit_entered", new_text)

func set_state(s):
	if state != s:
		state = s
		_on_state_changed(s)
