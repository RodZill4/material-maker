tool
extends EditorPlugin

var importer = null

func _enter_tree() -> void:
	importer = preload("res://addons/material_maker/import_plugin/ptex_import.gd").new(self)
	add_import_plugin(importer)

func _exit_tree() -> void:
	if importer != null:
		remove_import_plugin(importer)
		importer = null

func generate_material(ptex_filename: String) -> Material:
	var generator = mm_loader.load_gen(ptex_filename)
	add_child(generator)
	if generator.has_node("Material"):
		var gen_material = generator.get_node("Material")
		if gen_material != null:
			var return_value = gen_material.render_textures()
			while return_value is GDScriptFunctionState:
				return_value = yield(return_value, "completed")
			var prefix = ptex_filename.left(ptex_filename.rfind("."))
			return gen_material.export_textures(prefix, get_editor_interface())
	return null
