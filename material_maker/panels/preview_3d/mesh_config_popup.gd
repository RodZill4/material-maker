extends PopupPanel

var mesh : MeshInstance3D

func _ready() -> void:
	content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	min_size = get_contents_minimum_size() * content_scale_factor
	%ScaleLinked.icon = get_theme_icon("link", "MM_Icons")

func configure_mesh(m : MeshInstance3D) -> void:
	mesh = m
	%UV_Scale_X.value = mesh.uv_scale.x
	%UV_Scale_Y.value = mesh.uv_scale.y

	%ScaleLinked.button_pressed = %UV_Scale_X.value == %UV_Scale_Y.value

	if mesh.can_tesselate:
		%Tesselated.button_pressed = mesh.tesselated
	else:
		%Tesselated.hide()
		%Tesselated_Label.hide()

	for p in mesh.parameters:
		var label: Label = Label.new()
		label.text = (p.label if p.has("label") else p.name)+":"
		label.theme_type_variation = "MM_PanelMenuSubPanelLabel"
		%Parameters.add_child(label)
		var float_edit := preload("res://material_maker/widgets/float_edit/float_edit.tscn").instantiate()
		float_edit.float_only = true
		float_edit.step = 0.01
		float_edit.min_value = p.min_value
		float_edit.max_value = p.max_value
		float_edit.value = mesh.parameter_values[p.name]
		%Parameters.add_child(float_edit)
		float_edit.value_changed.connect(mesh.set_parameter.bind(p.name))

	popup(Rect2(get_mouse_position()*content_scale_factor, $VBoxContainer.get_minimum_size()*content_scale_factor))


func _on_scale_linked_toggled(toggled_on: bool) -> void:
	%UV_Scale_Y.visible = not toggled_on
	_on_UV_value_changed(%UV_Scale_X.value)
	size = $VBoxContainer.get_minimum_size() * content_scale_factor


func _on_MeshConfiguration_popup_hide():
	queue_free()


func _on_UV_value_changed(_value):
	if %ScaleLinked.button_pressed:
		%UV_Scale_X.value = _value
		%UV_Scale_Y.value = _value

	mesh.uv_scale = Vector2(%UV_Scale_X.value, %UV_Scale_Y.value)


func _on_Tesselated_toggled(button_pressed):
	mesh.tesselated = button_pressed
