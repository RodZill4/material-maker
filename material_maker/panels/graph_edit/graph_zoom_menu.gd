extends PanelContainer

const SETTING_GRAPH_ZOOM_LEVEL := "graph_zoom_level"


var zoom_level := 1.0


func _ready() -> void:
	if mm_globals.has_config(SETTING_GRAPH_ZOOM_LEVEL):
		zoom_level = mm_globals.get_config(SETTING_GRAPH_ZOOM_LEVEL)
	update_zoom()

func _open():
	var graph_edit : GraphEdit = mm_globals.main_window.get_current_graph_edit()
	if graph_edit:
		zoom_level = graph_edit.zoom
		%ZoomLabel.text = str(zoom_level*100).pad_decimals(0)+"%"


func _on_zoom_out_pressed() -> void:
	zoom_level -= 0.2
	update_zoom()


func _on_zoom_in_pressed() -> void:
	zoom_level += 0.2
	update_zoom()


func _on_zoom_reset_pressed() -> void:
	zoom_level = 1
	update_zoom()


func update_zoom() -> void:
	zoom_level = clamp(zoom_level, 0.25, 2)
	%ZoomLabel.text = str(zoom_level*100).pad_decimals(0)+"%"
	var graph_edit : GraphEdit = mm_globals.main_window.get_current_graph_edit()
	if graph_edit:
		graph_edit.zoom = zoom_level
	mm_globals.set_config(SETTING_GRAPH_ZOOM_LEVEL, zoom_level)
