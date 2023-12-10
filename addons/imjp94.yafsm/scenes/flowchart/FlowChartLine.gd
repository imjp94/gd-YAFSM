@tool
extends Container
# Custom style normal, focus, arrow

var selected: = false:
	set = set_selected


func _init():
	
	focus_mode = FOCUS_CLICK
	mouse_filter = MOUSE_FILTER_IGNORE

func _draw():
	pivot_at_line_start()
	var from = Vector2.ZERO
	from.y += size.y / 2.0
	var to = size
	to.y -= size.y / 2.0
	var arrow = get_theme_icon("arrow", "FlowChartLine")
	var tint = Color.WHITE
	if selected:
		tint = get_theme_stylebox("focus", "FlowChartLine").shadow_color
		draw_style_box(get_theme_stylebox("focus", "FlowChartLine"), Rect2(Vector2.ZERO, size))
	else:
		draw_style_box(get_theme_stylebox("normal", "FlowChartLine"), Rect2(Vector2.ZERO, size))
	
	
	draw_texture(arrow, Vector2.ZERO - arrow.get_size() / 2 + size / 2, tint)

func _get_minimum_size():
	return Vector2(0, 5)

func pivot_at_line_start():
	pivot_offset.x = 0
	pivot_offset.y = size.y / 2.0

func join(from, to, offset=Vector2.ZERO, clip_rects=[]):
	# Offset along perpendicular direction
	var perp_dir = from.direction_to(to).rotated(deg_to_rad(90.0)).normalized()
	from -= perp_dir * offset
	to -= perp_dir * offset

	var dist = from.distance_to(to)
	var dir = from.direction_to(to)
	var center = from + dir * dist / 2

	# Clip line with provided Rect2 array
	var clipped = [[from, to]]
	var line_from = from
	var line_to = to
	for clip_rect in clip_rects:
		if clipped.size() == 0:
			break
		
		line_from = clipped[0][0]
		line_to = clipped[0][1]
		clipped = Geometry2D.clip_polyline_with_polygon(
			[line_from, line_to], 
			[clip_rect.position, Vector2(clip_rect.position.x, clip_rect.end.y), 
				clip_rect.end, Vector2(clip_rect.end.x, clip_rect.position.y)]
		)

	if clipped.size() > 0:
		from = clipped[0][0]
		to = clipped[0][1]
	else: # Line is totally overlapped
		from = center
		to = center + dir * 0.1

	# Extends line by 2px to minimise ugly seam	
	from -= dir * 2.0
	to += dir * 2.0

	size.x = to.distance_to(from)
	# size.y equals to the thickness of line
	position = from
	position.y -= size.y / 2.0
	rotation = Vector2.RIGHT.angle_to(dir)
	pivot_at_line_start()

func set_selected(v):
	if selected != v:
		selected = v
		queue_redraw()

func get_from_pos():
	return get_transform() * (position)

func get_to_pos():
	return get_transform() * (position + size)
