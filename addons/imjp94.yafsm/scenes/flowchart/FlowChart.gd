tool
extends Control

const FlowChartNode = preload("FlowChartNode.gd")
const FlowChartNodeScene = preload("FlowChartNode.tscn")
const FlowChartLine = preload("FlowChartLine.gd")
const FlowChartLineScene = preload("FlowChartLine.tscn")

signal connection(from, to, line)
signal disconnection(from, to, line)
signal node_selected(node)
signal node_deselected(node)
signal drag_start(node)
signal drag_end(node)

export var scroll_margin = 100
export var interconnection_offset = 10

var h_scroll
var v_scroll

var _content
var _Lines # Node that hold all lines
var _connections = {}
var _is_connecting = false
var _current_connection
var _moving_node
var _mouse_offset = Vector2.ZERO
var _selection = []
var _mouse_start = Vector2.ZERO
	

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

	_content = Control.new()
	_content.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_content)
	_Lines = Control.new()
	_Lines.name = "Lines"
	_content.add_child(_Lines)
	_content.move_child(_Lines, 0) # Make sure lines always behind nodes

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

func _notification(what):
	match what:
		NOTIFICATION_DRAW:
			var content_rect = get_scroll_rect()
			if not get_rect().encloses(content_rect):
				h_scroll.min_value = content_rect.position.x
				h_scroll.max_value = content_rect.size.x + content_rect.position.x - rect_size.x
				# h_scroll.page = 10 # TODO: Dynamically update page with non-zero value
				v_scroll.min_value = content_rect.position.y
				v_scroll.max_value = content_rect.size.y + content_rect.position.y - rect_size.y
				# v_scroll.page = 10 # TODO: Dynamically update page with non-zero value

func _on_h_scroll_changed(value):
	_content.rect_position.x = -value

func _on_v_scroll_changed(value):
	_content.rect_position.y = -value


func _unhandled_key_input(event):
	match event.scancode:
		KEY_DELETE:
			for node in _selection:
				if node:
					if node is FlowChartLine:
						# TODO: More efficient way to get connection from Line node
						for connections_from in _connections.values():
							for connection in connections_from.values():
								if connection.line == node:
									disconnect_node(connection.from_node.name, connection.to_node.name)
									return
					elif node is FlowChartNode:
						for connection_pair in get_connection_list():
							if connection_pair.from == node.name or connection_pair.to == node.name:
								disconnect_node(connection_pair.from, connection_pair.to)
							remove_node(node.name)

func _gui_input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_MIDDLE:
				if event.doubleclick:
					_content.rect_scale = Vector2.ONE
			BUTTON_WHEEL_UP:
				_content.rect_scale += Vector2.ONE * 0.01
			BUTTON_WHEEL_DOWN:
				_content.rect_scale -= Vector2.ONE * 0.01
	if event is InputEventMouseMotion:
		match event.button_mask:
			BUTTON_MASK_MIDDLE:
				h_scroll.value -= event.relative.x
				v_scroll.value -= event.relative.y

	if event is InputEventMouseButton:
		var hit_node
		for i in _content.get_child_count():
			var child = _content.get_child(_content.get_child_count()-1 - i) # Inverse order to check from top to bottom of canvas
			if child is FlowChartNode:
				if child.get_rect().has_point(content_position(event.position)):
					hit_node = child
					break
		if not hit_node:
			# Test Line
			# Refer https://github.com/godotengine/godot/blob/master/editor/plugins/animation_state_machine_editor.cpp#L187
			var closest = -1
			var closest_d = 1e20
			var connection_list = get_connection_list()
			for i in connection_list.size():
				var connection = _connections[connection_list[i].from][connection_list[i].to]
				# Line's offset along its up-vector
				var line_local_up_offset = connection.line.rect_position - connection.line.get_transform().xform(Vector2.UP * connection.offset)
				var from_pos = connection.get_from_pos() + line_local_up_offset
				var to_pos = connection.get_to_pos() + line_local_up_offset
				var cp = Geometry.get_closest_point_to_segment_2d(content_position(event.position), from_pos, to_pos)
				var d = cp.distance_to(content_position(event.position))
				if d > connection.line.rect_size.y * 2:
					continue
				if d < closest_d:
					closest = i
					closest_d = d

			if closest >= 0:
				hit_node = _connections[connection_list[closest].from][connection_list[closest].to].line

		match event.button_index:
			BUTTON_LEFT:
				if event.pressed:
					if not hit_node in _selection and not event.shift:
						clear_selection()

					if hit_node:
						select(hit_node)
						if hit_node is FlowChartNode:
							_content.move_child(hit_node, get_child_count()-1) # Raise selected node to top
							if event.shift:
								# Connection start
								var line = create_line_instance()
								var connection = Connection.new(line, hit_node, null)
								_connect_node(line, connection.get_from_pos(), get_local_mouse_position())
								_current_connection = connection
							else:
								# Move node
								_moving_node = hit_node
								_mouse_offset = _moving_node.rect_position - content_position(event.position)
								_on_drag_end(_moving_node)
								emit_signal("drag_start", _moving_node)
							accept_event()
				else:
					if _current_connection:
						if hit_node is FlowChartNode:
							# Connection end
							_disconnect_node(_current_connection.line)
							_current_connection.to_node = hit_node
							connect_node(_current_connection.from_node.name, _current_connection.to_node.name)
						else:
							_current_connection.line.queue_free()
						accept_event()

					if _moving_node:
						_on_drag_end(_moving_node)
						emit_signal("drag_end", _moving_node)
						_moving_node = null
						_mouse_offset = Vector2.ZERO
					_current_connection = null

func _process(_delta):
	if _current_connection:
		_current_connection.line.join(_current_connection.get_from_pos(), content_position(get_local_mouse_position()))
	if _moving_node: # TODO: Immediate dragging right after selected, cause ScrollContainer unable focus properly
		_moving_node.rect_position =  content_position(get_local_mouse_position() + _mouse_offset)
		update()
		for from in _connections:
			var connections_from = _connections[from]
			for to in connections_from:
				if from == _moving_node.name or to == _moving_node.name:
					var connection = _connections[from][to]
					connection.join()

func get_scroll_rect():
	var rect = Rect2()
	for child in _content.get_children():
		var child_rect = child.get_rect()
		rect = rect.merge(child_rect)
	return rect.grow(scroll_margin)

func add_node(node):
	_content.add_child(node)
	_on_node_added(node)

func remove_node(node_name):
	var node = _content.get_node_or_null(node_name)
	if node:
		_content.remove_child(node)
		node.queue_free() # TODO: add to _to_free instead
		_on_node_removed(node_name)

func _on_node_added(node):
	pass

func _on_node_removed(node):
	pass

func _connect_node(line, from_pos, to_pos):
	_Lines.add_child(line)
	line.join(from_pos, to_pos)

func _disconnect_node(line):
	_Lines.remove_child(line)
	line.queue_free()

func create_line_instance():
	return FlowChartLineScene.instance()

func rename_node(old, new):
	for from in _connections.keys():
		if from == old: # Connection from
			var from_connections = _connections[from]
			_connections.erase(old)
			_connections[new] = from_connections
		else: # Connection to
			for to in _connections[from].keys():
				if to == old:
					var from_connection = _connections[from]
					var value = from_connection[old]
					from_connection.erase(old)
					from_connection[new] = value

func connect_node(from, to):
	var connections_from = _connections.get(from)
	if connections_from:
		if to in connections_from:
			return # Connection existed
	var line = create_line_instance()
	var connection = Connection.new(line, _content.get_node(from), _content.get_node(to))
	if not connections_from:
		connections_from = {}
		_connections[from] = connections_from
	connections_from[to] = connection
	_connect_node(line, connection.get_from_pos(), connection.get_to_pos())

	# Check if connection in both ways
	connections_from = _connections.get(to)
	if connections_from:
		var inv_connection = connections_from.get(from)
		if inv_connection:
			connection.offset = interconnection_offset
			inv_connection.offset = interconnection_offset
			connection.join()
			inv_connection.join()
	_on_connect_node(from, to)
	emit_signal("connection", from, to, line)

func disconnect_node(from, to):
	var connections_from = _connections.get(from)
	var connection = connections_from.get(to)
	if not connection:
		return

	_disconnect_node(connection.line)
	if connections_from.size() == 1:
		_connections.erase(from)
	else:
		connections_from.erase(to)

	connections_from = _connections.get(to)
	if connections_from:
		var inv_connection = connections_from.get(from)
		if inv_connection:
			inv_connection.offset = 0
			inv_connection.join()
	_on_disconnect_node(from, to)
	emit_signal("disconnection", from, to)

func clear_connections():
	for connections_from in _connections.values():
		for connection in connections_from.values():
			connection.line.queue_free()
	_connections.clear()

func select(node):
	if node in _selection:
		return

	_selection.append(node)
	node.selected = true
	emit_signal("node_selected", node)

func deselect(node):
	_selection.erase(node)
	node.selected = false
	emit_signal("node_deselected", node)

func clear_selection():
	for node in _selection:
		if not node:
			continue
		deselect(node)
	_selection.clear()

func _on_connect_node(from, to):
	pass

func _on_disconnect_node(from, to):
	pass

func _on_drag_start(node):
	pass

func _on_drag_end(node):
	pass

# Convert position in FlowChart space to content(takes translation/scale of content into account)
func content_position(pos):
	return (pos - _content.rect_position) * 1.0/_content.rect_scale

func get_connection_list():
	var connection_list = []
	for connections_from in _connections.values():
		for connection in connections_from.values():
			connection_list.append({"from": connection.from_node.name, "to": connection.to_node.name})
	return connection_list

func get_selected():
	var focused_owner = get_focus_owner()
	if focused_owner:
		if focused_owner.get_parent() == self or focused_owner.get_parent() == _Lines:
			return focused_owner
	return null

func set_selected(node):
	node.grab_focus()

class Connection:
	var line # Control node that draw line
	var from_node
	var to_node
	var offset = 0

	func _init(p_line, p_from_node, p_to_node):
		line = p_line
		from_node = p_from_node
		to_node = p_to_node

	func join():
		line.join(get_from_pos(), get_to_pos(), offset)

	func get_from_pos():
		return from_node.rect_position + from_node.rect_size / 2

	func get_to_pos():
		return to_node.rect_position + to_node.rect_size / 2 if to_node else line.rect_position
