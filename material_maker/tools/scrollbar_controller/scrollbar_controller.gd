extends Node

class_name ScrollbarController


var _timer : Timer
var _tween : Tween

var _scroll_stylebox : StyleBoxFlat

## Fade out duration
@export var fade_out_duration : float = 0.6

## Time to wait(in seconds) before fading out
@export var wait_time : float = 2.0

@export var _target_stylebox_name : String = "grabber"
@export var _target_theme_type : String = "VScrollBar"

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = wait_time
	_timer.autostart = true
	_timer.one_shot = true
	add_child(_timer)
	_setup_scrollbars()
	owner.theme_changed.connect(_invalidate_stylebox)


func initialize() -> void:
	if is_node_ready():
		_timer.start()
	if not _scroll_stylebox:
		_scroll_stylebox = owner.get_theme_stylebox(
				_target_stylebox_name, _target_theme_type).duplicate()


func _invalidate_stylebox() -> void:
	_scroll_stylebox = null


func _setup_scrollbars() -> void:
	if not _timer.timeout.is_connected(hide_scrollbars):
		_timer.timeout.connect(hide_scrollbars)
	initialize()


func hide_scrollbars() -> void:
	_tween = get_tree().create_tween()
	_tween.tween_property(_scroll_stylebox,
			"bg_color:a", 0.0, fade_out_duration)


func show_scrollbars() -> void:
	initialize()
	if _tween != null and _tween.is_running():
		_tween.kill()
	if _scroll_stylebox.bg_color.a != 1.0:
		_scroll_stylebox.bg_color.a = 1.0


## Setup scrollbar theme overrides for animation
func add_scrollbar(scroll_bar : ScrollBar) -> void:
	if scroll_bar.has_theme_color_override(_target_stylebox_name):
		scroll_bar.remove_theme_stylebox_override(_target_stylebox_name)
	scroll_bar.add_theme_stylebox_override(_target_stylebox_name, _scroll_stylebox)


func should_hide_scrollbars(s : Signal) -> void:
	if not s.is_connected(hide_scrollbars):
		s.connect(hide_scrollbars)


func should_show_scrollbars(s : Signal) -> void:
	if not s.is_connected(show_scrollbars):
		s.connect(show_scrollbars)


func _exit_tree() -> void:
	if _timer:
		_timer.queue_free()
	if _tween:
		_tween.kill()
