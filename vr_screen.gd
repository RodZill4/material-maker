extends Area

var prev_pos = null
var last_click_pos = null
var last_pos2d = null;

onready var viewport = $Viewport

var button_mask : int = 0
var button_times : Dictionary = {}

func ui_raycast_hit_event(position, button, pressed):
	# note: this transform assumes that the unscaled area is [-0.5, -0.5] to [0.5, 0.5] in size
	var local_position = to_local(position)
	var pos2d = Vector2(local_position.x, -local_position.y)
	pos2d = pos2d + Vector2(0.5, 0.5)
	pos2d.x *= viewport.size.x
	pos2d.y *= viewport.size.y
	var e : InputEventMouse
	if button != 0:
		e = InputEventMouseButton.new()
		e.pressed = pressed
		e.doubleclick = false
		var mask : int
		match button:
			BUTTON_LEFT:
				mask = BUTTON_MASK_LEFT
			BUTTON_RIGHT:
				mask = BUTTON_MASK_RIGHT
			BUTTON_MIDDLE:
				mask = BUTTON_MASK_MIDDLE
		if pressed:
			button_mask |= mask
			var time = OS.get_ticks_msec()
			if button_times.has(button) and time-button_times[button] < 300:
				e.doubleclick = true
			button_times[button] = time
		else:
			button_mask &= ~mask
		e.button_index = button
	elif last_pos2d != null and last_pos2d != pos2d:
		e = InputEventMouseMotion.new()
		e.relative = pos2d - last_pos2d
		e.speed = (pos2d - last_pos2d) / 16.0 #?? chose an arbitrary scale here for now
		viewport.warp_mouse(pos2d)
	else:
		return
	e.button_mask = button_mask
	e.global_position = pos2d
	e.position = pos2d
	viewport.input(e)
	last_pos2d = pos2d

