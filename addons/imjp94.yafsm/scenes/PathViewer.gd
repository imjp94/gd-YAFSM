tool
extends HBoxContainer

signal dir_pressed(path, index)


func _init():
	add_dir("root")

# Add directory button
func add_dir(dir):
	var button = Button.new()
	button.flat = true
	button.text = dir
	add_child(button)
	button.connect("pressed", self, "_on_button_pressed", [button])
	return button

# Remove directory until index(exclusive)
func remove_dir_until(index):
	var to_remove = []
	for i in get_child_count():
		if index == get_child_count()-1 - i:
			break
		var child = get_child(get_child_count()-1 - i)
		to_remove.append(child)
	for n in to_remove:
		remove_child(n)

# Return current working directory
func get_cwd():
	return get_dir_until(get_child_count()-1)

# Return path until index(inclusive) of directory
func get_dir_until(index):
	var path = ""
	for i in get_child_count():
		if i > index:
			break
		var child = get_child(i)
		if i == 0:
			path = "root"
		else:
			path = str(path, "/", child.text)
	return path

func _on_button_pressed(button):
	var index = button.get_index()
	var path = get_dir_until(index)
	emit_signal("dir_pressed", path, index)
