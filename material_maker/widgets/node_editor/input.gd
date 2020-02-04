extends HBoxContainer

func update_up_down_button() -> void:
	var parent = get_parent()
	if parent == null:
		return
	$Up.disabled = (get_index() == 0)
	$Down.disabled = (get_index() == get_parent().get_child_count()-2)

func set_model_data(data) -> void:
	$Name.text = data.name
	$Label.text = data.label
	if data.type == "rgb":
		$Type.selected = 1
	elif data.type == "rgba":
		$Type.selected = 2
	elif data.type == "sdf2d":
		$Type.selected = 3
	elif data.type == "sdf3d":
		$Type.selected = 4
	else:
		$Type.selected = 0
	$Default.text = data.default
	$Function.pressed = data.has("function") and data.function

func get_model_data() -> Dictionary:
	var data = { name=$Name.text, label=$Label.text, default=$Default.text }
	if $Type.selected == 1:
		data.type = "rgb"
	elif $Type.selected == 2:
		data.type = "rgba"
	elif $Type.selected == 3:
		data.type = "sdf2d"
	elif $Type.selected == 4:
		data.type = "sdf3d"
	else:
		data.type = "f"
	if $Function.pressed:
		data.function = true
	return data

func _on_Delete_pressed() -> void:
	var p = get_parent()
	p.remove_child(self)
	p.update_up_down_buttons()
	queue_free()

func _on_Up_pressed() -> void:
	get_parent().move_child(self, get_index() - 1)
	get_parent().update_up_down_buttons()

func _on_Down_pressed() -> void:
	get_parent().move_child(self, get_index() + 1)
	get_parent().update_up_down_buttons()
