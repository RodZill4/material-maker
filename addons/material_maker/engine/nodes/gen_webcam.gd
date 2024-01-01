@tool
extends MMGenBase
class_name MMGenWebcam


# Texture generator from camera


class MMCameraTexture:
	extends MMTexture
	
	func _init(webcam : int, feed : int = 0):
		texture = CameraTexture.new()
		set_webcam(webcam, feed)
	
	func set_webcam(webcam : int, feed : int = 0):
		var camfeed = CameraServer.feeds()[webcam]
		print(camfeed.get_datatype())
		texture.camera_feed_id = camfeed.get_id()
		texture.camera_is_active = true
		texture.which_feed = feed

	func get_texture_rid(target_rd : RenderingDevice) -> RID:
		return RID()

	func set_texture_rid(new_rid : RID, size : Vector2i, format : RenderingDevice.DataFormat, new_rd : RenderingDevice) -> void:
		pass
	
	func get_texture() -> Texture2D:
		return texture
	
	func set_texture(new_texture : Texture2D) -> void:
		pass
	

var webcam : int = 0
var texture : MMCameraTexture
var texture_1 : MMCameraTexture


func _ready() -> void:
	texture = MMCameraTexture.new(webcam)
	texture_1 = MMCameraTexture.new(webcam, 1)

func get_type() -> String:
	return "webcam"

func get_type_name() -> String:
	return "Webcam"

func get_parameter_defs() -> Array:
	var feeds : Array[Dictionary] = []
	for f in CameraServer.feeds():
		feeds.append({name=f.get_name(), value=str(f.get_id())})
	return [
				{ name="webcam", type="enum", label="", values=feeds, default=0 },
	]

func set_parameter(n : String, v) -> void:
	super.set_parameter(n, v)
	if n == "webcam":
		print("camera: "+str(v))
		webcam = v
		if texture:
			texture.set_webcam(webcam)
			texture_1.set_webcam(webcam, 1)

func get_output_defs(_show_hidden : bool = false) -> Array:
	return [ { type="rgb" } ]

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> ShaderCode:
	var genname = "o"+str(get_instance_id())
	var rv = ShaderCode.new()
	rv.output_type = "rgb"
	var texture_name = genname+"_tex"
	var variant_index = context.get_variant(self, uv)
	var type = "vec3"
	var ycbcr_matrix = "mat3(vec3(1.00000, 1.00000, 1.00000), vec3(0.00000, -0.18732, 1.85560), vec3(1.57481, -0.46813, 0.00000))"
	if variant_index == -1:
		variant_index = context.get_variant(self, uv)
		rv.add_uniform(texture_name+"_0", "sampler2D", texture)	
		rv.add_uniform(texture_name+"_1", "sampler2D", texture_1)
		rv.code = "vec3 %s_%d = %s*vec3(textureLod(%s_0, %s, 0.0).r, textureLod(%s_1, %s, 0.0).rg-vec2(0.5));\n" % [ genname, variant_index, ycbcr_matrix, texture_name, uv, texture_name, uv ]
	rv.output_values[rv.output_type] = "%s_%d" % [ genname, variant_index ]
	mm_deps.dependency_update(texture_name+"_0", texture)
	mm_deps.dependency_update(texture_name+"_1", texture_1)
	return rv

func _serialize(data: Dictionary) -> Dictionary:
	return data

func _serialize_data(data: Dictionary) -> Dictionary:
	return data

func _deserialize(data : Dictionary) -> void:
	pass
