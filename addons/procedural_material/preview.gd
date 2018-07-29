tool
extends ViewportContainer

var preview_material = null
var preview_maximized = false

const ENVIRONMENTS = [
	"experiment", "lobby", "night", "park", "schelde"
]

func _ready():
	preview_material = ShaderMaterial.new()
	preview_material.shader = Shader.new()
	preview_material.shader.set_code("shader_type spatial;\nvoid fragment() {\n  ALBEDO=vec3(0.5);\n}\n")
	$MaterialPreview/Objects/Cube.set_surface_material(0, preview_material)
	$MaterialPreview/Objects/Cylinder.set_surface_material(0, preview_material)
	$ObjectRotate.play("rotate")
	_on_Environment_item_selected($Environment.selected)

func _on_SelectedPreview_gui_input(ev):
	if ev is InputEventMouseButton && ev.button_index == 1 && ev.doubleclick:
		if preview_maximized:
			$SelectedPreviewAnimation.play("minimize")
		else:
			$SelectedPreviewAnimation.play("maximize")
		preview_maximized = !preview_maximized

func _on_Environment_item_selected(id):
	$MaterialPreview/WorldEnvironment.environment.background_sky.panorama = load("res://addons/procedural_material/panoramas/"+ENVIRONMENTS[id]+".hdr")
