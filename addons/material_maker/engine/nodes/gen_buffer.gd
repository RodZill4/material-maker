@tool
extends MMGenTexture
class_name MMGenBuffer


# Texture generator buffers, that render their input in a specific resolution and
# provide the result as output.
# This is useful when using generators that sample their inputs several times


const VERSION_OLD     : int = 0
const VERSION_SIMPLE  : int = 1
const VERSION_COMPLEX : int = 2


var version : int = VERSION_OLD
var exiting : bool = false

var shader_compute : MMShaderCompute
var is_greyscale : bool = false

var is_paused : bool = false


func _ready() -> void:
	shader_compute = MMShaderCompute.new()
	if !parameters.has("size"):
		parameters.size = 9
	mm_deps.create_buffer("o%d_tex" % get_instance_id(), self)
	do_update_shader()

func _exit_tree() -> void:
	exiting = true

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
			parameter_defs.push_back({ name="f32", label="32 bits", type="boolean", default=false })
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
			var param_name = "o%d_tex_size" % get_instance_id()
			var param_value = pow(2, v)
			mm_deps.dependency_update(param_name, param_value)
	super.set_parameter(n, v)

var updating_shader : bool = false
func update_shader() -> void:
	if ! updating_shader:
		updating_shader = true
		do_update_shader.call_deferred()

func do_update_shader() -> void:
	if ! is_instance_valid(self) or exiting:
		return
	if not is_node_ready():
		await ready
	updating_shader = false
	var context : MMGenContext = MMGenContext.new()
	var source : ShaderCode
	var source_output : OutputPort = get_source(0)
	if source_output != null:
		source = source_output.generator.get_shader_code("uv", source_output.output_index, context)
	else:
		source = get_default_generated_shader()
	var f32 = false
	if version == VERSION_COMPLEX:
		f32 = get_parameter("f32")
	var shader_status : bool = await shader_compute.set_shader_from_shadercode(source, f32)
	if shader_status:
		var new_is_greyscale = ((shader_compute.get_texture_type() & 1) == 0)
		if new_is_greyscale != is_greyscale:
			is_greyscale = new_is_greyscale
			notify_output_change(0)
			if version == VERSION_OLD:
				notify_output_change(1)
		await mm_deps.buffer_create_compute_material("o%d_tex" % get_instance_id(), shader_compute)
		mm_deps.update()
	else:
		print("buffer is invalid")

func on_dep_update_value(buffer_name, parameter_name, value) -> bool:
	if value != null:
		shader_compute.set_parameter(parameter_name, value)
	return false

func on_dep_update_buffer(buffer_name : String) -> bool:
	if is_paused:
		return false
	var status = await shader_compute.render(texture, pow(2, get_parameter("size")))
	if status:
		rendering_time = shader_compute.get_render_time()
		self.rendering_time_updated.emit(rendering_time)
		mm_deps.dependency_update(buffer_name, texture, true)
	else:
		print("Failed to update buffer")
	return status

func get_adjusted_uv(uv : String) -> String:
	if version == VERSION_COMPLEX and not get_parameter("filter"):
		var genname = "o"+str(get_instance_id())
		return "((floor(%s * %s_tex_size)+vec2(0.5))/%s_tex_size)" % [ uv, genname, genname ]
	else:
		return uv

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> ShaderCode:
	var genname = "o"+str(get_instance_id())
	var shader_code = _get_shader_code_lod(uv, output_index, context, is_greyscale, -1.0 if output_index == 0 else parameters.lod)
	shader_code.add_uniform("%s_tex_size" % genname, "float", pow(2, get_parameter("size")))
	return shader_code

func get_output_attributes(output_index : int) -> Dictionary:
	var attributes : Dictionary = {}
	attributes.texture = "o%d_tex" % get_instance_id()
	attributes.texture_size = "o%d_tex_size" % get_instance_id()
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
