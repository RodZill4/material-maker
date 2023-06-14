@tool
extends Node

var common_shader : String

var global_parameters : Dictionary = {}


const total_renderers = 8
var free_renderers = []

var max_renderers : int = 8
var renderers_enabled : bool = true
var max_viewport_size : int = 2048

var max_buffer_size = 0

var rendering_device : RenderingDevice
var rendering_device_user = null


signal free_renderer
signal free_rendering_device


func _ready() -> void:
	var file = FileAccess.open("res://addons/material_maker/common.gdshader", FileAccess.READ)
	common_shader = file.get_as_text()
	for i in total_renderers:
		var renderer = preload("res://addons/material_maker/engine/renderer.tscn").instantiate()
		add_child(renderer)
		free_renderers.append(renderer)
	rendering_device = RenderingServer.create_local_rendering_device()

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
	mm_deps.dependency_update("mm_global_"+n, value)

func get_global_parameter_declaration(n : String) -> String:
	if global_parameters.has(n):
		return "uniform float mm_global_"+n+" = "+str(global_parameters[n])
	return ""

# General_purpose shader functions

func generate_shader(src_code : MMGenBase.ShaderCode) -> String:
	var code
	code = "shader_type canvas_item;\n"
	code += "render_mode blend_disabled, unshaded;\n"
	code += common_shader
	code += "\n"
	for g in src_code.globals:
		code += g
	var shader_code = ""
	shader_code += src_code.uniforms_as_strings()
	shader_code += "\n"
	if src_code.defs != "":
		shader_code += src_code.defs
		shader_code += "\n"
	shader_code += "\nuniform float mm_chunk_size = 1.0;\n"
	shader_code += "\nuniform vec2 mm_chunk_offset = vec2(0.0);\n"
	shader_code += "\nuniform float variation = 0.0;\n"
	shader_code += "\nvoid fragment() {\n"
	shader_code += "float _seed_variation_ = variation;\n"
	shader_code += "vec2 uv = mm_chunk_offset+mm_chunk_size*UV;\n"
	if src_code.code != "":
		shader_code += src_code.code
		shader_code += "\n"
	if src_code.output_values.has("rgba"):
		shader_code += "COLOR = "+src_code.output_values.rgba+";\n"
	else:
		shader_code += "COLOR = vec4(1.0, 0.0, 0.0, 1.0);\n"
	shader_code += "}\n"
	#print("GENERATED SHADER:\n"+shader_code)
	code += shader_code
	return code

# Renderer request and management
func enable_renderers(b : bool) -> void:
	if b != renderers_enabled:
		renderers_enabled = b
		if renderers_enabled:
			free_renderer.emit()

func request(object : Object) -> Object:
	while !renderers_enabled or free_renderers.size() <= total_renderers - max_renderers:
		await self.free_renderer
	if ! is_instance_valid(object) or ! object.is_inside_tree():
		return null
	var renderer = free_renderers.pop_back()
	return renderer.request(object)

func release(renderer : Object) -> void:
	free_renderers.append(renderer)
	free_renderer.emit()


func request_rendering_device(user) -> RenderingDevice:
	while rendering_device_user != null:
		await free_rendering_device
	rendering_device_user = user
	return rendering_device

func release_rendering_device(user) -> void:
	if rendering_device_user != user:
		print("Release rendering device with incorrect user. Please fix your code")
	rendering_device_user = null
	free_rendering_device.emit()
