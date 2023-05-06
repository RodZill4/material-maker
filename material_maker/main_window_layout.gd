extends HSplitContainer

const PANEL_POSITIONS = {
	TopLeft="Left/Top",
	BottomLeft="Left/Bottom",
	TopRight="SplitRight/Right/Top",
	BottomRight="SplitRight/Right/Bottom"
}
const PANELS = [
	{ name="Library", scene=preload("res://material_maker/panels/library/library.tscn"), position="TopLeft" },
	{ name="Preview2D", scene=preload("res://material_maker/panels/preview_2d/preview_2d_panel.tscn"), position="BottomLeft" },
	{ name="Preview3D", scene=preload("res://material_maker/panels/preview_3d/preview_3d_panel.tscn"), position="BottomLeft" },
	{ name="Preview2D (2)", scene=preload("res://material_maker/panels/preview_2d/preview_2d_panel.tscn"), position="BottomLeft", parameters={ config_var_suffix="_2" } },
	{ name="Histogram", scene=preload("res://material_maker/widgets/histogram/histogram.tscn"), position="BottomLeft" },
	{ name="Hierarchy", scene=preload("res://material_maker/panels/hierarchy/hierarchy_panel.tscn"), position="TopRight" },
	{ name="Reference", scene=preload("res://material_maker/panels/reference/reference_panel.tscn"), position="BottomLeft" },
	#{ name="Brushes", scene=preload("res://material_maker/panels/brushes/brushes.tscn"), position="TopLeft" },
	#{ name="Layers", scene=preload("res://material_maker/panels/layers/layers.tscn"), position="BottomRight" },
	#{ name="Parameters", scene=preload("res://material_maker/panels/parameters/parameters.tscn"), position="TopRight" },
]
const HIDE_PANELS = {
	material=[ "Brushes", "Layers", "Parameters" ],
	paint=[ "Preview3D", "Histogram", "Hierarchy" ]
}

var panels = {}
var previous_width : float
var current_mode : String = "material"

func _ready() -> void:
	previous_width = size.x

func toggle_side_panels() -> void:
	# Toggle side docks' visibility to maximize the space available
	# for the graph panel. This is useful on smaller displays.
	$Left.visible = not $Left.visible
	$SplitRight/Right.visible = not $SplitRight/Right.visible

func load_panels() -> void:
	# Create panels
	for panel_pos in PANEL_POSITIONS.keys():
		get_node(PANEL_POSITIONS[panel_pos]).set_tabs_rearrange_group(1)
	for panel in PANELS:
		var node : Node = panel.scene.instantiate()
		node.name = panel.name
		if panel.has("parameters"):
			for p in panel.parameters.keys():
				node.set(p, panel.parameters[p])
		panels[panel.name] = node
		var tab = get_node(PANEL_POSITIONS[panel.position])
		var config_panel_name = panel.name.replace(" ", "_").replace("(", "_").replace(")", "_")
		if mm_globals.config.has_section_key("layout", config_panel_name+"_location"):
			tab = get_node(PANEL_POSITIONS[mm_globals.config.get_value("layout", config_panel_name+"_location")])
		if mm_globals.config.has_section_key("layout", config_panel_name+"_hidden") && mm_globals.config.get_value("layout", config_panel_name+"_hidden"):
			node.set_meta("parent_tab_container", tab)
			node.set_meta("hidden", true)
		else:
			tab.add_child(node)
			node.set_meta("hidden", false)
	# Split positions
	await get_tree().process_frame
	if mm_globals.config.has_section_key("layout", "LeftVSplitOffset"):
		split_offset = mm_globals.config.get_value("layout", "LeftVSplitOffset")
	if mm_globals.config.has_section_key("layout", "LeftHSplitOffset"):
		$Left.split_offset = mm_globals.config.get_value("layout", "LeftHSplitOffset")
	if mm_globals.config.has_section_key("layout", "RightVSplitOffset"):
		$SplitRight.split_offset = mm_globals.config.get_value("layout", "RightVSplitOffset")
	if mm_globals.config.has_section_key("layout", "RightHSplitOffset"):
		$SplitRight/Right.split_offset = mm_globals.config.get_value("layout", "RightHSplitOffset")

func save_config() -> void:
	for p in panels:
		var config_panel_name = p.replace(" ", "_").replace("(", "_").replace(")", "_")
		var location = panels[p].get_parent()
		var panel_hidden = false
		if location == null:
			panel_hidden = panels[p].get_meta("hidden")
			location = panels[p].get_meta("parent_tab_container")
		mm_globals.config.set_value("layout", config_panel_name+"_hidden", panel_hidden)
		for l in PANEL_POSITIONS.keys():
			if location == get_node(PANEL_POSITIONS[l]):
				mm_globals.config.set_value("layout", config_panel_name+"_location", l)
	mm_globals.config.set_value("layout", "LeftVSplitOffset", split_offset)
	mm_globals.config.set_value("layout", "LeftHSplitOffset", $Left.split_offset)
	mm_globals.config.set_value("layout", "RightVSplitOffset", $SplitRight.split_offset)
	mm_globals.config.set_value("layout", "RightHSplitOffset", $SplitRight/Right.split_offset)

func get_panel(n) -> Control:
	if panels.has(n):
		return panels[n]
	return Control.new()

func get_panel_list() -> Array:
	var panels_list = panels.keys()
	panels_list.sort()
	return panels_list

func is_panel_visible(panel_name : String) -> bool:
	return panels[panel_name].get_parent() != null

func set_panel_visible(panel_name : String, v : bool) -> void:
	var panel = panels[panel_name]
	panel.set_meta("hidden", !v)
	if panel.is_inside_tree():
		panel.set_meta("parent_tab_container", panel.get_parent())
	if v and HIDE_PANELS[current_mode].find(panel_name) == -1:
		if ! panel.is_inside_tree():
			panel.get_meta("parent_tab_container").add_child(panel)
	elif panel.is_inside_tree():
		panel.get_parent().remove_child(panel)
	update_panels()

func change_mode(m : String) -> void:
	current_mode = m
	for p in panels:
		set_panel_visible(p, !panels[p].get_meta("hidden"))
	update_panels()

func update_panels() -> void:
	var left_width = $Left.size.x
	var left_requested = left_width
	var right_width = $SplitRight/Right.size.x
	var right_requested = right_width
	if $Left/Top.get_tab_count() == 0:
		if $Left/Bottom.get_tab_count() == 0:
			left_requested = 10
			$Left.split_offset -= ($Left/Top.size.y-$Left/Bottom.size.y)/2
			$Left.clamp_split_offset()
		else:
			$Left.split_offset -= $Left/Top.size.y-10
			$Left.clamp_split_offset()
	elif $Left/Bottom.get_tab_count() == 0:
		$Left.split_offset += $Left/Bottom.size.y-10
		$Left.clamp_split_offset()
	if $SplitRight/Right/Top.get_tab_count() == 0:
		if $SplitRight/Right/Bottom.get_tab_count() == 0:
			right_requested = 10
			$SplitRight/Right.split_offset -= ($SplitRight/Right/Top.size.y-$SplitRight/Right/Bottom.size.y)/2
			$SplitRight/Right.clamp_split_offset()
		else:
			$SplitRight/Right.split_offset -= $SplitRight/Right/Top.size.y-10
			$SplitRight/Right.clamp_split_offset()
	elif $SplitRight/Right/Bottom.get_tab_count() == 0:
		$SplitRight/Right.split_offset += $SplitRight/Right/Bottom.size.y-10
		$SplitRight/Right.clamp_split_offset()
	split_offset += left_requested - left_width + right_requested - right_width
	clamp_split_offset()
	$SplitRight.split_offset += right_width - right_requested

func _on_Left_dragged(_offset : int) -> void:
	$Left.clamp_split_offset()

func _on_Right_dragged(_offset : int) -> void:
	$SplitRight/Right.clamp_split_offset()

func _on_tab_changed(_tab):
	update_panels()

func _on_Layout_resized():
	# warning-ignore:narrowing_conversion
	split_offset -= size.x - previous_width
	previous_width = size.x
