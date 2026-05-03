extends Node

func show_error(message : String, exit_on_error : bool = false):
	print(message)
	if exit_on_error:
		get_tree().quit(1)

static func name_to_lower(s : String) -> String:
	s = s.strip_edges()
	s = s.to_lower()
	s = s.replace(" ", "_")
	s = s.remove_chars("()/\"")
	return s

func parse_cli_arguments(args : PackedStringArray) -> Dictionary:
	var defaults = {
		"enabled": false,
		"success": true,
		"error": "",
		"image_size": 2048,
		"target": "Godot/Godot 4 Standard",
		"output_dir": DirAccess.open(".").get_current_dir(),
		"output_file": "%f",
		"files": [],
		"list_export_profiles": false,
		"json_output": false
	}

	var texture_size : int = 0
	var i : int = 0
	while i < args.size():
		var arg : String = args[i]
		match arg:
			"--export", "--export-material", "--list-export-profiles":
				defaults["enabled"] = true
				if arg == "--list-export-profiles":
					defaults["list_export_profiles"] = true
			"-t", "--target":
				i += 1
				if i >= args.size():
					return _argument_error(defaults, "ERROR: missing target for " + arg)
				defaults["target"] = args[i]
			"-o", "--output-dir":
				i += 1
				if i >= args.size():
					return _argument_error(defaults, "ERROR: missing output dir for " + arg)
				defaults["output_dir"] = args[i]
			"--output-file":
				i += 1
				if i >= args.size():
					return _argument_error(defaults, "ERROR: missing output file format for --output-file")
				defaults["output_file"] = args[i]
			"--size":
				i += 1
				if i >= args.size():
					return _argument_error(defaults, "ERROR: missing size for --size")
				texture_size = int(args[i])
				if texture_size <= 0:
					return _argument_error(defaults, "ERROR: incorrect size " + args[i])
				defaults["image_size"] = texture_size
			"--json":
				defaults["json_output"] = true
			_:
				defaults["files"].append(arg)
		i += 1
	return defaults

func _argument_error(parsed_args : Dictionary, message : String) -> Dictionary:
	parsed_args["success"] = false
	parsed_args["error"] = message
	return parsed_args

func snapshot_output_directory(output_dir : String) -> Dictionary:
	var files : Dictionary = {}
	if output_dir == "":
		return files
	if DirAccess.open(output_dir) == null:
		return files
	var dirs : Array = [""]
	while !dirs.is_empty():
		var relative_dir : String = dirs.pop_back()
		var current_dir : String = output_dir if relative_dir == "" else output_dir + "/" + relative_dir
		var dir : DirAccess = DirAccess.open(current_dir)
		if dir == null:
			continue
		dir.list_dir_begin()
		var file_name : String = dir.get_next()
		while file_name != "":
			if file_name != "." and file_name != "..":
				var child_relative : String = file_name if relative_dir == "" else relative_dir + "/" + file_name
				if dir.current_is_dir():
					dirs.push_back(child_relative)
				else:
					var full_path : String = current_dir + "/" + file_name
					var file_bytes : PackedByteArray = FileAccess.get_file_as_bytes(full_path)
					files[child_relative] = {
						"size": file_bytes.size(),
						"time": FileAccess.get_modified_time(full_path)
					}
			file_name = dir.get_next()
		dir.list_dir_end()
	return files

func changed_output_files(before_snapshot : Dictionary, after_snapshot : Dictionary) -> Array:
	var output_files : Array = []
	for file_name in after_snapshot.keys():
		if !before_snapshot.has(file_name) or before_snapshot[file_name] != after_snapshot[file_name]:
			output_files.append(file_name)
	output_files.sort()
	return output_files

func expand_input_files(files : Array[String]) -> Array[String]:
	var expanded_files : Array[String] = []
	for f : String in files:
		var basedir : String = f.get_base_dir()
		if basedir == "":
			basedir = "."
		var basename : String = f.get_file()
		if basename.find("*") != -1:
			basename = basename.replace("*", ".*")
			var dir : DirAccess = DirAccess.open(basedir)
			if dir.is_open():
				var regex : RegEx = RegEx.new()
				regex.compile("^"+basename+"$")
				dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
				var file_name = dir.get_next()
				while file_name != "":
					if regex.search(file_name) and file_name.get_extension() == "ptex":
						expanded_files.push_back(basedir+"/"+file_name)
					file_name = dir.get_next()
		elif f.begins_with("website:"):
			for m : String in f.right(-8).split(","):
				var range : PackedStringArray = m.split("-")
				match range.size():
					1:
						if m.is_valid_int():
							expanded_files.push_back("website:"+m)
					2:
						if range[0].is_valid_int() and range[1].is_valid_int():
							for mi in range(range[0].to_int(), range[1].to_int()+1):
								expanded_files.push_back("website:"+str(mi))
		else:
			expanded_files.push_back(f)
	return expanded_files

func list_export_profiles_for_files(files : Array[String]) -> bool:
	var results : Array = []
	var has_loaded_input : bool = false
	var has_failure : bool = false
	for f : String in files:
		var gen = await mm_loader.load_gen(f)
		if gen == null:
			results.append({ "input": f, "material": null, "profiles": [] })
			has_failure = true
			continue
		has_loaded_input = true
		add_child(gen)
		var has_material : bool = false
		for c in gen.get_children():
			if c.has_method("get_export_profiles") and c.has_method("export_material"):
				has_material = true
				var profiles : Array = c.get_export_profiles()
				profiles.sort()
				results.append({ "input": f, "material": c.name, "profiles": profiles })
		if !has_material:
			results.append({ "input": f, "material": null, "profiles": [] })
			has_failure = true
		gen.queue_free()
	print(JSON.stringify(results))
	return has_loaded_input and !has_failure

func load_material_generator(input : String, website_materials : Array) -> Dictionary:
	var result = {
		"input": input,
		"generator": null,
		"basename": input.get_file().get_basename(),
		"material_name": input.get_file().get_basename(),
		"material_author": "unknown",
		"from_website": false,
		"load_failed": false
	}

	var gen = await mm_loader.load_gen(input)
	result["generator"] = gen
	if gen != null:
		return result

	if !input.begins_with("website:"):
		result["load_failed"] = true
		return result

	var asset_index = input.right(-8).to_int()
	result["basename"] = "website_"+str(asset_index)
	var http_request : HTTPRequest = HTTPRequest.new()
	add_child(http_request)

	if website_materials.is_empty():
		var get_materials_error = http_request.request(MMPaths.WEBSITE_ADDRESS+"/api/getMaterials")
		if get_materials_error == OK:
			var data = ( await http_request.request_completed )[3].get_string_from_utf8()
			var json = JSON.new()
			if json.parse(data) == OK and json.get_data() is Array:
				website_materials.clear()
				website_materials.append_array(json.get_data())

	for m in website_materials:
		if int(m.id) == asset_index:
			result["material_name"] = m.name
			result["material_author"] = m.author
			break

	var get_material_error = http_request.request(MMPaths.WEBSITE_ADDRESS+"/api/getMaterial?id="+str(asset_index))
	if get_material_error != OK:
		result["load_failed"] = true
		return result

	var material_data = ( await http_request.request_completed )[3].get_string_from_utf8()
	var material_json : JSON = JSON.new()
	if material_json.parse(material_data) != OK or !material_json.data is Dictionary:
		result["load_failed"] = true
		return result

	var parse_result : Dictionary = material_json.data
	if material_json.parse(parse_result.json) != OK or !material_json.data is Dictionary:
		print("Failed to download asset ", asset_index)
		result["load_failed"] = true
		return result

	result["generator"] = await mm_loader.create_gen(material_json.data)
	result["from_website"] = true
	return result

func choose_export_target(material_node : Node, requested_target : String, input_file : String) -> String:
	var chosen_target : String = requested_target
	if !material_node.has_method("get_export_profiles"):
		return chosen_target

	var profiles : Array = material_node.get_export_profiles()
	if profiles.find(requested_target) == -1:
		var best_similarity : float = 0.0
		for p : String in profiles:
			var similarity : float = p.similarity(requested_target)
			if similarity > best_similarity:
				best_similarity = similarity
				chosen_target = p
		if chosen_target == "":
			print("No export profile for target ", requested_target, " in ", input_file.get_file())
			return ""
		print("Using target ", chosen_target, " (and not ", requested_target, ")")
	return chosen_target

func build_output_prefix(output_dir : String, output_file : String, basename : String, material_name : String, material_author : String) -> String:
	var target_file_name = output_file
	target_file_name = target_file_name.replace("%f", basename)
	target_file_name = target_file_name.replace("%N", material_name)
	target_file_name = target_file_name.replace("%A", material_author)
	target_file_name = target_file_name.replace("%n", name_to_lower(material_name))
	target_file_name = target_file_name.replace("%a", name_to_lower(material_author))
	return output_dir + "/" + target_file_name

func _append_export_failure(export_summary : Array, input_file : String, requested_target : String, chosen_target : String = "") -> void:
	export_summary.append({
		"input": input_file,
		"requested_target": requested_target,
		"chosen_target": chosen_target,
		"prefix": "",
		"output_files": [],
		"success": false
	})

func export_materials_for_files(files : Array[String], output_dir : String, target : String, output_file : String, image_size : int) -> Dictionary:
	var website_materials : Array = []
	var export_list : PackedStringArray = PackedStringArray()
	var export_summary : Array = []
	var any_success : bool = false
	var any_failure : bool = false
	for f : String in files:
		var load_result = await load_material_generator(f, website_materials)
		var gen = load_result["generator"]
		var from_website = load_result["from_website"]
		var basename = load_result["basename"]
		var mat_name = load_result["material_name"]
		var mat_author = load_result["material_author"]

		if load_result["load_failed"] or gen == null:
			any_failure = true
			_append_export_failure(export_summary, f, target)
			continue

		var has_exportable : bool = false
		add_child(gen)
		for c in gen.get_children():
			if !c.has_method("export_material"):
				continue
			has_exportable = true
			var chosen_target = choose_export_target(c, target, f)
			if chosen_target == "":
				any_failure = true
				_append_export_failure(export_summary, f, target)
				continue
			var prefix : String = build_output_prefix(output_dir, output_file, basename, mat_name, mat_author)
			var output_files : Array = []

			var before_files : Dictionary = snapshot_output_directory(output_dir)
			print("Exporting %s to %s..." % [f.get_file(), prefix])
			await c.export_material(prefix, chosen_target, image_size, true)
			print("Done")
			if from_website:
				export_list.append("\""+prefix.get_file()+"\": \""+mat_name+","+mat_author+"\"")

			output_files = changed_output_files(before_files, snapshot_output_directory(output_dir))
			var success : bool = output_files.size() > 0
			if !success:
				any_failure = true
			else:
				any_success = true
			export_summary.append({
				"input": f,
				"requested_target": target,
				"chosen_target": chosen_target,
				"prefix": prefix,
				"output_files": output_files,
				"success": success
			})
		if !has_exportable:
			any_failure = true
			_append_export_failure(export_summary, f, target)
		gen.queue_free()

	if !export_list.is_empty():
		print(",\n".join(export_list))
	var export_success : bool = any_success and !any_failure
	return { "success": export_success, "files": export_summary }

func _ready():
	RenderingServer.set_default_clear_color(Color.BLACK)
	var args : PackedStringArray = OS.get_cmdline_args()
	var parsed_args = parse_cli_arguments(args)

	if !parsed_args["enabled"]:
		var no_logo : bool = ( args.find("--no-splash") != -1 )
		var scene : PackedScene
		if no_logo:
			scene = load("res://material_maker/main_window.tscn")
		else:
			scene = load("res://splash_screen/splash_screen.tscn")
		await get_tree().process_frame
		get_tree().change_scene_to_packed(scene)
		return

	if !parsed_args["success"]:
		show_error(parsed_args["error"], true)
		return

	var target : String = parsed_args["target"]
	var image_size : int = parsed_args["image_size"]
	var output_dir : String = parsed_args["output_dir"]
	var output_file : String = parsed_args["output_file"]
	var json_output : bool = parsed_args["json_output"]
	var list_export_profiles : bool = parsed_args["list_export_profiles"]
	var files : Array[String] = []
	for file_name in parsed_args["files"]:
		files.append(file_name)

	var expanded_files : Array[String] = expand_input_files(files)
	if expanded_files.is_empty():
		show_error("ERROR: No input files provided", true)
		return

	if list_export_profiles:
		var list_success = await list_export_profiles_for_files(expanded_files)
		get_tree().quit(0 if list_success else 1)
		return

	if !json_output:
		print("Exporting...")
		var dir : DirAccess = DirAccess.open(".")
		print("Current dir: ", dir.get_current_dir())
		print("Output dir: ", output_dir)

	var root_dir : DirAccess = DirAccess.open(".")
	if !root_dir.dir_exists(output_dir):
		show_error("ERROR: Output directory '%s' does not exist" % output_dir, true)
		return

	var export_result = await export_materials_for_files(expanded_files, output_dir, target, output_file, image_size)
	if json_output:
		print(JSON.stringify(export_result))
	var export_success = export_result.has("success") and export_result["success"]
	get_tree().quit(0 if export_success else 1)
