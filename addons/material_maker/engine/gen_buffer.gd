tool
extends MMGenTexture
class_name MMGenBuffer

"""
Texture generator buffers, that render their input in a specific resolution and provide the result as output.
This is useful when using generators that sample their inputs several times
"""

var material : ShaderMaterial = null
var updating : bool = false
var update_again : bool = true

var current_renderer = null
var is_pending : bool = false

var pending_textures = []

func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = Shader.new()
	if !parameters.has("size"):
		parameters.size = 9
	add_to_group("preview")

func _exit_tree() -> void:
	if current_renderer != null:
		current_renderer.release(self)

func get_type() -> String:
	return "buffer"

func get_type_name() -> String:
	return "Buffer"

func get_parameter_defs() -> Array:
	return [
			{ name="size", type="size", first=4, last=12, default=4 },
			{ name="lod", type="float", min=0, max=10.0, step=0.01, default=0 }
		]

func get_input_defs() -> Array:
	return [ { name="in", type="rgba" } ]

func get_output_defs() -> Array:
	return [ { type="rgba" }, { type="rgba" } ]

func source_changed(_input_port_index : int) -> void:
	call_deferred("update_shader")

func all_sources_changed() -> void:
	call_deferred("update_shader")

func update_shader() -> void:
	var context : MMGenContext = MMGenContext.new()
	var source = {}
	var source_output = get_source(0)
	if source_output != null:
		source = source_output.generator.get_shader_code("uv", source_output.output_index, context)
		assert (!(source is GDScriptFunctionState))
		while source is GDScriptFunctionState:
			source = yield(source, "completed")
	if source.empty():
		source = DEFAULT_GENERATED_SHADER
	var shader_code = mm_renderer.generate_shader(source)
	if shader_code.find("$") != -1:
		print("Incorrect shader generated for "+get_hier_name())
		#shader_code = mm_renderer.generate_shader({ rgba="vec4(0.0, 0.0, 0.0, 1.0)" })
	material.shader.code = shader_code
	update_again = true
	if source.has("textures"):
		for k in source.textures.keys():
			material.set_shader_param(k, source.textures[k])
	if source.has("pending_textures"):
		pending_textures = source.pending_textures
	else:
		pending_textures = []
	if pending_textures.empty():
		update_buffer()
	elif ! is_pending:
		mm_renderer.add_pending_request()
		is_pending = true

func on_float_parameters_changed(parameter_changes : Dictionary) -> void:
	var do_update : bool = false
	for n in parameter_changes.keys():
		for p in VisualServer.shader_get_param_list(material.shader.get_rid()):
			if p.name == n:
				material.set_shader_param(n, parameter_changes[n])
				do_update = true
				break
	if mm_renderer.update_float_parameters(material, parameter_changes):
		update_again = true
		if pending_textures.empty():
			update_buffer()

func on_texture_changed(n : String) -> void:
	pending_textures.erase(n)
	if pending_textures.empty():
		for p in VisualServer.shader_get_param_list(material.shader.get_rid()):
			if p.name == n:
				update_again = true
				update_buffer()
				return

func update_buffer() -> void:
	if !updating:
		updating = true
		while update_again:
			if is_pending:
				mm_renderer.remove_pending_request()
				is_pending = false
			var renderer = mm_renderer.request(self)
			while renderer is GDScriptFunctionState:
				renderer = yield(renderer, "completed")
			if renderer == null:
				return
			current_renderer = renderer
			update_again = false
			var time = OS.get_ticks_msec()
			renderer = renderer.render_material(self, material, pow(2, get_parameter("size")))
			while renderer is GDScriptFunctionState:
				renderer = yield(renderer, "completed")
			if !update_again:
				renderer.copy_to_texture(texture)
			emit_signal("rendering_time", OS.get_ticks_msec() - time)
			renderer.release(self)
			current_renderer = null
		updating = false
		get_tree().call_group("preview", "on_texture_changed", "o%s_tex" % str(get_instance_id()))

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var shader_code = _get_shader_code_lod(uv, output_index, context, -1.0 if output_index == 0 else parameters.lod)
	if updating or update_again or !pending_textures.empty():
		shader_code.pending_textures = shader_code.textures.keys()
	return shader_code

func _serialize(data: Dictionary) -> Dictionary:
	data.type = "buffer"
	return data
