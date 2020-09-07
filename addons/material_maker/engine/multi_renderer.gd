extends Node

var common_shader : String

var free_renderers = []

var render_queue_size = 0

signal free_renderer
signal render_queue(count)

func _ready():
	var file = File.new()
	file.open("res://addons/material_maker/common.shader", File.READ)
	common_shader = file.get_as_text()
	for i in 4:
		var renderer = preload("res://addons/material_maker/engine/renderer.tscn").instance()
		add_child(renderer)
		free_renderers.append(renderer)

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
	var shader_code = ""
	if src_code.has("defs"):
		shader_code = src_code.defs
	shader_code += "\nvoid fragment() {\n"
	shader_code += "vec2 uv = UV;\n"
	if src_code.has("code"):
		shader_code += src_code.code
	if src_code.has("rgba"):
		shader_code += "COLOR = "+src_code.rgba+";\n"
	else:
		shader_code += "COLOR = vec4(1.0, 0.0, 0.0, 1.0);\n"
	shader_code += "}\n"
	#print("GENERATED SHADER:\n"+shader_code)
	code += shader_code
	return code

func request(object : Object) -> Object:
	render_queue_size += 1
	emit_signal("render_queue", render_queue_size)
	while free_renderers.empty():
		yield(self, "free_renderer")
	var renderer = free_renderers.pop_back()
	return renderer.request(object)

func release(renderer : Object) -> void:
	free_renderers.append(renderer)
	emit_signal("free_renderer", render_queue_size)
	render_queue_size -= 1
	emit_signal("render_queue", render_queue_size)
