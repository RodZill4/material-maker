tool
extends EditorImportPlugin

var plugin = null

const PRESET_NAMES = [ "Skip", "Import with Material Maker" ]
const PRESET_OPTIONS = [
	[{ name="skip", default_value=true }],
	[{ name="skip", default_value=false }]
]

func _init(p) -> void:
	plugin = p

func get_import_options(preset : int) -> Array:
	return PRESET_OPTIONS[preset]

func get_import_order() -> int:
	return 1

func get_importer_name() -> String:
	return "material_maker.import"

func get_option_visibility(option: String, options: Dictionary) -> bool:
	return true

func get_preset_count() -> int:
	return 2

func get_preset_name(preset: int) -> String:
	return PRESET_NAMES[preset]

func get_priority() -> float:
	return 0.1

func get_recognized_extensions() -> Array:
	return [ "ptex" ]

func get_resource_type() -> String:
	return "Material"

func get_save_extension() -> String:
	return "tres"

func get_visible_name() -> String:
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
