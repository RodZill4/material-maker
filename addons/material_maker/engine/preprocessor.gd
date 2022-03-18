extends Node

# shader files
var shader_files : Dictionary = {}
const CACHE_SHADER_FILES : bool = false

var regex_include : RegEx

func _ready():
	regex_include = RegEx.new()
	regex_include.compile("#include\\s+\"([^\"]+)\"")

func test_preprocessor():
	print(preprocess_file("res://material_maker/tools/painter/shaders/brush.shader", { BRUSH_MODE="\"pattern\"", GENERATED_CODE = "generated code" }))

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

func preprocess_includes(shader : String, include_paths : Array = []) -> String:
	while true:
		var result : RegExMatch = regex_include.search(shader)
		if result == null:
			break
		shader = shader.replace(result.strings[0], get_file(result.strings[1], include_paths))
	return shader

func preprocess_macros(shader : String, defines : Dictionary = {}) -> String:
	for d in defines.keys():
		if shader.find(d) != -1:
			shader = shader.replace(d, defines[d])
	return shader

const SHARP_IF = 1
const SHARP_ELIF = 2
const SHARP_ELSE = 3
const SHARP_ENDIF = 4

func extract_ifs(shader : String) -> Array:
	var shader_size : int = shader.length()
	var start : int = 0
	var ifs : Array = []
	var level : int = 0
	ifs.push_back({ type=SHARP_IF, condition=true, level=level, start=0, end=0 })
	var expr : Expression = Expression.new()
	while true:
		var next_level : int = level
		var next_sharp : int = shader.find("#", start)
		var condition : String = ""
		var type : int
		if next_sharp == -1:
			break
		var eol : int = shader.find("\n", next_sharp)
		var line = shader.substr(next_sharp, eol-next_sharp)
		if line.left(3) == "#if":
			type = SHARP_IF
			condition=line.right(3)
			level += 1
			next_level = level
		elif line.left(5) == "#elif":
			type = SHARP_ELIF
			condition=line.right(5)
		elif line.left(5) == "#else":
			type = SHARP_ELSE
		elif line.left(6) == "#endif":
			type = SHARP_ENDIF
			next_level -= 1
		else:
			print(shader.substr(next_sharp, eol-next_sharp))
			break
		var condition_value = true
		if condition != "":
			if expr.parse(condition) == OK:
				condition_value = expr.execute()
			else:
				print("Failed to parse '%s'" % condition)
		ifs.push_back({ type=type, condition=condition_value, level=level, start=next_sharp, end=eol+1, line=line })
		start = next_sharp + 1
		level = next_level
	ifs.push_back({ type=SHARP_ENDIF, level=0, start=shader_size, end=shader_size })
	if level != 0:
		print("incorrect #if balance")
	return ifs

func exec_ifs(shader : String, ifs : Array, first : int, last : int) -> String:
	var rv : String = ""
	var level = ifs[first].level
	while first < last:
		if ifs[first].condition:
			while first < last:
				rv += shader.substr(ifs[first].end, ifs[first+1].start-ifs[first].end)
				first += 1
				if ifs[first].level == level:
					break
				if ifs[first].level != level+1 or ifs[first].type != SHARP_IF:
					rv += "// Unexpected #if statement (%s)" % ifs[first].line
				var inner_first = first
				var state : int = 0
				first += 1
				while first < last:
					if ifs[first].level == level+1:
						match ifs[first].type:
							SHARP_ELIF:
								if state != 0:
									rv += "// Unexpected #elif statement (%s)" % ifs[first].line
							SHARP_ELSE:
								if state != 0:
									rv += "// Unexpected #else statement (%s)" % ifs[first].line
								state = 1
							SHARP_ENDIF:
								rv += exec_ifs(shader, ifs, inner_first, first)
								break
							_:
								rv += "// Unexpected #if statement (%s)" % ifs[first].line
					first += 1
			break
		else:
			first += 1
			while first < last:
				if ifs[first].level == level:
					break
				first += 1
	return rv

func preprocess_ifs(shader : String) -> String:
	var ifs : Array = extract_ifs(shader)
	shader = exec_ifs(shader, ifs, 0, ifs.size()-1)
	return shader

func preprocess(shader : String, defines : Dictionary = {}, include_paths : Array = []) -> String:
	while true:
		var new_shader : String
		new_shader = preprocess_includes(shader, include_paths)
		new_shader = preprocess_macros(new_shader, defines)
		new_shader = preprocess_ifs(new_shader)
		if new_shader != shader:
			shader = new_shader
		else:
			break
	return shader

func preprocess_file(file_path : String, defines : Dictionary = {}) -> String:
	var include_paths : Array = [ file_path.get_base_dir() ]
	return preprocess(get_file(file_path), defines, include_paths)
