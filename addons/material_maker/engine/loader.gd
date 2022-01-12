tool
extends Node

var predefined_generators: Dictionary = {}

var current_project_path: String = ""

const CHECK_PREDEFINED: bool = false


func _ready() -> void:
	update_predefined_generators()


func update_predefined_generators() -> void:
	var parser
	if CHECK_PREDEFINED:
		parser = load("res://addons/material_maker/parser/glsl_parser.gd").new()
	predefined_generators = {}
	for path in MMPaths.get_nodes_paths():
		var dir = Directory.new()
		if dir.open(path) == OK:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if !dir.current_is_dir() and file_name.get_extension() == "mmg":
					var file: File = File.new()
					if file.open(path + "/" + file_name, File.READ) == OK:
						var generator = parse_json(file.get_as_text())
						if CHECK_PREDEFINED:
							if (
								generator.has("shader_model")
								and generator.shader_model.has("global")
								and generator.shader_model.global != ""
							):
								var parse_result = parser.parse(generator.shader_model.global)
								if parse_result.status != "OK":
									print(file_name + " has errors in global")
						predefined_generators[file_name.get_basename()] = generator
						file.close()
				file_name = dir.get_next()
	if false:
		var file: File = File.new()
		if file.open("predefined_nodes.json", File.WRITE) == OK:
			file.store_string(to_json(predefined_generators))
			file.close()


func get_material_nodes() -> Array:
	var rv: Array = Array()
	for g in predefined_generators.keys():
		var generator = predefined_generators[g]
		if generator.has("type") and generator.type == "material_export":
			if generator.has("shader_model") and generator.shader_model.has("name"):
				rv.push_back({name = g, label = generator.shader_model.name})
	return rv


func get_predefined_global(g: String) -> String:
	if !predefined_generators.has(g):
		return ""
	if !predefined_generators[g].has("shader_model"):
		return ""
	if !predefined_generators[g].shader_model.has("global"):
		return ""
	return predefined_generators[g].shader_model.global


func generator_name_from_path(path: String) -> String:
	for p in MMPaths.get_nodes_paths():
		print(p)
	print(path.get_base_dir())
	return path.get_basename().get_file()


func load_gen(filename: String) -> MMGenBase:
	var file = File.new()
	if file.open(filename, File.READ) == OK:
		var data = parse_json(file.get_as_text())
		current_project_path = filename.get_base_dir()
		var generator = create_gen(data)
		current_project_path = ""
		return generator
	return null


func add_to_gen_graph(gen_graph, generators, connections, position: Vector2 = Vector2(0, 0)) -> Dictionary:
	var rv = {generators = [], connections = []}
	var gennames = {}
	for n in generators:
		var g = create_gen(n)
		if g != null:
			g.orig_name = g.name
			var orig_name = g.name
			if gen_graph.add_generator(g):
				g.position += position
				rv.generators.append(g)
			gennames[orig_name] = g.name
	for c in connections:
		if gennames.has(c.from):
			c.from = gennames[c.from]
		if gennames.has(c.to):
			c.to = gennames[c.to]
		if gen_graph.connect_children(
			gen_graph.get_node(c.from), c.from_port, gen_graph.get_node(c.to), c.to_port
		):
			rv.connections.append(c)
	return rv


func create_gen(data) -> MMGenBase:
	var guess = [
		{keyword = "shader_model/preview_shader", type = MMGenMaterial},
		{keyword = "connections", type = MMGenGraph},
		{keyword = "nodes", type = MMGenGraph},
		{keyword = "is_brush", type = MMGenBrush},
		{keyword = "shader_model", type = MMGenShader},
		{keyword = "model_data", type = MMGenShader},
		{keyword = "widgets", type = MMGenRemote}
	]
	var types = {
		material_export = MMGenMaterial,
		buffer = MMGenBuffer,
		image = MMGenImage,
		text = MMGenText,
		iterate_buffer = MMGenIterateBuffer,
		ios = MMGenIOs,
		switch = MMGenSwitch,
		export = MMGenExport,
		comment = MMGenComment,
		debug = MMGenDebug,
		reroute = MMGenReroute
	}
	var generator = null
	for g in guess:
		var guessed = true
		var d = data
		for k in g.keyword.split("/"):
			if !d.has(k):
				guessed = false
				break
			d = d[k]
		if guessed:
			generator = g.type.new()
			break
	if generator == null and data.has("type"):
		if types.has(data.type):
			generator = types[data.type].new()
		elif predefined_generators.has(data.type):
			generator = create_gen(predefined_generators[data.type])
			if generator == null:
				print("Cannot find description for " + data.type)
			else:
				generator.model = data.type
		if generator != null:
			generator.name = data.type
	if generator == null:
		print("LOADER: data not supported:" + str(data))
	if generator != null:
		generator.deserialize(data)
	return generator


func get_generator_list() -> Array:
	var rv = []
	var dir: Directory = Directory.new()
	for p in MMPaths.get_nodes_paths():
		dir.open(p)
		dir.list_dir_begin(true)
		while true:
			var f = dir.get_next()
			if f == "":
				break
			if f.right(f.length() - 4) == ".mmg":
				var n = f.left(f.length() - 4)
				if rv.find(n) == -1:
					rv.push_back(n)
	rv.sort()
	return rv
