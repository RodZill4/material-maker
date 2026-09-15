extends Node

var active_touch : int = 0
var active_touch_drag : int = 0

var long_press_timer : float = 0.0
var has_long_pressed : bool = false

## Time in seconds until a long tap is registered
const LONG_PRESS_THRESHOLD : float = 0.8

signal long_pressed()

func _ready() -> void:
	if OS.get_name() != "Android":
		set_process_input(false)
		set_process(false)

func _input(event : InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			active_touch = event.index + 1
			has_long_pressed = false
			long_press_timer = 0.0
	elif event is InputEventScreenDrag:
		active_touch_drag = event.index + 1
	else:
		active_touch = 0
		active_touch_drag = 0

func _process(delta : float) -> void:
	if has_long_pressed:
		return

	if long_press_timer >= LONG_PRESS_THRESHOLD:
		has_long_pressed = true
		long_pressed.emit()
	else:
		if active_touch == 1:
			long_press_timer += delta

func setup_window_touch(window : Window) -> void:
	if not window.window_input.is_connected(_input):
		window.window_input.connect(_input)
