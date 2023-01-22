extends Node
#class_name MMLProjectContainer
class_name MMLProjectContainer

# Class that finds and contains data from MM projects to be used along MMLServer

var remote_params_gens_dict : Dictionary = {} 
var local_params_gens_dict : Dictionary = {}
var project : MMGraphEdit
var remote_gen : MMGenRemote
#var _image_name : String
var material_node : MMGenMaterial
#var server : MMLServer
var remote_parameters
var local_parameters

func init(project : MMGraphEdit, _image_name : String):
	#image_name = _image_name
	self.project = project
	material_node = project.get_material_node()
	remote_gen = find_remote()
	remote_parameters = find_remote_parameters()
	local_parameters = find_local_parameters()
	
func inform(text):
	print("Unimplemented")
	
func find_remote() -> MMGenRemote:
	for child in project.top_generator.get_children():
		if child.get_type() == "remote":
			return child
	inform("Warning: Remote node not found.")
	return null
	
func find_remote_parameters() -> Array:
	remote_params_gens_dict.clear()

	var output = []
	#if not remote_gen:
	if remote_gen == null:
		inform("No remote node found.")
		return output
	for widget in remote_gen.widgets:
		for lw in widget.linked_widgets:
			var top_gen = project.top_generator.get_node(lw.node)
			var param = top_gen.get_parameter(lw.widget)
			output.push_back( { 'node' : lw.node, 'param_name' : lw.widget, 'param_value' : param, 'param_label':widget.label } )
			remote_params_gens_dict["{}/{}".format([lw.node, lw.widget], "{}")] = top_gen
	return output
	
func find_local_parameters() -> Array:
	var output = []
	for child in project.top_generator.get_children():
		if child.get_type() == "remote":
			continue
		for param in child.parameters:
			var identifier = "{}/{}".format([child.get_hier_name(), param], "{}")
			local_params_gens_dict[identifier] = child
			output.push_back( { 'node' : child.get_hier_name(), 'param_name' : param, 'param_label':"", 'param_value' : child.get_parameter(param), 'param_type':child.get_parameter_def(param) } )
	print("local_params_gens_dict: ", local_params_gens_dict)
	return output

func set_parameter_value(node_name : String, param_name : String, value : String, is_remote : bool):
	var dict = remote_params_gens_dict if is_remote else local_params_gens_dict
	var identifier = "{}/{}".format([node_name, param_name], "{}")
	var gen = dict[identifier]
	var type = gen.get_parameter_def(param_name).type
	var typed_value = null
	if  type == "enum" or type == "boolean" or type == "size":
		typed_value = int(value)
	elif type == "float":
		typed_value = float(value)
	elif value.is_valid_integer():
		typed_value = value
	else:
		inform("Invalid parameter value input.")
		return
	gen.set_parameter(param_name, typed_value)
