extends MMPipeline
class_name MMComputeShader


var shader : RID
var texture_type : int

var diff : int

var render_time : int = 0


const LOCAL_SIZE : int = 32


func _init():
	clear()

func clear():
	super.clear()

func set_shader(string : String, tex_type : int, replaces : Dictionary = {}):
	texture_type = tex_type
	replaces["@LOCAL_SIZE"] = str(LOCAL_SIZE)
	replaces["@OUT_TEXTURE_TYPE"] = TEXTURE_TYPE[tex_type].decl
	replaces["@DECLARATIONS"] = get_uniform_declarations()+"\n"+get_texture_declarations()
	
	var rd : RenderingDevice = await mm_renderer.request_rendering_device(self)
	shader = do_compile_shader(rd, { compute=string }, replaces)
	mm_renderer.release_rendering_device(self)

func set_parameters_from_shadercode(shader_code : MMGenBase.ShaderCode, parameters_as_constants : bool = false):
	for u in shader_code.uniforms:
		for c in [ "\n".join(shader_code.globals), shader_code.defs, shader_code.code, shader_code.output_values.rgba ]:
			if c.find(u.name) != -1:
				add_parameter_or_texture(u.name, u.type, u.value, parameters_as_constants)
				break

func set_shader_from_shadercode_ext(shader_template : String, shader_code : MMGenBase.ShaderCode, is_greyscale : bool = false, is_32_bits : bool = false, compare_texture : MMTexture = null, extra_parameters : Array[Dictionary] = [], parameters_as_constants : bool = false) -> void:
	var tex_type : int = 0 if is_greyscale else 1
	if is_32_bits:
		tex_type |= 2
	
	var replaces : Dictionary = {}
	
	clear()
	set_parameters_from_shadercode(shader_code, parameters_as_constants)
	for p in extra_parameters:
		add_parameter_or_texture(p.name, p.type, p.value)
	
	if compare_texture != null:
		add_parameter_or_texture("mm_compare", "sampler2D", compare_texture)
	
	replaces["@COMMON_SHADER_FUNCTIONS"] = preload("res://addons/material_maker/shader_functions.tres").text
	replaces["@GLOBALS"] = "\n".join(shader_code.globals)
	replaces["@DEFINITIONS"] = shader_code.defs
	replaces["@CODE"] = shader_code.code
	replaces["@OUTPUT_VALUE"] = shader_code.output_values.rgba

	await set_shader(shader_template, tex_type, replaces)

func set_shader_from_shadercode(shader_code : MMGenBase.ShaderCode, is_32_bits : bool = false, compare_texture : MMTexture = null, extra_parameters : Array[Dictionary] = []) -> void:
	var shader_template : String
	
	if compare_texture:
		shader_template = load("res://addons/material_maker/engine/nodes/iterate_buffer_compute.tres").text
	else:
		shader_template = load("res://addons/material_maker/engine/nodes/buffer_compute.tres").text
	
	extra_parameters.append({ name="elapsed_time", type="float", value=0.0 })
	
	await set_shader_from_shadercode_ext(shader_template, shader_code, shader_code.output_type == "f", is_32_bits, compare_texture, extra_parameters)

func get_parameters() -> Dictionary:
	var rv : Dictionary = {}
	for p in parameters.keys():
		rv[p] = parameters[p].value
	for t in texture_indexes.keys():
		rv[t] = textures[texture_indexes[t]].texture
	return rv

func render_loop(rd : RenderingDevice, size : Vector2i, chunk_height : int, uniform_set_0 : RID, uniform_set_1 : RID, uniform_set_2 : RID, uniform_set_4 : RID):
	var y : int = 0
	var loop_parameters_values : PackedByteArray = PackedByteArray()
	loop_parameters_values.resize(4)
	while y < size.y:
		var h : int = min(chunk_height, size.y-y)
		
		var rids : RIDs = RIDs.new()
		
		# Create a compute pipeline
		var pipeline : RID = rd.compute_pipeline_create(shader)
		if ! pipeline.is_valid():
			print("Cannot create pipeline")
		rids.add(pipeline)
		var compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
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
		rd.compute_list_dispatch(compute_list, (size.x+LOCAL_SIZE-1)/LOCAL_SIZE, h, 1)
		rd.compute_list_end()
		#print("Rendering "+str(self))
		rd.submit()
		#await mm_renderer.get_tree().process_frame
		rd.sync()
		
		rids.free_rids(rd)
		
		#print("End rendering %d-%d (%dms)" % [ y, y+h, render_time ])
		
		y += h

func render(texture : MMTexture, size : Vector2i) -> bool:
	var rd : RenderingDevice = await mm_renderer.request_rendering_device(self)
	var rids : RIDs = RIDs.new()
	var start_time = Time.get_ticks_msec()
	set_parameter("elapsed_time", 0.001*float(start_time), true)
	var status = await render_2(rd, texture, size, rids)
	rids.free_rids(rd)
	render_time = Time.get_ticks_msec() - start_time
	mm_renderer.release_rendering_device(self)
	return status

func render_2(rd : RenderingDevice, texture : MMTexture, size : Vector2i, rids : RIDs) -> bool:
	#print("Preparing render")
	var output_tex : RID = create_output_texture(rd, size, texture_type)
	if shader.is_valid():
		var status : bool = await do_render(rd, output_tex, size, rids)
		if ! status:
			return false
	else:
		print("Invalid shader, generating blank image")
		return false
	
	texture.set_texture_rid(output_tex, size, TEXTURE_TYPE[texture_type].data_format)
	
	return true

func do_render(rd : RenderingDevice, output_tex : RID, size : Vector2i, rids : RIDs) -> bool:
	var outputs : PackedByteArray
	
	diff = 65536
	
	var output_tex_uniform : RDUniform = RDUniform.new()
	output_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_tex_uniform.binding = 0
	output_tex_uniform.add_id(output_tex)
	var uniform_set_0 : RID = rd.uniform_set_create([output_tex_uniform], shader, 0)
	rids.add(uniform_set_0)
	
	var uniform_set_1 : RID = RID()
	if parameter_values.size() > 0:
		uniform_set_1 = get_parameter_uniforms(rd, shader, rids)
		if ! uniform_set_1.is_valid():
			print("Failed to create valid uniform for parameters")
			return false
	
	var uniform_set_2 = RID()
	if !textures.is_empty():
		uniform_set_2 = get_texture_uniforms(rd, shader, rids)
		if ! uniform_set_2.is_valid():
			print("Failed to create valid uniform for textures")
			return false
	
	var uniform_set_4 = RID()
	var outputs_buffer : RID
	if texture_indexes.has("mm_compare"):
		outputs = PackedInt32Array([0]).to_byte_array()
		outputs_buffer = rd.storage_buffer_create(outputs.size(), outputs)
		rids.add(outputs_buffer)
		var outputs_uniform : RDUniform = RDUniform.new()
		outputs_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		outputs_uniform.binding = 0
		outputs_uniform.add_id(outputs_buffer)
		uniform_set_4 = rd.uniform_set_create([outputs_uniform], shader, 4)
		rids.add(uniform_set_4)
	
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
	
	if uniform_set_4.is_valid():
		outputs = rd.buffer_get_data(outputs_buffer)
		diff = outputs.to_int32_array()[0]
	
	return true

func get_difference() -> int:
	return diff
