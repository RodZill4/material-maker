extends Node

func show_error(message : String):
	print(message)

static func name_to_lower(s : String) -> String:
	s = s.strip_edges()
	s = s.to_lower()
	s = s.replace(" ", "_")
	s = s.remove_chars("()/")
	return s

func export_files(files, output_dir, target, target_file, image_size) -> void:
	var website_materials : Array = []
	var export_list : PackedStringArray = PackedStringArray()
	for f : String in files:
		var basename : String = f.get_file().get_basename()
		var mat_name : String = f.get_file().get_basename()
		var mat_author : String = "unknown"
		var gen = await mm_loader.load_gen(f)
		var from_website : bool = false
		if gen == null and f.begins_with("website:"):
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
				continue
			var data = ( await http_request.request_completed )[3].get_string_from_utf8()
			var json : JSON = JSON.new()
			if json.parse(data) != OK or ! json.data is Dictionary:
				continue
			var parse_result : Dictionary = json.data
			if json.parse(parse_result.json) == OK and json.data is Dictionary:
				gen = await mm_loader.create_gen(json.data)
			else:
				print("Failed to download asset ", asset_index)
				continue
			from_website = true
		var mat_name_lower = name_to_lower(mat_name)
		var mat_author_lower = name_to_lower(mat_author)
		if gen != null:
			add_child(gen)
			for c in gen.get_children():
				if c.has_method("export_material"):
					var best_target : String = target
					if c.has_method("get_export_profiles"):
						if c.get_export_profiles().find(target) == -1:
							var best_similarity : float = 0.0
							for p : String in c.get_export_profiles():
								var similarity : float = p.similarity(target)
								if similarity > best_similarity:
									best_similarity = similarity
									best_target = p
							if best_target == "":
								continue
							print("Using target ", best_target, " (and not ", target, ")")
					var target_file_name = target_file
					target_file_name = target_file_name.replace("%f", basename)
					target_file_name = target_file_name.replace("%N", mat_name)
					target_file_name = target_file_name.replace("%A", mat_author)
					target_file_name = target_file_name.replace("%n", mat_name_lower)
					target_file_name = target_file_name.replace("%a", mat_author_lower)
					var prefix : String = output_dir+"/"+target_file_name
					print("Exporting %s to %s..." % [f.get_file(), prefix])
					await c.export_material(prefix, best_target, image_size, true)
					print("Done")
					if from_website:
						export_list.append("\""+prefix.get_file()+"\": \""+mat_name+","+mat_author+"\"")
			gen.queue_free()
	if not export_list.is_empty():
		print(",\n".join(export_list))
	get_tree().quit()

func _ready():
	var args : PackedStringArray = OS.get_cmdline_args()
	if ("--export" in args) or ("--export-material" in args):
		print("Exporting...")
		var image_size : int = 2048
		var dir : DirAccess = DirAccess.open(".")
		var output = []
		print("Current dir: ", dir.get_current_dir())
		var target : String = "Godot/Godot 4 Standard"
		#TODO: fix this
		var output_dir : String = dir.get_current_dir()
		var output_file : String = "%f"
		var texture_size : int = 0
		var files : Array[String] = []
		var i = 1
		while i < OS.get_cmdline_args().size():
			match OS.get_cmdline_args()[i]:
				"-t", "--target":
					i += 1
					target = OS.get_cmdline_args()[i]
				"-o", "--output-dir":
					i += 1
					output_dir = OS.get_cmdline_args()[i]
				"--output-file":
					i += 1
					output_file = OS.get_cmdline_args()[i]
				"--size":
					i += 1
					texture_size = int(OS.get_cmdline_args()[i])
					if texture_size < 0:
						#show_error("ERROR: incorrect size "+OS.get_cmdline_args()[i])
						return
				_:
					files.push_back(OS.get_cmdline_args()[i])
			i += 1
		print("Output dir: ", output_dir)
		if ! dir.dir_exists(output_dir):
			show_error("ERROR: Output directory '%s' does not exist" % output_dir)
			return
		var expanded_files = []
		for f : String in files:
			var basedir : String = f.get_base_dir()
			if basedir == "":
				basedir = "."
			var basename : String = f.get_file()
			if basename.find("*") != -1:
				basename = basename.replace("*", ".*")
				dir = DirAccess.open(basedir)
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
		await export_files(expanded_files, output_dir, target, output_file, image_size)
	else:
		var no_logo : bool = ( args.find("--no-splash") != -1 )
		var scene : PackedScene
		if no_logo:
			scene = load("res://material_maker/main_window.tscn")
		else:
			scene = load("res://splash_screen/splash_screen.tscn")
		await get_tree().process_frame
		get_tree().change_scene_to_packed(scene)
