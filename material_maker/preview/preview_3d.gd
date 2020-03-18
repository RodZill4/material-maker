extends ViewportContainer

const CAMERA_DISTANCE_MIN = 1.0
const CAMERA_DISTANCE_MAX = 10.0

export var ui_path : String = "Preview3DUI"

onready var objects = $MaterialPreview/Preview3d/Objects
onready var current_object = objects.get_child(0)

onready var environments = $MaterialPreview/Preview3d/Environments
onready var current_environment = environments.get_child(0)

onready var camera_stand = $MaterialPreview/Preview3d/CameraPivot
onready var camera = $MaterialPreview/Preview3d/CameraPivot/Camera

onready var ui = get_node(ui_path)

signal need_update(me)

func _ready() -> void:
	var model_list : Array = []
	for o in objects.get_children():
		var m = o.get_surface_material(0)
		o.set_surface_material(0, m.duplicate())
		model_list.push_back(o.name)
	ui.set_models(model_list)
	var environment_list : Array = []
	for e in environments.get_children():
		environment_list.push_back(e.name)
	ui.set_environments(environment_list)
	$MaterialPreview/Preview3d/ObjectRotate.play("rotate")

func _on_Model_item_selected(id) -> void:
	current_object.visible = false
	current_object = objects.get_child(id)
	current_object.visible = true
	emit_signal("need_update", [ self ])

func _on_Environment_item_selected(id) -> void:
	current_environment.visible = false
	current_environment = environments.get_child(id)
	$MaterialPreview/Preview3d/CameraPivot/Camera.set_environment(current_environment.environment)
	current_environment.visible = true

func _on_Rotate_toggled(button_pressed) -> void:
	if button_pressed:
		$MaterialPreview/Preview3d/ObjectRotate.play("rotate")
	else:
		$MaterialPreview/Preview3d/ObjectRotate.stop(false)

func get_materials() -> Array:
	return [ current_object.get_surface_material(0) ]

func on_gui_input(event) -> void:
	if event is InputEventMouseButton:
		$MaterialPreview/Preview3d/ObjectRotate.stop(false)
		ui.rotation_cancelled()
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
