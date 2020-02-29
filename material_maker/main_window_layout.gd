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


func _on_Left_dragged(offset : int) -> void:
	print(offset)

func _on_Right_dragged(offset : int) -> void:
	print(offset)
