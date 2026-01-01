@tool
extends EditorImportPlugin

var plugin = null

const PRESET_NAMES = [ "Render in game", "Prerender" ]
const PRESET_OPTIONS = [
	[{ name="render", default_value=false }, { name="scale", default_value=1.0 }],
	[{ name="render", default_value=true }, { name="scale", default_value=1.0 }]
]

func _init(p):
	plugin = p

func _get_import_options(path: String, preset : int) -> Array[Dictionary]:
	return PRESET_OPTIONS[preset]

func _get_import_order() -> int:
	return 1

func _get_importer_name() -> String:
	return "material_maker.import"

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _get_preset_count() -> int:
	return 2

func _get_preset_name(preset: int) -> String:
	return PRESET_NAMES[preset]

func get_priority() -> float:
	return 0.1

func _get_recognized_extensions() -> PackedStringArray:
	return [ "ptex" ]

func _get_resource_type() -> String:
	return "StandardMaterial3D"

func _get_save_extension() -> String:
	return "tres"

func _get_visible_name() -> String:
	return "Material Maker Importer"

func import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> int:
	var material = null
	if options.render:
		var gen = await mm_loader.load_gen(source_file)
		if gen != null:
			plugin.add_child(gen)
			for c in gen.get_children():
				if c.has_method("get_export_profiles"):
					var result = await c.export_material(source_file.get_basename(), "Godot")
					break
			gen.queue_free()
	else:
		var filename = save_path + "." + _get_save_extension()
		material = StandardMaterial3D.new()
		material.set_script(preload("res://addons/material_maker/import_plugin/ptex_spatial_material.gd"))
		var file = FileAccess.open(source_file, FileAccess.READ)
		if file == OK:
			var test_json_conv = JSON.new()
			test_json_conv.parse(file.get_as_text())
			material.set_ptex_no_render(JSON.new().stringify(test_json_conv.get_data()))
			file.close()
		material.uv1_scale = options.scale * Vector3(1.0, 1.0, 1.0)
		ResourceSaver.save(filename, material)
	return OK
