extends Viewport

func get_materials() -> Array:
	return [ $PreviewScene/Pivot/Sphere.get_surface_material(0) ]
