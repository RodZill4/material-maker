@tool
extends EditorScript

func _run():
	var dir : Directory = Directory.new()
	dir.open("res://addons/material_maker/nodes")
	dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	var file_name = dir.get_next()
	var loader = load("res://addons/material_maker/engine/loader.gd").new()
	while file_name != "":
		if file_name.ends_with('.mmg'):
			print("converting "+file_name)
			var file_path : String = "res://addons/material_maker/nodes".path_join(file_name)
			var g = mm_loader.load_gen(file_path)
			mm_loader.save_gen(file_path, g)
		file_name = dir.get_next()
