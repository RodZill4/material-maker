extends Node3D


@export var camera_path : NodePath:
	set(v):
		camera_path = v
		if is_inside_tree():
			camera_position.remote_path = camera_position.get_path_to(get_node(camera_path))

@onready var camera_position : Node3D = $CameraRotation1/CameraRotation2/Camera3D
@onready var camera_target_position = self
@onready var camera_rotation1 = $CameraRotation1
@onready var camera_rotation2 = $CameraRotation1/CameraRotation2


func _ready():
	camera_path = camera_path

func process_event(event : InputEvent) -> bool:
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE != 0:
			if event.shift_pressed:
				var factor = 0.0025*camera_position.position.z
				camera_target_position.translate(-factor*event.relative.x*camera_position.global_transform.basis.x)
				camera_target_position.translate(factor*event.relative.y*camera_position.global_transform.basis.y)
			else:
				camera_rotation2.rotate_x(-0.01*event.relative.y)
				camera_rotation1.rotate_y(-0.01*event.relative.x)
			return true
	elif event is InputEventMouseButton:
		if not event.is_command_or_control_pressed():
			var zoom = 0.0
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom -= 1.0
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom += 1.0
			else:
				return false
			if zoom != 0.0:
				camera_position.translate(Vector3(0.0, 0.0, zoom*(1.0 if event.shift_pressed else 0.1)))
			return true
	elif event is InputEventPanGesture:
		# TODO: test and fix this
		camera_rotation2.rotate_x(-0.01*event.delta.y)
		camera_rotation1.rotate_y(-0.01*event.delta.x)
		return true
	elif event is InputEventMagnifyGesture:
		# TODO: test and fix this
		camera_position.z /= event.factor
		return true
	return false
