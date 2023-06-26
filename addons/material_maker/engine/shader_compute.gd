extends MMShaderBase
class_name MMShaderCompute


class Parameter:
	extends RefCounted
	
	var type : String
	var offset : int
	var size : int
	var value
	
	func _init(t : String, v):
		type = t
		offset = 0
		match type:
			"float":
				size = 4
			"vec4":
				size = 16
			_:
				size = 0
		value = v

class InputTexture:
	extends RefCounted
	
	var name : String
	var texture : MMTexture
	
	func _init(n : String, t : MMTexture):
		name = n
		texture = t

var shader_source : String
var shader : RID
var texture_type : int

var parameters : Dictionary
var parameter_values : PackedByteArray

var texture_indexes : Dictionary
var textures : Array[InputTexture]

var diff : int

var render_time : int = 0

const TEXTURE_TYPE : Array[Dictionary] = [
	{ decl="r16f", data_format=RenderingDevice.DATA_FORMAT_R16_SFLOAT, image_format=Image.FORMAT_RH },
	{ decl="rgba16f", data_format=RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT, image_format=Image.FORMAT_RGBAH },
	{ decl="r32f", data_format=RenderingDevice.DATA_FORMAT_R32_SFLOAT, image_format=Image.FORMAT_RF },
	{ decl="rgba32f", data_format=RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT, image_format=Image.FORMAT_RGBAF }
]


func _init():
	clear()

func clear():
	shader_source = ""
	parameters = {}
	parameter_values = PackedByteArray()
	texture_indexes = {}
	textures = []

func add_parameter_or_texture(n : String, t : String, v):
	if t == "sampler2D":
		if texture_indexes.has(n):
			print("ERROR: Redefining texture "+n)
		texture_indexes[n] = textures.size()
		textures.append(InputTexture.new(n, v))
	else:
		if parameters.has(n):
			print("ERROR: Redefining parameter "+n)
		parameters[n] = Parameter.new(t, v)

func get_uniform_declarations() -> String:
	var uniform_declarations : String = ""
	var size : int = 0
	for type in [ "vec4", "float" ]:
		for p in parameters.keys():
			var parameter : Parameter = parameters[p]
			if parameter.type != type:
				continue
			uniform_declarations += "\t%s %s;\n" % [ parameter.type, p ]
			parameter.offset = size
			size += parameter.size
	if uniform_declarations != "":
		uniform_declarations = "layout(set = 1, binding = 0, std430) restrict buffer Parameters {\n"+uniform_declarations+"};\n"
		parameter_values.resize(size)
		for p in parameters.keys():
			set_parameter(p, parameters[p].value)
	return uniform_declarations

func get_texture_declarations() -> String:
	var texture_declarations : String = ""
	for ti in textures.size():
		var t : InputTexture = textures[ti]
		texture_declarations += "layout(set = 2, binding = %d) uniform sampler2D %s;\n" % [ ti, t.name ]
	return texture_declarations

func compile_shader() -> bool:
	var rv : bool = true
	var src : RDShaderSource = RDShaderSource.new()
	src.source_compute = shader_source
	var rd : RenderingDevice = await mm_renderer.request_rendering_device(self)
	var spirv : RDShaderSPIRV = rd.shader_compile_spirv_from_source(src)
	if shader.is_valid():
		rd.free_rid(shader)
	if spirv.compile_error_compute != "":
		var ln : int = 0
		for l in shader_source.split("\n"):
			ln += 1
			print("%4d: %s" % [ ln, l ])
		print(spirv.compile_error_compute)
		shader = RID()
		rv = false
	else:
		shader = rd.shader_create_from_spirv(spirv)
	mm_renderer.release_rendering_device(self)
	return rv

func set_shader_from_shadercode(shader_code : MMGenBase.ShaderCode, is_32_bits : bool = false, compare_texture : MMTexture = null) -> void:
	texture_type = 0 if shader_code.output_type == "f" else 1
	if is_32_bits:
		texture_type |= 2
	
	clear()
	for u in shader_code.uniforms:
		add_parameter_or_texture(u.name, u.type, u.value)
	
	if compare_texture != null:
		add_parameter_or_texture("mm_compare", "sampler2D", compare_texture)
	
	shader_source = "#version 450\n"
	shader_source += "\n"
	shader_source += "layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;\n"
	shader_source += "\n"
	shader_source += "layout(set = 0, binding = 0, %s) uniform image2D OUTPUT_TEXTURE;\n" % TEXTURE_TYPE[texture_type].decl
	shader_source += get_uniform_declarations()
	shader_source += get_texture_declarations()
	shader_source += "layout(set = 3, binding = 0, std430) restrict buffer MM {\n"
	shader_source += "\tint mm_chunk_y;\n"
	shader_source += "};\n"
	if compare_texture != null:
		shader_source += "layout(set = 4, binding = 0, std430) buffer MMout {\n"
		shader_source += "\tint mm_compare[1];\n"
		shader_source += "} mm_out;\n"
	shader_source += preload("res://addons/material_maker/shader_functions.tres").text
	shader_source += "\n"
	shader_source += "const float seed_variation = 0.0;\n"
	shader_source += "\n"
	shader_source += "\n".join(shader_code.globals)
	shader_source += "\n"
	if shader_code.defs != "":
		shader_source += shader_code.defs
	shader_source += "void main() {\n"
	shader_source += "\tfloat _seed_variation_ = seed_variation;\n"
	shader_source += "\tvec2 pixel = gl_GlobalInvocationID.xy+vec2(0.5, 0.5+mm_chunk_y);\n"
	shader_source += "\tvec2 uv = pixel/imageSize(OUTPUT_TEXTURE);\n"
	if shader_code.code != "":
		shader_source += "\t"+shader_code.code
	shader_source += "\tvec4 outColor = "+shader_code.output_values.rgba+";\n"
	shader_source += "\timageStore(OUTPUT_TEXTURE, ivec2(pixel), outColor);\n"
	if compare_texture != null:
		shader_source += "\tvec4 diff_vec = abs(outColor - texture(mm_compare, uv));\n"
		shader_source += "\tfloat diff = max(max(diff_vec.r, diff_vec.g), max(diff_vec.b, diff_vec.a));\n"
		shader_source += "\tatomicMax(mm_out.mm_compare[0], int(diff*65536.0));\n"
	shader_source += "}\n"
	
	compile_shader()

func get_parameters() -> Dictionary:
	var rv : Dictionary = {}
	for p in parameters.keys():
		rv[p] = parameters[p].value
	for t in texture_indexes.keys():
		rv[t] = textures[texture_indexes[t]].texture
	return rv

func set_parameter(name : String, value) -> void:
	if value == null or !parameters.has(name):
		print("Cannot set parameter "+name)
		return
	var p : Parameter = parameters[name]
	p.value = value
	match p.type:
		"float":
			if value is float:
				parameter_values.encode_float(p.offset, value)
				return
		"vec4":
			if value is Color:
				parameter_values.encode_float(p.offset,    value.r)
				parameter_values.encode_float(p.offset+4,  value.g)
				parameter_values.encode_float(p.offset+8,  value.b)
				parameter_values.encode_float(p.offset+12, value.a)
				return
	print("Unsupported value %s for parameter %s of type %s" % [ str(value), name, p.type ])

func render(texture : MMTexture, size : int) -> bool:
	if ! shader.is_valid():
		render_time = 0
		print("shader is invalid")
		return false
	var rids : Dictionary = {}
	var rd : RenderingDevice = await mm_renderer.request_rendering_device(self)
	var outputs : PackedByteArray
	
	diff = 65536
	
	#print("Preparing render")
	
	var start_time = Time.get_ticks_msec()
	
	#print("Preparing target texture")
	
	var fmt : RDTextureFormat = RDTextureFormat.new()
	fmt.width = size
	fmt.height = size
	fmt.format = TEXTURE_TYPE[texture_type].data_format
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var view : RDTextureView = RDTextureView.new()
	
	var output_tex : RID = rd.texture_create(fmt, view, PackedByteArray())
	var output_tex_uniform : RDUniform = RDUniform.new()
	output_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_tex_uniform.binding = 0
	output_tex_uniform.add_id(output_tex)
	var uniform_set_0 : RID = rd.uniform_set_create([output_tex_uniform], shader, 0)
	rids[uniform_set_0] = "uniform_set_0"
	rids[uniform_set_0] = "output_tex"
	
	var uniform_set_1 : RID = RID()
	if parameter_values.size() > 0:
		var parameters_buffer : RID = rd.storage_buffer_create(parameter_values.size(), parameter_values)
		var parameters_uniform : RDUniform = RDUniform.new()
		parameters_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		parameters_uniform.binding = 0
		parameters_uniform.add_id(parameters_buffer)
		uniform_set_1 = rd.uniform_set_create([parameters_uniform], shader, 1)
		rids[uniform_set_1] = "uniform_set_1"
		rids[parameters_buffer] = "parameters_buffer"
	
	var uniform_set_2 = RID()
	if !textures.is_empty():
		var sampler_state : RDSamplerState = RDSamplerState.new()
		sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
		sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
		sampler_state.mip_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
		var sampler : RID = rd.sampler_create(sampler_state)
		rids[sampler] = "sampler"
		var sampler_uniform_array : Array = []
		for i in textures.size():
			var tex : RID = textures[i].texture.get_texture_rid(rd)
			var sampler_uniform : RDUniform = RDUniform.new()
			sampler_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
			sampler_uniform.binding = i
			sampler_uniform.add_id(sampler)
			sampler_uniform.add_id(tex)
			sampler_uniform_array.append(sampler_uniform)
		uniform_set_2 = rd.uniform_set_create(sampler_uniform_array, shader, 2)
		rids[uniform_set_2] = "uniform_set_2"
	
	var uniform_set_4 = RID()
	var outputs_buffer : RID
	if texture_indexes.has("mm_compare"):
		outputs = PackedInt32Array([0]).to_byte_array()
		outputs_buffer = rd.storage_buffer_create(outputs.size(), outputs)
		rids[outputs_buffer] = "outputs_buffer"
		var outputs_uniform : RDUniform = RDUniform.new()
		outputs_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		outputs_uniform.binding = 0
		outputs_uniform.add_id(outputs_buffer)
		uniform_set_4 = rd.uniform_set_create([outputs_uniform], shader, 4)
		rids[uniform_set_4] = "uniform_set_4"
	
	var chunk_count : int = max(1, size*size/(512*512))
	var chunk_height : int = max(1, size/chunk_count)
	
	var y : int = 0
	while y < size:
		var h : int = min(chunk_height, size-y)
		
		# Create a compute pipeline
		var pipeline : RID = rd.compute_pipeline_create(shader)
		if !pipeline.is_valid():
			print("Cannot create pipeline")
		var compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		rd.compute_list_bind_uniform_set(compute_list, uniform_set_0, 0)
		if uniform_set_1.is_valid():
			rd.compute_list_bind_uniform_set(compute_list, uniform_set_1, 1)
		if uniform_set_2.is_valid():
			rd.compute_list_bind_uniform_set(compute_list, uniform_set_2, 2)
		
		var loop_parameters_values : PackedByteArray = PackedByteArray()
		loop_parameters_values.resize(4)
		loop_parameters_values.encode_s32(0, y)
		var loop_parameters_buffer : RID = rd.storage_buffer_create(loop_parameters_values.size(), loop_parameters_values)
		var loop_parameters_uniform : RDUniform = RDUniform.new()
		loop_parameters_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		loop_parameters_uniform.binding = 0
		loop_parameters_uniform.add_id(loop_parameters_buffer)
		var uniform_set_3 : RID = rd.uniform_set_create([loop_parameters_uniform], shader, 3)
		rd.compute_list_bind_uniform_set(compute_list, uniform_set_3, 3)
		
		if uniform_set_4.is_valid():
			rd.compute_list_bind_uniform_set(compute_list, uniform_set_4, 4)
		
		#print("Dispatching compute list")
		rd.compute_list_dispatch(compute_list, size, h, 1)
		rd.compute_list_end()
		#print("Rendering "+str(self))
		rd.submit()
		await mm_renderer.get_tree().process_frame
		rd.sync()
		
		rd.free_rid(uniform_set_3)
		rd.free_rid(loop_parameters_buffer)
		rd.free_rid(pipeline)
		
		#print("End rendering %d-%d (%dms)" % [ y, y+h, render_time ])
		
		y += h
	
	#var byte_data : PackedByteArray = rd.texture_get_data(output_tex, 0)
	#var image : Image = Image.create_from_data(size, size, false, TEXTURE_TYPE[texture_type].image_format, byte_data)
	#texture.set_image(image)
	
	if uniform_set_4.is_valid():
		outputs = rd.buffer_get_data(outputs_buffer)
		diff = outputs.to_int32_array()[0]
	
	texture.set_texture_rid(output_tex, Vector2i(size, size), TEXTURE_TYPE[texture_type].data_format)
	for r in rids.keys():
		if r.is_valid():
			#print("Freeing %s: %s" % [ str(r), rids[r] ])
			rd.free_rid(r)
		else:
			print("Bad rid for "+rids[r])
	
	render_time = Time.get_ticks_msec() - start_time
	
	mm_renderer.release_rendering_device(self)

	return true

func get_difference() -> int:
	return diff
