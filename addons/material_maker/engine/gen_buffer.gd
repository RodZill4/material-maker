tool
extends MMGenTexture
class_name MMGenBuffer

"""
Texture generator buffers, that render their input in a specific resolution and provide the result as output.
This is useful when using generators that sample their inputs several times
"""

const VERSION_OLD     : int = 0
const VERSION_SIMPLE  : int = 1
const VERSION_COMPLEX : int = 2

var version : int = VERSION_OLD

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
	var parameter_defs : Array = [ { name="size", type="size", first=4, last=12, default=4 } ]
	match version:
		VERSION_OLD:
			parameter_defs.push_back({ name="lod", type="float", min=0, max=10.0, step=0.01, default=0 })
		VERSION_COMPLEX:
			parameter_defs.push_back({ name="filter", type="boolean", default=true })
			parameter_defs.push_back({ name="mipmap", type="boolean", default=true })
	return parameter_defs

func get_input_defs() -> Array:
	return [ { name="in", type="rgba" } ]

func get_output_defs() -> Array:
	if version == VERSION_OLD:
		return [ { type="rgba" }, { type="rgba" } ]
	else:
		return [ { type="rgba" } ]

func source_changed(_input_port_index : int) -> void:
	call_deferred("update_shader")

func all_sources_changed() -> void:
	call_deferred("update_shader")

func set_parameter(n : String, v) -> void:
	if is_inside_tree():
		get_tree().call_group("preview", "on_texture_invalidated", "o%s_tex" % str(get_instance_id()))
		if n == "size":
			var param_name = "o%s_tex_size" % str(get_instance_id())
			var param_value = pow(2, v)
			get_tree().call_group("preview", "on_float_parameters_changed", { param_name:param_value })
	.set_parameter(n, v)

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
	else:
		set_pending()

func set_pending() -> void:
	if ! is_pending:
		mm_renderer.add_pending_request()
		is_pending = true

func on_float_parameters_changed(parameter_changes : Dictionary) -> void:
	if mm_renderer.update_float_parameters(material, parameter_changes):
		update_again = true
		get_tree().call_group("preview", "on_texture_invalidated", "o%s_tex" % str(get_instance_id()))
		if pending_textures.empty():
			update_buffer()

func on_texture_changed(n : String) -> void:
	pending_textures.erase(n)
	if pending_textures.empty() and mm_renderer.material_has_parameter(material, n):
		update_again = true
		update_buffer()

func on_texture_invalidated(n : String) -> void:
	if mm_renderer.material_has_parameter(material, n):
		if pending_textures.empty():
			get_tree().call_group("preview", "on_texture_invalidated", "o%s_tex" % str(get_instance_id()))
			set_pending()
		if pending_textures.find(n) == -1:
			pending_textures.push_back(n)

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
				match version:
					VERSION_COMPLEX:
						var flags = Texture.FLAG_REPEAT | ImageTexture.STORAGE_COMPRESS_LOSSLESS
						if ! parameters.has("filter") or parameters.filter:
							flags |= Texture.FLAG_FILTER
						if ! parameters.has("mipmap") or parameters.mipmap:
							flags |= Texture.FLAG_MIPMAPS
						texture.flags = flags
					_:
						texture.flags = Texture.FLAGS_DEFAULT
			emit_signal("rendering_time", OS.get_ticks_msec() - time)
			renderer.release(self)
			current_renderer = null
		updating = false
		get_tree().call_group("preview", "on_texture_changed", "o%s_tex" % str(get_instance_id()))

func get_globals(texture_name : String) -> Array:
	var texture_globals : String = "uniform sampler2D %s;\nuniform float %s_size = %d.0;\n" % [ texture_name, texture_name, pow(2, get_parameter("size")) ]
	return [ texture_globals ]

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> Dictionary:
	var shader_code = _get_shader_code_lod(uv, output_index, context, -1.0 if output_index == 0 else parameters.lod)
	if updating or update_again or !pending_textures.empty():
		shader_code.pending_textures = shader_code.textures.keys()
	return shader_code

func get_output_attributes(output_index : int) -> Dictionary:
	var attributes : Dictionary = {}
	attributes.texture = "o%s_tex" % str(get_instance_id())
	attributes.texture_size = "o%s_tex_size" % str(get_instance_id())
	return attributes

func _serialize(data: Dictionary) -> Dictionary:
	data.type = "buffer"
	if version != VERSION_OLD:
		data.version = version
	return data

func _deserialize(data : Dictionary) -> void:
	if data.has("version"):
		version = data.version
	else:
		version = VERSION_OLD
