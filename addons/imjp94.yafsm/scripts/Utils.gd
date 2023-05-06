# Position Popup near to its target while within window, solution from ColorPickerButton source code(https://github.com/godotengine/godot/blob/6d8c14f849376905e1577f9fc3f9512bcffb1e3c/scene/gui/color_picker.cpp#L878)
static func popup_on_target(popup: Popup, target: Control):
	popup.reset_size()
	var usable_rect = Rect2(Vector2.ZERO, DisplayServer.window_get_size_with_decorations())
	var cp_rect = Rect2(Vector2.ZERO, popup.get_size())
	for i in 4:
		if i > 1:
			cp_rect.position.y = target.global_position.y - cp_rect.size.y
		else:
			cp_rect.position.y = target.global_position.y + target.get_size().y

		if i & 1:
			cp_rect.position.x = target.global_position.x
		else:
			cp_rect.position.x = target.global_position.x - max(0, cp_rect.size.x - target.get_size().x)

		if usable_rect.encloses(cp_rect):
			break
	var main_window_position = DisplayServer.window_get_position()
	var popup_position = main_window_position + Vector2i(cp_rect.position)  # make it work in multi-screen setups
	popup.set_position(popup_position)
	popup.popup()

static func get_complementary_color(color):
	var r = max(color.r, max(color.b, color.g)) + min(color.r, min(color.b, color.g)) - color.r
	var g = max(color.r, max(color.b, color.g)) + min(color.r, min(color.b, color.g)) - color.g
	var b = max(color.r, max(color.b, color.g)) + min(color.r, min(color.b, color.g)) - color.b
	return Color(r, g, b)

class CohenSutherland:
	const INSIDE = 0 # 0000
	const LEFT = 1 # 0001
	const RIGHT = 2 # 0010
	const BOTTOM = 4 # 0100
	const TOP = 8 # 1000

	# Compute bit code for a point(x, y) using the clip
	static func compute_code(x, y, x_min, y_min, x_max, y_max):
		var code = INSIDE # initialised as being inside of clip window
		if x < x_min: # to the left of clip window
			code |= LEFT
		elif x > x_max: # to the right of clip window
			code |= RIGHT
		
		if y < y_min: # below the clip window
			code |= BOTTOM
		elif y > y_max: # above the clip window
			code |= TOP
		
		return code

	# Cohen-Sutherland clipping algorithm clips a line from
	# P0 = (x0, y0) to P1 = (x1, y1) against a rectangle with
	# diagonal from start(x_min, y_min) to end(x_max, y_max)
	static func line_intersect_rectangle(from, to, rect):
		var x_min = rect.position.x
		var y_min = rect.position.y
		var x_max = rect.end.x
		var y_max = rect.end.y

		var code0 = compute_code(from.x, from.y, x_min, y_min, x_max, y_max)
		var code1 = compute_code(to.x, to.y, x_min, y_min, x_max, y_max)

		var i = 0
		while true:
			i += 1
			if !(code0 | code1): # bitwise OR 0, both points inside window
				return true
			elif code0 & code1: # Bitwise AND not 0, both points share an outside zone
				return false
			else:
				# Failed both test, so calculate line segment to clip
				# from outside point to intersection with clip edge
				var x
				var y
				var code_out = max(code0, code1) # Pick the one outside window

				# Find intersection points
				# slope = (y1 - y0) / (x1 - x0)
				# x = x0 + (1 / slope) * (ym - y0), where ym is y_mix/y_max
				# y = y0 + slope * (xm - x0), where xm is x_min/x_max
				if code_out & TOP: # Point above clip window
					x = from.x + (to.x - from.x) * (y_max - from.y) / (to.y - from.y)
					y = y_max
				elif code_out & BOTTOM: # Point below clip window
					x = from.x + (to.x - from.x) * (y_min - from.y) / (to.y - from.y)
					y = y_min
				elif code_out & RIGHT: # Point is to the right of clip window
					y = from.y + (to.y - from.y) * (x_max - from.x) / (to.x - from.x)
					x = x_max
				elif code_out & LEFT: # Point is to the left of clip window
					y = from.y + (to.y - from.y) * (x_min - from.x) / (to.x - from.x)
					x = x_min

				# Now move outside point to intersection point to clip and ready for next pass
				if code_out == code0:
					from.x = x
					from.y = y
					code0 = compute_code(from.x, from.y, x_min, y_min, x_max, y_max)
				else:
					to.x = x
					to.y = y
					code1 = compute_code(to.x ,to.y, x_min, y_min, x_max, y_max)
