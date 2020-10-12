# Position Popup near to its target while within window, solution from ColorPickerButton source code(https://github.com/godotengine/godot/blob/6d8c14f849376905e1577f9fc3f9512bcffb1e3c/scene/gui/color_picker.cpp#L878)
static func popup_on_target(popup, target):
	popup.set_as_minsize()
	var usable_rect = Rect2(Vector2.ZERO, OS.get_real_window_size())
	var cp_rect = Rect2(Vector2.ZERO, popup.get_size())
	for i in 4:
		if i > 1:
			cp_rect.position.y = target.rect_global_position.y - cp_rect.size.y
		else:
			cp_rect.position.y = target.rect_global_position.y + target.get_size().y

		if i & 1:
			cp_rect.position.x = target.rect_global_position.x
		else:
			cp_rect.position.x = target.rect_global_position.x - max(0, cp_rect.size.x - target.get_size().x)

		if usable_rect.encloses(cp_rect):
			break
	popup.set_position(cp_rect.position)
	popup.popup()
