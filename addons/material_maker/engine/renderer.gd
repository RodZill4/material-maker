tool
extends Viewport
class_name MMGenRenderer

export(String) var debug_path = ""
var debug_file_index : int = 0

var rendering : bool = false
signal done

func _ready() -> void:
	$ColorRect.material = $ColorRect.material.duplicate(true)

static func generate_shader(src_code) -> String:
	var code
	code = "shader_type canvas_item;\n"
	code += "render_mode blend_disabled;\n"
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
	shader_code += "\nvoid fragment() {\n"
	shader_code += "vec2 uv = UV;\n"
	shader_code += src_code.code
	if src_code.has("rgba"):
		shader_code += "COLOR = "+src_code.rgba+";\n"
	else:
		shader_code += "COLOR = vec4(1.0, 0.0, 0.0, 1.0);\n"
	shader_code += "}\n"
	#print("GENERATED SHADER:\n"+shader_code)
	code += shader_code
	return code

static func generate_preview_shader(src_code) -> String:
	var code
	code = "shader_type canvas_item;\n"
	code += "render_mode blend_disabled;\n"
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
	if src_code.has("rgba"):
		shader_code += "\nvoid fragment() {\n"
		shader_code += "vec2 uv = UV;\n"
		shader_code += src_code.code
		shader_code += "COLOR = "+src_code.rgba+";\n"
		shader_code += "}\n"
	elif src_code.has("sdf2d"):
		shader_code += "\nvoid fragment() {\n"
		shader_code += "vec2 uv = UV;\n"
		shader_code += src_code.code
		shader_code += "float d = "+src_code.sdf2d+";\n"
		shader_code += "vec3 col = vec3(cos(d*62.8318530718*5.0));\n"
		shader_code += "col *= clamp(1.0-4.0*abs(d), 0.0, 1.0);\n"
		shader_code += "col *= vec3(1.0, vec2(step(-0.015, d)));\n"
		shader_code += "col *= vec3(vec2(step(d, 0.015)), 1.0);\n"
		shader_code += "COLOR = vec4(col, 1.0);\n"
		shader_code += "}\n"
	elif src_code.has("sdf3d"):
		shader_code += "\nfloat calcdist(vec3 uv) {\n"
		shader_code += src_code.code
		shader_code += "return min("+src_code.sdf3d+", uv.z);\n"
		shader_code += "}\n"
		shader_code += "float raymarch(vec3 ro, vec3 rd) {\n"
		shader_code += "float d=0.0;\n"
		shader_code += "for (int i = 0; i < 50; i++) {\n"
		shader_code += "vec3 p = ro + rd*d;\n"
		shader_code += "float dstep = calcdist(p);\n"
		shader_code += "d += dstep;\n"
		shader_code += "if (dstep < 0.0001) break;\n"
		shader_code += "}\n"
		shader_code += "return d;\n"
		shader_code += "}\n"
		shader_code += "vec3 normal(vec3 p) {\n"
		shader_code += "	float d = calcdist(p);\n"
		shader_code += "    float e = .0001;\n"
		shader_code += "    vec3 n = d - vec3(calcdist(p-vec3(e, 0.0, 0.0)), calcdist(p-vec3(0.0, e, 0.0)), calcdist(p-vec3(0.0, 0.0, e)));\n"
		shader_code += "    return normalize(n);\n"
		shader_code += "}\n"
		shader_code += "\nvoid fragment() {\n"
		shader_code += "vec2 uv = UV-vec2(0.5);\n"
		shader_code += "vec3 p = vec3(uv, 2.0-raymarch(vec3(uv, 2.0), vec3(0.0, 0.0, -1.0)));\n"
		shader_code += "vec3 n = normal(p);\n"
		shader_code += "vec3 l = vec3(5.0, 5.0, 10.0);\n"
		shader_code += "vec3 ld = normalize(l-p);\n"
		shader_code += "float o = step(p.z, 0.001);\n"
		shader_code += "float shadow = 1.0-0.75*step(raymarch(l, -ld), length(l-p)-0.01);\n"
		shader_code += "float light = 0.3+0.7*dot(n, ld)*shadow;\n"
		shader_code += "COLOR = vec4(vec3(0.8+0.2*o, 0.8+0.2*o, 1.0)*light, 1.0);\n"
		shader_code += "}\n"
	#print("GENERATED SHADER:\n"+shader_code)
	code += shader_code
	return code

static func generate_combined_shader(red_code, green_code, blue_code) -> String:
	var code
	code = "shader_type canvas_item;\n"
	code += "render_mode blend_disabled;\n"
	var file = File.new()
	file.open("res://addons/material_maker/common.shader", File.READ)
	code += file.get_as_text()
	code += "\n"
	var globals = []
	var textures = {}
	for c in [ red_code, green_code, blue_code ]:
		if c.has("textures"):
			for t in c.textures.keys():
				textures[t] = c.textures[t]
		if c.has("globals"):
			for g in c.globals:
				if globals.find(g) == -1:
					globals.push_back(g)
	for t in textures.keys():
		code += "uniform sampler2D "+t+";\n"
	for g in globals:
		code += g
	var shader_code = ""
	shader_code += red_code.defs
	shader_code += green_code.defs
	shader_code += blue_code.defs
	shader_code += "void fragment() {\n"
	shader_code += red_code.code
	shader_code += green_code.code
	shader_code += blue_code.code
	shader_code += "COLOR = vec4("+red_code.f+", "+green_code.f+", "+blue_code.f+", 1.0);\n"
	shader_code += "}\n"
	#print("GENERATED COMBINED SHADER:\n"+shader_code)
	code += shader_code
	return code

func setup_material(shader_material, textures, shader_code) -> void:
	for k in textures.keys():
		shader_material.set_shader_param(k+"_tex", textures[k])
	shader_material.shader.code = shader_code

func render_shader(shader, textures, render_size) -> Object:
	if debug_path != null and debug_path != "":
		var file_name = debug_path+str(debug_file_index)+".shader"
		var f = File.new()
		f.open(debug_path+str(debug_file_index)+".shader", File.WRITE)
		f.store_string(shader)
		f.close()
		debug_file_index += 1
		print("shader saved as "+file_name)
	while rendering:
		yield(self, "done")
	rendering = true
	size = Vector2(render_size, render_size)
	$ColorRect.rect_position = Vector2(0, 0)
	$ColorRect.rect_size = size
	var shader_material = $ColorRect.material
	shader_material.shader.code = shader
	if textures != null:
		for k in textures.keys():
			shader_material.set_shader_param(k, textures[k])
	render_target_update_mode = Viewport.UPDATE_ONCE
	update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	return self

func copy_to_texture(t : ImageTexture) -> void:
	var image : Image = get_texture().get_data()
	if image != null:
		image.lock()
		t.create_from_image(get_texture().get_data())
		image.unlock()

func save_to_file(fn : String) -> void:
	var image : Image = get_texture().get_data()
	image.lock()
	image.save_png(fn)
	image.unlock()

func release() -> void:
	rendering = false
	emit_signal("done")
