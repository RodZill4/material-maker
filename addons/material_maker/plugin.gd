tool
extends EditorPlugin

var importer = null

func _enter_tree() -> void:
	importer = preload("res://addons/material_maker/import_plugin/ptex_import.gd").new(self)
	add_import_plugin(importer)

func _exit_tree() -> void:
	if importer:
		remove_import_plugin(importer)
		importer = null
