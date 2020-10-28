tool
extends Container

export var line_width = 1.0 setget set_line_width


func _init():
	focus_mode = FOCUS_CLICK
	connect("focus_entered", self, "_on_focused_entered")

func _on_focused_entered():
	print("focused line")

func _draw():
	pivot_at_line_start()
	var from = Vector2.ZERO
	from.y += rect_size.y / 2.0
	var to = rect_size
	to.y -= rect_size.y / 2.0
	draw_line(from, to, Color.white, line_width, true)

func _notification(what):
	match what:
		NOTIFICATION_SORT_CHILDREN:
			for child in get_children():
				if child is Control:
					fit_child_in_rect(child, Rect2(Vector2.ZERO, rect_size))

func _get_minimum_size():
	return Vector2(0, 5)

func pivot_at_line_start():
	rect_pivot_offset.x = 0
	rect_pivot_offset.y = rect_size.y / 2.0

func join(from, to):
	rect_size.x = to.distance_to(from)
	# rect_size.y remain unchanged as it is bound to line_width
	rect_position = from
	rect_position.y -= rect_size.y / 2.0
	var dir = (to - from).normalized()
	var rotation = Vector2.RIGHT.angle_to(dir)
	rect_rotation = rad2deg(rotation)
	pivot_at_line_start()

func set_line_width(v):
	if line_width != v:
		line_width = v
		rect_size.y = v
		update()
