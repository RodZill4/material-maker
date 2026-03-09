## scene.gd — Scene/Project command handlers for Material Maker MCP
##
## Handles commands: get_scene_info, save_project, load_project, new_project.
##
## Uses real Material Maker APIs:
##   - _main_window.get_current_graph_edit() -> MMGraphEdit
##   - graph_edit.top_generator -> MMGenGraph (root data model)
##   - graph_edit.save_path -> String (file path)
##   - graph_edit.need_save -> bool (unsaved changes flag)
##   - graph_edit.save_file(path) -> void (save to disk)
##   - graph_edit.get_material_node() -> MMGenMaterial or null
##   - _main_window.do_load_project(path) -> bool (async)
##   - _main_window.new_material() -> void (async, creates default PBR)
##
## Written for Godot 4.x / Material Maker 1.4+.

extends RefCounted

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Reference to Material Maker's MainWindow Control. Set via init().
var _main_window = null

# ---------------------------------------------------------------------------
# Initialisation
# ---------------------------------------------------------------------------

## Called by addon.gd after construction to inject the MM main window reference.
func init(main_window) -> void:
	_main_window = main_window

# ---------------------------------------------------------------------------
# Helper — get the current MMGraphEdit
# ---------------------------------------------------------------------------

## Returns the active MMGraphEdit (UI graph editor) or null if none is open.
func _get_graph_edit():
	if _main_window == null:
		return null
	return _main_window.get_current_graph_edit()

# ---------------------------------------------------------------------------
# Command: get_scene_info
# ---------------------------------------------------------------------------

## Return metadata about the current open project.
##
## Response shape:
##   { file_path, material_type, node_count, has_unsaved_changes, mm_version }
func get_scene_info(params: Dictionary) -> Dictionary:
	var graph_edit = _get_graph_edit()
	if graph_edit == null:
		return {
			"file_path": "",
			"material_type": "none",
			"node_count": 0,
			"has_unsaved_changes": false,
			"mm_version": _get_mm_version(),
		}

	var generator = graph_edit.top_generator

	# Material type — find the MMGenMaterial child node.
	var material_type: String = "unknown"
	var material_node = graph_edit.get_material_node()
	if material_node != null:
		material_type = material_node.get_type_name()

	# Node count — all children of top_generator are MMGenBase instances.
	var node_count: int = generator.get_children().size()

	return {
		"file_path": graph_edit.save_path,
		"material_type": material_type,
		"node_count": node_count,
		"has_unsaved_changes": graph_edit.need_save,
		"mm_version": _get_mm_version(),
	}

# ---------------------------------------------------------------------------
# Command: save_project
# ---------------------------------------------------------------------------

## Save the current project to disk.
##
## Params:
##   path (optional string) — file path to save to. If omitted, saves to the
##       current project's existing path. Should end in ".ptex".
##
## Response shape:
##   { saved: true, path }
func save_project(params: Dictionary) -> Dictionary:
	var graph_edit = _get_graph_edit()
	if graph_edit == null:
		return _error("No project is currently open.")

	var path: String = params.get("path", "")

	# If no path given, use the current save path.
	if path.is_empty():
		path = graph_edit.save_path

	if path.is_empty():
		return _error("No save path specified and the project has not been saved before. Provide a 'path' parameter.")

	# Ensure the path ends with .ptex (Material Maker's project extension).
	if not path.ends_with(".ptex"):
		path += ".ptex"

	graph_edit.save_file(path)

	return { "saved": true, "path": path }

# ---------------------------------------------------------------------------
# Command: load_project
# ---------------------------------------------------------------------------

## Load a .ptex project file. This is async because do_load_project() is async.
##
## Params:
##   path (string, required) — path to the .ptex file to open.
##
## Response shape:
##   { loaded: true, path, node_count }
func load_project(params: Dictionary):
	var path: String = params.get("path", "")

	if path.is_empty():
		return _error("Missing required parameter 'path'.")

	if not FileAccess.file_exists(path):
		return _error("File not found: %s" % path)

	if not path.ends_with(".ptex"):
		return _error("Expected a .ptex file, got: %s" % path.get_extension())

	if _main_window == null:
		return _error("Main window reference not set.")

	var success: bool = await _main_window.do_load_project(path)
	if not success:
		return _error("Failed to load project: %s" % path)

	# After loading, get the new graph edit and count nodes.
	var graph_edit = _get_graph_edit()
	var node_count: int = 0
	if graph_edit != null:
		node_count = graph_edit.top_generator.get_children().size()

	return { "loaded": true, "path": path, "node_count": node_count }

# ---------------------------------------------------------------------------
# Command: new_project
# ---------------------------------------------------------------------------

## Create a new default PBR material project. This is async because
## new_material() is async.
##
## Note: MM's new_material() always creates a default PBR material.
## The material_type parameter is accepted but ignored — MM does not support
## choosing the type at creation time via this API.
##
## Response shape:
##   { created: true, material_type: "pbr" }
func new_project(params: Dictionary):
	if _main_window == null:
		return _error("Main window reference not set.")

	await _main_window.new_material()

	return { "created": true, "material_type": "pbr" }

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Get the Material Maker version string.
func _get_mm_version() -> String:
	if ProjectSettings.has_setting("application/config/actual_release"):
		return ProjectSettings.get_setting("application/config/actual_release")
	return "unknown"


## Construct a standardised error dictionary.
func _error(msg: String) -> Dictionary:
	return { "error": true, "message": msg }
