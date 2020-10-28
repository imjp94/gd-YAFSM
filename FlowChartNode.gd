extends Container


var stylebox = StyleBoxFlat.new()


func _init():
	focus_mode = FOCUS_CLICK

func _ready():
	connect("focus_entered", self, "_on_focused_entered")
	update()

# func _gui_input(event):
# 	if event is InputEventMouseButton:
# 		if event.pressed:
# 			grab_focus()
# 			accept_event()

func _process(delta):
	if Input.is_mouse_button_pressed(BUTTON_LEFT) and get_focus_owner() == self:
		rect_position = get_global_mouse_position()
		update()

func _draw():
	draw_style_box(stylebox, Rect2(Vector2.ZERO, rect_size))

func _notification(what):
	match what:
		NOTIFICATION_SORT_CHILDREN:
			for child in get_children():
				if child is Control:
					fit_child_in_rect(child, Rect2(Vector2.ZERO, rect_size))

func _get_minimum_size():
	return Vector2(50, 50)

func _on_focused_entered():
	print("focused")
