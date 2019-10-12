tool
extends "res://addons/material_maker/node_base.gd"

var generator = null setget set_generator

onready var label = $VBox/Label
onready var editor = $VBox/TextEdit

func set_generator(g):
	generator = g
	label.text = generator.text
	rect_size = generator.size

func _on_resize_request(new_size):
	rect_size = new_size
	generator.size = new_size

func _on_Label_gui_input(ev):
	if ev is InputEventMouseButton and ev.doubleclick and ev.button_index == BUTTON_LEFT:
		editor.rect_min_size = label.rect_size + Vector2(0, rect_size.y - get_minimum_size().y)
		editor.text = label.text
		label.visible = false
		editor.visible = true
		editor.select_all()
		editor.grab_focus()

func _on_TextEdit_focus_exited():
	label.text = editor.text
	generator.text = editor.text
	label.visible = true
	editor.visible = false
