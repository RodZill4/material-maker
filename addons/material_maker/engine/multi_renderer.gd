tool
extends Node

var common_shader : String

const total_renderers = 8
var free_renderers = []

var max_renderers = 8

var render_queue_size = 0
var pending_requests = 0

signal free_renderer
signal render_queue(count, pending)
signal render_queue_empty

func _ready() -> void:
	var file = File.new()
	file.open("res://addons/material_maker/common.shader", File.READ)
	common_shader = file.get_as_text()
	for i in total_renderers:
		var renderer = preload("res://addons/material_maker/engine/renderer.tscn").instance()
		add_child(renderer)
		free_renderers.append(renderer)

func generate_shader(src_code : Dictionary) -> String:
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
	emit_signal("render_queue", render_queue_size, pending_requests)
	while free_renderers.size() <= total_renderers - max_renderers:
		yield(self, "free_renderer")
	if !is_instance_valid(object) || !object.is_inside_tree():
		render_queue_size -= 1
		emit_signal("render_queue", render_queue_size, pending_requests)
		return null
	var renderer = free_renderers.pop_back()
	return renderer.request(object)

func release(renderer : Object) -> void:
	free_renderers.append(renderer)
	emit_signal("free_renderer", render_queue_size, pending_requests)
	render_queue_size -= 1
	emit_signal("render_queue", render_queue_size, pending_requests)
	if render_queue_size == 0 and pending_requests == 0:
		emit_signal("render_queue_empty")

func add_pending_request() -> void:
	pending_requests += 1

func remove_pending_request() -> void:
	assert(pending_requests > 0)
	pending_requests -= 1
