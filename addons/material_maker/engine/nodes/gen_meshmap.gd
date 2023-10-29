@tool
extends MMGenBase
class_name MMGenMeshMap


# Texture generator from mesh map


var timer : Timer
var filetime : int = 0
var current_mesh : Mesh = null
var current_map : MMTexture = null
var texture : MMTexture


const MESH_MAPS : Array[Dictionary] = [
	{
		name="Position",
		output_type="rgb",
		map="position",
		output="$AABB_POSITION+$AABB_SIZE*texture($TEXTURE, $UV).rgb"
	},
	{
		name="Normal",
		output_type="rgb",
		map="normal",
		output="2.0*texture($TEXTURE, $UV).rgb-vec3(1.0)"
	},
	{
		name="Tangent",
		output_type="rgb",
		map="tangent",
		output="2.0*texture($TEXTURE, $UV).rgb-vec3(1.0)"
	},
	{
		name="Occlusion",
		output_type="f",
		map="ambient_occlusion",
		output="texture($TEXTURE, $UV).r"
	}
]


func _ready() -> void:
	if get_parent() is MMGenGraph:
		set_current_mesh(get_parent().get_current_mesh())

func get_type() -> String:
	return "meshmap"

func get_type_name() -> String:
	return "Mesh Map"

func get_parameter_defs() -> Array:
	return [
		{ name="map", type="enum", values=MESH_MAPS, label="Map", default=0 },
	]

func set_parameter(n : String, v) -> void:
	super.set_parameter(n, v)
	if n == "map" and current_mesh:
		current_map = await MMMapGenerator.get_map(current_mesh, MESH_MAPS[v].map)
		notify_output_change(0)
		mm_deps.dependency_update(get_texture_parameter_name(), current_map, true)

func get_output_defs(_show_hidden : bool = false) -> Array:
	return [ { type=MESH_MAPS[get_parameter("map")].output_type } ]

func set_current_mesh(m : Mesh) -> void:
	if current_mesh != m:
		current_mesh = m
		if current_mesh:
			current_map = await MMMapGenerator.get_map(current_mesh, MESH_MAPS[get_parameter("map")].map)
			notify_output_change(0)
			mm_deps.dependency_update(get_texture_parameter_name(), current_map, true)

func get_texture_parameter_name() -> String:
	var mesh_id : String = "nomesh"
	if current_mesh:
		mesh_id = "mesh_%d" % abs(current_mesh.get_instance_id())
	return mesh_id+"_"+MESH_MAPS[get_parameter("map")].map

func _get_shader_code(uv : String, output_index : int, context : MMGenContext) -> ShaderCode:
	var genname : String = "o"+str(get_instance_id())
	var rv = ShaderCode.new()
	var map_index = get_parameter("map")
	rv.output_type = MESH_MAPS[map_index].output_type
	var texture_name = get_texture_parameter_name()
	var type = mm_io_types.types[rv.output_type].type
	var variant_index = context.get_variant(self, uv)
	if variant_index == -1:
		variant_index = context.get_variant(self, uv)
		rv.add_uniform(texture_name, "sampler2D", current_map)
		print(current_map)
		var code : String = MESH_MAPS[map_index].output
		code = code.replace("$TEXTURE", texture_name)
		code = code.replace("$UV", uv)
		if current_mesh:
			var aabb : AABB = current_mesh.get_aabb()
			code = code.replace("$AABB_POSITION", "vec3(%.09f, %.09f, %.09f)" % [aabb.position.x, aabb.position.y, aabb.position.z])
			code = code.replace("$AABB_SIZE", "vec3(%.09f, %.09f, %.09f)" % [aabb.size.x, aabb.size.y, aabb.size.z])
		rv.code = "%s %s_%d = %s;\n" % [ type, genname, variant_index, code ]
	rv.output_values[rv.output_type] = "%s_%d" % [ genname, variant_index ]
	return rv

func _serialize(data: Dictionary) -> Dictionary:
	return data

func _serialize_data(data: Dictionary) -> Dictionary:
	return data

func _deserialize(data : Dictionary) -> void:
	pass
