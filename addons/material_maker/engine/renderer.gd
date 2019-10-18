tool
extends Viewport
class_name MMGenRenderer

export(String) var debug_path = ""
var debug_file_index : int = 0

var rendering : bool = false
signal done

func _ready():
	$ColorRect.material = $ColorRect.material.duplicate(true)

static func generate_shader(src_code):
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
	shader_code += src_code.code
	shader_code += "COLOR = "+src_code.rgba+";\n"
	shader_code += "}\n"
	#print("GENERATED SHADER:\n"+shader_code)
	code += shader_code
	return code

static func generate_combined_shader(red_code, green_code, blue_code):
	var code
	code = "shader_type canvas_item;\n"
	code += "render_mode blend_disabled;\n"
	var file = File.new()
	file.open("res://addons/material_maker/common.shader", File.READ)
	code += file.get_as_text()
	code += "\n"
	var globals = []
	for c in [ red_code, green_code, blue_code ]:
		if c.has("globals"):
			for g in c.globals:
				if globals.find(g) == -1:
					globals.push_back(g)
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

func setup_material(shader_material, textures, shader_code):
	for k in textures.keys():
		shader_material.set_shader_param(k+"_tex", textures[k])
	shader_material.shader.code = shader_code

func render_shader(shader, textures, render_size):
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

func copy_to_texture(t : ImageTexture):
	var image : Image = get_texture().get_data()
	if image != null:
		image.lock()
		t.create_from_image(get_texture().get_data())
		image.unlock()

func save_to_file(fn : String):
	var image : Image = get_texture().get_data()
	image.lock()
	image.save_png(fn)
	image.unlock()

func release():
	rendering = false
	emit_signal("done")
