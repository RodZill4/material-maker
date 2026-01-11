class_name Achievement

extends MarginContainer

@export var cup_color : Color

func set_texts(title : String, text : String, unlocked : bool = false):
	%Title.text = title
	%Text.text = text
	if unlocked:
		%Icon.material = null

func set_cup_color(c : Color):
	cup_color = c
	$HBoxContainer/Icon.material.set_shader_param("c", c)
