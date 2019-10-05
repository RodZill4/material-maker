tool
extends Object
class_name MMGenLoader

static func load_gen(filename: String) -> MMGenBase:
	var file = File.new()
	if file.open(filename, File.READ) == OK:
		var data = parse_json(file.get_as_text())
		return create_gen(data)
	return null

static func add_to_gen_graph(gen_graph, generators, connections):
	var rv = { generators=[], connections=[] }
	var gennames = {}
	for n in generators:
		var g = create_gen(n)
		if g != null:
			var orig_name = g.name
			gen_graph.add_generator(g)
			rv.generators.append(g)
			gennames[orig_name] = g.name
	for c in connections:
		if gennames.has(c.from) and gennames.has(c.to):
			c.from = gennames[c.from]
			c.to = gennames[c.to]
			gen_graph.connections.append(c)
			rv.connections.append(c)
	return rv

static func create_gen(data) -> MMGenBase:
	var generator = null
	if data.has("connections") and data.has("nodes"):
		generator = MMGenGraph.new()
		if data.has("label"):
			generator.label = data.label
		add_to_gen_graph(generator, data.nodes, data.connections)
	elif data.has("shader_model"):
		generator = MMGenShader.new()
		generator.set_shader_model(data.shader_model)
	elif data.has("convolution_params"):
		generator = MMGenConvolution.new()
		generator.set_convolution_params(data.convolution_params)
	elif data.has("model_data"):
		generator = MMGenShader.new()
		generator.set_shader_model(data.model_data)
	elif data.has("widgets"):
		generator = MMGenRemote.new()
		generator.set_widgets(data.widgets.duplicate(true))
	elif data.has("type"):
		if data.type == "material":
			generator = MMGenMaterial.new()
		elif data.type == "buffer":
			generator = MMGenBuffer.new()
		elif data.type == "image":
			generator = MMGenImage.new()
		elif data.type == "ios":
			generator = MMGenIOs.new()
			generator.ports = data.ports
		elif data.type == "switch":
			generator = MMGenSwitch.new()
		else:
			var file = File.new()
			var gen_path = OS.get_executable_path().get_base_dir()+"/generators"
			if file.open(gen_path+"/"+data.type+".mmg", File.READ) == OK:
				generator = create_gen(parse_json(file.get_as_text()))
				generator.model = data.type
				file.close()
			elif file.open("res://addons/material_maker/nodes/"+data.type+".mmg", File.READ) == OK:
				generator = create_gen(parse_json(file.get_as_text()))
				generator.model = data.type
				file.close()
			elif file.open("res://addons/material_maker/nodes/"+data.type+".mmn", File.READ) == OK:
				generator = MMGenShader.new()
				generator.model = data.type
				generator.set_shader_model(parse_json(file.get_as_text()))
				file.close()
			else:
				print("Cannot find description for "+data.type)
		if generator != null:
			generator.name = data.type
	else:
		print("LOADER: data not supported:"+str(data))
	if generator != null:
		if data.has("name"):
			generator.name = data.name
		if data.has("node_position"):
			generator.position.x = data.node_position.x
			generator.position.y = data.node_position.y
		if data.has("parameters"):
			for p in data.parameters.keys():
				generator.parameters[p] = MMType.deserialize_value(data.parameters[p])
	return generator
