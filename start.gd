extends Control

func _ready():
	print("Loading...")
	call_deferred("change_scene")

func change_scene():
	if Directory.new().file_exists("res://material_maker/main_window.tscn"):
		get_tree().change_scene("res://material_maker/main_window.tscn")
	else:
		get_tree().change_scene("res://demo/demo.tscn")
