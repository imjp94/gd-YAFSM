extends Node
class_name RuntimeStateMachineDebugger

## Runtime launcher for YAFSM's RuntimeStateMachineEditor.
## Drop this node anywhere in a running scene, enable it, and it will open
## a separate OS window that visualizes a StateMachinePlayer in real time.
## Add below to StateMachinePlayer.gd 
## func get_local_params(): return _local_parameters.duplicate()



@export var enabled := true

@export_group("StateMachinePlayer Lookup")
@export var target_smp_path: NodePath
@export var search_group := "state_machine_player"
@export var auto_find_smp := true

@export_group("Window")
@export_range(0.1, 1.0, 0.05) var window_scale := 1.0 / 1.5
@export var min_window_size := Vector2i(480, 280)
@export var max_window_size := Vector2i(1280, 900)
@export var window_title := "YAFSM Runtime Debugger"
@export var always_on_top := true
@export var center_on_main_window := false
@export var initial_margin := Vector2i(-250, -250)

## IMPORTANT:
## Create this scene by duplicating:
##   res://addons/imjp94.yafsm/scenes/StateMachineEditor.tscn
## as:
##   res://addons/imjp94.yafsm/scenes/RuntimeStateMachineEditor.tscn
## Then change the root script to:
##   res://addons/imjp94.yafsm/scenes/RuntimeStateMachineEditor.gd
const RuntimeEditorScene := preload("res://addons/imjp94.yafsm/scenes/RuntimeStateMachineEditor.tscn")

var window: Window
var editor: Control
var smp: StateMachinePlayer

var _old_gui_embed_subwindows := true


func _ready() -> void:
	if not enabled:
		return

	_old_gui_embed_subwindows = get_tree().root.gui_embed_subwindows
	get_tree().root.gui_embed_subwindows = false

	await get_tree().process_frame

	smp = _get_target_smp()
	if not smp:
		push_warning("RuntimeStateMachineDebugger: No StateMachinePlayer found.")
		return

	_create_debug_window()


func _exit_tree() -> void:
	if not enabled:
		return

	if get_tree() and get_tree().root:
		get_tree().root.gui_embed_subwindows = _old_gui_embed_subwindows


func _get_target_smp() -> StateMachinePlayer:
	if target_smp_path != NodePath():
		var node := get_node_or_null(target_smp_path)
		if node is StateMachinePlayer:
			return node
		push_warning("RuntimeStateMachineDebugger: target_smp_path does not point to a StateMachinePlayer.")

	if not search_group.is_empty():
		for node in get_tree().get_nodes_in_group(search_group):
			if node is StateMachinePlayer:
				return node

	if auto_find_smp:
		return _find_smp_recursive(get_tree().current_scene)

	return null


func _find_smp_recursive(node: Node) -> StateMachinePlayer:
	if not node:
		return null

	if node is StateMachinePlayer:
		return node

	for child in node.get_children():
		var result := _find_smp_recursive(child)
		if result:
			return result

	return null


func _create_debug_window() -> void:
	window = Window.new()
	window.title = window_title
	window.size = _get_default_window_size()
	window.position = _get_default_window_position(window.size)
	window.visible = true

	window.borderless = false
	window.unresizable = false
	window.exclusive = false
	window.transient = false
	window.always_on_top = always_on_top
	window.wrap_controls = false

	window.close_requested.connect(_on_debug_window_close_requested)

	add_child(window)

	editor = RuntimeEditorScene.instantiate()
	window.add_child(editor)

	await get_tree().process_frame

	editor.set_anchors_preset(Control.PRESET_FULL_RECT)
	editor.position = Vector2.ZERO
	editor.size = Vector2(window.size)
	editor.offset_left = 0
	editor.offset_top = 0
	editor.offset_right = 0
	editor.offset_bottom = 0
	editor.custom_minimum_size = Vector2.ZERO
	editor.mouse_filter = Control.MOUSE_FILTER_STOP

	editor.bind_state_machine_player(smp)


func _get_default_window_size() -> Vector2i:
	var main_window := get_tree().root
	var scaled_size := Vector2i(Vector2(main_window.size) * window_scale)

	return Vector2i(
		clampi(scaled_size.x, min_window_size.x, max_window_size.x),
		clampi(scaled_size.y, min_window_size.y, max_window_size.y)
	)


func _get_default_window_position(size_to_place: Vector2i) -> Vector2i:
	var main_window := get_tree().root

	if center_on_main_window:
		return main_window.position + (main_window.size - size_to_place) / 2

	return main_window.position + main_window.size - size_to_place - initial_margin


func _on_debug_window_close_requested() -> void:
	if is_instance_valid(window):
		window.queue_free()
		window = null
