extends Node

## basic touch handling and mobile utilities

var active_touch : int = -1
var active_touch_drag : int = -1

var touch_info : Dictionary[int, Vector2] = {}

signal back_pressed()

func _ready() -> void:
	if not OS.get_name() == "Android":
		set_process_input(false)

func _input(event : InputEvent) -> void:
	if event is InputEventScreenDrag:
		touch_info[event.index] = event.position
		active_touch_drag = event.index
	elif event is InputEventScreenTouch:
		if event.pressed:
			active_touch = event.index
			touch_info[event.index] = event.position
		elif not event.pressed and touch_info.has(event.index):
			touch_info.erase(event.index)
	elif event is InputEventKey and event.keycode == KEY_BACK and event.pressed:
		back_pressed.emit()

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
