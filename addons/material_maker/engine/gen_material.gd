tool
extends MMGenShader
class_name MMGenMaterial

var export_paths = {}

var updating : bool = false
var update_again : bool = false
var render_not_ready : bool = false

var preview_shader_code : String = ""
var preview_textures = {}
var preview_texture_dependencies = {}

# The minimum allowed texture size as a power-of-two exponent
const TEXTURE_SIZE_MIN = 4  # 16x16

# The maximum allowed texture size as a power-of-two exponent
const TEXTURE_SIZE_MAX = 13  # 8192x8192

# The default texture size as a power-of-two exponent
const TEXTURE_SIZE_DEFAULT = 10  # 1024x1024


func _ready() -> void:
	add_to_group("preview")

func accept_float_expressions() -> bool:
	return false

func can_be_deleted() -> bool:
	return false

func get_type() -> String:
	return "material_export"

func get_type_name() -> String:
	if shader_model.has("name"):
		return shader_model.name
	return "Material"

func get_output_defs() -> Array:
	return []

func get_image_size() -> int:
	var rv : int
	if parameters.has("size"):
		rv = int(pow(2, parameters.size))
	else:
		rv = int(pow(2, TEXTURE_SIZE_DEFAULT))
	return rv

func update_preview() -> void:
	var graph_edit = self
	while graph_edit is MMGenBase:
		graph_edit = graph_edit.get_parent()
	if graph_edit != null and graph_edit.has_method("send_changed_signal"):
		graph_edit.send_changed_signal()
	update_textures()

func set_parameter(p, v) -> void:
	.set_parameter(p, v)
	update_preview()

func source_changed(input_index : int) -> void:
	update_preview()

func all_sources_changed() -> void:
	update_preview()

func on_float_parameters_changed(parameter_changes : Dictionary) -> void:
	update_textures()

func on_texture_changed(n : String) -> void:
	render_not_ready = true
	update_textures()

func update_textures() -> void:
	var size = get_image_size()
	update_again = true
	if !updating:
		while update_again:
			update_again = false
			var image_size = get_image_size()
			updating = true
			for t in preview_textures.keys():
				var result = render(self, preview_textures[t].output, size)
				while result is GDScriptFunctionState:
					result = yield(result, "completed")
				# Abort rendering if material changed
				if ! preview_textures.has(t):
					result.release(self)
					break
				result.copy_to_texture(preview_textures[t].texture)
				result.release(self)
			updating = false

func update_materials(material_list) -> void:
	for m in material_list:
		update_material(m)

func update_material(m) -> void:
	if m is SpatialMaterial:
		pass
	elif m is ShaderMaterial:
		m.shader.code = preview_shader_code
		for t in preview_texture_dependencies.keys():
			m.set_shader_param(t, preview_texture_dependencies[t])
		for t in preview_textures.keys():
			m.set_shader_param(t, preview_textures[t].texture)
		update_textures()

func update() -> void:
	var result = process_shader(shader_model.preview_shader)
	preview_shader_code = result.shader_code
	preview_texture_dependencies = result.texture_dependencies
	"""
	var file : File = File.new()
	file.open("d:/test.shader", File.WRITE)
	file.store_string(preview_shader_code)
	file.close()
	"""





func process_shader(shader_text : String):
	var rv = { globals=[], defs="", code="", textures={}, pending_textures=[] }
	var shader_code = ""
	preview_textures = {}
	var context : MMGenContext = MMGenContext.new()
	var texture_regexp : RegEx = RegEx.new()
	texture_regexp.compile("uniform\\s+sampler2D\\s+([\\w_]+).*output\\((\\d)\\)")
	# Generate parameter declarations
	rv = generate_parameter_declarations(rv)
	# Generate functions for inputs
	rv = generate_input_declarations(rv, context)
	# Generate shader
	var generating : bool = false
	var gen_buffer : String = ""
	var gen_options : Array = []
	for l in shader_text.split("\n"):
		if generating:
			if l == "$end_generate":
				var subst_code = subst(gen_buffer, context, "UV")
				# Add global definitions
				for d in subst_code.globals:
					if rv.globals.find(d) == -1:
						rv.globals.push_back(d)
				# Add generated definitions
				rv.defs += subst_code.defs
				# Add generated code
				var new_code : String = subst_code.code+"\n"
				new_code += subst_code.string+"\n"
				for o in gen_options:
					if has_method("process_option_"+o):
						new_code = call("process_option_"+o, new_code)
				shader_code += new_code
				# process textures
				for t in subst_code.textures.keys():
					rv.textures[t] = subst_code.textures[t]
				for t in subst_code.pending_textures:
					if rv.pending_textures.find(t) == -1:
						rv.pending_textures.push_back(t)
				generating = false
			else:
				gen_buffer += l+"\n"
		elif l.find("$begin_generate") != -1:
			generating = true
			gen_buffer = ""
			gen_options = l.replace(" ", "").replace("$begin_generate", "").split(",")
		else:
			var result = texture_regexp.search(l)
			if result:
				preview_textures[result.strings[1]] = { output=result.strings[2].to_int(), texture=ImageTexture.new() }
			shader_code += l+"\n"
	var definitions : String
	for d in rv.globals:
		definitions += d+"\n"
	definitions += rv.defs+"\n"
	
	shader_text = shader_code
	shader_code = ""
	for l in shader_text.split("\n"):
		if l.find("$definitions") != -1:
			gen_options = l.replace(" ", "").replace("$definitions", "").split(",")
			print("gen options: "+str(gen_options))
			for o in gen_options:
				if has_method("process_option_"+o):
					definitions = call("process_option_"+o, definitions)
			shader_code += definitions
			shader_code += "\n"
		else:
			shader_code += l
			shader_code += "\n"

	return { shader_code = shader_code, texture_dependencies=rv.textures }

# Export filters

func process_option_hlsl(s : String) -> String:
	s = s.replace("vec2(", "tofloat2(")
	s = s.replace("vec3(", "tofloat3(")
	s = s.replace("vec2", "float2")
	s = s.replace("vec3", "float3")
	s = s.replace("vec4", "float4")
	s = s.replace("mat2(", "tofloat2x2(")
	s = s.replace("mat2", "float2x2")
	s = s.replace("mod", "fmod")
	s = s.replace("mix", "lerp")
	s = s.replace("fract", "frac")
	s = s.replace("uniform", "static const")
	s = s.replace("elapsed_time", "_Time.y")
	var re : RegEx = RegEx.new()
	re.compile("(\\w+)\\s*\\*=\\s*tofloat2x2([^;]+);")
	while true:
		var m : RegExMatch = re.search(s)
		if m == null:
			break
		s = s.replace(m.strings[0], "%s = mul(%s, tofloat2x2%s);" % [ m.strings[1], m.strings[1], m.strings[2] ])
	return s

# Export

func get_export_profiles() -> Array:
	return shader_model.exports.keys()

func get_export_extension(profile : String) -> String:
	return shader_model.exports[profile].export_extension

func get_export_path(profile : String) -> String:
	if export_paths.has(profile):
		return export_paths[profile]
	return ""

static func subst_string(s : String, export_context : Dictionary) -> String:
	var modified : bool = true
	while modified:
		modified = false
		for k in export_context.keys():
			var new_s = s.replace(k, export_context[k])
			if new_s != s:
				s = new_s
				modified = true
	while (true):
		var search_string = "$(expr:"
		var position = s.find(search_string)
		if position == -1:
			break
		var parenthesis_level = 0
		var expr_begin = position+search_string.length()
		for i in range(expr_begin, s.length()):
			if s[i] == '(':
				parenthesis_level += 1
			elif s[i] == ')':
				if parenthesis_level == 0:
					var expression = s.substr(expr_begin, i-expr_begin)
					var expr = Expression.new()
					var error = expr.parse(expression, [])
					if error == OK:
						s = s.replace(s.substr(position, i+1-position), str(expr.execute()))
					else:
						s = s.replace(s.substr(position, i+1-position), "EXPRESSION ERROR ("+expression+")")
					break
				parenthesis_level -= 1
	return s

static func get_template_text(template : String) -> String:
	var in_file = File.new()
	if in_file.open(MMPaths.STD_GENDEF_PATH+"/"+template, File.READ) != OK:
		if in_file.open(OS.get_executable_path().get_base_dir()+"/nodes/"+template, File.READ) != OK:
			return template
	return in_file.get_as_text()

static func process_conditionals(template : String) -> String:
	var processed : String = ""
	var skip_state : Array = [ false ]
	for l in template.split("\n"):
		if l == "":
			continue
		elif l.left(4) == "$if ":
			var condition = l.right(4)
			var expr = Expression.new()
			var error = expr.parse(condition, [])
			if error != OK:
				#print("Error in expression "+condition+": "+expr.get_error_text())
				continue
			skip_state.push_back(!expr.execute())
		elif l.left(3) == "$fi":
			skip_state.pop_back()
		elif l.left(5) == "$else":
			skip_state.push_back(!skip_state.pop_back())
		elif ! skip_state.back():
			processed += l
			processed += "\n"
	return processed

static func process_template(template : String, export_context : Dictionary) -> String:
	var processed : String = ""
	var skip_state : Array = [ false ]
	for l in template.split("\n"):
		if l == "":
			continue
		processed += subst_string(l, export_context)
		processed += "\n"
	return processed

func create_file_from_template(template : String, file_name : String, export_context : Dictionary) -> bool:
	template = get_template_text(template)
	var out_file = File.new()
	Directory.new().remove(file_name)
	if out_file.open(file_name, File.WRITE) != OK:
		print("Cannot write file '"+file_name+"' ("+str(out_file.get_error())+")")
		return false
	var processed_template = process_conditionals(process_template(template, export_context))
	processed_template = process_shader(processed_template).shader_code
	out_file.store_string(processed_template)
	return true

func export_material(prefix : String, profile : String, size : int = 0) -> void:
	if size == 0:
		size = get_image_size()
	export_paths[profile] = prefix
	var export_context : Dictionary = {
		"$(path_prefix)":prefix,
		"$(file_prefix)":prefix.get_file()
	}
	for i in range(shader_model.inputs.size()):
		var input = shader_model.inputs[i]
		export_context["$(connected:"+input.name+")"] = "true" if get_source(i) != null else "false"
	for p in shader_model.parameters:
		var value = p.default
		if parameters.has(p.name):
			value = parameters[p.name]
		match p.type:
			"float", "size", "boolean":
				export_context["$(param:"+p.name+")"] = str(value)
			"color":
				export_context["$(param:"+p.name+".r)"] = str(value.r)
				export_context["$(param:"+p.name+".g)"] = str(value.g)
				export_context["$(param:"+p.name+".b)"] = str(value.b)
				export_context["$(param:"+p.name+".a)"] = str(value.a)
			_:
				print(p.type+" not supported in material")
	if shader_model.exports[profile].has("uids"):
		for i in range(shader_model.exports[profile].uids):
			var uid : String
			var r = []
			for _k in range(16):
				r.append(randi() & 255)
			r[6] = (r[6] & 0x0f) | 0x40
			r[8] = (r[8] & 0x3f) | 0x80
			for k in range(16):
# warning-ignore:unassigned_variable_op_assign
				uid += '%02x' % r[k]
			export_context["$(uid:"+str(i)+")"] = uid
	for f in shader_model.exports[profile].files:
		if f.has("conditions"):
			var condition = subst_string(f.conditions, export_context)
			var expr = Expression.new()
			var error = expr.parse(condition, [])
			if error != OK:
				print("Error in expression: "+expr.get_error_text())
				continue
			if !expr.execute():
				continue
		match f.type:
			"texture":
				# Wait until no buffer has been updated for 5 frames
				render_not_ready = true
				while render_not_ready:
					render_not_ready = false
					yield(get_tree(), "idle_frame")
					yield(get_tree(), "idle_frame")
					yield(get_tree(), "idle_frame")
					yield(get_tree(), "idle_frame")
					yield(get_tree(), "idle_frame")
				var file_name = subst_string(f.file_name, export_context)
				var result = render(self, f.output, size)
				while result is GDScriptFunctionState:
					result = yield(result, "completed")
				result.save_to_file(file_name)
				result.release(self)
			"template":
				var file_export_context = export_context.duplicate()
				if f.has("file_params"):
					for p in f.file_params.keys():
						file_export_context["$(file_param:"+p+")"] = f.file_params[p]
				var file_name = subst_string(f.file_name, export_context)
				create_file_from_template(f.template, file_name, file_export_context)

func _serialize_data(data: Dictionary) -> Dictionary:
	data = ._serialize_data(data)
	data.export_paths = export_paths
	return data

func _serialize(data: Dictionary) -> Dictionary:
	._serialize(data)
	data.export = {}
	return data

func _deserialize(data : Dictionary) -> void:
	._deserialize(data)
	if data.has("export_paths"):
		export_paths = data.export_paths.duplicate()

func edit(node) -> void:
	if shader_model != null:
		var edit_window = load("res://material_maker/windows/material_editor/material_editor.tscn").instance()
		node.get_parent().add_child(edit_window)
		edit_window.set_model_data(shader_model)
		edit_window.connect("node_changed", node, "update_generator")
		edit_window.connect("popup_hide", edit_window, "queue_free")
		edit_window.popup_centered()
