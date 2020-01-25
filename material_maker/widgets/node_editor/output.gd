tool
extends HBoxContainer

func update_up_down_button() -> void:
	var parent = get_parent()
	if parent == null:
		return
	$Up.disabled = (get_index() == 0)
	$Down.disabled = (get_index() == get_parent().get_child_count()-2)

func set_model_data(data) -> void:
	if data.has("rgb"):
		$Type.selected = 1
		$Value.text = data.rgb
	elif data.has("rgba"):
		$Type.selected = 2
		$Value.text = data.rgba
	elif data.has("sdf2d"):
		$Type.selected = 3
		$Value.text = data.sdf2d
	elif data.has("sdf3d"):
		$Type.selected = 4
		$Value.text = data.sdf3d
	elif data.has("f"):
		$Type.selected = 0
		$Value.text = data.f

func get_model_data() -> Dictionary:
	if $Type.selected == 1:
		return { rgb=$Value.text }
	elif $Type.selected == 2:
		return { rgba=$Value.text }
	elif $Type.selected == 3:
		return { sdf2d=$Value.text }
	elif $Type.selected == 4:
		return { sdf3d=$Value.text }
	else:
		return { f=$Value.text }

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
