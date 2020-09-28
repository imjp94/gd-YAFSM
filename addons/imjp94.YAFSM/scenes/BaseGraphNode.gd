tool
extends GraphNode
const Transition = preload("../src/Transition.gd")
const State = preload("../src/State.gd")


var state = State.new() setget set_state


func _ready():
	connect("offset_changed", self, "_on_offset_changed")

func _on_offset_changed():
	state.offset = offset

func set_state(s):
	state = s
	offset = state.offset