extends MeshInstance

export var can_tesselate : bool = true

export var uv_scale : Vector2 = Vector2(1, 1) setget set_uv_scale
export var tesselated : bool = false setget set_tesselated

var thumbnail: Texture = null


func _ready():
	update_material()

func set_uv_scale(s : Vector2) -> void:
	if s != uv_scale:
		uv_scale = s
		var material = get_surface_material(0)
		if material != null:
			if material is SpatialMaterial:
				material.uv1_scale.x = uv_scale.x
				material.uv1_scale.y = uv_scale.y
			elif material is ShaderMaterial:
				material.set_shader_param("uv1_scale", Vector3(uv_scale.x, uv_scale.y, 1))

func set_tesselated(t : bool) -> void:
	var new_tesselated = t && can_tesselate
	if new_tesselated == tesselated:
		return
	tesselated = new_tesselated
	update_material()
	# Force material update (this is not need at startup)
	var parent = self
	while ! (parent is ViewportContainer):
		parent = parent.get_parent()
	parent.emit_signal("need_update", [ parent ]) 

func update_material() -> void:
	if mesh == null:
		return
	var material
	if tesselated:
		material = preload("res://material_maker/panels/preview_3d/materials/shader_material_tesselated.tres").duplicate()
		material.set_shader_param("uv1_scale", Vector3(uv_scale.x, uv_scale.y, 1))
		match mesh.get_class():
			"CubeMesh","PrismMesh":
				mesh.subdivide_width = 128
				mesh.subdivide_height = 128
				mesh.subdivide_depth = 128
			"PlaneMesh":
				mesh.subdivide_width = 128
				mesh.subdivide_depth = 128
			"CylinderMesh":
				mesh.radial_segments = 128
				mesh.rings = 128
			"SphereMesh":
				mesh.radial_segments = 128
				mesh.rings = 64
			_:
				print(mesh.get_class())
	else:
		material = preload("res://material_maker/panels/preview_3d/materials/spatial_material.tres").duplicate()
		material.uv1_scale.x = uv_scale.x
		material.uv1_scale.y = uv_scale.y
		match mesh.get_class():
			"CubeMesh","PrismMesh":
				mesh.subdivide_width = 0
				mesh.subdivide_height = 0
				mesh.subdivide_depth = 0
			"PlaneMesh":
				mesh.subdivide_width = 0
				mesh.subdivide_depth = 0
			"CylinderMesh":
				mesh.radial_segments = 32
				mesh.rings = 1
			"SphereMesh":
				mesh.radial_segments = 32
				mesh.rings = 16
			_:
				#print(mesh.get_class())
				pass
	set_surface_material(0, material)
