tool
extends Viewport

var material = null

func _ready():
	material = ShaderMaterial.new()
	material.shader = Shader.new()
	$Objects/Cube.set_surface_material(0, material)
	$Objects/Cylinder.set_surface_material(0, material)
	$AnimationPlayer.play("rotate")
