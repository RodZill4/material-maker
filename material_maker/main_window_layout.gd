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
	{ name="Preview3D", scene=preload("res://material_maker/preview/preview_3d_panel.tscn"), position="BottomLeft" }
]

var panes = {}

func load_panes() -> void:
	# Create panels
	for pane_pos in PANE_POSITIONS.keys():
		get_node(PANE_POSITIONS[pane_pos]).set_tabs_rearrange_group(1)
	for pane in PANES:
		var node = pane.scene.instance()
		node.name = pane.name
		var tab = get_node(PANE_POSITIONS[pane.position])
		tab.add_child(node)
		panes[pane.name] = node
	update_panes()

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

func _on_Left_dragged(offset : int) -> void:
	$Left.clamp_split_offset()

func _on_Right_dragged(offset : int) -> void:
	$SplitRight/Right.clamp_split_offset()

func _on_tab_changed(_tab):
	update_panes()
