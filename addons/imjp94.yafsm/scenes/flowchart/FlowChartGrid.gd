extends Control

var flowchart
	
func _ready():
    flowchart = get_parent().get_parent()
    queue_redraw()

func _draw():
    self.position = flowchart.position
    self.size = flowchart.size*100  # good with min_zoom = 0.5 e max_zoom = 2.0

    # Original Draw in FlowChart.gd inspired by:
	# https://github.com/godotengine/godot/blob/6019dab0b45e1291e556e6d9e01b625b5076cc3c/scene/gui/graph_edit.cpp#L442

    var zoom = flowchart.zoom
    var snap = flowchart.snap

    var offset = -Vector2(1, 1)*10000  # good with min_zoom = 0.5 e max_zoom = 2.0
    var corrected_size = size/zoom

    var from = (offset / float(snap)).floor()
    var l = (corrected_size / float(snap)).floor() + Vector2(1, 1)

    var grid_minor = flowchart.grid_minor_color
    var grid_major = flowchart.grid_major_color

    # for (int i = from.x; i < from.x + len.x; i++) {
    for i in range(from.x, from.x + l.x):
        var color

        if (int(abs(i)) % 10 == 0):
            color = grid_major
        else:
            color = grid_minor

        var base_ofs = i * snap
        draw_line(Vector2(base_ofs, offset.y), Vector2(base_ofs, corrected_size.y), color, -1, true)

    # for (int i = from.y; i < from.y + len.y; i++) {
    for i in range(from.y, from.y + l.y):
        var color;

        if (int(abs(i)) % 10 == 0):
            color = grid_major
        else:
            color = grid_minor

        var base_ofs = i * snap
        draw_line(Vector2(offset.x, base_ofs), Vector2(corrected_size.x, base_ofs), color, -1, true)