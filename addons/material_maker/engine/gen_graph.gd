tool
extends MMGenBase
class_name MMGenGraph

var label : String = "Graph"
var connections = []

func get_type():
	return "graph"

func get_type_name():
	return label

func get_parameter_defs():
	return []

func get_input_defs():
	var inputs = get_node("gen_inputs")
	if inputs != null:
		return inputs.get_input_defs()
	return []

func get_output_defs():
	var outputs = get_node("gen_outputs")
	if outputs != null:
		return outputs.get_output_defs()
	return []

func source_changed(input_index : int):
	var generator = get_node("gen_inputs")
	if generator != null:
		generator.source_changed(input_index)

func get_port_source(gen_name: String, input_index: int) -> OutputPort:
	if gen_name == "gen_inputs":
		var parent = get_parent()
		if parent != null and parent.get_type() == "graph":
			return parent.get_port_source(name, input_index)
	else:
		for c in connections:
			if c.to == gen_name and c.to_port == input_index:
				var src_gen = get_node(c.from)
				if src_gen != null:
					if src_gen.get_type() == "graph":
						return src_gen.get_port_source("gen_outputs", c.from_port)
					return OutputPort.new(src_gen, c.from_port)
	return null

func get_port_targets(gen_name: String, output_index: int) -> InputPort:
	var rv = []
	for c in connections:
		if c.from == gen_name and c.from_port == output_index:
			var tgt_gen = get_node(c.to)
			if tgt_gen != null:
				rv.push_back(InputPort.new(tgt_gen, c.to_port))
	return rv

func remove_generator(generator : MMGenBase):
	var new_connections = []
	for c in connections:
		if c.from != generator.name and c.to != generator.name:
			new_connections.append(c)
	connections = new_connections
	generator.queue_free()
	
func replace_generator(old : MMGenBase, new : MMGenBase):
	new.name = old.name
	new.position = old.position
	remove_child(old)
	old.free()
	add_child(new)

func connect_children(from, from_port : int, to, to_port : int):
	# disconnect target
	while true:
		var remove = -1
		for i in connections.size():
			if connections[i].to == to.name and connections[i].to_port == to_port:
				remove = i
				break
		if remove == -1:
			break
		connections.remove(remove)
	# create new connection
	connections.append({from=from.name, from_port=from_port, to=to.name, to_port=to_port})
	return true

func disconnect_children(from, from_port : int, to, to_port : int):
	while true:
		var remove = -1
		for i in connections.size():
			if connections[i].from == from.name and connections[i].from_port == from_port and connections[i].to == to.name and connections[i].to_port == to_port:
				remove = i
				break
		if remove == -1:
			break
		connections.remove(remove)
	return true

func _get_shader_code(uv : String, output_index : int, context : MMGenContext):
	print("Getting shader code from graph")
	var outputs = get_node("gen_outputs")
	if outputs != null:
		print("found!")
		var rv = outputs._get_shader_code(uv, output_index, context)
		while rv is GDScriptFunctionState:
			rv = yield(rv, "completed")
		return rv
	return { defs="", code="", textures={} }

func _serialize(data):
	data.label = label
	data.nodes = []
	for c in get_children():
		data.nodes.append(c.serialize())
	data.connections = connections
	return data

func edit(node):
	node.get_parent().call_deferred("update_view", self)