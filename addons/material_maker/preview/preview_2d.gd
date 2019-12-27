tool
extends ColorRect

var generator = null

func set_preview_texture(tex: Texture) -> void:
	material.set_shader_param("tex", tex)

func on_resized() -> void:
	material.set_shader_param("size", rect_size)
	setup_controls(generator)

func setup_controls(g : MMGenBase) -> void:
	if is_instance_valid(g):
		generator = g
		var param_defs : Array = generator.get_parameter_defs()
		for c in get_children():
			c.setup_control(generator, param_defs)
	else:
		g = null
		for c in get_children():
			c.setup_control(generator, [])

func value_to_pos(value : Vector2) -> Vector2:
	return rect_size*0.5+(value-Vector2(0.5, 0.5))*min(rect_size.x, rect_size.y)/1.2

func value_to_offset(value : Vector2) -> Vector2:
	return value*min(rect_size.x, rect_size.y)/1.2

func pos_to_value(pos : Vector2) -> Vector2:
	return (pos - rect_size*0.5)*1.2/min(rect_size.x, rect_size.y)+Vector2(0.5, 0.5)
