@tool
extends MMGenBuffer
class_name MMGenAutoExport


func get_type() -> String:
	return "autoexport"

func get_type_name() -> String:
	return "Auto Export"

func get_parameter_defs() -> Array:
	var parameter_defs : Array = [
		{ name="size",label="Size", type="size", first=4, last=13, default=4 },
		{ name="filename", label="Filename", type="string", default="test.png", longdesc="Name of the exported file" }
	]
	return parameter_defs

func on_buffer_updated():
	var file_name : String = get_parameter("filename")
	
	var graph_node : MMGenBase = self
	while graph_node.get_parent() is MMGenBase:
		graph_node = graph_node.get_parent()
	if graph_node and graph_node.has_meta("file_path"):
		var project_file_path : String = graph_node.get_meta("file_path")
		file_name = project_file_path.get_base_dir().path_join(file_name)
	
	texture.save_to_file(file_name)
