extends "res://addons/imjp94.yafsm/scenes/StateMachineEditor.gd"

## Runtime adapter for YAFSM's original StateMachineEditor.
##
## This script reuses the original StateMachineEditor drawing/debug logic, but
## replaces Remote Inspector reads with direct reads from a real
## StateMachinePlayer instance.
##
## Expected setup:
## - Duplicate StateMachineEditor.tscn as RuntimeStateMachineEditor.tscn.
## - Set the duplicated scene root script to this file.
## - Instantiate RuntimeStateMachineEditor.tscn from RuntimeStateMachineDebugger.

@export var runtime_accent_color := Color(1.0, 0.55, 0.0, 1.0)
@export var runtime_button_active_color := Color(0.25, 0.55, 1.0, 1.0)
@export var icon_button_min_size := Vector2(24, 24)
@export var disable_grid_on_start := true
@export var center_graph_on_bind := true

const ICON_ZOOM_LESS_PATH := "res://addons/imjp94.yafsm/assets/editor_icons/ZoomLess.svg"
const ICON_ZOOM_RESET_PATH := "res://addons/imjp94.yafsm/assets/editor_icons/ZoomReset.svg"
const ICON_ZOOM_MORE_PATH := "res://addons/imjp94.yafsm/assets/editor_icons/ZoomMore.svg"
const ICON_SNAP_GRID_PATH := "res://addons/imjp94.yafsm/assets/editor_icons/SnapGrid.svg"
const ICON_VISIBILITY_VISIBLE_PATH := "res://addons/imjp94.yafsm/assets/editor_icons/GuiVisibilityVisible.svg"
const ICON_VISIBILITY_HIDDEN_PATH := "res://addons/imjp94.yafsm/assets/editor_icons/GuiVisibilityHidden.svg"
const ICON_TRANSITION_ARROW_PATH := "res://addons/imjp94.yafsm/assets/editor_icons/TransitionImmediateBig.svg"

var _runtime_theme_ready := false


func bind_state_machine_player(smp: StateMachinePlayer) -> void:
	if not smp:
		push_warning("RuntimeStateMachineEditor: Cannot bind null StateMachinePlayer.")
		return

	if not smp.state_machine:
		push_warning("RuntimeStateMachineEditor: StateMachinePlayer has no StateMachine resource.")
		return

	# Must happen before assigning state_machine, because set_state_machine()
	# calls draw_graph(), and draw_graph() creates TransitionLine instances
	# using transition_arrow_icon/editor_accent_color.
	setup_runtime_theme()

	state_machine_player = smp
	state_machine = smp.state_machine
	debug_mode = true
	show()

	if center_graph_on_bind:
		call_deferred("_center_runtime_graph")


func setup_runtime_theme() -> void:
	if _runtime_theme_ready:
		return

	editor_accent_color = runtime_accent_color

	var arrow_icon := _load_texture(ICON_TRANSITION_ARROW_PATH)
	if arrow_icon:
		transition_arrow_icon = arrow_icon

	_set_button_icon(zoom_minus, ICON_ZOOM_LESS_PATH)
	_set_button_icon(zoom_reset, ICON_ZOOM_RESET_PATH)
	_set_button_icon(zoom_plus, ICON_ZOOM_MORE_PATH)
	_set_button_icon(snap_button, ICON_SNAP_GRID_PATH)

	var visible_icon := _load_texture(ICON_VISIBILITY_VISIBLE_PATH)
	var hidden_icon := _load_texture(ICON_VISIBILITY_HIDDEN_PATH)
	if visible_icon:
		condition_visibility.texture_pressed = visible_icon
	if hidden_icon:
		condition_visibility.texture_normal = hidden_icon

	selection_stylebox.bg_color = Color(runtime_accent_color.r, runtime_accent_color.g, runtime_accent_color.b, 0.15)
	selection_stylebox.border_color = runtime_accent_color

	_setup_runtime_button_styles()
	_setup_runtime_button_feedback()
	_setup_runtime_message_box()
	_apply_runtime_theme_to_existing_layers()

	if disable_grid_on_start:
		_set_runtime_grid_visible(false)
		snap_button.button_pressed = false
		_update_snap_button_visual()

	_runtime_theme_ready = true


func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_warning("RuntimeStateMachineEditor: Missing runtime icon: %s" % path)
		return null

	var resource := load(path)
	if resource is Texture2D:
		return resource

	push_warning("RuntimeStateMachineEditor: Resource is not Texture2D: %s" % path)
	return null


func _set_button_icon(button: Button, path: String) -> void:
	var icon := _load_texture(path)
	if icon:
		button.icon = icon

	button.custom_minimum_size = icon_button_min_size


func _setup_runtime_button_styles() -> void:
	var normal := StyleBoxEmpty.new()

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(runtime_button_active_color.r, runtime_button_active_color.g, runtime_button_active_color.b, 0.18)
	hover.set_corner_radius_all(3)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(runtime_button_active_color.r, runtime_button_active_color.g, runtime_button_active_color.b, 0.35)
	pressed.set_corner_radius_all(3)

	for button in [zoom_minus, zoom_reset, zoom_plus, snap_button]:
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("hover_pressed", pressed)
		button.add_theme_stylebox_override("focus", normal)
		button.add_theme_stylebox_override("disabled", normal)


func _setup_runtime_button_feedback() -> void:
	# Flat buttons may not show theme pressed state clearly outside the editor.
	# Modulate feedback guarantees visible runtime response.
	if not zoom_minus.pressed.is_connected(_flash_runtime_button.bind(zoom_minus)):
		zoom_minus.pressed.connect(_flash_runtime_button.bind(zoom_minus))
	if not zoom_reset.pressed.is_connected(_flash_runtime_button.bind(zoom_reset)):
		zoom_reset.pressed.connect(_flash_runtime_button.bind(zoom_reset))
	if not zoom_plus.pressed.is_connected(_flash_runtime_button.bind(zoom_plus)):
		zoom_plus.pressed.connect(_flash_runtime_button.bind(zoom_plus))
	if not snap_button.pressed.is_connected(_update_snap_button_visual):
		snap_button.pressed.connect(_update_snap_button_visual)


func _flash_runtime_button(button: Button) -> void:
	button.modulate = runtime_button_active_color

	var tween := create_tween()
	tween.tween_property(button, "modulate", Color.WHITE, 0.18)


func _update_snap_button_visual() -> void:
	snap_button.modulate = runtime_button_active_color if snap_button.button_pressed else Color.WHITE


func _setup_runtime_message_box() -> void:
	# message_box is a bottom-wide transparent overlay. In a runtime Window it can
	# steal input from the ParametersPanel button, so it must ignore mouse events.
	if not is_instance_valid(message_box):
		return

	message_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in message_box.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_runtime_grid_visible(v: bool) -> void:
	is_snapping = v

	if v:
		grid_major_color = Color(1, 1, 1, 0.2)
		grid_minor_color = Color(1, 1, 1, 0.05)
	else:
		grid_major_color = Color(1, 1, 1, 0.0)
		grid_minor_color = Color(1, 1, 1, 0.0)

	if is_instance_valid(grid):
		grid.visible = v
		grid.queue_redraw()

	queue_redraw()


func _on_snap_button_pressed() -> void:
	_set_runtime_grid_visible(snap_button.button_pressed)
	_update_snap_button_visual()


func _apply_runtime_theme_to_existing_layers() -> void:
	for layer in content.get_children():
		_apply_runtime_theme_to_layer(layer)


func _apply_runtime_theme_to_layer(layer: Node) -> void:
	if not layer:
		return

	if "editor_accent_color" in layer:
		layer.editor_accent_color = editor_accent_color

	# The original layer setter derives a complementary color from accent_color.
	# Runtime uses the same orange accent for active/current-state highlight.
	if "editor_complementary_color" in layer:
		layer.editor_complementary_color = editor_accent_color


func create_layer_instance():
	var layer = super.create_layer_instance()
	_apply_runtime_theme_to_layer(layer)
	return layer


func create_line_instance():
	# Keep original line creation. It reads editor_accent_color and
	# transition_arrow_icon prepared by setup_runtime_theme().
	return super.create_line_instance()


func _on_state_machine_player_changed(_new_state_machine_player) -> void:
	# Runtime viewer does not create/edit StateMachine resources.
	pass


func _process(_delta: float) -> void:
	if not debug_mode:
		set_process(false)
		return

	if not is_instance_valid(state_machine_player):
		set_process(false)
		set_debug_mode(false)
		return

	var stack = state_machine_player.stack

	if stack == null or stack.is_empty():
		set_process(false)
		set_debug_mode(false)
		return

	if stack.size() == 1:
		set_current_state(state_machine_player.current)
	else:
		var stack_max_index = stack.size() - 1
		var prev_index = stack.find(_current_state)
		if prev_index == -1:
			if _last_stack.size() < stack.size():
				# Reproduce skipped transitions, matching the original editor debugger behavior.
				var common_index = -1
				for i in _last_stack.size():
					if _last_stack[i] == stack[i]:
						common_index = i
						break
				if common_index > -1:
					var count_from_last_stack = _last_stack.size() - 1 - common_index - 1
					var reversed_last_stack = _last_stack.duplicate()
					reversed_last_stack.reverse()
					for i in count_from_last_stack:
						set_current_state(reversed_last_stack[i + 1])
					for i in range(common_index + 1, stack.size()):
						set_current_state(stack[i])
				else:
					set_current_state(stack.back())
			else:
				set_current_state(stack.back())
		else:
			var missing_count = stack_max_index - prev_index
			for i in range(1, missing_count + 1):
				set_current_state(stack[prev_index + i])

	_last_stack = stack

	var params = state_machine_player.get_params()
	var local_params = _get_local_params_from_player()

	param_panel.update_params(params, local_params)
	var layer = get_focused_layer(_current_state)
	if layer:
		layer.debug_update(_current_state, params, local_params)


func _get_local_params_from_player() -> Dictionary:
	if state_machine_player.has_method("get_local_params"):
		return state_machine_player.get_local_params()

	var value = state_machine_player.get("_local_parameters")
	if value is Dictionary:
		return value.duplicate()

	return {}


func _center_runtime_graph() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	if not current_layer:
		return

	var nodes = current_layer.content_nodes.get_children()
	if nodes.is_empty():
		return

	var bounds := Rect2(nodes[0].position, nodes[0].size)

	for node in nodes:
		if node is Control:
			bounds = bounds.merge(Rect2(node.position, node.size))

	var graph_center := bounds.get_center()
	var viewport_center := size * 0.5

	content.position = viewport_center - graph_center * content.scale

	h_scroll.value = clampf(-content.position.x, h_scroll.min_value, h_scroll.max_value)
	v_scroll.value = clampf(-content.position.y, v_scroll.min_value, v_scroll.max_value)

	content.position.x = -h_scroll.value
	content.position.y = -v_scroll.value

	queue_redraw()
