extends EditorImportPlugin

var plugin = null

func _init(p):
	plugin = p

func _ready():
	pass # Replace with function body.

func get_import_options(preset : int):
	return []

func get_import_order():
	return 1

func get_importer_name():
	return "MaterialMakerImporter"

func get_option_visibility(option: String, options: Dictionary):
	return false

func get_preset_count():
	return 1

func get_preset_name(preset: int) -> String:
	return "Default"

func get_priority():
	return 1

func get_recognized_extensions():
	return [ "ptex" ]

func get_resource_type():
	return "Material"

func get_save_extension():
	return "tres"

func get_visible_name():
	return "Material Maker Importer"

func import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> int:
	var filename = save_path + "." + get_save_extension()
	var material = plugin.generate_material(source_file)
	while material is GDScriptFunctionState:
		material = yield(material, "completed")
	ResourceSaver.save(filename, material)
	return OK
