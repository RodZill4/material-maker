tool
extends Control

onready var tree = $VBoxContainer/Tree

const LIB_FILE = "res://addons/material_spray/brushes/base.json"

var current_brush = null

signal brush_selected(brush)

func _ready():
	read_lib(LIB_FILE)

func read_lib(filename):
	var file = File.new()
	if file.open(filename, File.READ) == OK:
		tree.set_lib(parse_json(file.get_as_text()))
		file.close()

func _on_Tree_item_edited():
	pass # Replace with function body.

func _on_Tree_item_selected():
	emit_signal("brush_selected", tree.get_selected().get_metadata(0).duplicate())

func brush_changed(new_brush, _update_shader):
	current_brush = new_brush

func _on_Add_pressed():
	if current_brush != null:
		tree.create_brush(current_brush.duplicate())

func _on_Update_pressed():
	if current_brush != null:
		tree.update_brush(current_brush.duplicate())

func _on_Save_pressed():
	var file = File.new()
	file.open(LIB_FILE, File.WRITE)
	file.store_string(to_json(tree.get_lib()))
	file.close()
