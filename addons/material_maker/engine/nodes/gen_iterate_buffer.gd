@tool
extends MMGenTexture
class_name MMGenIterateBuffer


# Iterate buffers, that render their input in a specific resolution and apply
# a loop n times on the result.


var exiting : bool = false

var shader_computes : Array[MMShaderCompute]
var is_greyscale : bool = false
var is_paused : bool = false
var is_rendering : bool = false
var current_iteration : int = 0

var buffer_names : Array
var iteration_param_name : String
var used_named_parameters : Array = []


func _ready():
	#texture.flags = Texture2D.FLAG_REPEAT
	shader_computes.append(MMShaderCompute.new())
	shader_computes.append(MMShaderCompute.new())
	if !parameters.has("size"):
		parameters.size = 9
	buffer_names = [
		"o%d_input_init" % get_instance_id(),
		"o%d_input_loop" % get_instance_id(),
		"o%d_loop_tex" % get_instance_id(),
		"o%d_tex" % get_instance_id()
	]
	iteration_param_name = "o%d_iteration" % get_instance_id()
	mm_deps.create_buffer(buffer_names[3], self)
	mm_deps.create_buffer(buffer_names[0], self)
	mm_deps.create_buffer(buffer_names[1], self)
	set_current_iteration(0)

func _exit_tree() -> void:
	exiting = true

func get_type() -> String:
	return "iterate_buffer"

func get_type_name() -> String:
	return "Iterate Buffer"

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
	return [
		{ name="size", type="size", first=4, last=13, default=4 },
		{ name="shrink", type="boolean", default=false },
		{ name="autostop", type="boolean", default=false },
		{ name="iterations", type="float", min=1, max=50, step=1, default=5 },
		{ name="filter", type="boolean", default=true },
		{ name="mipmap", type="boolean", default=true },
		{ name="f32", label="32 bits", type="boolean", default=false }
	]

func get_input_defs() -> Array:
	return [ { name="in", type="rgba" }, { name="loop_in", type="rgba" } ]

func get_output_defs(_show_hidden : bool = false) -> Array:
	return [ { type="rgba" }, { type="rgba" } ]

func source_changed(input_port_index : int) -> void:
	update_shaders()

func all_sources_changed() -> void:
	update_shaders()

func follow_input(input_index : int) -> Array:
	if input_index == 1:
		return [ OutputPort.new(self, 0) ]
	else:
		return super.follow_input(input_index)

var require_shaders_update : bool = false

func update_shaders() -> void:
	if ! require_shaders_update:
		do_update_shaders.call_deferred()
		require_shaders_update = true

func do_update_shaders() -> void:
	require_shaders_update = false
	var sources : Array[ShaderCode] = [null, null]
	var new_is_greyscale = true
	for i in 2:
		var context : MMGenContext = MMGenContext.new()
		var source_output = get_source(i)
		if source_output != null:
			sources[i] = source_output.generator.get_shader_code("uv", source_output.output_index, context)
		else:
			sources[i] = get_default_generated_shader()
		if sources[i].output_type == "":
			sources[i] = get_default_generated_shader()
		if sources[i].output_type != "f":
			new_is_greyscale = false
	var f32 = get_parameter("f32")
	for i in 2:
		var shader_compute : MMShaderCompute = shader_computes[i]
		var buffer_name : String = buffer_names[i]
		if i == 1 and get_parameter("autostop"):
			await shader_compute.set_shader_from_shadercode(sources[i], f32, texture)
		else:
			await shader_compute.set_shader_from_shadercode(sources[i], f32)
		mm_deps.buffer_create_compute_material(buffer_name, shader_compute)
	mm_deps.update()
	if new_is_greyscale != is_greyscale:
		is_greyscale = new_is_greyscale
		notify_output_change(0)
		notify_output_change(1)
	set_current_iteration(0)

func set_parameter(n : String, v) -> void:
	super.set_parameter(n, v)
	set_current_iteration(0)

func on_dep_update_value(buffer_name, parameter_name, value) -> bool:
	if parameter_name != buffer_names[2] and parameter_name != iteration_param_name and (buffer_name != buffer_names[1] or ! value is Texture2D):
		set_current_iteration(0)
	if value != null:
		if buffer_name == buffer_names[0]:
			shader_computes[0].set_parameter(parameter_name, value)
		elif buffer_name == buffer_names[1]:
			shader_computes[1].set_parameter(parameter_name, value)
	return false

func on_dep_buffer_invalidated(buffer_name : String):
	if !exiting and (buffer_name == buffer_names[0] or buffer_name == buffer_names[1]):
		mm_deps.buffer_invalidate(buffer_names[3])

func on_dep_update_buffer(buffer_name : String) -> bool:
	if is_paused:
		return false
	if buffer_name == buffer_names[3]:
		return false
	if false and is_rendering:
		return false
	
	is_rendering = true
	
	var shader_compute : MMShaderCompute = shader_computes[0] if current_iteration == 0 else shader_computes[1]
	# Calculate iteration count
	var iterations = calculate_float_parameter("iterations")
	if iterations.has("used_named_parameters"):
		used_named_parameters = iterations.used_named_parameters
	if iterations.has("value"):
		iterations = iterations.value
	else:
		iterations = 1
	if current_iteration > iterations:
		await get_tree().process_frame
		mm_deps.dependency_update(buffer_name, null, true)
		is_rendering = false
		return false
	var check_current_iteration : int = current_iteration
	var autostop : bool = get_parameter("autostop")
	
	var time = Time.get_ticks_msec()
	var size = pow(2, get_parameter("size"))
	if get_parameter("shrink"):
		size = int(size)
		size >>= current_iteration
		if size < 4:
			size = 4
	
	var status : bool = await shader_compute.render(texture, size)
	
	is_rendering = false
	
	if check_current_iteration != current_iteration:
		mm_deps.dependency_update(buffer_name, texture, true)
		return false
	
	#todo texture.flags = 0
	
	# Calculate iteration index
	if autostop and shader_compute.get_difference() == 0:
		set_current_iteration(iterations+1)
	else:
		set_current_iteration(current_iteration+1)
	if current_iteration <= iterations:
		mm_deps.dependency_update("o%d_loop_tex" % get_instance_id(), texture, true)
	else:
		mm_deps.dependency_update("o%d_tex" % get_instance_id(), texture, true)
	mm_deps.dependency_update(buffer_name, texture, true)
	
	return status

func set_current_iteration(i : int) -> void:
	if i == current_iteration:
		return
	current_iteration = i
	mm_deps.dependency_update(iteration_param_name, current_iteration, true)
	if current_iteration == 0:
		mm_deps.buffer_invalidate(buffer_names[3])

#TODO: Remove this
func get_globals__(texture_name : String) -> Array[String]:
	var texture_globals : String = "uniform sampler2D %s;\nuniform float o%d_tex_size = %d.0;\nuniform float o%d_iteration = 0.0;\n" % [ texture_name, get_instance_id() 	, pow(2, get_parameter("size")), get_instance_id() ]
	return [ texture_globals ]

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> ShaderCode:
	var genname = "o"+str(get_instance_id())
	var shader_code = _get_shader_code_lod(uv, output_index, context, is_greyscale, -1.0, "_tex" if output_index == 0 else "_loop_tex")
	shader_code.add_uniform("%s_tex_size" % genname, "float", pow(2, get_parameter("size")))
	return shader_code

func get_output_attributes(output_index : int) -> Dictionary:
	var genname = "o"+str(get_instance_id())
	var attributes : Dictionary = {}
	match output_index:
		0:
			attributes.texture = "%s_tex" % genname
			attributes.texture_size = "%s_tex_size" % genname
		1:
			attributes.texture = "%s_loop_tex" % genname
			attributes.texture_size = "%s_tex_size" % genname
			attributes.iteration = iteration_param_name
	return attributes

func _serialize(data: Dictionary) -> Dictionary:
	data.type = "iterate_buffer"
	return data
