tool
extends EditorImportPlugin

var plugin = null

const PRESET_NAMES = [ "Skip", "Import with Material Maker" ]
const PRESET_OPTIONS = [
	[{ name="skip", default_value=true }],
	[{ name="skip", default_value=false }]
]

func _init(p):
	plugin = p

func get_import_options(preset : int):
	return PRESET_OPTIONS[preset]

func get_import_order():
	return 1

func get_importer_name():
	return "material_maker.import"

func get_option_visibility(option: String, options: Dictionary):
	return true

func get_preset_count():
	return 2

func get_preset_name(preset: int) -> String:
	return PRESET_NAMES[preset]

func get_priority():
	return 0.1

func get_recognized_extensions():
	return [ "ptex" ]

func get_resource_type():
	return "Material"

func get_save_extension():
	return "tres"

func get_visible_name():
	return "Material Maker Importer"

func import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> int:
	if !options.skip:
		var filename = save_path + "." + get_save_extension()
		var material = plugin.generate_material(source_file)
		while material is GDScriptFunctionState:
			material = yield(material, "completed")
		if material != null:
			ResourceSaver.save(filename, material)
	return OK
