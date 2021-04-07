extends Node

var main_window : Control

func _ready():
	pass # Replace with function body.

func get_main_window() -> Control:
	return main_window

func set_main_window(w) -> void:
	main_window = w

