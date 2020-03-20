extends ColorRect

export(String, MULTILINE) var shader : String = ""

var generator : MMGenBase = null

func set_generator(g : MMGenBase, output : int = 0) -> void:
	var source = { defs="", code="", textures={}, type="f", f="1.0" }
	if is_instance_valid(g):
		generator = g
		var param_defs : Array = generator.get_parameter_defs()
		for c in get_children():
			c.setup_control(generator, param_defs)
		var gen_output_defs = generator.get_output_defs()
		if ! gen_output_defs.empty():
			var context : MMGenContext = MMGenContext.new()
			source = generator.get_shader_code("uv", output, context)
			while source is GDScriptFunctionState:
				source = yield(source, "completed")
			if source.empty():
				source = { defs="", code="", textures={}, type="f", f="1.0" }
	else:
		g = null
		for c in get_children():
			c.setup_control(generator, [])
	material.shader.code = MMGenBase.generate_preview_shader(source, source.type, shader)
	if source.has("textures"):
		for k in source.textures.keys():
			material.set_shader_param(k, source.textures[k])

func on_float_parameter_changed(n : String, v : float) -> void:
	for p in VisualServer.shader_get_param_list(material.shader.get_rid()):
		if p.name == n:
			material.set_shader_param(n, v)
			return

func on_resized() -> void:
	material.set_shader_param("size", rect_size)
	set_generator(generator)

func value_to_pos(value : Vector2) -> Vector2:
	return rect_size*0.5+value*min(rect_size.x, rect_size.y)/1.2

func value_to_offset(value : Vector2) -> Vector2:
	return value*min(rect_size.x, rect_size.y)/1.2

func pos_to_value(pos : Vector2) -> Vector2:
	return (pos - rect_size*0.5)*1.2/min(rect_size.x, rect_size.y)
