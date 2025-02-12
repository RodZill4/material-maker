extends PanelContainer

const SETTING_GRAPH_ZOOM_LEVEL := "graph_zoom_level"


var zoom_level := 1.0


func _ready() -> void:
	if mm_globals.has_config(SETTING_GRAPH_ZOOM_LEVEL):
		zoom_level = mm_globals.get_config(SETTING_GRAPH_ZOOM_LEVEL)


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
	%ZoomLabel.text = str(zoom_level*100)+"%"
	for n in %Projects.get_children():
		if n is GraphEdit:
			n.zoom = zoom_level
	mm_globals.set_config(SETTING_GRAPH_ZOOM_LEVEL, zoom_level)
