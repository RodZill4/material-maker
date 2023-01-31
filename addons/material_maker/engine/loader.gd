tool
extends Node

var predefined_generators : Dictionary = {}
var predefined_functions : Dictionary = {}

var external_export_targets : Dictionary = {}

var current_project_path : String = ""


const CHECK_PREDEFINED : bool = false

const USER_EXPORT_DIR : String = "user://export_targets"
const SHARED_NODES_DIR : String = "user://shared_nodes"


func _ready()-> void:
	update_predefined_generators()
	load_external_export_targets()

func get_predefined_generators_from_dir(path : String) -> void:
	var parser
	if CHECK_PREDEFINED:
		parser = load("res://addons/material_maker/parser/glsl_parser.gd").new()
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.get_extension() == "mmg":
				var file : File = File.new()
				if file.open(path+"/"+file_name, File.READ) == OK:
					var generator = string_to_dict_tree(file.get_as_text())
					if CHECK_PREDEFINED:
						if generator.has("shader_model") and generator.shader_model.has("global") and generator.shader_model.global != "":
							var parse_result = parser.parse(generator.shader_model.global)
							if parse_result.status != "OK":
								print(file_name+" has errors in global")
							elif parse_result.value.type == "translation_unit":
								for definition in parse_result.value.value:
									if definition.type == "function_definition":
										var function_name = definition.value[0].value[0].value.name
										if function_name.type == "IDENTIFIER":
											if predefined_functions.has(function_name.value):
												print(str(function_name.value)+" is defined in "+file_name.get_basename()+" and "+predefined_functions[function_name.value])
											else:
												predefined_functions[function_name.value] = file_name.get_basename()
										else:
											print(definition)
									else:
										print(definition.type)
					var node_name : String = file_name.get_basename()
					if node_name.left(8) == "website_":
						print(node_name.right(8))
						node_name[7] = ":"
					predefined_generators[node_name] = generator
					file.close()
			file_name = dir.get_next()

func update_predefined_generators() -> void:
	predefined_generators = {}
	predefined_functions = {}
	for path in MMPaths.get_nodes_paths():
		get_predefined_generators_from_dir(path)
	if false:
		var file : File = File.new()
		if file.open("predefined_nodes.json", File.WRITE) == OK:
			file.store_string(to_json(predefined_generators))
			file.close()

func get_node_from_website(node_name : String) -> bool:
	var node_id : String = node_name.right(8)
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(MMPaths.WEBSITE_ADDRESS+"/api/getMaterial?id="+node_id)
	if error != OK:
		return false
	var result = yield(http_request, "request_completed")
	if ! result is Array or result[0] != 0 or result[1] != 200:
		return false
	var json : JSONParseResult = JSON.parse(result[3].get_string_from_ascii())
	if json.error != OK or ! json.result is Dictionary:
		return false
	predefined_generators[node_name] = string_to_dict_tree(json.result.json)
	var dir : Directory = Directory.new()
	dir.make_dir_recursive(SHARED_NODES_DIR)
	var file : File = File.new()
	if file.open(SHARED_NODES_DIR+"/website_"+node_id+".mmg", File.WRITE) == OK:
		file.store_string(dict_tree_to_string(predefined_generators[node_name].duplicate(true)))
		file.close()
	return true

func get_material_nodes() -> Array:
	var rv : Array = Array()
	for g in predefined_generators.keys():
		var generator = predefined_generators[g]
		if generator.has("type") and generator.type == "material_export":
			if generator.has("shader_model") and generator.shader_model.has("name"):
				rv.push_back({ name=g, label=generator.shader_model.name })
	return rv

func get_predefined_global(g : String) -> String:
	if ! predefined_generators.has(g):
		return ""
	if ! predefined_generators[g].has("shader_model"):
		return ""
	if ! predefined_generators[g].shader_model.has("global"):
		return ""
	return predefined_generators[g].shader_model.global

func generator_name_from_path(path : String) -> String:
	for p in MMPaths.get_nodes_paths():
		print(p)
	print(path.get_base_dir())
	return path.get_basename().get_file()

const REPLACE_MULTILINE_STRINGS_PROCESS_ITEMS : Array = [ "code", "custom", "global", "instance", "preview_shader", "template" ]
const REPLACE_MULTILINE_STRINGS_WALK_ITEMS : Array = [ "shader_model", "nodes", "template", "files" ]
const REPLACE_MULTILINE_STRINGS_WALK_CHILDREN : Array = [ "exports" ]

static func replace_multiline_strings_with_arrays(data, walk_children : bool = false):
	if data is Dictionary:
		for k in data.keys():
			if k in REPLACE_MULTILINE_STRINGS_PROCESS_ITEMS:
				if data[k] is String:
					data[k] = data[k].replace("    ", "\t")
					if data[k].find("\n") != -1:
						data[k] = Array(data[k].split("\n"))
			elif walk_children or k in REPLACE_MULTILINE_STRINGS_WALK_ITEMS:
				data[k] = replace_multiline_strings_with_arrays(data[k])
			elif k in REPLACE_MULTILINE_STRINGS_WALK_CHILDREN:
				data[k] = replace_multiline_strings_with_arrays(data[k], true)
	elif data is Array:
		for i in data.size():
			data[i] = replace_multiline_strings_with_arrays(data[i])
	return data

static func replace_arrays_with_multiline_strings(data, walk_children : bool = false):
	if data is Dictionary:
		for k in data.keys():
			if k in REPLACE_MULTILINE_STRINGS_PROCESS_ITEMS:
				if data[k] is Array:
					data[k] = PoolStringArray(data[k]).join("\n")
			elif walk_children or k in REPLACE_MULTILINE_STRINGS_WALK_ITEMS:
				data[k] = replace_arrays_with_multiline_strings(data[k])
			elif k in REPLACE_MULTILINE_STRINGS_WALK_CHILDREN:
				data[k] = replace_arrays_with_multiline_strings(data[k], true)
	elif data is Array:
		for i in data.size():
			data[i] = replace_arrays_with_multiline_strings(data[i])
	return data

static func string_to_dict_tree(string_data : String) -> Dictionary:
	var json : JSONParseResult = JSON.parse(string_data)
	if json.error == OK and json.result is Dictionary:
		return replace_arrays_with_multiline_strings(json.result)
	return {}

static func dict_tree_to_string(data : Dictionary) -> String:
	return JSON.print(replace_multiline_strings_with_arrays(data), "\t", true)

func load_gen(filename: String) -> MMGenBase:
	var file = File.new()
	if file.open(filename, File.READ) == OK:
		var data = string_to_dict_tree(file.get_as_text())
		if data != null:
			current_project_path = filename.get_base_dir()
			var generator = create_gen(data)
			while generator is GDScriptFunctionState:
				generator = yield(generator, "completed")
			current_project_path = ""
			return generator
	return null

func save_gen(filename : String, generator : MMGenBase) -> void:
	var file = File.new()
	if file.open(filename, File.WRITE) == OK:
		var data = generator.serialize()
		data.name = filename.get_file().get_basename()
		data.node_position = { x=0, y=0 }
		for k in [ "uids", "export_paths" ]:
			if data.has(k):
				data.erase(k)
		file.store_string(dict_tree_to_string(data))
		file.close()
		mm_loader.update_predefined_generators()


func add_to_gen_graph(gen_graph, generators, connections, position : Vector2 = Vector2(0, 0)) -> Dictionary:
	var rv = { generators=[], connections=[] }
	var gennames = {}
	for n in generators:
		var g = create_gen(n)
		while g is GDScriptFunctionState:
			g = yield(g, "completed")
		if g != null:
			g.orig_name = g.name
			var orig_name = g.name
			if gen_graph.add_generator(g):
				g.position += position
				rv.generators.append(g)
			gennames[orig_name] = g.name
		else:
			print("Cannot create gen "+str(n))
	for c in connections:
		if gennames.has(c.from):
			c.from = gennames[c.from]
		if gennames.has(c.to):
			c.to = gennames[c.to]
		if gen_graph.connect_children(gen_graph.get_node(c.from), c.from_port, gen_graph.get_node(c.to), c.to_port):
			rv.connections.append(c)
		else:
			print("Cannot connect %s:%d to %s:%d" % [c.from, c.from_port, c.to, c.to_port])
	return rv

func create_gen(data) -> MMGenBase:
	var guess = [
		{ keyword="shader_model/preview_shader", type=MMGenMaterial },
		{ keyword="connections", type=MMGenGraph },
		{ keyword="nodes", type=MMGenGraph },
		{ keyword="is_brush", type=MMGenBrush },
		{ keyword="shader_model", type=MMGenShader },
		{ keyword="sdf_scene", type=MMGenSDF },
		{ keyword="model_data", type=MMGenShader },
		{ keyword="widgets", type=MMGenRemote }
	]
	var types = {
		material_export = MMGenMaterial,
		buffer = MMGenBuffer,
		image = MMGenImage,
		text = MMGenText,
		iterate_buffer = MMGenIterateBuffer,
		sdf = MMGenSDF,
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
			if ! d.has(k):
				guessed = false
				break
			d = d[k]
		if guessed:
			generator = g.type.new()
			break
	if generator == null and data.has("type"):
		if types.has(data.type):
			generator = types[data.type].new()
		else:
			if !predefined_generators.has(data.type) and data.type.left(8) == "website:":
				var status = get_node_from_website(data.type)
				while status is GDScriptFunctionState:
					status = yield(status, "completed")
			if predefined_generators.has(data.type):
				generator = create_gen(predefined_generators[data.type])
				while generator is GDScriptFunctionState:
					generator = yield(generator, "completed")
				if generator == null:
					print("Cannot find description for "+data.type)
				else:
					generator.model = data.type
		if generator != null:
			generator.name = data.type
	if generator == null:
		print("LOADER: data not supported:"+str(data))
	if generator != null:
		var status = generator.deserialize(data)
		while status is GDScriptFunctionState:
			status = yield(status, "completed")
	return generator

func get_generator_list() -> Array:
	var rv = []
	var dir : Directory = Directory.new()
	for p in MMPaths.get_nodes_paths():
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

# External export targets

static func get_export_file_name(material_name : String, export_name : String) -> String:
	export_name = export_name.to_lower()
	export_name = export_name.replace(" ", "_")
	export_name = export_name.replace("/", "_")
	export_name = export_name.replace(".", "_")
	return material_name+"_export_"+export_name+".mme"

func load_external_export_targets():
	var dir = Directory.new()
	if dir.open(USER_EXPORT_DIR) != OK:
		print("Cannot open "+USER_EXPORT_DIR)
		return
	var rv : Dictionary = {}
	dir.list_dir_begin()
	var file_name : String = dir.get_next()
	while file_name != "":
		if file_name.get_extension() == "mme":
			var file : File = File.new()
			if file.open(USER_EXPORT_DIR.plus_file(file_name), File.READ) == OK:
				var export_data : Dictionary = string_to_dict_tree(file.get_as_text())
				if export_data != {}:
					var material : String = export_data.material
					if file_name != get_export_file_name(material, export_data.name):
						print("Warning, %s has an incorrect name" % file_name)
					if ! external_export_targets.has(material):
						external_export_targets[material] = { exports={}, files=[] }
					external_export_targets[material].exports[export_data.name] = export_data
					external_export_targets[material].files.append(file_name)
		file_name = dir.get_next()

func get_external_export_targets(material_name : String) -> Dictionary:
	return external_export_targets[material_name].exports if external_export_targets.has(material_name) else {}

func save_export_target(material_name : String, export_target_name : String, export_target : Dictionary) -> String:
	var file : File = File.new()
	var file_name : String = get_export_file_name(material_name, export_target_name)
	if file.open(USER_EXPORT_DIR.plus_file(file_name), File.WRITE) == OK:
		file.store_string(dict_tree_to_string(export_target))
	return file_name

func update_external_export_targets(material_name : String, export_targets : Dictionary):
	var dir : Directory = Directory.new()
	dir.make_dir_recursive(USER_EXPORT_DIR)
	var files = []
	for k in export_targets.keys():
		files.append(save_export_target(material_name, k, export_targets[k]))
	if ! external_export_targets.has(material_name):
		external_export_targets[material_name] = { exports={}, files=[] }
	external_export_targets[material_name].exports = export_targets
	for f in external_export_targets[material_name].files:
		if files.find(f) == -1:
			dir.remove(USER_EXPORT_DIR.plus_file(f))
	external_export_targets[material_name].files = files
