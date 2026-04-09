@tool
extends Node

var common_shader : String

var global_parameters : Dictionary = {}


const total_renderers = 1
var free_renderers = []

var max_renderers : int = 1
var renderers_enabled : bool = true
var max_viewport_size : int = 2048

var max_buffer_size = 0

var shader_error_handler


signal free_renderer()
signal free_rendering_device


func _ready() -> void:
	shader_error_handler = load("res://addons/material_maker/engine/shader_error_handler.gd").new()
	common_shader = "varying float elapsed_time;\nvoid vertex() {\n\telapsed_time = TIME;\n}\n"
	common_shader += preload("res://addons/material_maker/shader_functions.tres").text
	for i in total_renderers:
		var renderer = preload("res://addons/material_maker/engine/renderer.tscn").instantiate()
		add_child(renderer)
		free_renderers.append(renderer)
	initialize_rendering_thread()
	
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
	code += src_code.get_globals_string()
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
	shader_code += "vec4 _controlled_variation_ = vec4(0.0);\n"
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
			free_rendering_device.emit()

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


# rendering thread

const render_in_separate_thread : bool = true
var rendering_thread : Thread
var rendering_mutex : Mutex
var rendering_semaphore : Semaphore
var rendering_callable : Callable
var rendering_parameters : Array
var rendering_return_value
var rendering_thread_running : bool
var rendering_thread_working : bool = false
var rendering_device : RenderingDevice
var rendering_device_user = null

func thread_loop():
	while true:
		rendering_semaphore.wait()
		rendering_mutex.lock()
		var running : bool = rendering_thread_running
		if not running:
			rendering_mutex.unlock()
			break
		var rv = rendering_callable.callv(rendering_parameters)
		rendering_return_value = rv
		rendering_thread_running = false
		rendering_mutex.unlock()

func thread_run(c : Callable, p : Array = [], stop_thread = false):
	if render_in_separate_thread:
		if rendering_thread == null:
			return
		while rendering_thread_working and is_inside_tree():
			await get_tree().process_frame
		rendering_thread_working = true
		while not rendering_mutex.try_lock() and is_inside_tree():
			await get_tree().process_frame
		rendering_callable = c
		rendering_parameters = p
		rendering_thread_running = not stop_thread
		rendering_mutex.unlock()
		rendering_semaphore.post()
		var running : bool = true
		var rv
		while running:
			while not rendering_mutex.try_lock():
				if is_inside_tree():
					await get_tree().process_frame
			running = rendering_thread_running
			rv = rendering_return_value
			rendering_mutex.unlock()
		rendering_thread_working = false
		return rv
	else:
		return await c.callv(p)

func create_rendering_device():
	rendering_device = RenderingServer.create_local_rendering_device()

func destroy_rendering_device():
	pass

func initialize_rendering_thread():
	if render_in_separate_thread:
		rendering_thread = Thread.new()
		rendering_mutex = Mutex.new()
		rendering_semaphore = Semaphore.new()
		rendering_thread.start(self.thread_loop, 2)
		thread_run(self.create_rendering_device)
	else:
		create_rendering_device()

func stop_rendering_thread():
	if render_in_separate_thread:
		await thread_run(destroy_rendering_device, [])
		await thread_run(destroy_rendering_device, [], true)
		rendering_thread.wait_to_finish()
		rendering_thread = null

func request_rendering_device(user) -> RenderingDevice:
	while ! renderers_enabled or rendering_device_user != null:
		await self.free_rendering_device
	rendering_device_user = user
	var scene_tree : SceneTree = get_tree()
	if scene_tree:
		await scene_tree.process_frame
	return rendering_device

func release_rendering_device(user) -> void:
	if rendering_device_user != user:
		print("Release rendering device with incorrect user. Please fix your code")
	rendering_device_user = null
	free_rendering_device.emit()
