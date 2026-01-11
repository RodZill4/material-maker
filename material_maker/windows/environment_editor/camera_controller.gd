extends Node3D


@export var camera_path : NodePath:
	set(v):
		camera_path = v
		if is_inside_tree():
			camera_position.remote_path = camera_position.get_path_to(get_node(camera_path))
@export var capture_mouse : bool = false

@onready var camera_position : Node3D = $CameraRotation1/CameraRotation2/Camera3D
@onready var camera_target_position = self
@onready var camera_rotation1 = $CameraRotation1
@onready var camera_rotation2 = $CameraRotation1/CameraRotation2

var mouse_start_position : Vector2

func _ready():
	camera_path = camera_path

func process_event(event : InputEvent, viewport : Viewport = null) -> bool:
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE != 0:
			if event.shift_pressed:
				var factor = 0.0025*camera_position.position.z
				camera_target_position.translate(-factor*event.relative.x*camera_position.global_transform.basis.x)
				camera_target_position.translate(factor*event.relative.y*camera_position.global_transform.basis.y)
			elif event.ctrl_pressed or event.meta_pressed:
				if get_parent().name == "Preview3d":
					var preview_3d : SubViewportContainer = get_parent().owner

					mm_globals.handle_warped_drag_zoom(preview_3d,
					(func() -> void:
						var amount : float = 1.0 + event.relative.y * 0.002
						camera_position.position.z = clamp(
								camera_position.position.z * amount,
								preview_3d.CAMERA_DISTANCE_MIN, preview_3d.CAMERA_DISTANCE_MAX)
					), 0, preview_3d.get_rect().size.y, preview_3d.get_local_mouse_position())
			else:
				camera_rotation2.rotate_x(-0.01*event.relative.y)
				camera_rotation1.rotate_y(-0.01*event.relative.x)
			return true
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT != 0:
			if event.shift_pressed:
				var world_env : WorldEnvironment = get_node("../WorldEnvironment")
				world_env.environment.sky_rotation.y += event.relative.x * 0.001
			return false
	elif event is InputEventMouseButton:
		if not event.is_command_or_control_pressed():
			var zoom = 0.0
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom -= 1.0
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom += 1.0
			if zoom != 0.0:
				camera_position.translate(Vector3(0.0, 0.0, zoom*(1.0 if event.shift_pressed else 0.1)))
				return true
		if capture_mouse and event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				mouse_start_position = event.global_position
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
				if viewport:
					viewport.warp_mouse(mouse_start_position)
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			return true
	elif event is InputEventPanGesture:
		camera_rotation2.rotate_x(-0.05*event.delta.y)
		camera_rotation1.rotate_y(-0.05*event.delta.x)
		return true
	elif event is InputEventMagnifyGesture:
		camera_position.position.z /= event.factor
		return true
	return false
