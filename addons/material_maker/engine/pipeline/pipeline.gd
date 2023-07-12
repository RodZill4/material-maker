extends RefCounted
class_name MMPipeline


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
			"int":
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

class RIDs:
	extends RefCounted
	
	var rendering_device : RenderingDevice
	var rids : Array[RID] = []
	
	func _init(rd : RenderingDevice):
		rendering_device = rd
	
	func add(rid : RID):
		if rid.is_valid():
			if rids.find(rid) != -1:
				print("ERROR: RID stored twice")
			else:
				rids.append(rid)
		else:
			print("RID is invalid")
	
	func free_rids():
		for r in rids:
			rendering_device.free_rid(r)

const TEXTURE_TYPE : Array[Dictionary] = [
	{ decl="r16f", data_format=RenderingDevice.DATA_FORMAT_R16_SFLOAT, image_format=Image.FORMAT_RH },
	{ decl="rgba16f", data_format=RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT, image_format=Image.FORMAT_RGBAH },
	{ decl="r32f", data_format=RenderingDevice.DATA_FORMAT_R32_SFLOAT, image_format=Image.FORMAT_RF },
	{ decl="rgba32f", data_format=RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT, image_format=Image.FORMAT_RGBAF }
]


var parameters : Dictionary
var parameter_values : PackedByteArray

var texture_indexes : Dictionary
var textures : Array[InputTexture]


func clear():
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

func set_parameter(name : String, value) -> void:
	if parameters.has(name):
		if value == null:
			print("Cannot assign null value to parameter "+name)
			return
		var p : Parameter = parameters[name]
		p.value = value
		match p.type:
			"float":
				if value is float:
					parameter_values.encode_float(p.offset, value)
					return
			"int":
				if value is int:
					parameter_values.encode_s32(p.offset, value)
					return
			"vec4":
				if value is Color:
					parameter_values.encode_float(p.offset,    value.r)
					parameter_values.encode_float(p.offset+4,  value.g)
					parameter_values.encode_float(p.offset+8,  value.b)
					parameter_values.encode_float(p.offset+12, value.a)
					return
		print("Unsupported value %s for parameter %s of type %s" % [ str(value), name, p.type ])
	elif texture_indexes.has(name):
		var texture_index : int = texture_indexes[name]
		textures[texture_index].texture = value
	else:
		print("Cannot assign parameter "+name)

func get_uniform_declarations() -> String:
	var uniform_declarations : String = ""
	var size : int = 0
	for type in [ "vec4", "float", "int" ]:
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

func create_output_texture(rd : RenderingDevice, texture_size : Vector2i, texture_type : int) -> RID:
	var fmt : RDTextureFormat = RDTextureFormat.new()
	fmt.width = texture_size.x
	fmt.height = texture_size.y
	fmt.format = TEXTURE_TYPE[texture_type].data_format
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var view : RDTextureView = RDTextureView.new()
	
	return rd.texture_create(fmt, view, PackedByteArray())

func get_parameter_uniforms(rd : RenderingDevice, shader : RID, rids : RIDs) -> RID:
	var parameters_buffer : RID = rd.storage_buffer_create(parameter_values.size(), parameter_values)
	var parameters_uniform : RDUniform = RDUniform.new()
	parameters_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	parameters_uniform.binding = 0
	parameters_uniform.add_id(parameters_buffer)
	var uniform_set : RID = rd.uniform_set_create([parameters_uniform], shader, 1)
	rids.add(uniform_set)
	rids.add(parameters_buffer)
	return uniform_set

func get_texture_uniforms(rd : RenderingDevice, shader : RID, rids : RIDs) -> RID:
	var sampler_state : RDSamplerState = RDSamplerState.new()
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_state.mip_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	var sampler : RID = rd.sampler_create(sampler_state)
	rids.add(sampler)
	var sampler_uniform_array : Array = []
	for i in textures.size():
		var tex : RID = textures[i].texture.get_texture_rid(rd)
		if ! tex.is_valid():
			print("Invalid texture")
		var sampler_uniform : RDUniform = RDUniform.new()
		sampler_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
		sampler_uniform.binding = i
		sampler_uniform.add_id(sampler)
		sampler_uniform.add_id(tex)
		sampler_uniform_array.append(sampler_uniform)
	var uniform_set = rd.uniform_set_create(sampler_uniform_array, shader, 2)
	if uniform_set.is_valid():
		rids.add(uniform_set)
	return uniform_set
