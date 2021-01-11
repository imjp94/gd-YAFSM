tool
extends Reference

const State = preload("states/State.gd")

var path
var current setget ,get_current
var base setget ,get_base
var end setget ,get_end

var _current_index = 0
var _dirs = [""] # Empty string equals to root


func _init(p):
	path = p
	_dirs += Array(p.split("/"))

func next():
	if has_next():
		_current_index += 1
		return get_current_end()

	return null

func back():
	if has_back():
		_current_index -= 1
		return get_current_end()
	
	return null

func has_next():
	return _current_index < _dirs.size() - 1

func has_back():
	return _current_index > 0

func get_current():
	return PoolStringArray(_dirs.slice(get_base_index(), _current_index)).join("/")

func get_current_end():
	var current_path = get_current()
	return current_path.right(current_path.rfind("/") + 1)

func get_base_index():
	return 1 # Root(empty string) at index 0, base at index 1

func get_end_index():
	return _dirs.size() - 1

func get_base():
	return _dirs[get_base_index()]

func get_end():
	return _dirs[get_end_index()]

func get_dirs():
	return _dirs.duplicate()

func is_entry():
	return get_end() == State.ENTRY_STATE

func is_exit():
	return get_end() == State.EXIT_STATE

func is_nested():
	return _dirs.size() > 2 # Root(empty string) & base taken 2 place
