tool
extends Control
const FlowChartNode = preload("FlowChartNode.tscn")


export var from = Vector2.ZERO
export var to = Vector2.ZERO

onready var Line = $Line

var _is_connecting = false


func _gui_input(event):
	if Engine.editor_hint:
		return

	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_LEFT:
				if event.pressed:
					var focus_owner = get_focus_owner()
					if focus_owner:
						focus_owner.release_focus()
					_is_connecting = false
					_is_connecting = true
					from = get_local_mouse_position()
				else:
					to = get_local_mouse_position()
				Line.join(from, to)
			BUTTON_RIGHT:
				if not event.pressed:
					_on_context_menu_request(get_local_mouse_position())

func _process(_delta):
	if Engine.editor_hint:
		return

	if Input.is_mouse_button_pressed(BUTTON_LEFT) and _is_connecting:
		to = get_local_mouse_position()
		Line.join(from, to)

func _on_context_menu_request(_pos):
	var new_node = FlowChartNode.instance()
	add_child(new_node)
