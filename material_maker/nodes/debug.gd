extends MMGraphNodeBase

static func generate_debug_shader(src_code) -> String:
	var code
	code = ""
	var file = File.new()
	file.open("res://addons/material_maker/common.shader", File.READ)
	code += file.get_as_text()
	code += "\n"
	if src_code.has("textures"):
		for t in src_code.textures.keys():
			code += "uniform sampler2D "+t+";\n"
	if src_code.has("globals"):
		for g in src_code.globals:
			code += g
	var shader_code = src_code.defs
	shader_code += "\nvoid mainImage(out vec4 fragColor, in vec2 fragCoord) {\nvec2 UV = fragCoord/iResolution.xy;\n"
	shader_code += src_code.code
	if src_code.has("rgba"):
		shader_code += "fragColor = "+src_code.rgba+";\n"
	else:
		shader_code += "fragColor = vec4(1.0, 0.0, 0.0, 1.0);\n"
	shader_code += "}\n"
	#print("GENERATED SHADER:\n"+shader_code)
	code += shader_code
	return code

func _on_Button_pressed() -> void:
	var src = generator.get_source(0)
	if src != null:
		var context : MMGenContext = MMGenContext.new()
		var source = src.generator.get_shader_code("UV", src.output_index, context)
		var popup = preload("res://material_maker/nodes/debug/debug_popup.tscn").instance()
		get_parent().add_child(popup)
		popup.show_code(generate_debug_shader(source))
