tool
extends ViewportContainer

var preview_maximized = false

const ENVIRONMENTS = [
	"experiment", "lobby", "night", "park", "schelde"
]

onready var objects = $MaterialPreview/Objects
onready var current_object = objects.get_child(0)

signal need_update
signal show_background_preview

func _ready():
	current_object.visible = true
	$Config/Model.clear()
	for o in objects.get_children():
		var m = o.get_surface_material(0)
		o.set_surface_material(0, m.duplicate())
		$Config/Model.add_item(o.name)
	$ObjectRotate.play("rotate")
	$Preview2D.material = $Preview2D.material.duplicate(true)
	_on_Environment_item_selected($Config/Environment.selected)
	_on_Preview_resized()
	$MaterialPreview/CameraPivot/Camera/RemoteTransform.set_remote_node("../../../../../../ProjectsPane/BackgroundPreview/Viewport/Camera")

func _on_Environment_item_selected(id):
	$MaterialPreview/WorldEnvironment.environment.background_sky.panorama = load("res://addons/material_maker/panoramas/"+ENVIRONMENTS[id]+".hdr")

func _on_Model_item_selected(id):
	current_object.visible = false
	current_object = objects.get_child(id)
	current_object.visible = true
	emit_signal("need_update")

func get_materials():
	return [ current_object.get_surface_material(0) ]

func set_2d(tex: Texture):
	$Preview2D.material.set_shader_param("tex", tex)

func _on_Preview_resized():
	if preview_maximized:
		var size = min(rect_size.x, rect_size.y)
		$Preview2D.rect_position = 0.5*Vector2(rect_size.x-size, rect_size.y-size)
		$Preview2D.rect_size = Vector2(size, size)
	else:
		$Preview2D.rect_position = Vector2(0, rect_size.y-64)
		$Preview2D.rect_size = Vector2(64, 64)

func _on_Preview2D_gui_input(ev : InputEvent):
	if ev is InputEventMouseButton and ev.button_index == 1 and ev.pressed:
		preview_maximized = !preview_maximized
		_on_Preview_resized()

func _on_Button_toggled(button_pressed):
	emit_signal("show_background_preview", button_pressed)

func on_gui_input(event):
	if event is InputEventMouseButton:
		$ObjectRotate.stop()
	elif event is InputEventMouseMotion:
		if event.button_mask != 0:
			$MaterialPreview/Objects.rotation.y += 0.01*event.relative.x
			$MaterialPreview/CameraPivot.rotation.x -= 0.01*event.relative.y
