extends PanelContainer

const SETTING_GRAPH_MINIMAP := "graph_minimap"
const SETTING_GRAPH_GRID_VISIBILITY := "graph_grid_visibility"
const SETTING_GRAPH_GRID_SIZE := "graph_grid_size"
const SETTING_GRAPH_GRID_SNAPPING := "graph_grid_snapping"
const SETTING_GRAPH_LINE_CURVATURE := "graph_line_curvaature"
const SETTING_GRAPH_LINE_THICKNESS := "graph_line_thickness"

func _ready() -> void:
	if mm_globals.has_config(SETTING_GRAPH_MINIMAP):
		%Minimap.button_pressed = mm_globals.get_config(SETTING_GRAPH_MINIMAP)

	if mm_globals.has_config(SETTING_GRAPH_GRID_VISIBILITY):
		%GridVisibility.button_pressed = mm_globals.get_config(SETTING_GRAPH_GRID_VISIBILITY)

	if mm_globals.has_config(SETTING_GRAPH_GRID_SIZE):
		%GridSize.set_value(mm_globals.get_config(SETTING_GRAPH_GRID_SIZE))

	if mm_globals.has_config(SETTING_GRAPH_GRID_SNAPPING):
		%GridSnapping.button_pressed = mm_globals.get_config(SETTING_GRAPH_GRID_SNAPPING)
	
	if mm_globals.has_config(SETTING_GRAPH_LINE_CURVATURE):
		%LineCurvature.value = mm_globals.get_config(SETTING_GRAPH_LINE_CURVATURE)
	
	if mm_globals.has_config(SETTING_GRAPH_LINE_THICKNESS):
		%LineThickness.value = mm_globals.get_config(SETTING_GRAPH_LINE_THICKNESS)


	%Projects.tab_changed.connect(update_view_settings)

	await get_tree().process_frame
	update_view_settings()


func _on_grid_visibility_toggled(toggled_on: bool) -> void:
	mm_globals.set_config(SETTING_GRAPH_GRID_VISIBILITY, toggled_on)
	update_view_settings()


func _on_grid_snapping_toggled(toggled_on: bool) -> void:
	mm_globals.set_config(SETTING_GRAPH_GRID_SNAPPING, toggled_on)
	update_view_settings()


func _on_minimap_toggled(toggled_on: bool) -> void:
	mm_globals.set_config(SETTING_GRAPH_MINIMAP, toggled_on)
	update_view_settings()


func _on_grid_size_value_changed(value: Variant) -> void:
	mm_globals.set_config(SETTING_GRAPH_GRID_SIZE, value)
	update_view_settings()


func _on_line_curvature_value_changed(value: Variant) -> void:
	mm_globals.set_config(SETTING_GRAPH_LINE_CURVATURE, value)
	update_view_settings()


func _on_line_thickness_value_changed(value: Variant) -> void:
	mm_globals.set_config(SETTING_GRAPH_LINE_THICKNESS, value)
	update_view_settings()


func update_view_settings(_arg_ignore:Variant = null) -> void:
	for n in %Projects.get_children():
		var graph: GraphEdit = null
		if n is GraphEdit:
			graph = n
		elif n.has_method("get_graph_edit"):
			graph = n.get_graph_edit()
		else:
			continue
		graph.minimap_enabled = %Minimap.button_pressed
		graph.show_grid = %GridVisibility.button_pressed
		graph.snapping_distance = %GridSize.get_value()
		graph.snapping_enabled = %GridSnapping.button_pressed
		graph.connection_lines_curvature = %LineCurvature.value
		graph.connection_lines_thickness = %LineThickness.value
