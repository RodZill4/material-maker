extends ColorRect

var gradient = MMGradient.new()

signal clicked


func _ready() -> void:
	pass  # Replace with function body.


func set_gradient(g) -> void:
	gradient = g
	var shadertext = "shader_type canvas_item;\n"
	var params = gradient.get_shader_params("my")
	for v in params.keys():
		shadertext += "const float %s = %.09f;\n" % [v, params[v]]
	shadertext += gradient.get_shader("my")
	shadertext += "void fragment() {\nCOLOR = my_gradient_fct(UV.x);\n}\n"
	$ColorRect.material.shader.code = shadertext


func select(b: bool) -> void:
	color = Color(1.0, 1.0, 1.0, 1.0) if b else Color(1.0, 1.0, 1.0, 0.0)


func _on_ColorSlot_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("clicked", self)


func get_drag_data(_position):
	var preview = ColorRect.new()
	preview.material = $ColorRect.material
	preview.rect_min_size = Vector2(64, 16)
	set_drag_preview(preview)
	return gradient.serialize()
