extends PopupPanel

var mesh : MeshInstance3D

func configure_mesh(m : MeshInstance3D) -> void:
	mesh = m
	$VBoxContainer/UVScale/X.value = mesh.uv_scale.x
	$VBoxContainer/UVScale/Y.value = mesh.uv_scale.y
	if mesh.can_tesselate:
		$VBoxContainer/Tesselated.button_pressed = mesh.tesselated
	else:
		$VBoxContainer/Tesselated.disabled = true
	popup(Rect2(get_mouse_position(), $VBoxContainer.get_minimum_size()))

func _on_MeshConfiguration_popup_hide():
	queue_free()

func _on_UV_value_changed(_value):
	mesh.uv_scale = Vector2($VBoxContainer/UVScale/X.value, $VBoxContainer/UVScale/Y.value)

func _on_Tesselated_toggled(button_pressed):
	mesh.tesselated = button_pressed
