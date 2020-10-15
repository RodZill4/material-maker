tool
extends WindowDialog

func _ready():
	if !Engine.editor_hint:
		var mi = MeshInstance.new()
		mi.mesh = CubeMesh.new()
		print(mi.mesh)
		mi.set_surface_material(0, SpatialMaterial.new())
		set_object(mi)

func set_project_path(p):
	window_title = "Material Spray - "+p

func set_object(o):
	$PaintTool.set_object(o)
