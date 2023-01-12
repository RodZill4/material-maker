extends Control
class_name MMLServer

var _server : WebSocketServer = WebSocketServer.new()
var port = 6001
var project : MMGraphEdit
var _remote : MMGenRemote
var remote_params_gens_dict = {}
var local_params_gens_dict = {}

signal informing

var command_key_requirements : Dictionary = {
	"ping" : [],
	"load_ptex" : ["filepath"]
}

var map_to_output_index = {
	"albedo" : 0,
	"roughness" : 13,
	"metallicity" : 12,
	"normal" : 7,
	"depth" : 8,
	"sss" : 5,
	"emission" : 2,
	"occlusion" : 9,
	"displace" : 8 
}

func _ready():
	set_process(false)
	
func start():
	print("start()")
	var error = _server.listen(port)
	if error != OK:
		inform("Error setting up server. (Has a server already been started?)")
		return
	_server.connect("client_connected", self, "_connected")
	_server.connect("client_disconnected", self, "_disconnected")
	_server.connect("client_close_request", self, "_close_request")
	_server.connect("data_received", self, "_on_data")
	set_process(true)
	
func stop():
	print("stop()")
	_server.stop()
	set_process(false)
	
func toggle(boolean : bool) -> void:
	if boolean:
		start()
	else:
		stop()
	
func _connected(id, proto):
	inform("Client %d connected with protocol: %s" % [id, proto])
	
func _close_request(id, code, reason):
	inform("Client %d disconnecting with code: %d, reason: %s" % [id, code, reason])
	
func _disconnected(id, was_clean = false):
	inform("Client %d disconnected, clean: %s" % [id, str(was_clean)])
	
func _on_data(id):
	print("Packet received.")
	var pkt : PoolByteArray = _server.get_peer(id).get_packet()
	var pkt_string : String = pkt.get_string_from_ascii()
	inform("Got data from client %d: %s, ... echoing" % [id, pkt_string.substr(0, 140)])
	
	print("pkt_string: ", pkt_string)
	var data = parse_json(pkt_string)
	print("Data: ",str(data).substr(0,140))
	var command : String = data["command"]
	match command:
		
		"ping":
			var data_dict = { "command" : "pong" }
			send_json_data(id, data_dict)
			
		"load_ptex":
			var filepath : String = data["filepath"]
			load_ptex(filepath)
			inform_and_send(id, "Finished loading ptex file.")
			var remote_parameters = find_parameters_in_remote(_remote)		
			var local_parameters = find_local_parameters()
			if data["reset_parameters"]:
				var set_remote_parameters_command = { "command":"init_parameters", "image_name":data["image_name"], "parameters_type":"remote", "parameters":remote_parameters}		
				send_json_data(id, set_remote_parameters_command)
				var set_local_parameters_command = { "command":"init_parameters", "image_name":data["image_name"], "parameters_type":"local", "parameters":local_parameters}
				send_json_data(id, set_local_parameters_command)
				var parameters_loaded_notify_command = { "command":"parameters_loaded"}
				send_json_data(id, parameters_loaded_notify_command)
			else:
				var request_parameters_command = { "command":"request_parameters", "image_name":data["image_name"]}
				send_json_data(id, request_parameters_command)
				
		"request_render":
			inform("Performing render")
			var render_result
			for map in data['maps']:
				render_result = render(map_to_output_index[map], data["resolution"])
				while render_result is GDScriptFunctionState:
						render_result = yield(render_result, "completed")
				send_image_data(id, data['image_name'], map, data['resolution'], render_result) 
				
		"parameter_change":
			var node_name = data["node_name"]
			var parameter_name = data["param_name"]
			var render_result
			if not (data["parameter_type"] == "remote" or data["parameter_type"] == "local"):
				inform("Error interpreting 'parameter_type' argument.")
				return
			var is_remote = data["parameter_type"] == "remote"
			print("parameter_change")
			if data["render"] == 'False':
				set_parameter_value(node_name, parameter_name, data['param_value'], is_remote)
				return
			if data["render"] != 'True':
				inform("Error interpreting 'render' argument.")
			for map in data["maps"]:
				if data["parameter_type"] == "remote":
					render_result = change_parameter_and_render(node_name, parameter_name, data["param_value"], map, data["resolution"], true)
				elif data["parameter_type"] == "local":
					render_result = change_parameter_and_render(node_name, parameter_name, data["param_value"], map, data["resolution"],  false)
				else:
					inform_and_send(id, "ERROR: Unable to determine parameter type.")

				while render_result is GDScriptFunctionState:
					render_result = yield(render_result, "completed")
				
				send_image_data(id, data["image_name"], map, data["resolution"], render_result) 
			inform_and_send(id, "Parameter changed, render finished and transfered.")
			
		"set_multiple_parameters":
			print(data)
			if local_params_gens_dict.empty() and remote_params_gens_dict.empty():
				inform("Finding parameters")
				find_parameters_in_remote(_remote)		
				find_local_parameters()
			for parameter_string in data["parameters"]:
				var parameter = parse_json(parameter_string)
				var node_name = parameter["node_name"]
				var param_name = parameter["param_name"]
				var param_label = parameter["param_label"]
				var param_value = parameter["param_value"]
				var is_remote = parameter["param_type"] == "remote"
				set_parameter_value(node_name, param_name, param_value, is_remote)
				
			var parameters_loaded_notify_command = { "command":"parameters_loaded"}
			send_json_data(id, parameters_loaded_notify_command)
		_:
			inform_and_send(id, "Unable  to read message command.")	

	
func send_json_data(id : int, data : Dictionary) -> void:
	var response = PoolByteArray()
	response.append_array("json|".to_utf8())
	var json_data = to_json(data)
	response.append_array(json_data.to_utf8())
	_server.get_peer(id).put_packet(response)
	
func send_image_data(id : int, image_name : String, map : String, resolution : int, image_data : PoolByteArray) -> void: # Unfortunately there's apparently a limit to the size of elements in Godot's dictionaries, this is a workaround
	var response = PoolByteArray()
	var suffix = "_" + map if map != "albedo" else ""
	var prefix_size = 16 + len(image_name) + len(suffix)
	var prefix_size_string = str(prefix_size).pad_zeros(3)
	var padded_resolution_string = str(resolution).pad_zeros(4)
	response.append_array("image|{}|{}|{}|".format([prefix_size_string, image_name + suffix, padded_resolution_string], "{}").to_utf8())
	response.append_array(image_data)
	_server.get_peer(id).put_packet(response)
	
func load_ptex(filepath : String) -> void:
	#var material_loaded = mm_globals.main_window.do_load_material(filepath, true, false)
	var material_loaded = mm_globals.main_window.do_load_material(filepath, true)
	project = mm_globals.main_window.get_current_project()
	var material_node = project.get_material_node()
	_remote = get_remote()
	find_local_parameters()


func render(output_index : int, resolution : int):
	var material_node = project.get_material_node()
	var result = material_node.render(material_node, output_index, resolution)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	var image_output : Image = result.texture.get_data()
	image_output.convert(Image.FORMAT_RGBA8)
	var output = image_output.get_data()
	result.release(material_node)
	return output
		
func get_remote() -> MMGenRemote:
	for child in project.top_generator.get_children():
		if child.get_type() == "remote":
			return child
	inform("Warning: Remote node not found.")
	return null

func find_parameters_in_remote(remote_gen : MMGenRemote) -> Array:
	remote_params_gens_dict.clear()
	var output = []
	if not remote_gen:
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
	
func inform(message : String) -> void:
	print(message)
	mm_globals.set_tip_text(message)
	
func inform_and_send(id : int, message : String) -> void:
	inform(message)
	var data = { "command":"inform", "info":message }
	send_json_data(id, data)
	
func change_parameter_and_render(node_name : String, param_name : String, parameter_value : String, map : String, resolution : int, is_remote : bool) -> void:
	set_parameter_value(node_name, param_name, parameter_value, is_remote)
	print("ResolutioN: ", resolution)
	var result = render(map_to_output_index[map], resolution)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	return result
	
var i = 0
func _process(delta):
	# DEBUG:
	#if i % 30 == 0:
	#	print("Connection status: ", _server.get_connection_status())
	i += 1
	_server.poll()

func try_set_port_string(port_string : String):
	if not port_string.is_valid_integer():
		return
	
func set_port(new_port : int):
	print("Setting port to ", new_port)
	port = new_port
	_server.stop()
	_server.listen(new_port)
