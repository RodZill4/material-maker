extends "res://material_maker/panels/preview_3d/preview_mesh.gd"


@export_multiline var compute_shader : String
@export var vertex_count_expression : String
@export var index_count_expression : String


static var shader : MMComputeShader = MMComputeShader.new()
static var shader_string : String = ""
static var shader_size : int = 0


func _ready():
	super._ready()
	can_tesselate = false

func get_expression_value_from_string(expression_string : String, values: Dictionary) -> int:
	var expression : Expression = Expression.new()
	var input_names : PackedStringArray = PackedStringArray()
	var input_values : Array = []
	for k in values.keys():
		input_names.append(k)
		input_values.append(values[k])
	expression.parse(expression_string, input_names)
	var rv : int = expression.execute(input_values)
	return rv

func do_update_mesh() -> void:
	var size : int = mm_globals.main_window.preview_tesselation_detail
	if size != shader_size or compute_shader != shader_string:
		var vertex_count : int = get_expression_value_from_string(vertex_count_expression, { size=size} )
		var index_count : int = get_expression_value_from_string(index_count_expression, { size=size} )
		shader.local_size = size if size < 32 else 32
		shader.clear()
		shader.add_parameter_or_texture("size", "int", size)
		for p in parameters:
			shader.add_parameter_or_texture(p.name, "float", p.default_value)
		shader.add_output_parameter("vertices", "float", 3*vertex_count)
		shader.add_output_parameter("normals", "float", 3*vertex_count)
		shader.add_output_parameter("tangents", "float", 4*vertex_count)
		shader.add_output_parameter("tex_uvs", "float", 2*vertex_count)
		shader.add_output_parameter("indexes", "int", index_count)
		await shader.set_shader_ext(compute_shader)
		shader_size = size
		shader_string = compute_shader
	var opv : Dictionary = { vertices_format="vec3", normals_format="vec3", tex_uvs_format="vec2" }
	shader.set_parameter("size", size)
	for p in parameters:
		shader.set_parameter(p.name, parameter_values[p.name])
	await shader.render_ext([], Vector2i(size, size), opv)
	if opv.has("vertices"):
		mesh.clear_surfaces()
		var flags : int = Mesh.ARRAY_FORMAT_VERTEX | Mesh.ARRAY_FORMAT_NORMAL | Mesh.ARRAY_FORMAT_TEX_UV | Mesh.ARRAY_FORMAT_INDEX
		var vertices : PackedVector3Array = opv.vertices
		var normals : PackedVector3Array = opv.normals
		var tangents : PackedFloat32Array = opv.tangents
		var tex_uvs : PackedVector2Array = opv.tex_uvs
		var indexes : PackedInt32Array = opv.indexes
		var arrays : Array = [vertices, normals, tangents, null, tex_uvs, null, null, null, null, null, null, null, indexes]
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays, [], {}, flags)
		set_surface_override_material(0, material)

var need_update : bool = false
static var updating : bool = false

func update_mesh() -> void:
	need_update = true
	if updating:
		return
	while need_update:
		need_update = false
		updating = true
		await do_update_mesh()
	updating = false
