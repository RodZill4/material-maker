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

func _snapshot_output_directory(output_dir : String) -> Dictionary:
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

func _list_new_output_files(before_snapshot : Dictionary, after_snapshot : Dictionary) -> Array:
	var output_files : Array = []
	for file_name in after_snapshot.keys():
		if !before_snapshot.has(file_name) or before_snapshot[file_name] != after_snapshot[file_name]:
			output_files.append(file_name)
	output_files.sort()
	return output_files

func _expand_input_files(files : Array[String]) -> Array[String]:
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

func _list_export_profiles(files : Array[String]) -> bool:
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

func export_files(files : Array[String], output_dir : String, target : String, target_file : String, image_size : int) -> Dictionary:
	var website_materials : Array = []
	var export_list : PackedStringArray = PackedStringArray()
	var export_summary : Array = []
	var any_success : bool = false
	var any_failure : bool = false
	for f : String in files:
		var basename : String = f.get_file().get_basename()
		var mat_name : String = f.get_file().get_basename()
		var mat_author : String = "unknown"
		var gen = await mm_loader.load_gen(f)
		var from_website : bool = false
		var load_failed : bool = gen == null
		if gen == null and f.begins_with("website:"):
			load_failed = false
			var asset_index = f.right(-8).to_int()
			basename = "website_"+str(asset_index)
			var http_request : HTTPRequest = HTTPRequest.new()
			add_child(http_request)
			if website_materials.is_empty():
				var error = http_request.request(MMPaths.WEBSITE_ADDRESS+"/api/getMaterials")
				if error == OK:
					var data = ( await http_request.request_completed )[3].get_string_from_utf8()
					var json = JSON.new()
					if json.parse(data) == OK and json.get_data() is Array:
						website_materials = json.get_data()
			for m in website_materials:
				if int(m.id) == asset_index:
					mat_name = m.name
					mat_author = m.author
					break
			var error = http_request.request(MMPaths.WEBSITE_ADDRESS+"/api/getMaterial?id="+str(asset_index))
			if error != OK:
				load_failed = true
			else:
				var data = ( await http_request.request_completed )[3].get_string_from_utf8()
				var json : JSON = JSON.new()
				if json.parse(data) != OK or ! json.data is Dictionary:
					load_failed = true
				else:
					var parse_result : Dictionary = json.data
					if json.parse(parse_result.json) == OK and json.data is Dictionary:
						gen = await mm_loader.create_gen(json.data)
						from_website = true
					else:
						print("Failed to download asset ", asset_index)
						load_failed = true
		if load_failed or gen == null:
			any_failure = true
			export_summary.append({
				"input": f,
				"requested_target": target,
				"chosen_target": "",
				"prefix": "",
				"output_files": [],
				"success": false
			})
			continue

		var mat_name_lower = name_to_lower(mat_name)
		var mat_author_lower = name_to_lower(mat_author)
		var has_exportable : bool = false
		add_child(gen)
		for c in gen.get_children():
			if !c.has_method("export_material"):
				continue
			has_exportable = true
			var best_target : String = target
			if c.has_method("get_export_profiles"):
				var profiles : Array = c.get_export_profiles()
				if profiles.find(target) == -1:
					var best_similarity : float = 0.0
					for p : String in profiles:
						var similarity : float = p.similarity(target)
						if similarity > best_similarity:
							best_similarity = similarity
							best_target = p
					if best_target == "":
						print("No export profile for target ", target, " in ", f.get_file())
						any_failure = true
						export_summary.append({
							"input": f,
							"requested_target": target,
							"chosen_target": "",
							"prefix": "",
							"output_files": [],
							"success": false
						})
						continue
					print("Using target ", best_target, " (and not ", target, ")")
			var target_file_name = target_file
			target_file_name = target_file_name.replace("%f", basename)
			target_file_name = target_file_name.replace("%N", mat_name)
			target_file_name = target_file_name.replace("%A", mat_author)
			target_file_name = target_file_name.replace("%n", mat_name_lower)
			target_file_name = target_file_name.replace("%a", mat_author_lower)
			var prefix : String = output_dir+"/"+target_file_name

			var before_files : Dictionary = _snapshot_output_directory(output_dir)
			print("Exporting %s to %s..." % [f.get_file(), prefix])
			await c.export_material(prefix, best_target, image_size, true)
			print("Done")
			if from_website:
				export_list.append("\""+prefix.get_file()+"\": \""+mat_name+","+mat_author+"\"")

			var output_files : Array = _list_new_output_files(before_files, _snapshot_output_directory(output_dir))
			var success : bool = output_files.size() > 0
			if !success:
				any_failure = true
			else:
				any_success = true
			export_summary.append({
				"input": f,
				"requested_target": target,
				"chosen_target": best_target,
				"prefix": prefix,
				"output_files": output_files,
				"success": success
			})
		if !has_exportable:
			any_failure = true
			export_summary.append({
				"input": f,
				"requested_target": target,
				"chosen_target": "",
				"prefix": "",
				"output_files": [],
				"success": false
			})
		gen.queue_free()
	if not export_list.is_empty():
		print(",\n".join(export_list))
	var export_success : bool = any_success and !any_failure
	return { "success": export_success, "files": export_summary }

func _ready():
	RenderingServer.set_default_clear_color(Color.BLACK)
	var args : PackedStringArray = OS.get_cmdline_args()
	if ("--export" in args) or ("--export-material" in args) or ("--list-export-profiles" in args):
		var image_size : int = 2048
		var dir : DirAccess = DirAccess.open(".")
		var output = []
		var target : String = "Godot/Godot 4 Standard"
		#TODO: fix this
		var output_dir : String = dir.get_current_dir()
		var output_file : String = "%f"
		var texture_size : int = 0
		var files : Array[String] = []
		var list_export_profiles : bool = false
		var json_output : bool = false
		var i = 0
		while i < args.size():
			var arg : String = args[i]
			match arg:
				"--export", "--export-material":
					pass
				"-t", "--target":
					i += 1
					if i >= args.size():
						show_error("ERROR: missing target for " + arg, true)
						return
					target = args[i]
				"-o", "--output-dir":
					i += 1
					if i >= args.size():
						show_error("ERROR: missing output dir for " + arg, true)
						return
					output_dir = args[i]
				"--output-file":
					i += 1
					if i >= args.size():
						show_error("ERROR: missing output file format for --output-file", true)
						return
					output_file = args[i]
				"--size":
					i += 1
					if i >= args.size():
						show_error("ERROR: missing size for --size", true)
						return
					texture_size = int(args[i])
					if texture_size <= 0:
						show_error("ERROR: incorrect size " + args[i], true)
						return
					image_size = texture_size
				"--json":
					json_output = true
				"--list-export-profiles":
					list_export_profiles = true
				_:
					files.push_back(arg)
			i += 1

		var expanded_files : Array[String] = _expand_input_files(files)
		if expanded_files.is_empty():
			show_error("ERROR: No input files provided", true)
			return

		if list_export_profiles:
			var list_success = await _list_export_profiles(expanded_files)
			get_tree().quit(0 if list_success else 1)
			return

		if !json_output:
			print("Exporting...")
			print("Current dir: ", dir.get_current_dir())
			print("Output dir: ", output_dir)
		if ! dir.dir_exists(output_dir):
			show_error("ERROR: Output directory '%s' does not exist" % output_dir, true)
			return

		var export_result = await export_files(expanded_files, output_dir, target, output_file, image_size)
		if json_output:
			print(JSON.stringify(export_result))
		var export_success = export_result.has("success") and export_result["success"]
		get_tree().quit(0 if export_success else 1)
	else:
		var no_logo : bool = ( args.find("--no-splash") != -1 )
		var scene : PackedScene
		if no_logo:
			scene = load("res://material_maker/main_window.tscn")
		else:
			scene = load("res://splash_screen/splash_screen.tscn")
		await get_tree().process_frame
		get_tree().change_scene_to_packed(scene)
