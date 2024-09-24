extends Node

var shader : MMComputeShader = MMComputeShader.new()
var size : int = 2

@onready var generated_mesh = $Pivot/MeshInstance
@onready var plane = $Pivot/Plane

# Called when the node enters the scene tree for the first time.
func _ready():
	var w : Window = get_window()
	w.borderless = false
	w.size = Vector2i(800, 600)
	w.move_to_center()
	await setup_shader()
	await generate_mesh()

func get_expression_value_from_string(string : String, prefix: String, values: Dictionary) -> int:
	var begin : int = string.find(prefix)
	if begin == -1:
		return 0
	begin += prefix.length()
	var end : int = string.find("\n", begin)
	var expression_string : String = string.substr(begin, end-begin)
	var expression : Expression = Expression.new()
	var input_names : PackedStringArray = PackedStringArray()
	var input_values : Array = []
	for k in values.keys():
		input_names.append(k)
		input_values.append(values[k])
	expression.parse(expression_string, input_names)
	var rv : int = expression.execute(input_values)
	print(prefix+" "+str(rv))
	return rv

func setup_shader():
	var string : String = FileAccess.open("res://material_maker/panels/preview_3d/meshes/compute_plane.txt", FileAccess.READ).get_as_text()
	var vertex_count : int = get_expression_value_from_string(string, "// VERTEX COUNT:", {size=size})
	var index_count : int = get_expression_value_from_string(string, "// INDEX COUNT:", {size=size})
	shader.local_size = size if size < 32 else 32
	shader.clear()
	shader.add_parameter_or_texture("size", "int", size)
	shader.add_parameter_or_texture("curvature", "float", 0.0)
	shader.add_output_parameter("vertices", "float", 3*vertex_count)
	shader.add_output_parameter("normals", "float", 3*vertex_count)
	shader.add_output_parameter("tangents", "float", 4*vertex_count)
	shader.add_output_parameter("tex_uvs", "float", 2*vertex_count)
	shader.add_output_parameter("indexes", "int", index_count)
	await shader.set_shader_ext(string)

func generate_mesh():
	var opv : Dictionary = { vertices_format="vec3", normals_format="vec3", tex_uvs_format="vec2" }
	shader.set_parameter("size", size)
	shader.set_parameter("curvature", $UI/VBoxContainer/Curvature.value)
	await shader.render_ext([], Vector2i(size, size), opv)
	var mesh : ArrayMesh = generated_mesh.mesh
	mesh.clear_surfaces()
	var flags : int = Mesh.ARRAY_FORMAT_VERTEX | Mesh.ARRAY_FORMAT_NORMAL | Mesh.ARRAY_FORMAT_TEX_UV | Mesh.ARRAY_FORMAT_INDEX
	var vertices : PackedVector3Array = opv.vertices
	var normals : PackedVector3Array = opv.normals
	var tangents : PackedFloat32Array = opv.tangents
	var tex_uvs : PackedVector2Array = opv.tex_uvs
	var indexes : PackedInt32Array = opv.indexes
	var arrays : Array = [vertices, normals, tangents, null, tex_uvs, null, null, null, null, null, null, null, indexes]
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays, [], {}, flags)
	print("Done")

func _on_reload_shader_pressed():
	await setup_shader()
	await generate_mesh()

func _on_model_pressed():
	generated_mesh.visible = not generated_mesh.visible
	plane.visible = not plane.visible

func _on_size_value_changed(value):
	size = 1 << int(value)
	await setup_shader()
	await generate_mesh()

func _on_curvature_value_changed(value):
	await generate_mesh()
