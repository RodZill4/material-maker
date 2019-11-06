extends HBoxContainer

func set_label(l : String) -> void:
	$Name.set_text(l)

func update_up_down_button() -> void:
	var parent = get_parent()
	if parent == null:
		return
	$Up.disabled = (get_index() == 0)
	$Down.disabled = (get_index() == get_parent().get_child_count()-2)

func _on_Name_label_changed(new_label) -> void:
	get_parent().generator.set_port_name(get_index(), new_label)

func _on_Delete_pressed() -> void:
	get_parent().generator.delete_port(get_index())

func _on_Up_pressed() -> void:
	get_parent().generator.swap_ports(get_index(), get_index()-1)

func _on_Down_pressed() -> void:
	get_parent().generator.swap_ports(get_index(), get_index()+1)
