extends "res://material_maker/tools/achievements/achievement.gd"

func _ready():
	pass # Replace with function body.

func _on_Achievement_gui_input(event : InputEvent):
	if event is InputEventMouseButton and event.pressed:
		get_parent().get_parent().show_achievements()
