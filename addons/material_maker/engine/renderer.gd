tool
extends Viewport
class_name MMGenRenderer

export(String) var debug_path = ""
var debug_file_index : int = 0

var common_shader : String

var rendering : bool = false

signal done


func _ready() -> void:
	$ColorRect.material = $ColorRect.material.duplicate(true)
	var file = File.new()
	file.open("res://addons/material_maker/common.shader", File.READ)
	common_shader = file.get_as_text()

func generate_shader(src_code) -> String:
	var code
	code = "shader_type canvas_item;\n"
	code += "render_mode blend_disabled;\n"
	code += common_shader
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

func setup_material(shader_material, textures, shader_code) -> void:
	for k in textures.keys():
		shader_material.set_shader_param(k+"_tex", textures[k])
	shader_material.shader.code = shader_code

func render_material(material, render_size, with_hdr = true) -> Object:
	while rendering:
		yield(self, "done")
	rendering = true
	var shader_material = $ColorRect.material
	size = Vector2(render_size, render_size)
	$ColorRect.rect_position = Vector2(0, 0)
	$ColorRect.rect_size = size
	$ColorRect.material = material
	hdr = with_hdr
	render_target_update_mode = Viewport.UPDATE_ONCE
	update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	$ColorRect.material = shader_material
	return self

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
	shader_material.set_shader_param("preview_size", render_size)
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
	match fn.get_extension():
		"png":
			image.save_png(fn)
		"exr":
			image.save_exr(fn)
	image.unlock()

func release() -> void:
	rendering = false
	hdr = false
	emit_signal("done")
