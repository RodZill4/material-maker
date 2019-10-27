tool
extends Object
class_name MMGenLoader

const STD_GENDEF_PATH = "res://addons/material_maker/nodes"

static func generator_name_from_path(path : String) -> String:
	for p in [ STD_GENDEF_PATH, OS.get_executable_path().get_base_dir()+"/generators" ]:
		print(p)
	print(path.get_base_dir())
	return path.get_basename().get_file()

static func load_gen(filename: String) -> MMGenBase:
	var file = File.new()
	if file.open(filename, File.READ) == OK:
		var data = parse_json(file.get_as_text())
		return create_gen(data)
	return null

static func add_to_gen_graph(gen_graph, generators, connections) -> Dictionary:
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
			if gen_graph.connect_children(gen_graph.get_node(c.from), c.from_port, gen_graph.get_node(c.to), c.to_port):
				rv.connections.append(c)
	return rv

static func create_gen(data) -> MMGenBase:
	var guess = [
		{ keyword="connections", type=MMGenGraph },
		{ keyword="nodes", type=MMGenGraph },
		{ keyword="shader_model", type=MMGenShader },
		{ keyword="model_data", type=MMGenShader },
		{ keyword="convolution_params", type=MMGenConvolution },
		{ keyword="widgets", type=MMGenRemote }
	]
	var types = {
		material = MMGenMaterial,
		buffer = MMGenBuffer,
		image = MMGenImage,
		switch = MMGenSwitch
	}
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
		elif data.type == "comment":
			generator = MMGenComment.new()
			if data.has("text"):
				generator.text = data.text
			if data.has("size"):
				generator.size = Vector2(data.size.x, data.size.y)
		elif data.type == "image":
			generator = MMGenImage.new()
		elif data.type == "ios":
			generator = MMGenIOs.new()
			generator.ports = data.ports
		elif data.type == "switch":
			generator = MMGenSwitch.new()
		else:
			var file = File.new()
			var gen_paths = [ STD_GENDEF_PATH, OS.get_executable_path().get_base_dir()+"/generators" ]
			for p in gen_paths:
				if file.open(p+"/"+data.type+".mmg", File.READ) == OK:
					generator = create_gen(parse_json(file.get_as_text()))
					generator.model = data.type
					file.close()
					break
				elif file.open(p+"/"+data.type+".mmn", File.READ) == OK:
					generator = MMGenShader.new()
					generator.model = data.type
					generator.set_shader_model(parse_json(file.get_as_text()))
					file.close()
					break
			if generator == null:
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
				generator.set_parameter(p, MMType.deserialize_value(data.parameters[p]))
		else:
			for p in generator.get_parameter_defs():
				if data.has(p.name) and p.name != "type":
					generator.set_parameter(p.name, MMType.deserialize_value(data[p.name]))
		generator._post_load()
	return generator

static func get_generator_list() -> Array:
	var rv = []
	var dir : Directory = Directory.new()
	for p in [ STD_GENDEF_PATH, OS.get_executable_path().get_base_dir()+"/generators" ]:
		dir.open(p)
		dir.list_dir_begin(true)
		while true:
			var f = dir.get_next()
			if f == "":
				break
			if f.right(f.length()-4) == ".mmg":
				var n = f.left(f.length()-4)
				if rv.find(n) == -1:
					rv.push_back(n)
	rv.sort()
	return rv
