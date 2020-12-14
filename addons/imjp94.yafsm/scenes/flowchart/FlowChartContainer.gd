tool
extends Container

var h_scroll
var v_scroll


func _ready():
	h_scroll = HScrollBar.new()
	add_child(h_scroll)
	h_scroll.set_anchors_and_margins_preset(PRESET_BOTTOM_WIDE)
	h_scroll.connect("value_changed", self, "_on_h_scroll_changed")
	h_scroll.connect("gui_input", self, "_on_h_scroll_gui_input")

	v_scroll = VScrollBar.new()
	add_child(v_scroll)
	v_scroll.set_anchors_and_margins_preset(PRESET_RIGHT_WIDE)
	v_scroll.connect("value_changed", self, "_on_v_scroll_changed")
	v_scroll.connect("gui_input", self, "_on_v_scroll_gui_input")

	h_scroll.margin_right = -v_scroll.rect_size.x
	v_scroll.margin_bottom = -h_scroll.rect_size.y

func _on_h_scroll_gui_input(event):
	if event is InputEventMouseButton:
		var v = (h_scroll.max_value - h_scroll.min_value) * 0.01 # Scroll at 0.1% step
		match event.button_index:
			BUTTON_WHEEL_UP:
				h_scroll.value -= v
			BUTTON_WHEEL_DOWN:
				h_scroll.value += v

func _on_v_scroll_gui_input(event):
	if event is InputEventMouseButton:
		var v = (v_scroll.max_value - v_scroll.min_value) * 0.01 # Scroll at 0.1% step
		match event.button_index:
			BUTTON_WHEEL_UP:
				v_scroll.value -= v # scroll left
			BUTTON_WHEEL_DOWN:
				v_scroll.value += v # scroll right

func _gui_input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_MIDDLE:
				if event.doubleclick:
					get_child(0).rect_scale = Vector2.ONE
			BUTTON_WHEEL_UP:
				get_child(0).rect_scale += Vector2.ONE * 0.01
			BUTTON_WHEEL_DOWN:
				get_child(0).rect_scale -= Vector2.ONE * 0.01
	if event is InputEventMouseMotion:
		match event.button_mask:
			BUTTON_MASK_MIDDLE:
				h_scroll.value -= event.relative.x
				v_scroll.value -= event.relative.y

func _notification(what):
	match what:
		NOTIFICATION_DRAW:
			var content_rect = get_child(0).get_scroll_rect()
			if not get_rect().encloses(content_rect):
				h_scroll.min_value = content_rect.position.x
				h_scroll.max_value = content_rect.size.x + content_rect.position.x - rect_size.x
				# h_scroll.page = 10 # TODO: Dynamically update page with non-zero value
				v_scroll.min_value = content_rect.position.y
				v_scroll.max_value = content_rect.size.y + content_rect.position.y - rect_size.y
				# v_scroll.page = 10 # TODO: Dynamically update page with non-zero value

func _on_h_scroll_changed(value):
	get_child(0).rect_position.x = -value

func _on_v_scroll_changed(value):
	get_child(0).rect_position.y = -value
