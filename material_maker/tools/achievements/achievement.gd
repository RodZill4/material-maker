class_name Achievement

extends Panel

@export var cup_color : Color

func set_texts(title : String, text : String, unlocked : bool = false):
	$HBoxContainer/MarginContainer/Text/Title.text = title
	$HBoxContainer/MarginContainer/Text/Text.text = text
	if unlocked:
		$HBoxContainer/Icon.material = null

func set_cup_color(c : Color):
	cup_color = c
	$HBoxContainer/Icon.material.set_shader_param("c", c)
