extends PopupPanel

var mesh : MeshInstance3D

func configure_mesh(m : MeshInstance3D) -> void:
	mesh = m
	$VBoxContainer/UVScale/X.value = mesh.uv_scale.x
	$VBoxContainer/UVScale/Y.value = mesh.uv_scale.y
	if mesh.can_tesselate:
		$VBoxContainer/Tesselated.button_pressed = mesh.tesselated
	else:
		$VBoxContainer/Tesselated.visible = false
	for p in mesh.parameters:
		var label : Label = Label.new()
		label.text = (p.label if p.has("label") else p.name)+":"
		%Parameters.add_child(label)
		var float_edit = preload("res://material_maker/widgets/float_edit/float_edit.tscn").instantiate()
		float_edit.float_only = true
		float_edit.min_value = p.min_value
		float_edit.max_value = p.max_value
		float_edit.value = mesh.parameter_values[p.name]
		%Parameters.add_child(float_edit)
		float_edit.value_changed.connect(mesh.set_parameter.bind(p.name))
	popup(Rect2(get_mouse_position(), $VBoxContainer.get_minimum_size()))

func _on_MeshConfiguration_popup_hide():
	queue_free()

func _on_UV_value_changed(_value):
	mesh.uv_scale = Vector2($VBoxContainer/UVScale/X.value, $VBoxContainer/UVScale/Y.value)

func _on_Tesselated_toggled(button_pressed):
	mesh.tesselated = button_pressed
