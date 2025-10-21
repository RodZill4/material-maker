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
	zoom_level = clamp(zoom_level, 0.2, 2)
	%ZoomLabel.text = str(zoom_level*100).pad_decimals(0)+"%"
	var graph_edit : GraphEdit = mm_globals.main_window.get_current_graph_edit()
	if graph_edit:
		graph_edit.zoom = zoom_level
	mm_globals.set_config(SETTING_GRAPH_ZOOM_LEVEL, zoom_level)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if not (event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_UP):
			return

		for n in %Projects.get_children():
			var graph: GraphEdit
			if n is GraphEdit:
				graph = n
			elif n.has_method("get_graph_edit"):
				graph = n.get_graph_edit()
			else:
				continue
			if not graph.is_visible_in_tree():
				continue
			if not graph.get_global_rect().has_point(get_global_mouse_position()):
				continue

			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_on_zoom_out_pressed()
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_on_zoom_in_pressed()
				get_viewport().set_input_as_handled()
