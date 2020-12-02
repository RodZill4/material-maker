extends Viewport


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_materials() -> Array:
	return [ $PreviewScene/Sphere.get_surface_material(0) ]
