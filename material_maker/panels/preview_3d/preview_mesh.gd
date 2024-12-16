extends MeshInstance3D


@export var can_tesselate : bool = true

@export var uv_scale : Vector2 = Vector2(1, 1): set = set_uv_scale
@export var tesselated : bool = false: set = set_tesselated

@export var parameters : Array = []
var parameter_values : Dictionary = {}


var material : ShaderMaterial


func _ready():
	material = ShaderMaterial.new()
	material.shader = Shader.new()
	material.set_shader_parameter("uv1_scale", Vector3(uv_scale.x, uv_scale.y, 1))
	for p in parameters:
		if not parameter_values.has(p.name):
			parameter_values[p.name] = p.default_value
	update_mesh.call_deferred()

func get_material() -> Material:
	if get_surface_override_material_count() > 0:
		set_surface_override_material(0, material)
	return material

func set_uv_scale(s : Vector2) -> void:
	if s != uv_scale:
		uv_scale = s
		if material != null:
			material.set_shader_parameter("uv1_scale", Vector3(uv_scale.x, uv_scale.y, 1))

func set_parameter(v : float, n : String) -> void:
	if parameter_values[n] != v:
		parameter_values[n] = v
		update_mesh()

func set_tesselated(t : bool) -> void:
	var new_tesselated = t && can_tesselate
	if new_tesselated == tesselated:
		return
	tesselated = new_tesselated
	update_mesh()
	# Force material update (this is not need at startup)
	var parent = self
	while ! (parent is SubViewportContainer):
		parent = parent.get_parent()
	parent.emit_signal("need_update", [ parent ])

func update_mesh() -> void:
	if mesh == null:
		return
	var subdivide = 0
	var radial_segments = 64
	var cylinder_rings = 1
	var sphere_rings = 32
	if tesselated:
		var tesselation_detail: int = mm_globals.main_window.preview_tesselation_detail
		subdivide = tesselation_detail
		radial_segments = tesselation_detail
		cylinder_rings = tesselation_detail
		sphere_rings = round(tesselation_detail * 0.5)
	match mesh.get_class():
		"BoxMesh", "PrismMesh":
			mesh.subdivide_width = subdivide
			mesh.subdivide_height = subdivide
			mesh.subdivide_depth = subdivide
		"PlaneMesh":
			mesh.subdivide_width = subdivide
			mesh.subdivide_depth = subdivide
		"CylinderMesh":
			mesh.radial_segments = radial_segments
			mesh.rings = cylinder_rings
		"SphereMesh":
			mesh.radial_segments = radial_segments
			mesh.rings = sphere_rings
		"ArrayMesh":
			pass
		_:
			push_error("Unknown non-tesselated mesh type: %s" % mesh.get_class())
	get_material()
