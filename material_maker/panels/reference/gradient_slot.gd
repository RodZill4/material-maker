extends Button

var gradient = MMGradient.new()


func _ready() -> void:
	button_group.pressed.connect(func(_x): $ColorRect/Icon.queue_redraw())
	toggled.connect(func(_x): $ColorRect/Icon.queue_redraw())


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


func _on_icon_draw() -> void:
	if button_pressed:
		var picker_icon := get_theme_icon("color_picker", "MM_Icons")
		printt(get_rect().size, picker_icon.get_size())
		$ColorRect/Icon.draw_texture(picker_icon, ($ColorRect/Icon.get_rect().size-picker_icon.get_size())/2.0)
