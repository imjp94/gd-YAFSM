extends Control

var flowchart
	
func _ready():
    flowchart = get_parent().get_parent()
    queue_redraw()

# Original Draw in FlowChart.gd inspired by:
# https://github.com/godotengine/godot/blob/6019dab0b45e1291e556e6d9e01b625b5076cc3c/scene/gui/graph_edit.cpp#L442
func _draw():

    self.position = flowchart.position
    # Extents of the grid.
    self.size = flowchart.size*100  # good with min_zoom = 0.5 e max_zoom = 2.0

    var zoom = flowchart.zoom
    var snap = flowchart.snap

    # Origin of the grid. 
    var offset = -Vector2(1, 1)*10000  # good with min_zoom = 0.5 e max_zoom = 2.0
    
    var corrected_size = size/zoom

    var from = (offset / snap).floor()
    var l = (corrected_size / snap).floor() + Vector2(1, 1)

    var grid_minor = flowchart.grid_minor_color
    var grid_major = flowchart.grid_major_color

    var multi_line_vector_array: PackedVector2Array = PackedVector2Array()
    var multi_line_color_array: PackedColorArray  = PackedColorArray ()

    # for (int i = from.x; i < from.x + len.x; i++) {
    for i in range(from.x, from.x + l.x):
        var color

        if (int(abs(i)) % 10 == 0):
            color = grid_major
        else:
            color = grid_minor

        var base_ofs = i * snap

        multi_line_vector_array.append(Vector2(base_ofs, offset.y))
        multi_line_vector_array.append(Vector2(base_ofs, corrected_size.y))
        multi_line_color_array.append(color)

    # for (int i = from.y; i < from.y + len.y; i++) {
    for i in range(from.y, from.y + l.y):
        var color

        if (int(abs(i)) % 10 == 0):
            color = grid_major
        else:
            color = grid_minor

        var base_ofs = i * snap

        multi_line_vector_array.append(Vector2(offset.x, base_ofs))
        multi_line_vector_array.append(Vector2(corrected_size.x, base_ofs))
        multi_line_color_array.append(color)

    draw_multiline_colors(multi_line_vector_array, multi_line_color_array, -1)