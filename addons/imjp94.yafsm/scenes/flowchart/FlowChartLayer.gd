@tool
extends Control
const FlowChartNode = preload("res://addons/imjp94.yafsm/scenes/flowchart/FlowChartNode.gd")

var content_lines = Control.new() # Node that hold all flowchart lines
var content_nodes = Control.new() # Node that hold all flowchart nodes

var _connections = {}

func _init():
	
	name = "FlowChartLayer"
	mouse_filter = MOUSE_FILTER_IGNORE

	content_lines.name = "content_lines"
	content_lines.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(content_lines)
	move_child(content_lines, 0) # Make sure content_lines always behind nodes

	content_nodes.name = "content_nodes"
	content_nodes.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(content_nodes)

func hide_content():
	content_nodes.hide()
	content_lines.hide()

func show_content():
	content_nodes.show()
	content_lines.show()

# Get required scroll rect base on content
func get_scroll_rect(scroll_margin=0):
	var rect = Rect2()
	for child in content_nodes.get_children():
		# Every child is a state/statemachine node
		var child_rect = child.get_rect()
		rect = rect.merge(child_rect)
	return rect.grow(scroll_margin)

# Add node
func add_node(node):
	content_nodes.add_child(node)

# Remove node
func remove_node(node):
	if node:
		content_nodes.remove_child(node)

# Called after connection established
func _connect_node(connection):
	content_lines.add_child(connection.line)
	connection.join()

# Called after connection broken
func _disconnect_node(connection):
	content_lines.remove_child(connection.line)
	return connection.line

# Rename node
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

# Connect two nodes with a line
func connect_node(line, from, to, interconnection_offset=0):
	if from == to:
		return # Connect to self
	var connections_from = _connections.get(from)
	if connections_from:
		if to in connections_from:
			return # Connection existed
	var connection = Connection.new(line, content_nodes.get_node(NodePath(from)), content_nodes.get_node(NodePath(to)))
	if connections_from == null:
		connections_from = {}
		_connections[from] = connections_from
	connections_from[to] = connection
	_connect_node(connection)

	# Check if connection in both ways
	connections_from = _connections.get(to)
	if connections_from:
		var inv_connection = connections_from.get(from)
		if inv_connection:
			connection.offset = interconnection_offset
			inv_connection.offset = interconnection_offset
			connection.join()
			inv_connection.join()

# Break a connection between two node
func disconnect_node(from, to):
	var connections_from = _connections.get(from)
	var connection = connections_from.get(to)
	if connection == null:
		return

	_disconnect_node(connection)
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
	return connection.line

# Clear all selection
func clear_connections():
	for connections_from in _connections.values():
		for connection in connections_from.values():
			connection.line.queue_free()
	_connections.clear()
			
# Return array of dictionary of connection as such [{"from1": "to1"}, {"from2": "to2"}]
func get_connection_list():
	var connection_list = []
	for connections_from in _connections.values():
		for connection in connections_from.values():
			connection_list.append({"from": connection.from_node.name, "to": connection.to_node.name})
	return connection_list

class Connection:
	var line # Control node that draw line
	var from_node
	var to_node
	var offset = 0 # line's y offset to make space for two interconnecting lines

	func _init(p_line, p_from_node, p_to_node):
		line = p_line
		from_node = p_from_node
		to_node = p_to_node

	# Update line position
	func join():
		line.join(get_from_pos(), get_to_pos(), offset, [from_node.get_rect() if from_node else Rect2(), to_node.get_rect() if to_node else Rect2()])

	# Return start position of line
	func get_from_pos():
		return from_node.position + from_node.size / 2

	# Return destination position of line
	func get_to_pos():
		return to_node.position + to_node.size / 2 if to_node else line.position
