@tool
extends Container
# Custom style normal, focus

var selected: = false:
	set = set_selected


func _init():
	
	focus_mode = FOCUS_NONE # Let FlowChart has the focus to handle gui_input
	mouse_filter = MOUSE_FILTER_PASS

func _draw():
	if selected:
		draw_style_box(get_theme_stylebox("focus", "FlowChartNode"), Rect2(Vector2.ZERO, size))
	else:
		draw_style_box(get_theme_stylebox("normal", "FlowChartNode"), Rect2(Vector2.ZERO, size))

func _notification(what):
	match what:
		NOTIFICATION_SORT_CHILDREN:
			for child in get_children():
				if child is Control:
					fit_child_in_rect(child, Rect2(Vector2.ZERO, size))

func _get_minimum_size():
	return Vector2(50, 50)

func set_selected(v):
	if selected != v:
		selected = v
		queue_redraw()
