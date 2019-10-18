tool
extends ViewportContainer

var preview_maximized = false

const ENVIRONMENTS = [
	"experiment", "lobby", "night", "park", "schelde"
]

const CAMERA_DISTANCE_MIN = 1.0
const CAMERA_DISTANCE_MAX = 10.0

onready var objects = $MaterialPreview/Preview3d/Objects
onready var current_object = objects.get_child(0)

onready var environments = $MaterialPreview/Preview3d/Environments
onready var current_environment = environments.get_child(0)

onready var camera_stand = $MaterialPreview/Preview3d/CameraPivot
onready var camera = $MaterialPreview/Preview3d/CameraPivot/Camera

signal need_update
signal show_background_preview

func _ready():
	$Config/Model.clear()
	for o in objects.get_children():
		var m = o.get_surface_material(0)
		o.set_surface_material(0, m.duplicate())
		$Config/Model.add_item(o.name)
	call_deferred("_on_Model_item_selected", 0)
	$Config/Environment.clear()
	for e in environments.get_children():
		$Config/Environment.add_item(e.name)
	call_deferred("_on_Environment_item_selected", 0)
	$MaterialPreview/Preview3d/ObjectRotate.play("rotate")
	$Preview2D.material = $Preview2D.material.duplicate(true)
	_on_Preview_resized()
	$MaterialPreview/Preview3d/CameraPivot/Camera/RemoteTransform.set_remote_node("../../../../../../../ProjectsPane/BackgroundPreview/Viewport/Camera")

func _on_Environment_item_selected(id):
	current_environment.visible = false
	current_environment = environments.get_child(id)
	$MaterialPreview/Preview3d/CameraPivot/Camera.set_environment(current_environment.environment)
	get_node("../../ProjectsPane/BackgroundPreview/Viewport/Camera").set_environment(current_environment.environment)
	current_environment.visible = true

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

func _on_Background_toggled(button_pressed):
	emit_signal("show_background_preview", button_pressed)

func on_gui_input(event):
	if event is InputEventMouseButton:
		$MaterialPreview/Preview3d/ObjectRotate.stop(false)
		$Config/Rotate.pressed = false
		match event.button_index:
			BUTTON_WHEEL_UP:
				camera.translation.z = clamp(
					camera.translation.z / (1.01 if event.shift else 1.1),
					CAMERA_DISTANCE_MIN,
					CAMERA_DISTANCE_MAX
				)
			BUTTON_WHEEL_DOWN:
				camera.translation.z = clamp(
					camera.translation.z * (1.01 if event.shift else 1.1),
					CAMERA_DISTANCE_MIN,
					CAMERA_DISTANCE_MAX
				)
	elif event is InputEventMouseMotion:
		var motion = 0.01*event.relative
		var camera_basis = camera.global_transform.basis
		if event.shift:
			if event.button_mask & BUTTON_MASK_LEFT:
				objects.rotate(camera_basis.x.normalized(), motion.y)
				objects.rotate(camera_basis.y.normalized(), motion.x)
			elif event.button_mask & BUTTON_MASK_RIGHT:
				objects.rotate(camera_basis.z.normalized(), motion.x)
		else:
			if event.button_mask & BUTTON_MASK_LEFT:
				camera_stand.rotate(camera_basis.x.normalized(), -motion.y)
				camera_stand.rotate(camera_basis.y.normalized(), -motion.x)
			elif event.button_mask & BUTTON_MASK_RIGHT:
				camera_stand.rotate(camera_basis.z.normalized(), -motion.x)

func _on_Rotate_toggled(button_pressed):
	if button_pressed:
		$MaterialPreview/Preview3d/ObjectRotate.play("rotate")
	else:
		$MaterialPreview/Preview3d/ObjectRotate.stop(false)
