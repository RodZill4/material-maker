extends Viewport


func get_materials() -> Array:
	return [$PreviewScene/Sphere.get_surface_material(0)]
