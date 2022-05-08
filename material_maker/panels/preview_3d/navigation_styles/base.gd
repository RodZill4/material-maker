extends Object
class_name NavigationStyle3D


const CAMERA_DISTANCE_MIN = 0.5
const CAMERA_DISTANCE_MAX = 150.0
const CAMERA_FOV_MIN = 10
const CAMERA_FOV_MAX = 90

var parent: ViewportContainer
var mouse_start_position: Vector2 = Vector2.ZERO


func _init(parent: ViewportContainer) -> void:
	self.parent = parent


func zoom(amount: float) ->void:
	parent.camera.translation.z = clamp(
		parent.camera.translation.z*amount,
		CAMERA_DISTANCE_MIN,
		CAMERA_DISTANCE_MAX
	)

func set_fov(amount: float) -> void:
	parent.camera.fov = clamp(
		amount,
		CAMERA_FOV_MIN,
		CAMERA_FOV_MAX
	)

# 'virtual' functions (kind of)
func handle_process(delta: float) -> void:
	pass
func handle_input(event: InputEvent) -> void:
	pass
