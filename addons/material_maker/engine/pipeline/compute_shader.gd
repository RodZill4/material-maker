extends MMPipeline
class_name MMComputeShader


class OutputTexture:
	extends RefCounted
	
	var name : String
	var type : int
	var writeonly : bool = true
	var keep : bool = false
	
	func _init(n : String, t : int, wo : bool = true, k : bool = false):
		name = n
		type = t
		writeonly = wo
		keep = k
	
	func get_declaration(binding : int) -> String:
		return "layout(set = 0, binding = %d, %s) restrict uniform%s image2D %s;\n" % [ binding, MMPipeline.TEXTURE_TYPE[type].decl, " writeonly" if writeonly else "", name ]


var output_textures : Array[OutputTexture]

var shader : RID

var render_time : int = 0


var local_size : int = 32


func _init():
	clear()

func clear():
	super.clear()

func get_output_texture_declarations() -> String:
	var texture_declarations : String = ""
	for ti in output_textures.size():
		var t : OutputTexture = output_textures[ti]
		texture_declarations += t.get_declaration(ti)
	return texture_declarations

func set_shader(string : String, output_texture_type : int, replaces : Dictionary = {}) -> bool:
	return await set_shader_ext(string, [{name="OUTPUT_TEXTURE", type=output_texture_type}], replaces)

func set_shader_ext(string : String, output_textures_desc : Array[Dictionary] = [], replaces : Dictionary = {}) -> bool:
	output_textures = []
	for ot in output_textures_desc:
		var writeonly : bool = true
		var keep : bool = false
		if ot.has("writeonly"):
			writeonly = ot.writeonly
		if ot.has("keep"):
			keep = ot.keep
		output_textures.append(OutputTexture.new(ot.name, ot.type, writeonly, keep))
	
	replaces["@LOCAL_SIZE"] = str(local_size)
	replaces["@DECLARATIONS"]  = get_output_texture_declarations()+"\n"
	replaces["@DECLARATIONS"] += get_uniform_declarations()+"\n"
	replaces["@DECLARATIONS"] += get_input_texture_declarations()+"\n"
	replaces["@DECLARATIONS"] += get_output_parameters_declarations()+"\n"
	
	var rd : RenderingDevice = await mm_renderer.request_rendering_device(self)
	shader = do_compile_shader(rd, { compute=string }, replaces)
	mm_renderer.release_rendering_device(self)
	return shader.is_valid()

func set_parameters_from_shadercode(shader_code : MMGenBase.ShaderCode, parameters_as_constants : bool = false):
	for u in shader_code.uniforms:
		for c in [ shader_code.get_globals_string(shader_code.defs+shader_code.code+shader_code.output_values.rgba), shader_code.defs, shader_code.code, shader_code.output_values.rgba ]:
			if c.find(u.name) != -1:
				var type : String = u.type
				if u.size > 0:
					type += "[%d]" % u.size
				add_parameter_or_texture(u.name, type, u.value, parameters_as_constants)
				break

func set_shader_from_shadercode_ext(shader_template : String, shader_code : MMGenBase.ShaderCode, output_textures_desc : Array[Dictionary], extra_parameters : Array[Dictionary] = [], parameters_as_constants : bool = false, extra_output_parameters : Array[Dictionary] = []) -> bool:
	var replaces : Dictionary = {}
	
	clear()
	set_parameters_from_shadercode(shader_code, parameters_as_constants)
	for p in extra_parameters:
		add_parameter_or_texture(p.name, p.type, p.value, p.array_size if p.has("array_size") else 0)
	
	for p in extra_output_parameters:
		add_output_parameter(p.name, p.type, p.array_size if p.has("array_size") else 0)
	
	replaces["@COMMON_SHADER_FUNCTIONS"] = preload("res://addons/material_maker/shader_functions.tres").text
	replaces["@GLOBALS"] = shader_code.get_globals_string(shader_code.defs+shader_code.code+shader_code.output_values.rgba)
	replaces["@DEFINITIONS"] = shader_code.defs
	replaces["@CODE"] = shader_code.code
	replaces["@OUTPUT_VALUE"] = shader_code.output_values.rgba

	return await set_shader_ext(shader_template, output_textures_desc, replaces)

func set_shader_from_shadercode(shader_code : MMGenBase.ShaderCode, is_32_bits : bool = false, extra_parameters : Array[Dictionary] = []) -> bool:
	var shader_template : String = load("res://addons/material_maker/engine/nodes/buffer_compute.tres").text
	
	#if compare_texture:
	#	shader_template = load("res://addons/material_maker/engine/nodes/iterate_buffer_compute.tres").text
	#else:
	
	extra_parameters.append({ name="elapsed_time", type="float", value=0.0 })
	
	var output_texture_type : int = 0 if (shader_code.output_type == "f") else 1
	if is_32_bits:
		output_texture_type |= 2
	var output_textures : Array[Dictionary] = [{name="OUTPUT_TEXTURE", type=output_texture_type}]
	
	return await set_shader_from_shadercode_ext(shader_template, shader_code, output_textures, extra_parameters)

func get_parameters() -> Dictionary:
	var rv : Dictionary = {}
	for p in parameters.keys():
		rv[p] = parameters[p].value
	for t in input_texture_indexes.keys():
		rv[t] = input_textures[input_texture_indexes[t]].texture
	return rv

func render_loop(rd : RenderingDevice, size : Vector2i, chunk_height : int, uniform_set_0 : RID, uniform_set_1 : RID, uniform_set_2 : RID, uniform_set_4 : RID):
	var y : int = 0
	var loop_parameters_values : PackedByteArray = PackedByteArray()
	loop_parameters_values.resize(4)
	while y < size.y:
		#print("Render %d/%d" % [y, size.y])
		var h : int = min(chunk_height, size.y-y)
		
		var rids : RIDs = RIDs.new()
		
		# Create a compute pipeline
		var pipeline : RID = rd.compute_pipeline_create(shader)
		if ! pipeline.is_valid():
			print("Cannot create pipeline")
		rids.add(pipeline)
		var compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		if uniform_set_0.is_valid():
			rd.compute_list_bind_uniform_set(compute_list, uniform_set_0, 0)
		if uniform_set_1.is_valid():
			rd.compute_list_bind_uniform_set(compute_list, uniform_set_1, 1)
		if uniform_set_2.is_valid():
			rd.compute_list_bind_uniform_set(compute_list, uniform_set_2, 2)
		
		loop_parameters_values.encode_s32(0, y)
		var uniform_set_3 : RID = rd.uniform_set_create(create_buffers_uniform_list(rd, [loop_parameters_values], rids), shader, 3)
		#rids.add(uniform_set_3)
		if rd.uniform_set_is_valid(uniform_set_3):
			rd.compute_list_bind_uniform_set(compute_list, uniform_set_3, 3)
		else:
			print("Incorrect uniform 3")
		
		if uniform_set_4.is_valid():
			rd.compute_list_bind_uniform_set(compute_list, uniform_set_4, 4)
		
		#print("Dispatching compute list")
		rd.compute_list_dispatch(compute_list, (size.x+local_size-1)/local_size, h, 1)
		rd.compute_list_end()
		#print("Rendering "+str(self))
		rd.submit()
		rd.sync()
		
		rids.free_rids(rd)
		
		#print("End rendering %d-%d (%dms)" % [ y, y+h, render_time ])
		
		y += h

func render(texture : MMTexture, size : Vector2i, output_parameters_values = null) -> bool:
	return await render_ext([texture], size, output_parameters_values)

func render_ext(textures : Array[MMTexture], size : Vector2i, output_parameters_values = null) -> bool:
	var rd : RenderingDevice = await mm_renderer.request_rendering_device(self)
	var rids : RIDs = RIDs.new()
	var start_time = Time.get_ticks_msec()
	set_parameter("elapsed_time", 0.001*float(start_time), true)
	var status = await render_2(rd, textures, output_parameters_values, size, rids)
	rids.free_rids(rd)
	render_time = Time.get_ticks_msec() - start_time
	mm_renderer.release_rendering_device(self)
	return status

func render_2(rd : RenderingDevice, textures : Array[MMTexture], output_parameters_values, size : Vector2i, rids : RIDs) -> bool:
	if not shader.is_valid():
		push_warning("Rendering with invalid shader")
		return false
	
	#print("Preparing render")
	var output_textures_rids : Array[RID] = []
	for i in range(textures.size()):
		var output_texture : OutputTexture = output_textures[i]
		if output_texture.keep:
			var texture : MMTexture = textures[i]
			var texture_rid : RID = texture.rid
			if texture_rid.is_valid() and texture.texture_size == size and texture.texture_format == TEXTURE_TYPE[output_textures[i].type].data_format:
				output_textures_rids.append(texture_rid)
				continue
		#print("Creating texture for "+output_texture.name)
		output_textures_rids.append(create_output_texture(rd, size, output_texture.type))
	
	var status : bool = await do_render(rd, output_textures_rids, size, rids, output_parameters_values)
	if ! status:
		push_warning("Rendering failed")
		return false
	
	for i in range(textures.size()):
		#print("Updating texture")
		textures[i].set_texture_rid(output_textures_rids[i], size, TEXTURE_TYPE[output_textures[i].type].data_format, rd)
	
	return true

func do_render(rd : RenderingDevice, output_textures_rids : Array[RID], size : Vector2i, rids : RIDs, output_parameters_values = null) -> bool:
	var outputs : PackedByteArray
	
	time("Create target textures uniforms")
	var uniform_set_0 : RID
	if output_textures_rids.is_empty():
		uniform_set_0 = RID()
	else:
		var uniform_array : Array[RDUniform] = []
		for i in output_textures_rids.size():
			var output_texture_uniform : RDUniform = RDUniform.new()
			output_texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
			output_texture_uniform.binding = i
			output_texture_uniform.add_id(output_textures_rids[i])
			uniform_array.append(output_texture_uniform)
		uniform_set_0 = rd.uniform_set_create(uniform_array, shader, 0)
		rids.add(uniform_set_0)
	
	time("Create parameters uniforms")
	var uniform_set_1 : RID = RID()
	if parameter_values.size() > 0:
		uniform_set_1 = get_parameter_uniforms(rd, shader, rids)
		if ! uniform_set_1.is_valid():
			push_warning("Failed to create valid uniform for parameters")
			return false
	
	time("Create input_textures uniforms")
	var uniform_set_2 : RID = get_texture_uniforms(rd, shader, rids)
	if uniform_set_2.get_id() != 0 and not uniform_set_2.is_valid():
		push_warning("Failed to create valid uniform for input_textures")
		return false
	
	time("Create output parameters")
	var uniform_set_4 = RID()
	var outputs_buffer : RID
	var has_output_parameters : bool = (output_parameters_values != null and output_parameters_values is Dictionary)
	if not output_parameters.is_empty():
		var outputs_size : int = 0
		for o in output_parameters.keys():
			var output_parameter : Parameter = output_parameters[o]
			var output_parameter_size : int = output_parameter.offset
			if output_parameter.array_size > 0:
				output_parameter_size += output_parameter.size * output_parameter.array_size
			else:
				output_parameter_size += output_parameter.size
			if outputs_size < output_parameter_size:
				outputs_size = output_parameter_size
		outputs = PackedByteArray()
		outputs.resize(outputs_size)
		if has_output_parameters:
			for p in output_parameters_values.keys():
				if output_parameters.has(p):
					set_parameter_value_to_buffer(output_parameters[p], outputs, output_parameters_values[p])
		outputs_buffer = rd.storage_buffer_create(outputs.size(), outputs)
		var outputs_uniform : RDUniform = RDUniform.new()
		outputs_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		outputs_uniform.binding = 0
		outputs_uniform.add_id(outputs_buffer)
		uniform_set_4 = rd.uniform_set_create([outputs_uniform], shader, 4)
		rids.add(uniform_set_4)
	
	time("Render")
	var max_viewport_size = mm_renderer.max_viewport_size
	var chunk_count : int = max(1, size.x*size.y/(max_viewport_size*max_viewport_size))
	var chunk_height : int = max(1, size.y/chunk_count)
	
	#await render_loop(rd, size, chunk_height, uniform_set_0, uniform_set_1, uniform_set_2, uniform_set_4)
	if true:
		# Use threads
		var thread : Thread = Thread.new()
		thread.start(render_loop.bind(rd, size, chunk_height, uniform_set_0, uniform_set_1, uniform_set_2, uniform_set_4))
		while thread.is_alive():
			await mm_renderer.get_tree().process_frame
		
		thread.wait_to_finish()
	else:
		render_loop(rd, size, chunk_height, uniform_set_0, uniform_set_1, uniform_set_2, uniform_set_4)
	
	if has_output_parameters:
		for pn in output_parameters.keys():
			output_parameters_values.erase(pn)
		if uniform_set_4.is_valid():
			time("Store output parameters")
			outputs = rd.buffer_get_data(outputs_buffer)
			for pn in output_parameters.keys():
				var format : String = ""
				if output_parameters_values.has(pn+"_format"):
					format = output_parameters_values[pn+"_format"]
				output_parameters_values[pn] = get_parameter_value_from_buffer(output_parameters[pn], outputs, format)
	time()
	
	return true
