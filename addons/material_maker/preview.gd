tool
extends ViewportContainer

var preview_maximized = false

const ENVIRONMENTS = [
	"experiment", "lobby", "night", "park", "schelde"
]

func _ready():
	var m
	m = $MaterialPreview/Objects/Cube.get_surface_material(0).duplicate()
	$MaterialPreview/Objects/Cube.set_surface_material(0, m)
	$MaterialPreview/Objects/Cylinder.set_surface_material(0, m)
	m = $MaterialPreview/Objects/Sphere.get_surface_material(0).duplicate()
	$MaterialPreview/Objects/Sphere.set_surface_material(0, m)
	$ObjectRotate.play("rotate")
	$Preview2D.material = $Preview2D.material.duplicate(true)
	_on_Environment_item_selected($Config/Environment.selected)
	_on_Preview_resized()

func _on_Environment_item_selected(id):
	$MaterialPreview/WorldEnvironment.environment.background_sky.panorama = load("res://addons/material_maker/panoramas/"+ENVIRONMENTS[id]+".hdr")

func _on_Model_item_selected(id):
	var model = $Config/Model.get_item_text(id)
	for c in $MaterialPreview/Objects.get_children():
		c.visible = (c.get_name() == model)

func get_materials():
	return [ $MaterialPreview/Objects/Cube.get_surface_material(0), $MaterialPreview/Objects/Sphere.get_surface_material(0) ]
	
func get_2d_material():
	return $Preview2D.material

func _on_Preview_resized():
	if preview_maximized:
		var size = min(rect_size.x, rect_size.y)
		$Preview2D.rect_position = 0.5*Vector2(rect_size.x-size, rect_size.y-size)
		$Preview2D.rect_size = Vector2(size, size)
	else:
		$Preview2D.rect_position = Vector2(0, rect_size.y-64)
		$Preview2D.rect_size = Vector2(64, 64)

func _on_Preview2D_gui_input(ev):
	if ev is InputEventMouseButton && ev.button_index == 1 && ev.doubleclick:
		preview_maximized = !preview_maximized
		_on_Preview_resized()


