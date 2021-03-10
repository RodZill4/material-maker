extends WindowDialog

var src_code

const GENFUNCTIONS : Array = [ "generate_shadertoy", "generate_godot_canvasitem", "generate_godot_spatial" ]

func show_code(s) -> void:
	src_code = s
	_on_ShaderType_item_selected(0)
	connect("popup_hide", self, "queue_free")
	popup_centered()

func _on_ShaderType_item_selected(index):
	if index < 3:
		$VBoxContainer/TextEdit.visible = true
		$VBoxContainer/TextEdit.text = call(GENFUNCTIONS[index])
		$VBoxContainer/ColorRect.visible = false
	else:
		$VBoxContainer/TextEdit.visible = false
		$VBoxContainer/ColorRect.visible = true
		$VBoxContainer/ColorRect.material.shader.code = generate_godot_canvasitem()

func _on_CopyToClipboard_pressed():
	OS.set_clipboard($VBoxContainer/TextEdit.text)

func generate_shadertoy() -> String:
	var code = ""
	code += mm_renderer.common_shader.right(mm_renderer.common_shader.find("//---"))
	code += "\n"
	if src_code.has("textures"):
		for t in src_code.textures.keys():
			code += "uniform sampler2D "+t+";\n"
	if src_code.has("globals"):
		for g in src_code.globals:
			code += g
	code += src_code.defs
	code += "\n"
	code += "void mainImage(out vec4 fragColor, in vec2 fragCoord) {\n"
	code += "float minSize = min(iResolution.x, iResolution.y);\n"
	code += "vec2 UV = vec2(0.0, 1.0) + vec2(1.0, -1.0) * (fragCoord-0.5*(iResolution.xy-vec2(minSize)))/minSize;\n"
	code += src_code.code
	if src_code.has("rgba"):
		code += "fragColor = "+src_code.rgba+";\n"
	else:
		code += "fragColor = vec4(1.0, 0.0, 0.0, 1.0);\n"
	code += "}\n"
	#print("GENERATED SHADER:\n"+shader_code)
	code = code.replace("uniform", "const")
	code = code.replace("elapsed_time", "iTime")
	return code

func generate_godot_canvasitem() -> String:
	var code = "shader_type canvas_item;\n"
	code += mm_renderer.common_shader
	code += "\n"
	if src_code.has("textures"):
		for t in src_code.textures.keys():
			code += "uniform sampler2D "+t+";\n"
	if src_code.has("globals"):
		for g in src_code.globals:
			code += g
	code += src_code.defs
	code += "\n"
	code += "void fragment() {\n"
	code += src_code.code
	if src_code.has("rgba"):
		code += "COLOR = "+src_code.rgba+";\n"
	else:
		code += "COLOR = vec4(1.0, 0.0, 0.0, 1.0);\n"
	code += "}\n"
	#print("GENERATED SHADER:\n"+shader_code)
	code = code.replace("uniform", "const")
	return code

func generate_godot_spatial() -> String:
	var code = "shader_type spatial;\n"
	code += mm_renderer.common_shader
	code += "\n"
	if src_code.has("textures"):
		for t in src_code.textures.keys():
			code += "uniform sampler2D "+t+";\n"
	if src_code.has("globals"):
		for g in src_code.globals:
			code += g
	code += src_code.defs
	code += "\n"
	code += "void fragment() {\n"
	code += src_code.code
	if src_code.has("rgb"):
		code += "ALBEDO = "+src_code.rgb+";\n"
	else:
		code += "ALBEDO = vec3(1.0, 0.0, 0.0);\n"
	code += "}\n"
	#print("GENERATED SHADER:\n"+shader_code)
	code = code.replace("uniform", "const")
	return code

