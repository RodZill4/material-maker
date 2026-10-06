@tool
class_name MMPaths

const WEBSITE_ADDRESS : String = "https://www.materialmaker.org"
#const WEBSITE_ADDRESS : String = "http://localhost:3000"

const STD_GENDEF_PATH = "res://addons/material_maker/nodes"

const DOC_ADDRESS : String = "https://rodzill4.github.io/material-maker/doc"

static func get_resource_dir() -> String:
	if Engine.is_editor_hint():
		return ProjectSettings.globalize_path("res://material_maker")
	if OS.get_name() == "Android":
		return "user:/"
	return OS.get_executable_path().get_base_dir()

static func get_nodes_paths() -> Array:
	return [ STD_GENDEF_PATH, get_resource_dir()+"/nodes", "user://shared_nodes" ]
