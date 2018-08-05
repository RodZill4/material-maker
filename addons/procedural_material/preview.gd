tool
extends ViewportContainer

const ENVIRONMENTS = [
	"experiment", "lobby", "night", "park", "schelde"
]

func _ready():
	var m = $MaterialPreview/Objects/Cube.get_surface_material(0).duplicate()
	$MaterialPreview/Objects/Cube.set_surface_material(0, m)
	$MaterialPreview/Objects/Cylinder.set_surface_material(0, m)
	$ObjectRotate.play("rotate")
	_on_Environment_item_selected($Environment.selected)

func _on_Environment_item_selected(id):
	$MaterialPreview/WorldEnvironment.environment.background_sky.panorama = load("res://addons/procedural_material/panoramas/"+ENVIRONMENTS[id]+".hdr")

func _on_Model_item_selected(id):
	var model = $Model.get_item_text(id)
	for c in $MaterialPreview/Objects.get_children():
		c.visible = (c.get_name() == model)

func get_materials():
	return [ $MaterialPreview/Objects/Cube.get_surface_material(0) ]


func _on_Preview_item_rect_changed():
	$MaterialPreview.size = rect_size
