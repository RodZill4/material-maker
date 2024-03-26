extends NavigationStyle3D
class_name TurntableNavigationStyle3D


const MOTION_FACTOR_ORBIT = 0.004
const MOTION_FACTOR_OBJECT = 0.004
const MOTION_FACTOR_ZOOM = 0.01

var trigger_on_right_click = true


# need to call parent class constructor
func _init(parent: SubViewportContainer) -> void:
	super(parent)


func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		handle_mouse_buttons(event)
	if event is InputEventMouseMotion:
		handle_mouse_motion(event)


func handle_mouse_buttons(event: InputEventMouseButton) -> void:
	if (event.button_index == MOUSE_BUTTON_LEFT
			or event.button_index == MOUSE_BUTTON_RIGHT
			or event.button_index == MOUSE_BUTTON_MIDDLE):
		# Don't stop rotating the preview on mouse wheel usage (zoom change).
		parent.get_node("MaterialPreview/Preview3d/ObjectRotate").stop(false)

	var zoom_factor = 1.01 if event.shift_pressed else 1.1
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			if event.is_command_or_control_pressed(): set_fov(parent.camera.fov + 1)
			else: zoom(1.0 / zoom_factor)
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.is_command_or_control_pressed(): set_fov(parent.camera.fov - 1)
			else: zoom(zoom_factor)
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				mouse_start_position = event.global_position
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # allow and hide cursor warp
				parent.get_viewport().warp_mouse(mouse_start_position)
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		MOUSE_BUTTON_RIGHT:
			if event.pressed:
				trigger_on_right_click = true
			elif trigger_on_right_click:
				trigger_on_right_click = false
				parent.on_right_click()


func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	var motion = event.relative
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var camera_basis = parent.camera.get_global_transform().basis
		if event.is_command_or_control_pressed(): # zooming by moving the mouse
			var zoom_factor = MOTION_FACTOR_ZOOM*0.1 if event.shift_pressed else MOTION_FACTOR_ZOOM
			zoom(1.0+motion.y*zoom_factor)
		elif event.shift_pressed: # rotate object
			var object_motion: Vector2 = motion*MOTION_FACTOR_OBJECT
			parent.objects_pivot.rotate(camera_basis.x.normalized(), object_motion.y)
			parent.objects_pivot.rotate(camera_basis.y.normalized(), object_motion.x)
		else: # orbiting around
			var orbit_motion: Vector2 = motion*MOTION_FACTOR_ORBIT
			parent.camera_stand.rotate(camera_basis.x.normalized(), -orbit_motion.y)
			parent.camera_stand.rotate(Vector3.UP, -orbit_motion.x)
