extends HBoxContainer

func _ready() -> void:
	$Type.clear()
	for tn in mm_io_types.type_names:
		var t = mm_io_types.types[tn]
		$Type.add_item(t.label)

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

func update_up_down_button() -> void:
	var parent = get_parent()
	if parent == null:
		return
	$Up.disabled = (get_index() == 0)
	$Down.disabled = (get_index() == get_parent().get_child_count()-2)

func _on_Name_label_changed(new_label) -> void:
	get_parent().command("set_port_name", [get_index(), new_label])

func _on_Type_item_selected(ID) -> void:
	get_parent().command("set_port_type", [get_index(), mm_io_types.type_names[ID]])

func _on_PortGroupButton_group_size_changed(s):
	get_parent().command("set_port_group_size", [get_index(), s])

func _on_Description_descriptions_changed(short_description, long_description):
	get_parent().command("set_port_descriptions", [get_index(), short_description, long_description])

func _on_Delete_pressed() -> void:
	get_parent().command("delete_port", [get_index()])

func _on_Up_pressed() -> void:
	get_parent().command("swap_ports", [get_index(), get_index()-1])

func _on_Down_pressed() -> void:
	get_parent().command("swap_ports", [get_index(), get_index()+1])
