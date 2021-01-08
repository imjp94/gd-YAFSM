tool
extends HBoxContainer

signal dir_pressed(path, dir, index)


func _init():
	add_dir("/")

func create_button_instance():
	var button = Button.new()
	button.flat = true
	return button

func add_dir(dir):
	var button = create_button_instance()
	button.text = dir
	add_child(button)
	button.connect("pressed", self, "_on_button_pressed", [button])
	return button

func remove_dir_until(index):
	var to_remove = []
	for i in get_child_count():
		if index == get_child_count()-1 - i:
			break
		var child = get_child(get_child_count()-1 - i)
		to_remove.append(child)
	for n in to_remove:
		remove_child(n)

func get_current_full_dir():
	return get_path_until(get_child_count()-1)

func get_path_until(index):
	var path = ""
	for i in get_child_count():
		if i > index:
			break
		var child = get_child(i)
		if i == 0:
			path = "/"
		elif i == 1:
			path = str(path, child.text)
		else:
			path = str(path, "/", child.text)
	return path

func _on_button_pressed(button):
	var index = button.get_index()
	var path = get_path_until(index)
	emit_signal("dir_pressed", path, button.text, index)
