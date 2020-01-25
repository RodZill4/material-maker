tool
extends EditorImportPlugin

var plugin = null

const PRESET_NAMES = [ "Render in game", "Prerender" ]
const PRESET_OPTIONS = [
	[{ name="render", default_value=false }, { name="scale", default_value=1.0 }],
	[{ name="render", default_value=true }, { name="scale", default_value=1.0 }]
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
	return "SpatialMaterial"

func get_save_extension() -> String:
	return "tres"

func get_visible_name() -> String:
	return "Material Maker Importer"

func import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> int:
	var filename = save_path + "." + get_save_extension()
	var material = null
	if options.render:
		material = plugin.generate_material(source_file)
		while material is GDScriptFunctionState:
			material = yield(material, "completed")
	else:
		material = SpatialMaterial.new()
		material.set_script(preload("res://addons/material_maker/import_plugin/ptex_spatial_material.gd"))
		var file : File = File.new()
		if file.open(source_file, File.READ) == OK:
			material.set_ptex_no_render(to_json(parse_json(file.get_as_text())))
			file.close()
	if material != null:
		material.uv1_scale = options.scale * Vector3(1.0, 1.0, 1.0)
		ResourceSaver.save(filename, material)
	return OK
