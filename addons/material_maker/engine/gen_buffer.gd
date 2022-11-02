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
var is_paused : bool = false
var need_update : bool = false
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
	#add_to_group("preview")
	mm_deps.create_buffer("o%s_tex" % str(get_instance_id()), self)

func _exit_tree() -> void:
	if current_renderer != null:
		current_renderer.release(self)
	if is_pending:
		mm_renderer.remove_pending_request()
	mm_deps.delete_buffer("o%s_tex" % str(get_instance_id()))

func get_type() -> String:
	return "buffer"

func get_type_name() -> String:
	return "Buffer"

func set_paused(v : bool) -> void:
	if v == is_paused:
		return
	is_paused = v
	if ! v:
		mm_deps.update()

func get_buffers(flags : int = BUFFERS_ALL) -> Array:
	if ( is_paused and flags == BUFFERS_RUNNING ) or ( ! is_paused and flags == BUFFERS_PAUSED ):
		return []
	return [ self ]

func get_parameter_defs() -> Array:
	var parameter_defs : Array = [ { name="size", type="size", first=4, last=13, default=4 } ]
	match version:
		VERSION_OLD:
			parameter_defs.push_back({ name="lod", type="float", min=0, max=10.0, step=0.01, default=0 })
		VERSION_COMPLEX:
			parameter_defs.push_back({ name="filter", type="boolean", default=true })
			parameter_defs.push_back({ name="mipmap", type="boolean", default=true })
	return parameter_defs

func get_input_defs() -> Array:
	return [ { name="in", type="rgba" } ]

func get_output_defs(_show_hidden : bool = false) -> Array:
	if version == VERSION_OLD:
		return [ { type="rgba" }, { type="rgba" } ]
	else:
		return [ { type="rgba" } ]

func source_changed(_input_port_index : int) -> void:
	update_shader()

func all_sources_changed() -> void:
	update_shader()

func set_parameter(n : String, v) -> void:
	if is_inside_tree():
		if n == "size":
			var param_name = "o%s_tex_size" % str(get_instance_id())
			var param_value = pow(2, v)
			mm_deps.dependencies_update({ param_name:param_value })
	.set_parameter(n, v)

var updating_shader : bool = false
func update_shader() -> void:
	if ! updating_shader:
		updating_shader = true
		call_deferred("do_update_shader")

func do_update_shader() -> void:
	updating_shader = false
	var context : MMGenContext = MMGenContext.new()
	var source = {}
	var source_output = get_source(0)
	if source_output != null:
		source = source_output.generator.get_shader_code("uv", source_output.output_index, context)
	if source.empty():
		source = DEFAULT_GENERATED_SHADER
	var shader_code = mm_renderer.generate_shader(source)
	if shader_code.find("$") != -1:
		print("Incorrect shader generated for "+get_hier_name())
		#shader_code = mm_renderer.generate_shader({ rgba="vec4(0.0, 0.0, 0.0, 1.0)" })
	material.shader.code = shader_code
	update_again = true
	var buffer_name = "o%s_tex" % str(get_instance_id())
	mm_deps.buffer_clear_dependencies(buffer_name)
	for p in VisualServer.shader_get_param_list(material.shader.get_rid()):
		mm_deps.buffer_add_dependency(buffer_name, p.name)
	if source.has("textures"):
		for k in source.textures.keys():
			material.set_shader_param(k, source.textures[k])
	pending_textures = []
	yield(get_tree(), "idle_frame")
	mm_deps.update()

func on_dep_update_value(buffer_name, parameter_name, value) -> bool:
	if value != null:
		material.set_shader_param(parameter_name, value)
	return false

func on_dep_update_buffer(buffer_name) -> bool:
	if is_paused:
		need_update = true
		return false
	assert(current_renderer == null)
	current_renderer = mm_renderer.request(self)
	while current_renderer is GDScriptFunctionState:
		current_renderer = yield(current_renderer, "completed")
	var time = OS.get_ticks_msec()
	current_renderer = current_renderer.render_material(self, material, pow(2, get_parameter("size")))
	while current_renderer is GDScriptFunctionState:
		current_renderer = yield(current_renderer, "completed")
	current_renderer.copy_to_texture(texture)
	current_renderer.release(self)
	current_renderer = null
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
	mm_deps.buffer_updated(buffer_name)
	return true

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
