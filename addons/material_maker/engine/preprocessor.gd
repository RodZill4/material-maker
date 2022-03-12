extends Node

# shader files
var shader_files : Dictionary = {}
const CACHE_SHADER_FILES : bool = false

func _ready():
	pass # Replace with function body.

func get_file(file_name : String, include_paths : Array = []) -> String:
	var shader_text = ""
	var path_list : Array = [ file_name ]
	for ip in include_paths:
		path_list.append(ip.plus_file(file_name))
	for p in path_list:
		if CACHE_SHADER_FILES and shader_files.has(p):
			shader_text = shader_files[p]
		else:
			var file = File.new()
			if file.open(p, File.READ) == OK:
				shader_text = file.get_as_text()
				file.close()
				shader_files[file_name] = shader_text
	return shader_text

func preprocess(shader : String, defines : Dictionary = {}, include_paths = []) -> String:
	var need_preprocess : bool = true
	while need_preprocess:
		need_preprocess = false
		var regex : RegEx = RegEx.new()
		regex.compile("#include\\s+\"([^\"]+)\"")
		while true:
			var result : RegExMatch = regex.search(shader)
			if result == null:
				break
			shader = shader.replace(result.strings[0], get_file(result.strings[1], include_paths))
			need_preprocess = true
	for d in defines.keys():
		if shader.find(d):
			shader = shader.replace(d, defines[d])
			need_preprocess = true
	return shader

func preprocess_file(file_path : String, defines : Dictionary = {}) -> String:
	var include_paths : Array = [ file_path.get_base_dir() ]
	return preprocess(get_file(file_path), defines, include_paths)
