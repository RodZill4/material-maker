extends Panel

export var cup_color : float setget set_cup_color

func _ready():
	pass # Replace with function body.

func set_texts(title : String, text : String, unlocked : bool = false):
	$HBoxContainer/MarginContainer/Text/Title.text = title
	$HBoxContainer/MarginContainer/Text/Text.text = text
	if unlocked:
		$HBoxContainer/Icon.material = null

func set_cup_color(c : float):
	cup_color = c
	$HBoxContainer/Icon.material.set_shader_param("c", c)
