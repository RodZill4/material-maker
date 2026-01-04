extends HBoxContainer

func _ready() -> void:
	$Type.clear()
	for tn in mm_io_types.type_names:
		var t = mm_io_types.types[tn]
		$Type.add_item(t.label)
	$Drag.icon = get_theme_icon("arrow_updown", "MM_Icons")
	$Drag.set_drag_forwarding(_row_drag_data, _row_can_drop_data, _row_drop_data)

func set_model_data(data, remaining_group_size = 0) -> int:
	$Name.set_text(data.name if data.has("name") else "")
	$Type.select(mm_io_types.type_names.find(data.type))
	if data.has("shortdesc"):
		$Description.short_description = data.shortdesc
	if data.has("longdesc"):
		$Description.long_description = data.longdesc
	$Description.update_tooltip()
	if data.has("group_size") and data.group_size > 1:
		$PortGroupButton.set_state(1)
		return data.group_size-1
	elif remaining_group_size == 1:
		$PortGroupButton.set_state(1)
	return int(max(remaining_group_size-1, 0))

func _on_Name_label_changed(new_label) -> void:
	get_parent().command("set_port_name", [get_index(), new_label])

func _on_Type_item_selected(ID) -> void:
	get_parent().command("set_port_type", [get_index(), mm_io_types.type_names[ID]])

func _on_PortGroupButton_groups_updated(g):
	get_parent().command("set_port_groups_sizes", [g], true)

func _on_Description_descriptions_changed(short_description, long_description):
	get_parent().command("set_port_descriptions", [get_index(), short_description, long_description])

func _on_Delete_pressed() -> void:
	get_parent().command("delete_port", [get_index()])

func _row_drag_data(_at_position: Vector2) -> Variant:
	var bg_panel := PanelContainer.new()
	bg_panel.theme_type_variation = "MM_PanelBackground"

	var panel_stylebox := get_theme_stylebox("panel", "GraphNode").duplicate()
	panel_stylebox.set_corner_radius_all(5)
	panel_stylebox.set_border_width_all(0)
	panel_stylebox.set_expand_margin_all(0)
	panel_stylebox.set_content_margin_all(4.0)
	panel_stylebox.bg_color.a = 0.8
	bg_panel.add_theme_stylebox_override("panel", panel_stylebox)

	var row : HBoxContainer = HBoxContainer.new()
	for control in get_children():
		var dupe := control.duplicate()
		dupe.custom_minimum_size.x = control.size.x
		if dupe.name == "Drag":
			dupe.toggle_mode = true
			dupe.button_pressed = true
		row.add_child(dupe)
	self.modulate = Color.TRANSPARENT

	bg_panel.add_child(row)
	bg_panel.position -= Vector2(16, 16)

	var preview_root := Control.new()
	preview_root.add_child(bg_panel)

	# match control scale to graph edit zoom
	preview_root.scale = Vector2.ONE * get_parent().get_parent().zoom
	set_drag_preview(preview_root)

	return { "index": get_index(), "parent_node": get_parent().name }


func _row_can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data.index != get_index() and data.parent_node == get_parent().name


func _row_drop_data(_at_position: Vector2, data: Variant) -> void:
	get_parent().command("swap_ports", [get_index(), data.index])
	get_parent().get_child(data.index).modulate = Color.WHITE


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_END:
			for c in get_parent().get_children():
				c.modulate = Color.WHITE
