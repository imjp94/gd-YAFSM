tool
extends GraphNode
const Transition = preload("../src/Transition.gd")


var state setget set_state


func _init():
	state = Transition.STATE_STRUCT.duplicate(true)

func _ready():
	connect("offset_changed", self, "_on_offset_changed")

func _on_offset_changed():
	state.offset = offset

func set_state(s):
	state = s
	offset = state.offset