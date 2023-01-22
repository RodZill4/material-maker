extends Control
class_name MMLServer

var _server : WebSocketServer = WebSocketServer.new()
var port = 6001
var name_to_project_container = {}

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
			load_ptex(data["image_name"], filepath)
			inform_and_send(id, "Finished loading ptex file.")
			if data["reset_parameters"]:
				var project_container = name_to_project_container[data['image_name']]
				var set_remote_parameters_command = { "command":"init_parameters", "image_name":data["image_name"], "parameters_type":"remote", "parameters":project_container.remote_parameters}		
				send_json_data(id, set_remote_parameters_command)
				var set_local_parameters_command = { "command":"init_parameters", "image_name":data["image_name"], "parameters_type":"local", "parameters":project_container.local_parameters}
				send_json_data(id, set_local_parameters_command)
				var parameters_loaded_notify_command = { "command":"parameters_loaded"}
				send_json_data(id, parameters_loaded_notify_command)
			else:
				var request_parameters_command = { "command":"request_parameters", "image_name":data["image_name"]}
				send_json_data(id, request_parameters_command)
				
		"request_render":
			inform("Performing render")
			var render_result
			var material = name_to_project_container[data['image_name']].material_node
			for map in data['maps']:
				render_result = render(material, map_to_output_index[map], data["resolution"])
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
			var project_container = name_to_project_container[data['image_name']]
			var material = project_container.material_node
			print("parameter_change")
			if data["render"] == 'False':
				project_container.set_parameter_value(node_name, parameter_name, data['param_value'], is_remote)
				return
			if data["render"] != 'True':
				inform("Error interpreting 'render' argument.")
			for map in data["maps"]:
				if data["parameter_type"] == "remote":
					render_result = change_parameter_and_render(project_container, node_name, parameter_name, data["param_value"], map, data["resolution"], true)
				elif data["parameter_type"] == "local":
					render_result = change_parameter_and_render(project_container, node_name, parameter_name, data["param_value"], map, data["resolution"],  false)
				else:
					inform_and_send(id, "ERROR: Unable to determine parameter type.")

				while render_result is GDScriptFunctionState:
					render_result = yield(render_result, "completed")
				
				send_image_data(id, data["image_name"], map, data["resolution"], render_result) 
			inform_and_send(id, "Parameter changed, render finished and transfered.")
			
		"set_multiple_parameters":
			for parameter_string in data["parameters"]:
				var material = "dummy"
				var parameter = parse_json(parameter_string)
				var node_name = parameter["node_name"]
				var param_name = parameter["param_name"]
				var param_label = parameter["param_label"]
				var param_value = parameter["param_value"]
				var is_remote = parameter["param_type"] == "remote"
				var project_container = name_to_project_container[data['image_name']]
				project_container.set_parameter_value(node_name, param_name, param_value, is_remote)
				
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
	
func load_ptex(image_name : String, filepath : String) -> void:
	var material_loaded = mm_globals.main_window.do_load_material(filepath, true, false)
	var project = mm_globals.main_window.get_current_project()
	var material_node = project.get_material_node()
	var project_container = MMLProjectContainer.new();
	project_container.init(project)
	name_to_project_container[image_name] = project_container

func render(material_node : MMGenMaterial, output_index : int, resolution : int):
	var result = material_node.render(material_node, output_index, resolution)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	var image_output : Image = result.texture.get_data()
	image_output.convert(Image.FORMAT_RGBA8)
	var output = image_output.get_data()
	result.release(material_node)
	return output
	
func inform(message : String) -> void:
	print(message)
	mm_globals.set_tip_text(message)
	
func inform_and_send(id : int, message : String) -> void:
	inform(message)
	var data = { "command":"inform", "info":message }
	send_json_data(id, data)
	
func change_parameter_and_render(project_container, node_name : String, param_name : String, parameter_value : String, map : String, resolution : int, is_remote : bool) -> void:
	project_container.set_parameter_value(node_name, param_name, parameter_value, is_remote)
	var result = render(project_container.material_node, map_to_output_index[map], resolution)
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
