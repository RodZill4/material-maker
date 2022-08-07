extends NavigationStyle3D
class_name DefaultNavigationStyle3D


var moving = false
var trigger_on_right_click = true


func _init(parent: ViewportContainer).(parent) -> void: pass


func handle_input(event: InputEvent) -> void:
	if event is InputEventPanGesture:
		parent.get_node("MaterialPreview/Preview3d/ObjectRotate").stop(false)
		var camera_basis = parent.camera.global_transform.basis
		var rotation : Vector2 = event.delta
		parent.camera_stand.rotate(camera_basis.x.normalized(), -rotation.y)
		parent.camera_stand.rotate(camera_basis.y.normalized(), -rotation.x)
	elif event is InputEventMagnifyGesture:
		zoom(event.factor)
	elif event is InputEventMouseButton:
		if (event.button_index == BUTTON_LEFT
				or event.button_index == BUTTON_RIGHT
				or event.button_index == BUTTON_MIDDLE):
			# Don't stop rotating the preview on mouse wheel usage (zoom change).
			parent.get_node("MaterialPreview/Preview3d/ObjectRotate").stop(false)

		match event.button_index:
			BUTTON_WHEEL_UP:
				if event.command: set_fov(parent.camera.fov + 1)
				else: zoom(1.0 / (1.01 if event.shift else 1.1))
			BUTTON_WHEEL_DOWN:
				if event.command: set_fov(parent.camera.fov - 1)
				else: zoom(1.01 if event.shift else 1.1)
			BUTTON_LEFT, BUTTON_RIGHT:
				var mask : int = Input.get_mouse_button_mask()
				var lpressed : bool = (mask & BUTTON_MASK_LEFT) != 0
				var rpressed : bool = (mask & BUTTON_MASK_RIGHT) != 0

				if event.pressed and lpressed != rpressed: # xor
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
					mouse_start_position = event.global_position
					moving = true
				elif not lpressed and not rpressed:
					Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # allow and hide cursor warp
					parent.get_viewport().warp_mouse(mouse_start_position)
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
					moving = false
				if event.button_index == BUTTON_RIGHT:
					if event.pressed:
						trigger_on_right_click = true
					elif trigger_on_right_click:
						trigger_on_right_click = false
						parent.on_right_click()
	elif moving and event is InputEventMouseMotion:
		trigger_on_right_click = false
		if event.pressure != 0.0:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		var motion = event.relative
		if Input.is_key_pressed(KEY_ALT):
			zoom(1.0+motion.y*0.01)
		else:
			motion *= 0.01
			if abs(motion.y) > abs(motion.x):
				motion.x = 0
			else:
				motion.y = 0
			var camera_basis = parent.camera.global_transform.basis
			var objects_rotation : int = -1 if Input.is_key_pressed(KEY_CONTROL) else 1 if Input.is_key_pressed(KEY_SHIFT) else 0
			if event.button_mask & BUTTON_MASK_LEFT:
				parent.objects_pivot.rotate(camera_basis.x.normalized(), objects_rotation * motion.y)
				parent.objects_pivot.rotate(camera_basis.y.normalized(), objects_rotation * motion.x)
				if objects_rotation != 1:
					parent.camera_stand.rotate(camera_basis.x.normalized(), -motion.y)
					parent.camera_stand.rotate(camera_basis.y.normalized(), -motion.x)
			elif event.button_mask & BUTTON_MASK_RIGHT:
				parent.objects_pivot.rotate(camera_basis.z.normalized(), objects_rotation * motion.x)
				if objects_rotation != 1:
					parent.camera_stand.rotate(camera_basis.z.normalized(), -motion.x)
