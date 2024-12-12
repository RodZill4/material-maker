extends ColorRect

var gradient = MMGradient.new()

signal clicked


func set_gradient(g) -> void:
	gradient = g
	var shader_code : String = ""
	shader_code = "shader_type canvas_item;\n"
	shader_code += gradient.get_shader_params("")
	shader_code += gradient.get_shader("")
	shader_code += "void fragment() { COLOR = _gradient_fct(UV.x); }"
	var shader : Shader = Shader.new()
	shader.code = shader_code
	$ColorRect.material.shader = shader
	update_shader_parameters()


func select(b : bool) -> void:
	color = Color(1.0, 1.0, 1.0, 1.0) if b else Color(1.0, 1.0, 1.0, 0.0)


func _on_ColorSlot_gui_input(event : InputEvent):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("clicked", self)


func _get_drag_data(_position):
	var preview = ColorRect.new()
	preview.material = $ColorRect.material
	preview.custom_minimum_size = Vector2(64, 16)
	set_drag_preview(preview)
	return gradient.serialize()


func update_shader_parameters() -> void:
	var parameter_values : Dictionary = gradient.get_parameter_values("")
	for n in parameter_values.keys():
		$ColorRect.material.set_shader_parameter(n, parameter_values[n])
