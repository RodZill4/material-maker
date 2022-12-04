tool
extends EditorScript

func _run():
	var dir : Directory = Directory.new()
	dir.open("res://addons/material_maker/nodes")
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var loader = load("res://addons/material_maker/engine/loader.gd").new()
	while file_name != "":
		if file_name.ends_with('.mmg'):
			print("converting "+file_name)
			var file_path : String = "res://addons/material_maker/nodes".plus_file(file_name)
			var file : File = File.new()
			if file.open(file_path, File.READ) == OK:
				var generator = loader.string_to_dict_tree(file.get_as_text())
				file.close()
				file.open(file_path, File.WRITE)
				file.store_string(loader.dict_tree_to_string(generator)+"\n")
				file.close()
		file_name = dir.get_next()
