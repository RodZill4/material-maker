extends SubViewport

func get_materials() -> Array:
	return [ $PreviewScene/Pivot/Sphere.get_surface_override_material(0) ]
