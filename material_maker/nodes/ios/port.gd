extends HBoxContainer

func _ready() -> void:
	$Type.clear()
	for tn in mm_io_types.type_names:
		var t = mm_io_types.types[tn]
		$Type.add_item(t.label)

func set_label(l : String) -> void:
	$Name.set_text(l)

func set_type(t : String) -> void:
	$Type.select(mm_io_types.type_names.find(t))

func update_up_down_button() -> void:
	var parent = get_parent()
	if parent == null:
		return
	$Up.disabled = (get_index() == 0)
	$Down.disabled = (get_index() == get_parent().get_child_count()-2)

func _on_Name_label_changed(new_label) -> void:
	get_parent().generator.set_port_name(get_index(), new_label)

func _on_Type_item_selected(ID) -> void:
	get_parent().generator.set_port_type(get_index(), mm_io_types.type_names[ID])

func _on_Delete_pressed() -> void:
	get_parent().generator.delete_port(get_index())

func _on_Up_pressed() -> void:
	get_parent().generator.swap_ports(get_index(), get_index()-1)

func _on_Down_pressed() -> void:
	get_parent().generator.swap_ports(get_index(), get_index()+1)
