tool
extends Object
class_name MMGenLoader

func load_gen(filename: String) -> MMGenBase:
	var file = File.new()
	if file.open(filename, File.READ) == OK:
		var data = parse_json(file.get_as_text())
		return create_gen(data)
	return null

func add_to_gen_graph(gen_graph, generators, connections):
	var rv = { generators=[], connections=[] }
	for n in generators:
		var g = create_gen(n)
		if g != null:
			var name = g.name
			var index = 1
			while gen_graph.has_node(name):
				index += 1
				name = g.name + "_" + str(index)
			g.name = name
			gen_graph.add_child(g)
			rv.generators.append(g)
	for c in connections:
		gen_graph.connections.append(c)
		rv.connections.append(c)
	return rv

func create_gen(data) -> MMGenBase:
	var generator = null
	if data.has("connections") and data.has("nodes"):
		generator = MMGenGraph.new()
		add_to_gen_graph(generator, data.nodes, data.connections)
	elif data.has("shader_model"):
		generator = MMGenShader.new()
		generator.set_shader_model(data.shader_model)
	elif data.has("type"):
		if data.type == "material":
			generator = MMGenMaterial.new()
		elif data.type == "buffer":
			generator = MMGenBuffer.new()
		elif data.type == "image":
			generator = MMGenImage.new()
		else:
			var file = File.new()
			if file.open("res://addons/material_maker/library/"+data.type+".mml", File.READ) == OK:
				print("loaded description "+data.type+".mml")
				generator = create_gen(parse_json(file.get_as_text()))
				file.close()
			elif file.open("res://addons/material_maker/nodes/"+data.type+".mmn", File.READ) == OK:
				generator = MMGenShader.new()
				print("loaded description "+data.type+".mmn")
				generator.set_shader_model(parse_json(file.get_as_text()))
				file.close()
			else:
				print("Cannot find description for "+data.type)
		if generator != null:
			generator.name = data.type
	else:
		print(data)
	if generator != null:
		if data.has("name"):
			generator.name = data.name
		if data.has("node_position"):
			generator.position.x = data.node_position.x
			generator.position.y = data.node_position.y
		if data.has("parameters"):
			for p in data.parameters.keys():
				generator.parameters[p] = data.parameters[p]
	return generator
