tool
extends Viewport

var material = null

func _ready():
	material = ShaderMaterial.new()
	material.shader = Shader.new()
	material.shader.set_code("shader_type spatial;\nvoid fragment() {\n  ALBEDO=vec3(0.5);\n}\n")
	$Objects/Cube.set_surface_material(0, material)
	$Objects/Cylinder.set_surface_material(0, material)
	$AnimationPlayer.play("rotate")
