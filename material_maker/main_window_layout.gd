extends HSplitContainer

const PANE_POSITIONS = {
	TopLeft="Left/Top",
	BottomLeft="Left/Bottom",
	TopRight="SplitRight/Right/Top",
	BottomRight="SplitRight/Right/Bottom"
}
const PANES = [
	{ name="Library", scene=preload("res://material_maker/library.tscn"), position="TopLeft" },
	{ name="Preview2D", scene=preload("res://material_maker/preview/preview_2d_panel.tscn"), position="BottomLeft" },
	{ name="Preview3D", scene=preload("res://material_maker/preview/preview_3d_panel.tscn"), position="BottomLeft" },
	{ name="Histogram", scene=preload("res://material_maker/widgets/histogram/histogram.tscn"), position="BottomLeft" },
	{ name="Hierarchy", scene=preload("res://material_maker/widgets/graph_tree/hierarchy_pane.tscn"), position="TopRight" }
]

var panes = {}

func load_panes(config_cache) -> void:
	# Create panels
	for pane_pos in PANE_POSITIONS.keys():
		get_node(PANE_POSITIONS[pane_pos]).set_tabs_rearrange_group(1)
	for pane in PANES:
		var node = pane.scene.instance()
		node.name = pane.name
		if "config_cache" in node:
			node.config_cache = config_cache
		panes[pane.name] = node
		var tab = get_node(PANE_POSITIONS[pane.position])
		if config_cache.has_section_key("layout", pane.name+"_location"):
			tab = get_node(PANE_POSITIONS[config_cache.get_value("layout", pane.name+"_location")])
		if config_cache.has_section_key("layout", pane.name+"_hidden") && config_cache.get_value("layout", pane.name+"_hidden"):
			node.set_meta("parent_tab_container", tab)
		else:
			tab.add_child(node)
	# Split positions
	if config_cache.has_section_key("layout", "LeftVSplitOffset"):
		split_offset = config_cache.get_value("layout", "LeftVSplitOffset")
	if config_cache.has_section_key("layout", "LeftHSplitOffset"):
		$Left.split_offset = config_cache.get_value("layout", "LeftHSplitOffset")
	if config_cache.has_section_key("layout", "RightVSplitOffset"):
		$SplitRight.split_offset = config_cache.get_value("layout", "RightVSplitOffset")
	if config_cache.has_section_key("layout", "RightHSplitOffset"):
		$SplitRight/Right.split_offset = config_cache.get_value("layout", "RightHSplitOffset")
	update_panes()

func save_config(config_cache) -> void:
	for p in panes:
		var location = panes[p].get_parent()
		var hidden = false
		if not location:
			hidden = true
			location = panes[p].get_meta("parent_tab_container")
		config_cache.set_value("layout", p+"_hidden", hidden)
		for l in PANE_POSITIONS.keys():
			if location == get_node(PANE_POSITIONS[l]):
				config_cache.set_value("layout", p+"_location", l)
	config_cache.set_value("layout", "LeftVSplitOffset", split_offset)
	config_cache.set_value("layout", "LeftHSplitOffset", $Left.split_offset)
	config_cache.set_value("layout", "RightVSplitOffset", $SplitRight.split_offset)
	config_cache.set_value("layout", "RightHSplitOffset", $SplitRight/Right.split_offset)

func get_pane(n) -> Control:
	return panes[n]

func get_pane_list() -> Array:
	var panes_list = panes.keys()
	panes_list.sort()
	return panes_list

func is_pane_visible(pane_name : String) -> bool:
	return panes[pane_name].get_parent() != null

func set_pane_visible(pane_name : String, v : bool) -> void:
	var pane = panes[pane_name]
	if v:
		pane.get_meta("parent_tab_container").add_child(pane)
	else:
		pane.set_meta("parent_tab_container", pane.get_parent())
		pane.get_parent().remove_child(pane)
	update_panes()

func update_panes() -> void:
	var left_width = $Left.rect_size.x
	var left_requested = left_width
	var right_width = $SplitRight/Right.rect_size.x
	var right_requested = right_width
	if $Left/Top.get_tab_count() == 0:
		if $Left/Bottom.get_tab_count() == 0:
			left_requested = 10
			$Left.split_offset -= ($Left/Top.rect_size.y-$Left/Bottom.rect_size.y)/2
			$Left.clamp_split_offset()
		else:
			$Left.split_offset -= $Left/Top.rect_size.y-10
			$Left.clamp_split_offset()
	elif $Left/Bottom.get_tab_count() == 0:
		$Left.split_offset += $Left/Bottom.rect_size.y-10
		$Left.clamp_split_offset()
	if $SplitRight/Right/Top.get_tab_count() == 0:
		if $SplitRight/Right/Bottom.get_tab_count() == 0:
			right_requested = 10
			$SplitRight/Right.split_offset -= ($SplitRight/Right/Top.rect_size.y-$SplitRight/Right/Bottom.rect_size.y)/2
			$SplitRight/Right.clamp_split_offset()
		else:
			$SplitRight/Right.split_offset -= $SplitRight/Right/Top.rect_size.y-10
			$SplitRight/Right.clamp_split_offset()
	elif $SplitRight/Right/Bottom.get_tab_count() == 0:
		$SplitRight/Right.split_offset += $SplitRight/Right/Bottom.rect_size.y-10
		$SplitRight/Right.clamp_split_offset()
	split_offset += left_requested - left_width + right_requested - right_width
	clamp_split_offset()
	$SplitRight.split_offset += right_width - right_requested

func _on_Left_dragged(_offset : int) -> void:
	$Left.clamp_split_offset()

func _on_Right_dragged(_offset : int) -> void:
	$SplitRight/Right.clamp_split_offset()

func _on_tab_changed(_tab):
	update_panes()
