extends Node

func _ready():
	var args : PackedStringArray = OS.get_cmdline_args()
	var no_logo : bool = ( args.find("--no-splash") != -1 )
	var scene : PackedScene
	if no_logo:
		scene = load("res://material_maker/main_window.tscn")
	else:
		scene = load("res://splash_screen/splash_screen.tscn")
	await get_tree().process_frame
	get_tree().change_scene_to_packed(scene)
