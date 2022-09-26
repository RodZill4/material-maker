tool
extends Node

var common_shader : String

var global_parameters : Dictionary = {}

const total_renderers = 8
var free_renderers = []

var max_renderers : int = 8
var renderers_enabled : bool = true
var max_viewport_size : int = 2048

var max_buffer_size = 0

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

# Global parameters

func get_global_parameters():
	return global_parameters.keys()

func get_global_parameter(n : String):
	if global_parameters.has(n):
		return global_parameters[n]
	else:
		return null

func set_global_parameter(n : String, value):
	global_parameters[n] = value
	get_tree().call_group("preview", "on_float_parameters_changed", { "mm_global_"+n:value })

func get_global_parameter_declaration(n : String) -> String:
	if global_parameters.has(n):
		return "uniform float mm_global_"+n+" = "+str(global_parameters[n])
	return ""

# General_purpose shader functions

func generate_shader(src_code : Dictionary) -> String:
	var code
	code = "shader_type canvas_item;\n"
	code += "render_mode blend_disabled;\n"
	code += common_shader
	code += "\n"
	if src_code.has("globals"):
		for g in src_code.globals:
			code += g
	var shader_code = ""
	if src_code.has("defs"):
		shader_code = src_code.defs
	shader_code += "\nuniform float mm_chunk_size = 1.0;\n"
	shader_code += "\nuniform vec2 mm_chunk_offset = vec2(0.0);\n"
	shader_code += "\nuniform float variation = 0.0;\n"
	shader_code += "\nvoid fragment() {\n"
	shader_code += "float _seed_variation_ = variation;\n"
	shader_code += "vec2 uv = mm_chunk_offset+mm_chunk_size*UV;\n"
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

static func material_has_parameter(material : ShaderMaterial, parameter : String) -> bool:
	for p in VisualServer.shader_get_param_list(material.shader.get_rid()):
		if p.name == parameter:
			return true
	return false

static func update_float_parameters(material : ShaderMaterial, parameter_changes : Dictionary) -> bool:
	if material == null:
		return false
	var updated : bool = false
	for n in parameter_changes.keys():
		for p in VisualServer.shader_get_param_list(material.shader.get_rid()):
			if p.name == n:
				material.set_shader_param(n, parameter_changes[n])
				updated = true
				break
	return updated

# Renderer request and management
func enable_renderers(b : bool) -> void:
	if b != renderers_enabled:
		renderers_enabled = b
		if renderers_enabled:
			emit_signal("free_renderer")

func request(object : Object) -> Object:
	render_queue_size += 1
	emit_signal("render_queue", render_queue_size, pending_requests)
	while !renderers_enabled or free_renderers.size() <= total_renderers - max_renderers:
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

