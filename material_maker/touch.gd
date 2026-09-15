extends Node

## basic touch handling and mobile utilities

var active_touch : int = 0
var active_touch_drag : int = 0

var touch_info : Dictionary[int, Vector2] = {}

#var long_press_timer : float = 0.0
#var has_long_pressed : bool = false

## time in seconds until [signal long_pressed] is emitted
#const LONG_PRESS_THRESHOLD : float = 0.8

#signal long_pressed(at_position : Vector2)
signal back_pressed()

func _ready() -> void:
	if not OS.get_name() == "Android":
		set_process_input(false)
		set_process(false)

func _input(event : InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			active_touch = event.index
			#has_long_pressed = false
			#long_press_timer = 0.0
			touch_info[event.index] = event.position
	elif event is InputEventScreenDrag:
		active_touch_drag = event.index
	elif event is InputEventKey and event.keycode == KEY_BACK and event.pressed:
		back_pressed.emit()
	else:
		active_touch = 0
		active_touch_drag = 0
		touch_info.clear()

#func _process(delta : float) -> void:
	#if has_long_pressed:
		#return
#
	#if long_press_timer >= LONG_PRESS_THRESHOLD:
		#has_long_pressed = true
#
		#if touch_info.size():
			#long_pressed.emit(touch_info[0])
	#else:
		#if active_touch == 0:
			#long_press_timer += delta

func setup_window_touch(window : Window) -> void:
	if not window.window_input.is_connected(_input):
		window.window_input.connect(_input)

func setup_dialog(window : Window) -> void:
	window.borderless = true
	setup_window_touch(window)
	back_pressed.connect(window.queue_free)
	window.min_size = Vector2.ZERO
	window.position = Vector2.ZERO
	window.size = DisplayServer.screen_get_size() / mm_globals.get_ui_scale()
	window.show()
