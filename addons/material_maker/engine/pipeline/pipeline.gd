extends RefCounted
class_name MMPipeline


const SIZE_FROM_TYPE : Dictionary = { bool=4, int=4, float=4, vec2=8, vec3=16, vec4=16, mat4x4=64 }


class Parameter:
	extends RefCounted
	
	var type : String
	var array_size : int
	var offset : int
	var size : int
	var value
	
	func _init(t : String, v = null, s : int = 0):
		var bracket_position = t.find("[")
		if bracket_position != -1:
			array_size = t.substr(bracket_position+1, t.find("]", bracket_position+1)).to_int()
			type = t.left(bracket_position)
		else:
			type = t
			array_size = 0
		if s > 0:
			array_size = s if array_size == 0 else array_size*s
		offset = 0
		size = SIZE_FROM_TYPE[type] if SIZE_FROM_TYPE.has(type) else 0
		value = v

class InputTexture:
	extends RefCounted
	
	var name : String
	var texture : MMTexture
	
	func _init(n : String, t : MMTexture):
		name = n
		texture = t

class RIDs:
	extends RefCounted
	
	var rids : Dictionary
	
	func add(rid : RID, description : String = ""):
		if rid.is_valid():
			if rids.has(rid):
				push_error("ERROR: RID %s stored twice (%s)" % [ rid, description ])
			else:
				rids[rid] = description
		else:
			print("RID is invalid")
	
	func free_rids(rd : RenderingDevice):
		for r in rids.keys():
			if r.is_valid():
				#push_warning("Freeing RID %s (%s)" % [ str(r), rids[r] ])
				rd.free_rid(r)

const TEXTURE_TYPE_R16F    : int = 0
const TEXTURE_TYPE_RGBA16F : int = 1
const TEXTURE_TYPE_R32F    : int = 2
const TEXTURE_TYPE_RGBA32F : int = 3
const TEXTURE_TYPE_DEPTH   : int = 4
const TEXTURE_TYPE : Array[Dictionary] = [
	{ decl="r16f", data_format=RenderingDevice.DATA_FORMAT_R16_SFLOAT, image_format=Image.FORMAT_RH, channels=1, bytes_per_channel=2 },
	{ decl="rgba16f", data_format=RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT, image_format=Image.FORMAT_RGBAH, channels=4, bytes_per_channel=2 },
	{ decl="r32f", data_format=RenderingDevice.DATA_FORMAT_R32_SFLOAT, image_format=Image.FORMAT_RF, channels=1, bytes_per_channel=4 },
	{ decl="rgba32f", data_format=RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT, image_format=Image.FORMAT_RGBAF, channels=4, bytes_per_channel=4 },
	{ decl="r32f", data_format=RenderingDevice.DATA_FORMAT_D32_SFLOAT, image_format=Image.FORMAT_RF, channels=1, bytes_per_channel=4 }
]


var parameters : Dictionary
var parameter_values : PackedByteArray

var constants : Dictionary

var input_texture_indexes : Dictionary
var input_textures : Array[InputTexture]

var time_current_desc : String = ""
var time_current_time : int = 0

var output_parameters : Dictionary

func time(desc : String = ""):
	return
	if time_current_desc != "":
		print("time(%s): %dms" % [ time_current_desc, Time.get_ticks_msec()-time_current_time ])
	time_current_desc = desc
	time_current_time = Time.get_ticks_msec()

func clear():
	parameters = {}
	constants = {}
	parameter_values = PackedByteArray()
	input_texture_indexes = {}
	input_textures = []
	output_parameters = {}

func do_compile_shader(rd : RenderingDevice, shader_text : Dictionary, replaces : Dictionary) -> RID:
	var errors : bool = false
	var src : RDShaderSource = RDShaderSource.new()
	for k in shader_text.keys():
		src["source_"+k] = mm_preprocessor.preprocess(shader_text[k], replaces)
	var spirv : RDShaderSPIRV = rd.shader_compile_spirv_from_source(src)
	var shader : RID = RID()
	for k in shader_text.keys():
		var error : String = spirv["compile_error_"+k]
		if error != "":
			mm_renderer.shader_error_handler.on_error(src["source_"+k], error)
			var ln : int = 0
			for l in src["source_"+k].split("\n"):
				ln += 1
				print("%4d: %s" % [ ln, l ])
			print(k.to_upper()+" SHADER ERROR: "+error)
			errors = true
	if ! errors:
		shader = rd.shader_create_from_spirv(spirv)
		if not shader.is_valid():
			print("Error creating shader from spirv")
	return shader

func add_parameter_or_texture(name : String, type : String, value, parameter_as_constant : bool = false, array_size : int = 0):
	if type == "sampler2D":
		if input_texture_indexes.has(name):
			print("ERROR: Redefining texture "+name)
			input_textures[input_texture_indexes[name]] = InputTexture.new(name, value)
		else:
			input_texture_indexes[name] = input_textures.size()
			input_textures.append(InputTexture.new(name, value))
	elif parameter_as_constant:
		if constants.has(name):
			print("ERROR: Redefining constant "+name)
		constants[name] = Parameter.new(type, value)
	else:
		if parameters.has(name):
			print("ERROR: Redefining parameter "+name)
		parameters[name] = Parameter.new(type, value, array_size)

func add_output_parameter(name : String, type : String, array_size : int = 0):
	output_parameters[name] = Parameter.new(type, null, array_size)

static func set_parameter_value_to_buffer(parameter : Parameter, buffer : PackedByteArray, value) -> bool:
	match parameter.type:
		"bool":
			if value is bool:
				buffer.encode_s32(parameter.offset, -1 if value else 0)
				return true
		"int":
			if value is int:
				buffer.encode_s32(parameter.offset, value)
				return true
			elif value is PackedInt32Array and value.size() == parameter.array_size:
				for i in value.size():
					buffer.encode_s32(parameter.offset+i*4, value[i])
				return true
		"float":
			if value is float or value is int:
				buffer.encode_float(parameter.offset, value)
				return true
			elif value is PackedFloat32Array and value.size() == parameter.array_size:
				for i in value.size():
					buffer.encode_float(parameter.offset+i*4, value[i])
				return true
		"vec2":
			if value is Vector2 or value is Vector2i:
				buffer.encode_float(parameter.offset,    value.x)
				buffer.encode_float(parameter.offset+4,  value.y)
				return true
			elif value is PackedVector2Array and value.size() == parameter.array_size:
				for i in value.size():
					buffer.encode_float(parameter.offset+i*8, value[i].x)
					buffer.encode_float(parameter.offset+i*8+4, value[i].y)
				return true
			elif value is PackedFloat32Array and value.size() == 2*parameter.array_size:
				for i in value.size():
					buffer.encode_float(parameter.offset+i*4, value[i])
				return true
		"vec3":
			if value is Vector3:
				buffer.encode_float(parameter.offset,    value.x)
				buffer.encode_float(parameter.offset+4,  value.y)
				buffer.encode_float(parameter.offset+8,  value.z)
				return true
		"vec4":
			if value is Color:
				buffer.encode_float(parameter.offset,    value.r)
				buffer.encode_float(parameter.offset+4,  value.g)
				buffer.encode_float(parameter.offset+8,  value.b)
				buffer.encode_float(parameter.offset+12, value.a)
				return true
			elif value is PackedColorArray and value.size() == parameter.array_size:
				for i in value.size():
					buffer.encode_float(parameter.offset+i*16,    value[i].r)
					buffer.encode_float(parameter.offset+i*16+4,  value[i].g)
					buffer.encode_float(parameter.offset+i*16+8,  value[i].b)
					buffer.encode_float(parameter.offset+i*16+12, value[i].a)
				return true
			elif value is PackedFloat32Array and value.size() == 4*parameter.array_size:
				for i in value.size():
					buffer.encode_float(parameter.offset+i*4, value[i])
				return true
		"mat4x4":
			if value is Projection:
				var offset : int = parameter.offset
				if buffer.size() < offset+16:
					print("Ack!")
				for v in [ value.x, value.y, value.z, value.w ]:
					for f in [ v.x, v.y, v.z, v.w ]:
						buffer.encode_float(offset, f)
						offset += 4
				return true
	return false

static func get_parameter_value_from_buffer(parameter : Parameter, buffer : PackedByteArray, format : String = "") -> Variant:
	var array_size : int = parameter.array_size
	var type : String = parameter.type
	if format != "":
		if type == "float" and format == "vec3":
			type = "vec3"
			array_size /= 3
		elif type == "float" and format == "vec2":
			type = "vec2"
			array_size /= 2
	match type:
		"bool":
			var value : bool = false if buffer.decode_s32(parameter.offset) == 0 else true
			return value
		"int":
			if array_size == 0:
				return buffer.decode_s32(parameter.offset)
			var ba : PackedByteArray = buffer.slice(parameter.offset, parameter.offset+4*array_size)
			return ba.to_int32_array()
		"float":
			if array_size == 0:
				return buffer.decode_float(parameter.offset)
			var ba : PackedByteArray = buffer.slice(parameter.offset, parameter.offset+4*array_size)
			return ba.to_float32_array()
		"vec2":
			if array_size == 0:
				var value : Vector2
				value.x = buffer.decode_float(parameter.offset)
				value.y = buffer.decode_float(parameter.offset+4)
				return value
			if false:
				var value : PackedVector2Array = PackedVector2Array()
				value.resize(array_size)
				for i in array_size:
					value[i].x = buffer.decode_float(parameter.offset+i*8)
					value[i].y = buffer.decode_float(parameter.offset+i*8+4)
				return value
			else:
				var ba : PackedByteArray = PackedByteArray()
				ba.resize(8)
				ba.encode_u32(0, TYPE_PACKED_VECTOR2_ARRAY)
				ba.encode_u32(4, array_size)
				ba.append_array(buffer.slice(parameter.offset, parameter.offset+8*array_size))
				return ba.decode_var(0)
		"vec3":
			if array_size == 0:
				var value : Vector3
				value.x = buffer.decode_float(parameter.offset)
				value.y = buffer.decode_float(parameter.offset+4)
				value.z = buffer.decode_float(parameter.offset+8)
				return value
			if false:
				var value : PackedVector3Array = PackedVector3Array()
				value.resize(array_size)
				for i in array_size:
					value[i].x = buffer.decode_float(parameter.offset+i*12)
					value[i].y = buffer.decode_float(parameter.offset+i*12+4)
					value[i].z = buffer.decode_float(parameter.offset+i*12+8)
				return value
			else:
				var ba : PackedByteArray = PackedByteArray()
				ba.resize(8)
				ba.encode_u32(0, TYPE_PACKED_VECTOR3_ARRAY)
				ba.encode_u32(4, array_size)
				ba.append_array(buffer.slice(parameter.offset, parameter.offset+12*array_size))
				return ba.decode_var(0)
		"vec4":
			if array_size == 0:
				var value : Color
				value.r = buffer.decode_float(parameter.offset)
				value.g = buffer.decode_float(parameter.offset+4)
				value.b = buffer.decode_float(parameter.offset+8)
				value.a = buffer.decode_float(parameter.offset+12)
				return value
			var value : PackedColorArray = PackedColorArray()
			value.resize(array_size)
			for i in array_size:
				value[i].r = buffer.decode_float(parameter.offset+i*16)
				value[i].g = buffer.decode_float(parameter.offset+i*16+4)
				value[i].b = buffer.decode_float(parameter.offset+i*16+8)
				value[i].a = buffer.decode_float(parameter.offset+i*16+12)
			return value
		"mat4x4":
			if array_size == 0:
				var offset : int = parameter.offset
				var value : Projection
				value.x.x = buffer.decode_float(parameter.offset)
				value.x.y = buffer.decode_float(parameter.offset+4)
				value.x.z = buffer.decode_float(parameter.offset+8)
				value.x.w = buffer.decode_float(parameter.offset+12)
				value.y.x = buffer.decode_float(parameter.offset+16)
				value.y.y = buffer.decode_float(parameter.offset+20)
				value.y.z = buffer.decode_float(parameter.offset+24)
				value.y.w = buffer.decode_float(parameter.offset+28)
				value.z.x = buffer.decode_float(parameter.offset+32)
				value.z.y = buffer.decode_float(parameter.offset+36)
				value.z.z = buffer.decode_float(parameter.offset+40)
				value.z.w = buffer.decode_float(parameter.offset+44)
				value.w.x = buffer.decode_float(parameter.offset+48)
				value.w.y = buffer.decode_float(parameter.offset+52)
				value.w.z = buffer.decode_float(parameter.offset+56)
				value.w.w = buffer.decode_float(parameter.offset+60)
				return value
	return false

func set_parameter(name : String, value, silent : bool = false) -> void:
	if parameters.has(name):
		if value == null:
			print("Cannot assign null value to parameter "+name)
			return
		var parameter : Parameter = parameters[name]
		parameter.value = value
		if not set_parameter_value_to_buffer(parameter, parameter_values, value):
			print("Unsupported value %s for parameter %s of type %s" % [ str(value), name, parameter.type ])
	elif input_texture_indexes.has(name):
		var texture_index : int = input_texture_indexes[name]
		input_textures[texture_index].texture = value
	elif not silent:
		print("Cannot assign parameter "+name)

static func get_parameter_declarations(defs : Dictionary, values = null) -> String:
	var uniform_declarations : String = ""
	var size : int = 0
	for type in [ "mat4x4", "vec4", "vec3", "vec2", "float", "int", "bool" ]:
		for p in defs.keys():
			var parameter : Parameter = defs[p]
			if parameter.type != type:
				continue
			var array : String = ""
			if parameter.array_size > 0:
				array = "[%d]" % parameter.array_size
			uniform_declarations += "\t%s %s%s;\n" % [ parameter.type, p, array ]
			parameter.offset = size
			if parameter.array_size == 0:
				size += parameter.size
			else:
				size += parameter.size*parameter.array_size
	if values != null and size > 0:
		values.resize(size)
	return uniform_declarations

func get_uniform_declarations() -> String:
	var uniform_declarations : String = get_parameter_declarations(parameters, parameter_values)
	if uniform_declarations != "":
		uniform_declarations = "layout(set = 1, binding = 0, std430) restrict readonly buffer Parameters {\n"+uniform_declarations+"};\n"
		for p in parameters.keys():
			set_parameter(p, parameters[p].value)
	if ! constants.is_empty():
		uniform_declarations += "\n"
		for c in constants.keys():
			var constant : Parameter = constants[c]
			var shader_uniform : MMGenBase.ShaderUniform = MMGenBase.ShaderUniform.new(c, constant.type, constant.value, constant.array_size)
			uniform_declarations += shader_uniform.to_str("const", true)
	return uniform_declarations

func get_input_texture_declarations() -> String:
	var texture_declarations : String = ""
	for ti in input_textures.size():
		var t : InputTexture = input_textures[ti]
		texture_declarations += "layout(set = 2, binding = %d) uniform sampler2D %s;\n" % [ ti, t.name ]
	return texture_declarations

func get_output_parameters_declarations() -> String:
	var output_parameters_declarations : String = get_parameter_declarations(output_parameters)
	if output_parameters_declarations != "":
		output_parameters_declarations = "layout(set = 4, binding = 0, std430) buffer MMout {\n"+output_parameters_declarations+"} mm_out;\n"
	return output_parameters_declarations

func create_texture(rd : RenderingDevice, texture_size : Vector2i, texture_type : int, usage_bits : int):
	if texture_size.x == 0 or texture_size.y == 0:
		return RID()
	var fmt : RDTextureFormat = RDTextureFormat.new()
	var texture_type_struct : Dictionary = TEXTURE_TYPE[texture_type]
	fmt.width = texture_size.x
	fmt.height = texture_size.y
	fmt.format = texture_type_struct.data_format
	fmt.usage_bits = usage_bits
	fmt.texture_type = RenderingDevice.TEXTURE_TYPE_2D
		
	var view : RDTextureView = RDTextureView.new()

	return rd.texture_create(fmt, view, [])

func create_output_texture(rd : RenderingDevice, texture_size : Vector2i, texture_type : int, is_framebuffer : bool = false) -> RID:
	var usage_bits : int
	if is_framebuffer:
		usage_bits =  RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	else:
		usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	return create_texture(rd, texture_size, texture_type, usage_bits)

func create_depth_texture(rd : RenderingDevice, texture_size : Vector2i) -> RID:
	return create_texture(rd, texture_size, TEXTURE_TYPE_DEPTH, RenderingDevice.TEXTURE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT)

func get_parameter_uniforms(rd : RenderingDevice, shader : RID, rids : RIDs) -> RID:
	var parameters_buffer : RID = rd.storage_buffer_create(parameter_values.size(), parameter_values)
	var parameters_uniform : RDUniform = RDUniform.new()
	parameters_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	parameters_uniform.binding = 0
	parameters_uniform.add_id(parameters_buffer)
	var uniform_set : RID = rd.uniform_set_create([parameters_uniform], shader, 1)
	rids.add(uniform_set)
	rids.add(parameters_buffer, "parameters_buffer")
	return uniform_set

func get_texture_uniforms(rd : RenderingDevice, shader : RID, rids : RIDs) -> RID:
	if input_textures.is_empty():
		return RID()
	var sampler_state : RDSamplerState = RDSamplerState.new()
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_state.mip_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	var sampler : RID = rd.sampler_create(sampler_state)
	rids.add(sampler, "sampler")
	var sampler_uniform_array : Array = []
	for i in input_textures.size():
		var tex : RID
		if input_textures[i].texture:
			tex = input_textures[i].texture.get_texture_rid(rd)
		if ! tex.is_valid():
			print("Invalid texture "+str(tex))
		var sampler_uniform : RDUniform = RDUniform.new()
		sampler_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
		sampler_uniform.binding = i
		sampler_uniform.add_id(sampler)
		sampler_uniform.add_id(tex)
		sampler_uniform_array.append(sampler_uniform)
	var uniform_set : RID = rd.uniform_set_create(sampler_uniform_array, shader, 2)
	#rids.add(uniform_set)
	return uniform_set

func create_buffers_uniform_list(rd : RenderingDevice, buffers : Array[PackedByteArray], rids : RIDs) -> Array[RDUniform]:
	var uniform_list : Array[RDUniform] = []
	var binding : int = 0
	for b in buffers:
		var buffer : RID = rd.storage_buffer_create(b.size(), b)
		rids.add(buffer, "buffer")
		var uniform : RDUniform = RDUniform.new()
		uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		uniform.binding = binding
		uniform.add_id(buffer)
		binding += 1
		uniform_list.append(uniform)
	return uniform_list
