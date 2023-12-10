@tool
extends Control

const Utils = preload("res://addons/imjp94.yafsm/scripts/Utils.gd")
const CohenSutherland = Utils.CohenSutherland
const FlowChartNode = preload("FlowChartNode.gd")
const FlowChartNodeScene = preload("FlowChartNode.tscn")
const FlowChartLine = preload("FlowChartLine.gd")
const FlowChartLineScene = preload("FlowChartLine.tscn")
const FlowChartLayer = preload("FlowChartLayer.gd")
const FlowChartGrid = preload("FlowChartGrid.gd")
const Connection = FlowChartLayer.Connection

signal connection(from, to, line) # When a connection established
signal disconnection(from, to, line) # When a connection broken
signal node_selected(node) # When a node selected
signal node_deselected(node) # When a node deselected
signal dragged(node, distance) # When a node dragged

# Margin of content from edge of FlowChart
@export var scroll_margin: = 50
# Offset between two line that interconnecting
@export var interconnection_offset: = 10
# Snap amount
@export var snap: = 20
# Zoom amount
@export var zoom: = 1.0:
	set = set_zoom
@export var zoom_step: = 0.2
@export var max_zoom: = 2.0
@export var min_zoom: = 0.5

var grid = FlowChartGrid.new() # Grid
var content = Control.new() # Root node that hold anything drawn in the flowchart
var current_layer
var h_scroll = HScrollBar.new()
var v_scroll = VScrollBar.new()
var top_bar = VBoxContainer.new()
var gadget = HBoxContainer.new() # Root node of top overlay controls
var zoom_minus = Button.new()
var zoom_reset = Button.new()
var zoom_plus = Button.new()
var snap_button = Button.new()
var snap_amount = SpinBox.new()

var is_snapping = true
var can_gui_select_node = true
var can_gui_delete_node = true
var can_gui_connect_node = true

var _is_connecting = false
var _current_connection
var _is_dragging = false
var _is_dragging_node = false
var _drag_start_pos = Vector2.ZERO
var _drag_end_pos = Vector2.ZERO
var _drag_origins = []
var _selection = []
var _copying_nodes = []

var selection_stylebox = StyleBoxFlat.new()
var grid_major_color = Color(1, 1, 1, 0.2)
var grid_minor_color = Color(1, 1, 1, 0.05)
	

func _init():
	
	focus_mode = FOCUS_ALL
	selection_stylebox.bg_color = Color(0, 0, 0, 0.3)
	selection_stylebox.set_border_width_all(1)

	self.z_index = 0

	content.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(content)
	content.z_index = 1

	grid.mouse_filter = MOUSE_FILTER_IGNORE
	content.add_child.call_deferred(grid)
	grid.z_index = -1

	add_child(h_scroll)
	h_scroll.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	h_scroll.value_changed.connect(_on_h_scroll_changed)
	h_scroll.gui_input.connect(_on_h_scroll_gui_input)

	add_child(v_scroll)
	v_scroll.set_anchors_and_offsets_preset(PRESET_RIGHT_WIDE)
	v_scroll.value_changed.connect(_on_v_scroll_changed)
	v_scroll.gui_input.connect(_on_v_scroll_gui_input)

	h_scroll.offset_right = -v_scroll.size.x
	v_scroll.offset_bottom = -h_scroll.size.y

	h_scroll.min_value = 0
	v_scroll.max_value = 0

	add_layer_to(content)
	select_layer_at(0)

	top_bar.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	top_bar.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(top_bar)

	gadget.mouse_filter = MOUSE_FILTER_IGNORE
	top_bar.add_child(gadget)

	zoom_minus.flat = true
	zoom_minus.tooltip_text = "Zoom Out"
	zoom_minus.pressed.connect(_on_zoom_minus_pressed)
	zoom_minus.focus_mode = FOCUS_NONE
	gadget.add_child(zoom_minus)

	zoom_reset.flat = true
	zoom_reset.tooltip_text = "Zoom Reset"
	zoom_reset.pressed.connect(_on_zoom_reset_pressed)
	zoom_reset.focus_mode = FOCUS_NONE
	gadget.add_child(zoom_reset)

	zoom_plus.flat = true
	zoom_plus.tooltip_text = "Zoom In"
	zoom_plus.pressed.connect(_on_zoom_plus_pressed)
	zoom_plus.focus_mode = FOCUS_NONE
	gadget.add_child(zoom_plus)

	snap_button.flat = true
	snap_button.toggle_mode = true
	snap_button.tooltip_text = "Enable snap and show grid"
	snap_button.pressed.connect(_on_snap_button_pressed)
	snap_button.button_pressed = true
	snap_button.focus_mode = FOCUS_NONE
	gadget.add_child(snap_button)

	snap_amount.value = snap
	snap_amount.value_changed.connect(_on_snap_amount_value_changed)
	gadget.add_child(snap_amount)

func _on_h_scroll_gui_input(event):
	if event is InputEventMouseButton:
		var v = (h_scroll.max_value - h_scroll.min_value) * 0.01 # Scroll at 0.1% step
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				h_scroll.value -= v
			MOUSE_BUTTON_WHEEL_DOWN:
				h_scroll.value += v

func _on_v_scroll_gui_input(event):
	if event is InputEventMouseButton:
		var v = (v_scroll.max_value - v_scroll.min_value) * 0.01 # Scroll at 0.1% step
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				v_scroll.value -= v # scroll left
			MOUSE_BUTTON_WHEEL_DOWN:
				v_scroll.value += v # scroll right

func _on_h_scroll_changed(value):
	content.position.x = -value

func _on_v_scroll_changed(value):
	content.position.y = -value

func set_zoom(v):
	zoom = clampf(v, min_zoom, max_zoom)
	content.scale = Vector2.ONE * zoom
	queue_redraw()
	grid.queue_redraw()

func _on_zoom_minus_pressed():
	set_zoom(zoom - zoom_step)
	queue_redraw()

func _on_zoom_reset_pressed():
	set_zoom(1.0)
	queue_redraw()

func _on_zoom_plus_pressed():
	set_zoom(zoom + zoom_step)
	queue_redraw()

func _on_snap_button_pressed():
	is_snapping = snap_button.button_pressed
	queue_redraw()

func _on_snap_amount_value_changed(value):
	snap = value
	queue_redraw()

func _draw():
	# Update scrolls
	var content_rect: Rect2 = get_scroll_rect(current_layer, 0)
	content.pivot_offset = content_rect.size / 2.0 # Scale from center
	var flowchart_rect: Rect2 = get_rect()
	# ENCLOSE CONDITIONS
	var is_content_enclosed = (flowchart_rect.size.x >= content_rect.size.x)
	is_content_enclosed = is_content_enclosed and (flowchart_rect.size.y >= content_rect.size.y)
	is_content_enclosed = is_content_enclosed and (flowchart_rect.position.x <= content_rect.position.x)
	is_content_enclosed = is_content_enclosed and (flowchart_rect.position.y >= content_rect.position.y)
	if not is_content_enclosed or (h_scroll.min_value==h_scroll.max_value) or (v_scroll.min_value==v_scroll.max_value):
		var h_min = 0 # content_rect.position.x - scroll_margin/2 - content_rect.get_center().x/2
		var h_max = content_rect.size.x - content_rect.position.x - size.x + scroll_margin + content_rect.get_center().x
		var v_min = 0 # content_rect.position.y - scroll_margin/2 - content_rect.get_center().y/2
		var v_max = content_rect.size.y - content_rect.position.y - size.y + scroll_margin + content_rect.get_center().y
		if h_min == h_max: # Otherwise scroll bar will complain no ratio
			h_min -= 0.1
			h_max += 0.1
		if v_min == v_max: # Otherwise scroll bar will complain no ratio
			v_min -= 0.1
			v_max += 0.1
		h_scroll.min_value = h_min
		h_scroll.max_value = h_max
		h_scroll.page = content_rect.size.x / 100
		v_scroll.min_value = v_min
		v_scroll.max_value = v_max
		v_scroll.page = content_rect.size.y / 100

	# Draw selection box
	if not _is_dragging_node and not _is_connecting:
		var selection_box_rect = get_selection_box_rect()
		draw_style_box(selection_stylebox, selection_box_rect)

	if is_snapping:
		grid.visible = true
		grid.queue_redraw()
	else:
		grid.visible = false

	# Debug draw
	# for node in content_nodes.get_children():
	# 	var rect = get_transform() * (content.get_transform() * (node.get_rect()))
	# 	draw_style_box(selection_stylebox, rect)

	# var connection_list = get_connection_list()
	# for i in connection_list.size():
	# 	var connection = _connections[connection_list[i].from][connection_list[i].to]
	# 	# Line's offset along its down-vector
	# 	var line_local_up_offset = connection.line.position - connection.line.get_transform() * (Vector2.UP * connection.offset)
	# 	var from_pos = content.get_transform() * (connection.get_from_pos() + line_local_up_offset)
	# 	var to_pos = content.get_transform() * (connection.get_to_pos() + line_local_up_offset)
	# 	draw_line(from_pos, to_pos, Color.yellow)

func _gui_input(event):

	var OS_KEY_DELETE = KEY_BACKSPACE if ( ["macOS", "OSX"].has(OS.get_name()) ) else KEY_DELETE
	if event is InputEventKey:
		match event.keycode:
			OS_KEY_DELETE:
				if event.pressed and can_gui_delete_node:
					# Delete nodes
					for node in _selection.duplicate():
						if node is FlowChartLine:
							# TODO: More efficient way to get connection from Line node
							for connections_from in current_layer._connections.duplicate().values():
								for connection in connections_from.duplicate().values():
									if connection.line == node:
										disconnect_node(current_layer, connection.from_node.name, connection.to_node.name).queue_free()
						elif node is FlowChartNode:
							remove_node(current_layer, node.name)
							for connection_pair in current_layer.get_connection_list():
								if connection_pair.from == node.name or connection_pair.to == node.name:
									disconnect_node(current_layer, connection_pair.from, connection_pair.to).queue_free()
					accept_event()
			KEY_C:
				if event.pressed and event.ctrl_pressed:
					# Copy node
					_copying_nodes = _selection.duplicate()
					accept_event()
			KEY_D:
				if event.pressed and event.ctrl_pressed:
					# Duplicate node directly from selection
					duplicate_nodes(current_layer, _selection.duplicate())
					accept_event()
			KEY_V:
				if event.pressed and event.ctrl_pressed:
					# Paste node from _copying_nodes
					duplicate_nodes(current_layer, _copying_nodes)
					accept_event()

	if event is InputEventMouseMotion:
		match event.button_mask:
			MOUSE_BUTTON_MASK_MIDDLE:
				# Panning
				h_scroll.value -= event.relative.x
				v_scroll.value -= event.relative.y
				queue_redraw()
			MOUSE_BUTTON_LEFT:
				# Dragging
				if _is_dragging:
					if _is_connecting:
						# Connecting
						if _current_connection:
							var pos = content_position(get_local_mouse_position())
							var clip_rects = [_current_connection.from_node.get_rect()]
							
							# Snapping connecting line
							for i in current_layer.content_nodes.get_child_count():
								var child = current_layer.content_nodes.get_child(current_layer.content_nodes.get_child_count()-1 - i) # Inverse order to check from top to bottom of canvas
								if child is FlowChartNode and child.name != _current_connection.from_node.name:
									if _request_connect_to(current_layer, child.name):
										if child.get_rect().has_point(pos):
											pos = child.position + child.size / 2
											clip_rects.append(child.get_rect())
											break
							_current_connection.line.join(_current_connection.get_from_pos(), pos, Vector2.ZERO, clip_rects)
					elif _is_dragging_node:
						# Dragging nodes
						var dragged = content_position(_drag_end_pos) - content_position(_drag_start_pos)
						for i in _selection.size():
							var selected = _selection[i]
							if not (selected is FlowChartNode):
								continue
							selected.position = (_drag_origins[i] + selected.size / 2.0 + dragged)
							selected.modulate.a = 0.3
							if is_snapping:
								selected.position = selected.position.snapped(Vector2.ONE * snap)
							selected.position -= selected.size / 2.0 
							_on_node_dragged(current_layer, selected, dragged)
							emit_signal("dragged", selected, dragged)
							# Update connection pos
							for from in current_layer._connections:
								var connections_from = current_layer._connections[from]
								for to in connections_from:
									if from == selected.name or to == selected.name:
										var connection = current_layer._connections[from][to]
										connection.join()
					_drag_end_pos = get_local_mouse_position()
					queue_redraw()

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				# Reset zoom
				if event.double_click:
					set_zoom(1.0)
					queue_redraw()
			MOUSE_BUTTON_WHEEL_UP:
				# Zoom in
				set_zoom(zoom + zoom_step/10)
				queue_redraw()
			MOUSE_BUTTON_WHEEL_DOWN:
				# Zoom out
				set_zoom(zoom - zoom_step/10)
				queue_redraw()
			MOUSE_BUTTON_LEFT:
				# Hit detection
				var hit_node
				for i in current_layer.content_nodes.get_child_count():
					var child = current_layer.content_nodes.get_child(current_layer.content_nodes.get_child_count()-1 - i) # Inverse order to check from top to bottom of canvas
					if child is FlowChartNode:
						if child.get_rect().has_point(content_position(get_local_mouse_position())):
							hit_node = child
							break
				if not hit_node:
					# Test Line
					# Refer https://github.com/godotengine/godot/blob/master/editor/plugins/animation_state_machine_editor.cpp#L187
					var closest = -1
					var closest_d = 1e20
					var connection_list = get_connection_list()
					for i in connection_list.size():
						var connection = current_layer._connections[connection_list[i].from][connection_list[i].to]
						# Line's offset along its down-vector
						var line_local_up_offset = connection.line.position - connection.line.get_transform()*(Vector2.DOWN * connection.offset)
						var from_pos = connection.get_from_pos() + line_local_up_offset
						var to_pos = connection.get_to_pos() + line_local_up_offset
						var cp = Geometry2D.get_closest_point_to_segment(content_position(event.position), from_pos, to_pos)
						var d = cp.distance_to(content_position(event.position))
						if d > connection.line.size.y * 2:
							continue
						if d < closest_d:
							closest = i
							closest_d = d
					if closest >= 0:
						hit_node = current_layer._connections[connection_list[closest].from][connection_list[closest].to].line
						
				if event.pressed:
					if not (hit_node in _selection) and not event.shift_pressed:
						# Click on empty space
						clear_selection()
					if hit_node:
						# Click on node(can be a line)
						_is_dragging_node = true
						if hit_node is FlowChartLine:
							current_layer.content_lines.move_child(hit_node, current_layer.content_lines.get_child_count()-1) # Raise selected line to top
							if event.shift_pressed and can_gui_connect_node:
								# Reconnection Start
								for from in current_layer._connections.keys():
									var from_connections = current_layer._connections[from]
									for to in from_connections.keys():
										var connection = from_connections[to]
										if connection.line == hit_node:
											_is_connecting = true
											_is_dragging_node = false
											_current_connection = connection
											_on_node_reconnect_begin(current_layer, from, to)
											break
						if hit_node is FlowChartNode:
							current_layer.content_nodes.move_child(hit_node, current_layer.content_nodes.get_child_count()-1) # Raise selected node to top
							if event.shift_pressed and can_gui_connect_node:
								# Connection start
								if _request_connect_from(current_layer, hit_node.name):
									_is_connecting = true
									_is_dragging_node = false
									var line = create_line_instance()
									var connection = Connection.new(line, hit_node, null)
									current_layer._connect_node(connection)
									_current_connection = connection
									_current_connection.line.join(_current_connection.get_from_pos(), content_position(event.position))
							accept_event()
						if _is_connecting:
							clear_selection()
						else:
							if can_gui_select_node:
								select(hit_node)
					if not _is_dragging:
						# Drag start
						_is_dragging = true
						for i in _selection.size():
							var selected = _selection[i]
							_drag_origins[i] = selected.position
							selected.modulate.a = 1.0
						_drag_start_pos = event.position
						_drag_end_pos = event.position
				else:
					var was_connecting = _is_connecting
					var was_dragging_node = _is_dragging_node
					if _current_connection:
						# Connection end
						var from = _current_connection.from_node.name
						var to = hit_node.name if hit_node else null
						if hit_node is FlowChartNode and _request_connect_to(current_layer, to) and from != to:
							# Connection success
							var line
							if _current_connection.to_node:
								# Reconnection
								line = disconnect_node(current_layer, from, _current_connection.to_node.name)
								_current_connection.to_node = hit_node
								_on_node_reconnect_end(current_layer, from, to)
								connect_node(current_layer, from, to, line)
							else:
								# New Connection
								current_layer.content_lines.remove_child(_current_connection.line)
								line = _current_connection.line
								_current_connection.to_node = hit_node
								connect_node(current_layer, from, to, line)
						else:
							# Connection failed
							if _current_connection.to_node:
								# Reconnection
								_current_connection.join()
								_on_node_reconnect_failed(current_layer, from, name)
							else:
								# New Connection
								_current_connection.line.queue_free()
								_on_node_connect_failed(current_layer, from)
						_is_connecting = false
						_current_connection = null
						accept_event()

					if _is_dragging:
						# Drag end
						_is_dragging = false
						_is_dragging_node = false
						if not (was_connecting or was_dragging_node) and can_gui_select_node:
							var selection_box_rect = get_selection_box_rect()
							# Select node
							for node in current_layer.content_nodes.get_children():
								var rect = get_transform() * (content.get_transform() * (node.get_rect()))
								if selection_box_rect.intersects(rect):
									if node is FlowChartNode:
										select(node)
							# Select line
							var connection_list = get_connection_list()
							for i in connection_list.size():
								var connection = current_layer._connections[connection_list[i].from][connection_list[i].to]
								# Line's offset along its down-vector
								var line_local_up_offset = connection.line.position - connection.line.get_transform() * (Vector2.UP * connection.offset)
								var from_pos = content.get_transform() * (connection.get_from_pos() + line_local_up_offset)
								var to_pos = content.get_transform() * (connection.get_to_pos() + line_local_up_offset)
								if CohenSutherland.line_intersect_rectangle(from_pos, to_pos, selection_box_rect):
									select(connection.line)
						if was_dragging_node:
							# Update _drag_origins with new position after dragged
							for i in _selection.size():
								var selected = _selection[i]
								_drag_origins[i] = selected.position
								selected.modulate.a = 1.0
						_drag_start_pos = _drag_end_pos
						queue_redraw()

# Get selection box rect
func get_selection_box_rect():
	var pos = Vector2(min(_drag_start_pos.x, _drag_end_pos.x), min(_drag_start_pos.y, _drag_end_pos.y))
	var size = (_drag_end_pos - _drag_start_pos).abs()
	return Rect2(pos, size)

# Get required scroll rect base on content
func get_scroll_rect(layer=current_layer, force_scroll_margin=null):
	var _scroll_margin = scroll_margin
	if force_scroll_margin!=null:
		_scroll_margin = force_scroll_margin
	return layer.get_scroll_rect(_scroll_margin)

func add_layer_to(target):
	var layer = create_layer_instance()
	target.add_child(layer)
	return layer

func get_layer(np):
	return content.get_node_or_null(NodePath(np))

func select_layer_at(i):
	select_layer(content.get_child(i))

func select_layer(layer):
	var prev_layer = current_layer
	_on_layer_deselected(prev_layer)
	current_layer = layer
	_on_layer_selected(layer)

# Add node
func add_node(layer, node):
	layer.add_node(node)
	_on_node_added(layer, node)

# Remove node
func remove_node(layer, node_name):
	var node = layer.content_nodes.get_node_or_null(NodePath(node_name))
	if node:
		deselect(node) # Must deselct before remove to make sure _drag_origins synced with _selections
		layer.remove_node(node)
		_on_node_removed(layer, node_name)

# Called after connection established
func _connect_node(line, from_pos, to_pos):
	pass

# Called after connection broken
func _disconnect_node(line):
	if line in _selection:
		deselect(line)

func create_layer_instance():
	var layer = Control.new()
	layer.set_script(FlowChartLayer)
	return layer

# Return new line instance to use, called when connecting node
func create_line_instance():
	return FlowChartLineScene.instantiate()

# Rename node
func rename_node(layer, old, new):
	layer.rename_node(old, new)

# Connect two nodes with a line
func connect_node(layer, from, to, line=null):
	if not line:
		line = create_line_instance()
	line.name = "%s>%s" % [from, to] # "From>To"
	layer.connect_node(line, from, to, interconnection_offset)
	_on_node_connected(layer, from, to)
	emit_signal("connection", from, to, line)

# Break a connection between two node
func disconnect_node(layer, from, to):
	var line = layer.disconnect_node(from, to)
	deselect(line) # Since line is selectable as well
	_on_node_disconnected(layer, from, to)
	emit_signal("disconnection", from, to)
	return line

# Clear all connections
func clear_connections(layer=current_layer):
	layer.clear_connections()

# Select a node(can be a line)
func select(node):
	if node in _selection:
		return

	_selection.append(node)
	node.selected = true
	_drag_origins.append(node.position)
	emit_signal("node_selected", node)

# Deselect a node
func deselect(node):
	_selection.erase(node)
	if is_instance_valid(node):
		node.selected = false
	_drag_origins.pop_back()
	emit_signal("node_deselected", node)

# Clear all selection
func clear_selection():
	for node in _selection.duplicate(): # duplicate _selection array as deselect() edit array
		if not node:
			continue
		deselect(node)
	_selection.clear()

# Duplicate given nodes in editor
func duplicate_nodes(layer, nodes):
	clear_selection()
	var new_nodes = []
	for i in nodes.size():
		var node = nodes[i]
		if not (node is FlowChartNode):
			continue
		var new_node = node.duplicate(DUPLICATE_SIGNALS + DUPLICATE_SCRIPTS)
		var offset = content_position(get_local_mouse_position()) - content_position(_drag_end_pos)
		new_node.position = new_node.position + offset
		new_nodes.append(new_node)
		add_node(layer, new_node)
		select(new_node)
	# Duplicate connection within selection
	for i in nodes.size():
		var from_node = nodes[i]
		for connection_pair in get_connection_list():
			if from_node.name == connection_pair.from:
				for j in nodes.size():
					var to_node = nodes[j]
					if to_node.name == connection_pair.to:
						connect_node(layer, new_nodes[i].name, new_nodes[j].name)
	_on_duplicated(layer, nodes, new_nodes)

# Called after layer selected(current_layer changed)
func _on_layer_selected(layer):
	pass

func _on_layer_deselected(layer):
	pass

# Called after a node added
func _on_node_added(layer, node):
	pass

# Called after a node removed
func _on_node_removed(layer, node):
	pass

# Called when a node dragged
func _on_node_dragged(layer, node, dragged):
	pass

# Called when connection established between two nodes
func _on_node_connected(layer, from, to):
	pass

# Called when connection broken
func _on_node_disconnected(layer, from, to):
	pass

func _on_node_connect_failed(layer, from):
	pass

func _on_node_reconnect_begin(layer, from, to):
	pass

func _on_node_reconnect_end(layer, from, to):
	pass

func _on_node_reconnect_failed(layer, from, to):
	pass

func _request_connect_from(layer, from):
	return true

func _request_connect_to(layer, to):
	return true

# Called when nodes duplicated
func _on_duplicated(layer, old_nodes, new_nodes):
	pass

# Convert position in FlowChart space to content(takes translation/scale of content into account)
func content_position(pos):
	return (pos - content.position - content.pivot_offset * (Vector2.ONE - content.scale)) * 1.0/content.scale

# Return array of dictionary of connection as such [{"from1": "to1"}, {"from2": "to2"}]
func get_connection_list(layer=current_layer):
	return layer.get_connection_list()
