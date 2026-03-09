## export.gd — Export command handlers for Material Maker MCP
##
## Handles export_material, export_for_engine, and list_export_profiles commands.
## Uses the real Material Maker APIs:
##   - graph_edit.get_material_node() -> MMGenMaterial
##   - material_node.render_output(output_index, size_vec) -> Image  (async)
##   - material_node.export_material(prefix, profile, size, command_line)  (async)
##   - material_node.get_export_profiles() -> Array[String]
##
## Written for Godot 4.x.

extends RefCounted

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Supported output image formats.
const SUPPORTED_FORMATS: Dictionary = {
	"png": "png",
	"exr": "exr",
	"jpg": "jpg",
}

## Map type names to MMGenMaterial output indices.
## These correspond to the outputs defined in material.mmg.
const MAP_OUTPUT_INDEX: Dictionary = {
	"albedo": 0,       # Albedo + Opacity (rgba)
	"orm": 1,          # ORM combined: AO/Roughness/Metallic as RGB
	"emission": 2,     # Emission (rgb)
	"normal": 3,       # Normal OpenGL (rgb)
	"depth": 4,        # Depth (f)
	"sss": 5,          # Subsurface scattering (f)
	"ao": 9,           # Ambient occlusion only (f)
	"metallic": 12,    # Metallic only (f)
	"roughness": 13,   # Roughness only (f)
}

## All map types available for individual rendering.
const ALL_MAP_TYPES: Array[String] = [
	"albedo", "orm", "emission", "normal", "depth",
	"sss", "ao", "metallic", "roughness",
]

## Engine name to MM export profile mapping.
const ENGINE_PROFILES: Dictionary = {
	"godot": "Godot/Godot 4 ORM",
	"unity": "Unity/3D",
	"unreal": "Unreal/Unreal Engine 5",
	"blender": "Blender",
}

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _main_window = null

# ---------------------------------------------------------------------------
# Initialisation
# ---------------------------------------------------------------------------

func init(main_window) -> void:
	_main_window = main_window

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Get the current MMGraphEdit from the main window.
func _get_graph_edit():
	if _main_window == null:
		return null
	return _main_window.get_current_graph_edit()


## Get the MMGenMaterial node from the current graph.
func _get_material_node():
	var graph_edit = _get_graph_edit()
	if graph_edit == null:
		return null
	return graph_edit.get_material_node()


## Convert pixel resolution to MM's power-of-two exponent.
## e.g. 1024 -> 10, 2048 -> 11, 4096 -> 12
func _resolution_to_exponent(resolution: int) -> int:
	return int(log(float(resolution)) / log(2.0))


## Ensure a directory exists, creating it recursively if needed.
func _ensure_directory(path: String) -> Error:
	if DirAccess.dir_exists_absolute(path):
		return OK
	return DirAccess.make_dir_recursive_absolute(path)


## Save an Image to disk in the specified format.
func _save_image(image: Image, file_path: String, format: String) -> Error:
	match format:
		"png":
			return image.save_png(file_path)
		"jpg":
			return image.save_jpg(file_path, 0.9)
		"exr":
			return image.save_exr(file_path, false)
		_:
			return ERR_INVALID_PARAMETER


## Construct a standardised error dictionary.
func _error(message: String) -> Dictionary:
	return { "error": true, "message": message }

# ---------------------------------------------------------------------------
# export_material
# ---------------------------------------------------------------------------

## Export the current material as individual texture map files.
##
## Params:
##   output_path : String — Directory to write files into.
##   format      : String — "png", "exr", or "jpg" (default "png").
##   resolution  : int    — Render resolution in pixels (default 1024).
##   maps        : Array  — Optional list of map type names to export.
##                          Defaults to all available map types.
##
## Uses render_output() per map for full control over format and naming.
func export_material(params: Dictionary):
	# Validate output_path
	if not params.has("output_path") or str(params["output_path"]).strip_edges().is_empty():
		return _error("Missing required parameter: output_path")
	var output_path: String = str(params["output_path"]).strip_edges()

	# Validate format
	var format: String = str(params.get("format", "png")).strip_edges().to_lower()
	if not SUPPORTED_FORMATS.has(format):
		return _error("Unsupported format '%s'. Must be one of: %s" % [format, ", ".join(SUPPORTED_FORMATS.keys())])

	# Validate resolution
	var resolution: int = int(params.get("resolution", 1024))
	if resolution <= 0 or (resolution & (resolution - 1)) != 0:
		return _error("Invalid resolution %d. Must be a positive power of two." % resolution)

	# Determine which maps to export
	var maps: Array = []
	if params.has("maps") and params["maps"] is Array:
		for map_name in params["maps"]:
			var name_str: String = str(map_name).strip_edges().to_lower()
			if not MAP_OUTPUT_INDEX.has(name_str):
				return _error("Unknown map type '%s'. Must be one of: %s" % [name_str, ", ".join(ALL_MAP_TYPES)])
			maps.append(name_str)
	else:
		maps = ALL_MAP_TYPES.duplicate()

	if maps.is_empty():
		return _error("No map types specified for export.")

	# Ensure output directory exists
	var dir_err: Error = _ensure_directory(output_path)
	if dir_err != OK:
		return _error("Failed to create output directory '%s' (Error %d)." % [output_path, dir_err])

	# Get the material node
	var material_node = _get_material_node()
	if material_node == null:
		return _error("No material node found in the current graph. Is a project loaded?")

	# Render and save each requested map
	var exported_files: Array = []
	var render_size := Vector2i(resolution, resolution)

	for map_type in maps:
		var output_index: int = MAP_OUTPUT_INDEX[map_type]
		var file_name: String = "%s.%s" % [map_type, SUPPORTED_FORMATS[format]]
		var file_path: String = output_path.path_join(file_name)

		var image = await material_node.render_output(output_index, render_size)
		if image == null or not (image is Image):
			push_warning("[MCP Export] render_output returned null for '%s' (output %d), skipping." % [map_type, output_index])
			continue

		var save_err: Error = _save_image(image, file_path, format)
		if save_err != OK:
			push_warning("[MCP Export] Failed to save '%s' (Error %d), skipping." % [file_path, save_err])
			continue

		exported_files.append({
			"map": map_type,
			"path": file_path,
			"resolution": resolution,
		})

	if exported_files.is_empty():
		return _error("Failed to export any maps. Check that the material graph has valid output nodes.")

	return { "exported_files": exported_files }

# ---------------------------------------------------------------------------
# export_for_engine
# ---------------------------------------------------------------------------

## Export the material using MM's built-in engine export profiles.
##
## Params:
##   output_path : String — Directory to write files into. The last path
##                          component is used as the file prefix.
##   engine      : String — "godot", "unity", "unreal", or "blender".
##   resolution  : int    — Render resolution in pixels (default 1024).
##
## Uses MMGenMaterial.export_material(prefix, profile, size, command_line).
func export_for_engine(params: Dictionary):
	# Validate output_path
	if not params.has("output_path") or str(params["output_path"]).strip_edges().is_empty():
		return _error("Missing required parameter: output_path")
	var output_path: String = str(params["output_path"]).strip_edges()

	# Validate engine
	if not params.has("engine") or str(params["engine"]).strip_edges().is_empty():
		return _error("Missing required parameter: engine")
	var engine: String = str(params["engine"]).strip_edges().to_lower()
	if not ENGINE_PROFILES.has(engine):
		return _error("Unsupported engine '%s'. Must be one of: %s" % [engine, ", ".join(ENGINE_PROFILES.keys())])
	var profile: String = ENGINE_PROFILES[engine]

	# Validate resolution
	var resolution: int = int(params.get("resolution", 1024))
	if resolution <= 0 or (resolution & (resolution - 1)) != 0:
		return _error("Invalid resolution %d. Must be a positive power of two." % resolution)
	var size_exponent: int = _resolution_to_exponent(resolution)

	# Ensure output directory exists
	var dir_err: Error = _ensure_directory(output_path)
	if dir_err != OK:
		return _error("Failed to create output directory '%s' (Error %d)." % [output_path, dir_err])

	# Get the material node
	var material_node = _get_material_node()
	if material_node == null:
		return _error("No material node found in the current graph. Is a project loaded?")

	# Build file prefix: output_path/base_name
	var base_name: String = output_path.get_file()
	if base_name.is_empty():
		base_name = "material"
	var prefix: String = output_path.path_join(base_name)

	# Call MM's built-in export pipeline (async).
	# export_material(prefix, profile, size, command_line)
	#   size = power-of-two exponent (0 = use material's default)
	#   command_line = true suppresses UI dialogs
	await material_node.export_material(prefix, profile, size_exponent, true)

	return {
		"engine": engine,
		"profile": profile,
		"output_path": output_path,
		"prefix": prefix,
		"resolution": resolution,
	}

# ---------------------------------------------------------------------------
# list_export_profiles
# ---------------------------------------------------------------------------

## List all available export profiles from the current material node.
##
## Params: none required.
##
## Returns an array of profile name strings (e.g. "Godot/Godot 4 ORM").
func list_export_profiles(params: Dictionary) -> Dictionary:
	var material_node = _get_material_node()
	if material_node == null:
		return _error("No material node found in the current graph. Is a project loaded?")

	var profiles = material_node.get_export_profiles()

	return { "profiles": profiles }
