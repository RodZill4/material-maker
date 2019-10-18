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
	if has_node("gen_parameters"):
		return get_node("gen_parameters").get_parameter_defs()
	return []

func set_parameter(p, v):
	if has_node("gen_parameters"):
		return get_node("gen_parameters").set_parameter(p, v)

func get_input_defs():
	if has_node("gen_inputs"):
		return get_node("gen_inputs").get_output_defs()
	return []

func get_output_defs():
	if has_node("gen_outputs"):
		return get_node("gen_outputs").get_input_defs()
	return []

func source_changed(input_index : int):
	if has_node("gen_inputs"):
		return get_node("gen_inputs").source_changed(input_index)

func get_port_source(gen_name: String, input_index: int) -> OutputPort:
	if gen_name == "gen_inputs":
		var parent = get_parent()
		if parent != null and parent.get_script() == get_script():
			return parent.get_port_source(name, input_index)
	else:
		for c in connections:
			if c.to == gen_name and c.to_port == input_index:
				var src_gen = get_node(c.from)
				if src_gen != null:
					if src_gen.get_script() == get_script():
						return src_gen.get_port_source("gen_outputs", c.from_port)
					return OutputPort.new(src_gen, c.from_port)
	return null

func get_port_targets(gen_name: String, output_index: int) -> Array:
	var rv = []
	for c in connections:
		if c.from == gen_name and c.from_port == output_index:
			var tgt_gen = get_node(c.to)
			if tgt_gen != null:
				rv.push_back(InputPort.new(tgt_gen, c.to_port))
	return rv

func add_generator(generator : MMGenBase):
	var name = generator.name
	var index = 1
	while has_node(name):
		index += 1
		name = generator.name + "_" + str(index)
	generator.name = name
	add_child(generator)

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
	# check the new connection does not create a loop
	var spreadlist = [ InputPort.new(to, to_port) ]
	while !spreadlist.empty():
		var input : InputPort = spreadlist.pop_front()
		for o in input.generator.follow_input(input.input_index):
			if o.generator == from and o.output_index == from_port:
				return false
			for t in o.generator.get_parent().get_port_targets(o.generator.name, o.output_index):
				spreadlist.push_back(t)
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
	var outputs = get_node("gen_outputs")
	if outputs != null:
		var rv = outputs._get_shader_code(uv, output_index, context)
		while rv is GDScriptFunctionState:
			rv = yield(rv, "completed")
		return rv
	return { globals=[], defs="", code="", textures={} }

func _serialize(data):
	data.label = label
	data.nodes = []
	for c in get_children():
		data.nodes.append(c.serialize())
	data.connections = connections
	return data

func edit(node):
	node.get_parent().call_deferred("update_view", self)

func create_subgraph(gens):
	# Remove material, gen_inputs and gen_outputs nodes
	var generators = []
	var center = Vector2(0, 0)
	var left_bound = 65535
	var right_bound = -65536
	var count = 0
	for g in gens:
		if g.name != "Material" and g.name != "gen_inputs" and g.name != "gen_outputs":
			generators.push_back(g)
			var p = g.position
			center += p
			count += 1
			if left_bound > p.x: left_bound = p.x
			if right_bound < p.x: right_bound = p.x
	if count == 0:
		return
	center /= count
	var new_graph = get_script().new()
	new_graph.name = "graph"
	add_generator(new_graph)
	new_graph.position = center
	var names : Array = []
	for g in generators:
		names.push_back(g.name)
		remove_child(g)
		new_graph.add_generator(g)
	var new_graph_connections = []
	var my_new_connections = []
	var gen_inputs = null
	var gen_outputs = null
	var inputs = []
	var outputs = []
	for c in connections:
		var src_name = c.from+"."+str(c.from_port)
		if names.find(c.from) != -1 and names.find(c.to) != -1:
			new_graph_connections.push_back(c)
		elif names.find(c.from) != -1:
			var port_index = outputs.find(src_name)
			if port_index == -1:
				port_index = outputs.size()
				outputs.push_back(src_name)
				if gen_outputs == null:
					gen_outputs = MMGenIOs.new()
					gen_outputs.name = "gen_outputs"
					gen_outputs.position = Vector2(right_bound+300, center.y)
					new_graph.add_generator(gen_outputs)
				gen_outputs.ports.push_back( { name="port"+str(port_index), type="rgba" } )
				print(gen_outputs.ports)
			my_new_connections.push_back( { from=new_graph.name, from_port=port_index, to=c.to, to_port=c.to_port } )
			new_graph_connections.push_back( { from=c.from, from_port=c.from_port, to="gen_outputs", to_port=port_index } )
		elif names.find(c.to) != -1:
			var port_index = inputs.find(src_name)
			if port_index == -1:
				port_index = inputs.size()
				inputs.push_back(src_name)
				if gen_inputs == null:
					gen_inputs = MMGenIOs.new()
					gen_inputs.name = "gen_inputs"
					gen_inputs.position = Vector2(left_bound-300, center.y)
					new_graph.add_generator(gen_inputs)
				gen_inputs.ports.push_back( { name="port"+str(port_index), type="rgba" } )
			my_new_connections.push_back( { from=c.from, from_port=c.from_port, to=new_graph.name, to_port=port_index } )
			new_graph_connections.push_back( { from="gen_inputs", from_port=port_index, to=c.to, to_port=c.to_port } )
		else:
			my_new_connections.push_back(c)
	connections = my_new_connections
	new_graph.connections = new_graph_connections
	for g in generators:
		if g.get_script() == load("res://addons/material_maker/engine/gen_remote.gd"):
			g.name = "gen_parameters"
			break
