tool
class_name MMPaths

const STD_GENDEF_PATH = "res://addons/material_maker/nodes"

static func get_resource_dir() -> String:
	return OS.get_executable_path().get_base_dir()

static func get_nodes_paths() -> Array:
	return [ STD_GENDEF_PATH, get_resource_dir()+"/nodes" ]
