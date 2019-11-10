tool
extends EditorPlugin

var mm_button = null
var material_maker = null
var importer = null

func _enter_tree() -> void:
	add_tool_menu_item("Material Maker", self, "open_material_maker")
	importer = preload("res://addons/material_maker/import_plugin/ptex_import.gd").new(self)
	add_import_plugin(importer)

func _exit_tree() -> void:
	remove_tool_menu_item("Material Maker")
	if material_maker != null:
		material_maker.hide()
		material_maker.queue_free()
		material_maker = null
	if importer != null:
		remove_import_plugin(importer)
		importer = null

func _get_state() -> Dictionary:
	return { mm_button=mm_button, material_maker=material_maker }

func _set_state(s) -> void:
	mm_button = s.mm_button
	material_maker = s.material_maker

func open_material_maker(__) -> void:
	if material_maker == null:
		material_maker = preload("res://addons/material_maker/window_dialog.tscn").instance()
		var panel = material_maker.get_node("MainWindow")
		panel.editor_interface = get_editor_interface()
		panel.connect("quit", self, "close_material_maker")
		add_child(material_maker)
	material_maker.popup_centered()

func close_material_maker() -> void:
	if material_maker != null:
		material_maker.hide()
		material_maker.queue_free()
		material_maker = null

func generate_material(ptex_filename: String) -> Material:
	var generator = MMGenLoader.load_gen(ptex_filename)
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
