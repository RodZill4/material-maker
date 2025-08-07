@tool
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
	var dir : DirAccess = DirAccess.open(path)
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.get_extension() == "mmg":
				var file : FileAccess = FileAccess.open(path+"/"+file_name, FileAccess.READ)
				if file != null:
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
						node_name[7] = ":"
					predefined_generators[file_name.get_basename()] = generator
			file_name = dir.get_next()

func update_predefined_generators()-> void:
	var parser
	if CHECK_PREDEFINED:
		parser = load("res://addons/material_maker/parser/glsl_parser.gd").new()
	predefined_generators = {}
	predefined_functions = {}
	for path in MMPaths.get_nodes_paths():
		get_predefined_generators_from_dir(path)
	if false:
		var file : FileAccess = FileAccess.open("predefined_nodes.json", FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(predefined_generators))
			file.close()

func get_node_from_website(node_name : String) -> bool:
	var node_id : String = node_name.right(-8)
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(MMPaths.WEBSITE_ADDRESS+"/api/getMaterial?id="+node_id)
	if error != OK:
		return false
	var result = await http_request.request_completed
	if ! result is Array or result[0] != 0 or result[1] != 200:
		return false
	var json : JSON = JSON.new()
	if json.parse(result[3].get_string_from_ascii()) != OK or ! json.data is Dictionary:
		return false
	predefined_generators[node_name] = string_to_dict_tree(json.data.json)
	DirAccess.make_dir_absolute(SHARED_NODES_DIR)
	var file : FileAccess = FileAccess.open(SHARED_NODES_DIR+"/website_"+node_id+".mmg", FileAccess.WRITE)
	if file != null:
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
	return path.get_basename().get_file()

const REPLACE_MULTILINE_STRINGS_PROCESS_ITEMS : Array = [ "code", "custom", "global", "instance", "preview_shader", "template" ]
const REPLACE_MULTILINE_STRINGS_WALK_ITEMS : Array = [ "shader_model", "nodes", "template", "files" ]
const REPLACE_MULTILINE_STRINGS_WALK_CHILDREN : Array = [ "exports" ]

func replace_multiline_strings_with_arrays(data, walk_children : bool = false):
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

func replace_arrays_with_multiline_strings(data, walk_children : bool = false):
	if data is Dictionary:
		for k in data.keys():
			if k in REPLACE_MULTILINE_STRINGS_PROCESS_ITEMS:
				if data[k] is Array:
					data[k] = "\n".join(PackedStringArray(data[k]))
			elif walk_children or k in REPLACE_MULTILINE_STRINGS_WALK_ITEMS:
				data[k] = replace_arrays_with_multiline_strings(data[k])
			elif k in REPLACE_MULTILINE_STRINGS_WALK_CHILDREN:
				data[k] = replace_arrays_with_multiline_strings(data[k], true)
	elif data is Array:
		for i in data.size():
			data[i] = replace_arrays_with_multiline_strings(data[i])
	return data

func string_to_dict_tree(string_data : String) -> Dictionary:
	var test_json_conv : JSON = JSON.new()
	if test_json_conv.parse(string_data) == OK and test_json_conv.data is Dictionary:
		return replace_arrays_with_multiline_strings(test_json_conv.data)
	return {}

func dict_tree_to_string(data : Dictionary) -> String:
	return JSON.stringify(replace_multiline_strings_with_arrays(data.duplicate(true)), "\t", true)

func load_gen(filename: String) -> MMGenBase:
	var file : FileAccess = FileAccess.open(filename, FileAccess.READ)
	if file != null:
		var data = string_to_dict_tree(file.get_as_text())
		if data != null:
			current_project_path = filename.get_base_dir()
			var generator = await create_gen(data)
			current_project_path = ""
			return generator
	return null

func save_gen(filename : String, generator : MMGenBase) -> void:
	var file : FileAccess = FileAccess.open(filename, FileAccess.WRITE)
	if file != null:
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
		var g = await create_gen(n)
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
		if gen_graph.connect_children(gen_graph.get_node(NodePath(c.from)), c.from_port, gen_graph.get_node(NodePath(c.to)), c.to_port):
			rv.connections.append(c)
		else:
			print("Cannot connect %s:%d to %s:%d" % [c.from, c.from_port, c.to, c.to_port])
	return rv

func fix_data(data : Dictionary) -> Dictionary:
	if data.has("nodes") and data.has("connections") and data.has("label") and data.label == "HBAO":
		data.type = "hbao"
		data.erase("nodes")
		data.erase("connections")
	elif data.has("shader_model") and data.shader_model.has("name") and data.shader_model.name == "Levels":
		data.erase("shader_model")
		data.type = "height_blend_levels"
	return data

func create_gen(data : Dictionary, fix : bool = true) -> MMGenBase:
	if fix:
		data = fix_data(data)
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
		meshmap = MMGenMeshMap,
		sdf = MMGenSDF,
		ios = MMGenIOs,
		switch = MMGenSwitch,
		export = MMGenExport,
		comment = MMGenComment,
		webcam = MMGenWebcam,
		debug = MMGenDebug,
		reroute = MMGenReroute,
		comment_line = MMGenCommentLine,
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
				var status = await get_node_from_website(data.type)
			if predefined_generators.has(data.type):
				generator = await create_gen(predefined_generators[data.type], false)
				if generator == null:
					print("Cannot find description for "+data.type)
				else:
					generator.model = data.type
		if generator != null:
			generator.name = data.type
	if generator == null:
		print("LOADER: data not supported:"+str(data))
	if generator != null:
		var status = await generator.deserialize(data)
	return generator

func get_generator_list() -> Array:
	var rv = []
	for p in MMPaths.get_nodes_paths():
		var dir : DirAccess = DirAccess.open(p)
		if dir != null:
			dir.list_dir_begin()
			var f = dir.get_next()
			while f != "":
				if f.right(4) == ".mmg":
					var n = f.left(f.length()-4)
					if rv.find(n) == -1:
						rv.push_back(n)
				f = dir.get_next()
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
	var dir = DirAccess.open(USER_EXPORT_DIR)
	if ! dir:
		print("Cannot open "+USER_EXPORT_DIR)
		return
	var rv : Dictionary = {}
	dir.list_dir_begin()
	var file_name : String = dir.get_next()
	while file_name != "":
		if file_name.get_extension() == "mme":
			var file : FileAccess = FileAccess.open(USER_EXPORT_DIR.path_join(file_name), FileAccess.READ)
			if file != null:
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
	var file_name : String = get_export_file_name(material_name, export_target_name)
	var file : FileAccess = FileAccess.open(USER_EXPORT_DIR.path_join(file_name), FileAccess.WRITE)
	if file != null:
		export_target.name = export_target_name
		file.store_string(dict_tree_to_string(export_target))
	return file_name

func update_external_export_targets(material_name : String, export_targets : Dictionary):
	var dir : DirAccess = DirAccess.open("")
	DirAccess.make_dir_absolute(USER_EXPORT_DIR)
	var files = []
	for k in export_targets.keys():
		files.append(save_export_target(material_name, k, export_targets[k]))
	if ! external_export_targets.has(material_name):
		external_export_targets[material_name] = { exports={}, files=[] }
	external_export_targets[material_name].exports = export_targets
	for f in external_export_targets[material_name].files:
		if files.find(f) == -1:
			dir.remove_at(USER_EXPORT_DIR.path_join(f))
	external_export_targets[material_name].files = files
