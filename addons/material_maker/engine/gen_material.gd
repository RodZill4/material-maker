tool
extends MMGenShader
class_name MMGenMaterial


var buffer_name_prefix : String

var export_last_target : String = ""
var export_paths : Dictionary = {}
var uids = {}

var updating : bool = false
var update_again : bool = false

var preview_material : ShaderMaterial = null
var preview_parameters : Dictionary = {}
var preview_textures = {}
var preview_texture_dependencies = {}

var external_previews : Array = []
var export_output_def : Dictionary


# The minimum allowed texture size as a power-of-two exponent
const TEXTURE_SIZE_MIN : int = 4  # 16x16

# The maximum allowed texture size as a power-of-two exponent
const TEXTURE_SIZE_MAX : int = 13  # 8192x8192

# The default texture size as a power-of-two exponent
const TEXTURE_SIZE_DEFAULT : int = 10  # 1024x1024

# The minimum allowed texture size as a power-of-two exponent
const TEXTURE_FILTERING_LIMIT : int = 256

const EXPORT_OUTPUT_DEF_INDEX : int = 12345


func _ready() -> void:
	preview_material = ShaderMaterial.new()
	preview_material.shader = Shader.new()
	buffer_name_prefix = "material_%d" % get_instance_id()
	mm_deps.create_buffer(buffer_name_prefix, self)
	update()

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

func get_output_defs(show_hidden : bool = false) -> Array:
	return .get_output_defs() if show_hidden else []

func get_preprocessed_output_def(output_index : int):
	if output_index == EXPORT_OUTPUT_DEF_INDEX:
		return export_output_def
	return .get_preprocessed_output_def(output_index)


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

func set_parameter(p, v) -> void:
	.set_parameter(p, v)

func source_changed(input_index : int) -> void:
	update()

func all_sources_changed() -> void:
	update()

func set_shader_model(data: Dictionary) -> void:
	var has_externals : bool = false
	var export_names = data.exports.keys()
	var external_export_targets : Dictionary = {}
	if data.has("exports") and is_template():
		for k in export_names:
			var e = data.exports[k]
			if e.has("external") and e.external:
				e.material = get_template_name()
				e.erase("external")
				data.exports.erase(k)
				external_export_targets[k] = e
	if ! external_export_targets.empty():
		mm_loader.update_external_export_targets(get_template_name(), external_export_targets)
	.set_shader_model(data)
	update()

func update_shaders() -> void:
	for t in preview_textures.keys():
		var output_shader = generate_output_shader(preview_textures[t].output)
		preview_textures[t].output_type = output_shader.output_type
		preview_textures[t].material = mm_deps.buffer_create_shader_material(preview_textures[t].buffer, null, output_shader.shader)

func on_dep_update_value(buffer_name, parameter_name, value) -> bool:
	if value == null:
		return false
	if buffer_name == buffer_name_prefix:
		preview_parameters[parameter_name] = value
		for p in external_previews:
			p.set_shader_param(parameter_name, value)
	else:
		var texture_name : String = buffer_name.right(buffer_name_prefix.length()+1)
		preview_textures[texture_name].material.set_shader_param(parameter_name, value)
	return false

func on_dep_update_buffer(buffer_name) -> bool:
	if buffer_name == buffer_name_prefix:
		yield(get_tree(), "idle_frame")
		mm_deps.dependency_update(buffer_name, null, true)
		return true
	var texture_name : String = buffer_name.right(buffer_name_prefix.length()+1)
	if ! preview_textures.has(texture_name) or ! preview_textures[texture_name].has("material"):
		print("Cannot update "+buffer_name)
		print(preview_textures[texture_name])
		return false
	var size = get_image_size()
	var renderer = mm_renderer.request(self)
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	var status = renderer.render_material(self, preview_textures[texture_name].material, size, preview_textures[texture_name].output_type != "rgba")
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	# Abort rendering if material changed
	renderer.copy_to_texture(preview_textures[texture_name].texture)
	renderer.release(self)
	mm_deps.dependency_update(preview_textures[texture_name].buffer, preview_textures[texture_name].texture, true)
	if size <= TEXTURE_FILTERING_LIMIT:
		preview_textures[texture_name].texture.flags &= ~Texture.FLAG_FILTER
	else:
		preview_textures[texture_name].texture.flags |= Texture.FLAG_FILTER
	return true

func update_materials(material_list, sequential : bool = false) -> void:
	for m in material_list:
		var status = update_material(m, sequential)
		if sequential:
			while status is GDScriptFunctionState:
				status = yield(status, "completed")

func update_material(m, sequential : bool = false) -> void:
	if m is SpatialMaterial:
		pass
	elif m is ShaderMaterial:
		m.shader.code = preview_material.shader.code
		for p in preview_parameters.keys():
			m.set_shader_param(p, preview_parameters[p])

func update_external_previews() -> void:
	for p in external_previews:
		p.shader.code = preview_material.shader.code
		for t in preview_textures.keys():
			p.set_shader_param(t, preview_textures[t].texture)
		for t in preview_texture_dependencies.keys():
			p.set_shader_param(t, preview_texture_dependencies[t])

func update() -> void:
	if preview_material == null:
		return
	var processed_preview_shader = process_conditionals(shader_model.preview_shader)
	var result = process_shader(processed_preview_shader)
	preview_material = mm_deps.buffer_create_shader_material(buffer_name_prefix, preview_material, result.shader_code)
	preview_texture_dependencies = result.texture_dependencies
	update_shaders()
	update_external_previews()

class CustomOptions:
	extends Object

func check_custom_script(custom_script : String) -> bool:
	for s in [ "OS", "Directory", "File" ]:
		if custom_script.find(s) != -1:
			print("Invalid custom script (found '%s')" % s)
			return false
	return true

func process_shader(shader_text : String, custom_script : String = ""):
	var custom_options = CustomOptions.new()
	if custom_script != "" and check_custom_script(custom_script):
		print("Using custom script")
		var custom_options_script = GDScript.new()
		custom_options_script.source_code = "extends Object\n\n"+custom_script
		custom_options_script.reload()
		custom_options.set_script(custom_options_script)
	var rv = { globals=[], defs="", code="", textures={}, pending_textures=[] }
	var shader_code = ""
	for t in preview_textures.keys():
		mm_deps.delete_buffer(preview_textures[t].buffer)
	preview_textures = {}
	var context : MMGenContext = MMGenContext.new()
	var texture_regexp : RegEx = RegEx.new()
	texture_regexp.compile("uniform\\s+sampler2D\\s+([\\w_]+).*output\\((\\d+)\\)")
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
					elif custom_options.has_method("process_option_"+o):
						new_code = custom_options.call("process_option_"+o, new_code)
					else:
						print("No implementation of option %s" % o)
				shader_code += new_code
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
				var buffer_name = "%s_%s" % [ buffer_name_prefix, result.strings[1] ]
				preview_textures[result.strings[1]] = {
					output=result.strings[2].to_int(),
					texture=ImageTexture.new(),
					buffer=buffer_name
				}
				mm_deps.create_buffer(buffer_name, self)
			shader_code += l+"\n"
	var definitions : String = get_template_text("glsl_defs.tmpl")+"\n"
	for d in rv.globals:
		definitions += d+"\n"
	definitions += rv.defs+"\n"
	
	shader_text = shader_code
	shader_code = ""
	for l in shader_text.split("\n"):
		if l.find("$definitions") != -1:
			var processed_definitions = definitions
			gen_options = l.replace(" ", "").replace("$definitions", "").split(",")
			for o in gen_options:
				if has_method("process_option_"+o):
					processed_definitions = call("process_option_"+o, processed_definitions, true)
				elif custom_options.has_method("process_option_"+o):
					processed_definitions = custom_options.call("process_option_"+o, processed_definitions, true)
			shader_code += processed_definitions
			shader_code += "\n"
		else:
			shader_code += l
			shader_code += "\n"
	return { shader_code = shader_code, texture_dependencies=rv.textures }

func set_3d_previews(previews : Array):
	external_previews = previews
	update_external_previews()

# Export filters

func process_option_hlsl(s : String, is_declaration : bool = false) -> String:
	s = s.replace("vec2(", "tofloat2(")
	s = s.replace("vec3(", "tofloat3(")
	s = s.replace("vec4(", "tofloat4(")
	s = s.replace("vec2", "float2")
	s = s.replace("vec3", "float3")
	s = s.replace("vec4", "float4")
	s = s.replace("mat2(", "tofloat2x2(")
	s = s.replace("mat2", "float2x2")
	s = s.replace("mix", "lerp")
	s = s.replace("fract", "frac")
	s = s.replace("atan", "hlsl_atan")
	s = s.replace("uniform float", "static const float")
	s = s.replace("uniform int", "static const int")
	var re : RegEx = RegEx.new()
	re.compile("(\\w+)\\s*\\*=\\s*tofloat2x2([^;]+);")
	while true:
		var m : RegExMatch = re.search(s)
		if m == null:
			break
		s = s.replace(m.strings[0], "%s = mul(%s, tofloat2x2%s);" % [ m.strings[1], m.strings[1], m.strings[2] ])
	if is_declaration:
		s = get_template_text("hlsl_defs.tmpl")+"\n\n// EngineSpecificDefinitions\n\n\n"+s
	return s

func process_option_float_uniform_to_const(s : String, is_declaration : bool = false) -> String:
	s = s.replace("uniform float", "const float")
	s = s.replace("uniform vec4", "const vec4")
	s = s.replace("uniform int", "const int")
	return s

func process_option_rename_buffers(s : String, is_declaration : bool = false) -> String:
	var index : int = 1
	for t in preview_texture_dependencies.keys():
		s = s.replace(t, "texture_%d" % index)
		index += 1
	return s

func process_option_unity(s : String, is_declaration : bool = false) -> String:
	s = s.replace("elapsed_time", "_Time.y")
	return s

func process_option_unreal(s : String, is_declaration : bool = false) -> String:
	s = s.replace("elapsed_time", "Time")
	s = s.replace("uniform sampler2D", "// uniform sampler2D ")
	if is_declaration:
		s = s.replace("// EngineSpecificDefinitions", "#define textureLod(t, uv, lod) t.SampleLevel(t##Sampler, uv, lod)");
	return s

# Export

func get_export_profiles() -> Array:
	var export_profiles : Array = []
	if shader_model.has("exports"):
		export_profiles = shader_model.exports.keys()
	if get_template_name() != null:
		for k in mm_loader.get_external_export_targets(get_template_name()).keys():
			if export_profiles.find(k) == -1:
				export_profiles.append(k)
	export_profiles.sort()
	return export_profiles

func get_export(profile : String) -> Dictionary:
	if get_template_name() != null:
		var external_export_targets = mm_loader.get_external_export_targets(get_template_name())
		if external_export_targets.has(profile):
			return external_export_targets[profile]
	if shader_model.has("exports") and shader_model.exports.has(profile):
		return shader_model.exports[profile]
	return {}

func get_export_extension(profile : String) -> String:
	var export_profile : Dictionary = get_export(profile)
	if export_profile.has("export_extension"):
		return export_profile.export_extension
	return ""

func get_last_export_target() -> String:
	return export_last_target

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
	var search_position = 0
	while (true):
		var search_string = "$(expr:"
		var position = s.find(search_string, search_position)
		if position == -1:
			break
		search_position = position+1
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
					elif false:
						print("EXPRESSION ERROR ("+expression+")")
						print("error: "+str(error))
						s = s.replace(s.substr(position, i+1-position), "EXPRESSION ERROR ("+expression+")")
					break
				parenthesis_level -= 1
	return s

static func get_template_text(template : String) -> String:
	var in_file = File.new()
	if in_file.open(MMPaths.STD_GENDEF_PATH+"/"+template, File.READ) != OK:
		if in_file.open(MMPaths.get_resource_dir()+"/nodes/"+template, File.READ) != OK:
			return template
	return in_file.get_as_text()

func process_conditionals(template : String) -> String:
	var context = get_connections_and_parameters_context()
	var processed : String = ""
	var skip_state : Array = [ false ]
	for l in template.split("\n"):
		if l == "":
			continue
		elif l.left(4) == "$if ":
			var condition = subst_string(l.right(4), context)
			var expr = Expression.new()
			var error = expr.parse(condition, [])
			if error != OK:
				print("Error in expression "+condition+": "+expr.get_error_text())
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

func process_buffers(template : String) -> String:
	var processed : String = ""
	var generating : bool = false
	var gen_buffer : String = ""
	var gen_options : Array = []
	for l in template.split("\n"):
		if generating:
			if l == "$end_buffers":
				var index : int = 1
				for t in preview_texture_dependencies.keys():
					processed += subst_string(gen_buffer, { "$(buffer_index)":str(index) })
					index += 1
				generating = false
			else:
				gen_buffer += l+"\n"
		elif l == "$begin_buffers":
			generating = true
			gen_buffer = ""
		else:
			processed += l+"\n"
	return processed

func reset_uids() -> void:
	uids = {}

func get_uid(index : int) -> String:
	if ! uids.has(index):
		var uid : String = ""
		var r = []
		for _k in range(16):
			r.append(randi() & 255)
		r[6] = (r[6] & 0x0f) | 0x40
		r[8] = (r[8] & 0x3f) | 0x80
		for k in range(16):
# warning-ignore:unassigned_variable_op_assign
			uid += '%02x' % r[k]
		uids[index] = uid
	return uids[index]

func process_uids(template : String) -> String:
	var uid_regexp : RegEx = RegEx.new()
	uid_regexp.compile("\\$uid\\((\\w+)\\)")
	while true:
		var result = uid_regexp.search(template)
		if ! result:
			break
		var uid = get_uid(int(result.strings[1]))
		template = template.replace(result.strings[0], uid)
	return template

func create_file_from_template(template : String, file_name : String, export_context : Dictionary) -> bool:
	template = get_template_text(template)
	var processed_template = process_uids(process_buffers(process_conditionals(process_template(template, export_context))))
	var custom_script = ""
	if export_context.has("@mm_custom_script"):
		custom_script = export_context["@mm_custom_script"]
	processed_template = process_shader(processed_template, custom_script).shader_code
	if file_name == "clipboard":
		OS.clipboard = processed_template
	else:
		var out_file = File.new()
		Directory.new().remove(file_name)
		if out_file.open(file_name, File.WRITE) != OK:
			print("Cannot write file '"+file_name+"' ("+str(out_file.get_error())+")")
			return false
		out_file.store_string(processed_template)
	return true

func get_connections_and_parameters_context() -> Dictionary:
	var context : Dictionary = {}
	for i in range(shader_model.inputs.size()):
		var input = shader_model.inputs[i]
		context["$(connected:"+input.name+")"] = "true" if get_source(i) != null else "false"
	for p in shader_model.parameters:
		var value = p.default
		if parameters.has(p.name):
			value = parameters[p.name]
		match p.type:
			"float", "size":
				context["$(param:"+p.name+")"] = str(value)
			"boolean":
				context["$(param:"+p.name+")"] = str(value).to_lower()
			"color":
				context["$(param:"+p.name+".r)"] = str(value.r)
				context["$(param:"+p.name+".g)"] = str(value.g)
				context["$(param:"+p.name+".b)"] = str(value.b)
				context["$(param:"+p.name+".a)"] = str(value.a)
	return context

func export_material(prefix : String, profile : String, size : int = 0) -> void:
	reset_uids()
	if size == 0:
		size = get_image_size()
	export_last_target = profile
	export_paths[profile] = prefix
	var export_context : Dictionary = get_connections_and_parameters_context()
	export_context["$(path_prefix)"] = prefix
	export_context["$(file_prefix)"] = prefix.get_file()
	export_context["$(dir_prefix)"] = prefix.get_base_dir()
	var exported_files : Array = []
	var overwrite_files : Array = []
	var dir : Directory = Directory.new()
	var export_profile = get_export(profile)
	if export_profile.has("custom"):
		export_context["@mm_custom_script"] = export_profile.custom
	for f in export_profile.files:
		if f.has("conditions"):
			var condition = subst_string(f.conditions, export_context)
			var expr = Expression.new()
			var error = expr.parse(condition, [])
			if error != OK:
				print("Error in expression: "+expr.get_error_text())
				continue
			if !expr.execute():
				continue
		if f.has("prompt_overwrite") and f.prompt_overwrite:
			var file_name = subst_string(f.file_name, export_context)
			if dir.file_exists(file_name):
				overwrite_files.push_back(f)
				continue
		exported_files.push_back(f)
	if ! overwrite_files.empty():
		var dialog = load("res://material_maker/windows/accept_dialog/accept_dialog.tscn").instance()
		dialog.dialog_text = "Overwrite existing files?"
		for f in overwrite_files:
			var file_name = subst_string(f.file_name, export_context)
			dialog.dialog_text += "\n- "+file_name.get_file()
		dialog.add_cancel("Keep existing file(s)");
		mm_globals.main_window.add_child(dialog)
		var result = dialog.ask()
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		if result == "ok":
			exported_files.append_array(overwrite_files)
	var progress_dialog = null
	var progress_dialog_scene = load("res://material_maker/windows/progress_window/progress_window.tscn")
	if progress_dialog_scene != null:
		progress_dialog = progress_dialog_scene.instance()
	get_tree().get_root().add_child(progress_dialog)
	progress_dialog.set_text("Exporting material")
	progress_dialog.set_progress(0)
	var total_files : int = 0
	for f in exported_files:
		match f.type:
			"texture", "template":
				total_files += 1
			"buffers", "buffer_templates":
				total_files += preview_texture_dependencies.size()
	var saved_files = 0
	for f in exported_files:
		match f.type:
			"texture":
				# Wait until the render queue is empty
				if mm_deps.get_render_queue_size() > 0:
					yield(mm_deps, "render_queue_empty")
				var file_name = subst_string(f.file_name, export_context)
				var output_index : int
				if f.has("output"):
					output_index = f.output
				elif f.has("expression"):
					var type = "rgba"
					var expression = f.expression
					var equal_position = expression.find("=")
					if equal_position != -1:
						var type_string = expression.left(equal_position)
						type_string = type_string.strip_edges()
						if type_string == "f" or type_string == "rgb" or type_string == "rgba":
							type = type_string
							expression = expression.right(equal_position+1)
					export_output_def = { type: expression, type=type }
					output_index = EXPORT_OUTPUT_DEF_INDEX
				else:
					# Error! Just ignore it
					saved_files += 1
					progress_dialog.set_progress(float(saved_files)/float(total_files))
					continue
				var result = render(self, output_index, size)
				while result is GDScriptFunctionState:
					result = yield(result, "completed")
				var is_greyscale : bool = false
				var output = get_preprocessed_output_def(output_index)
				if output != null:
					is_greyscale = output.has("type") and output.type == "f"
				result.save_to_file(file_name, is_greyscale)
				result.release(self)
				saved_files += 1
				progress_dialog.set_progress(float(saved_files)/float(total_files))
			"template":
				var file_export_context = export_context.duplicate()
				if f.has("file_params"):
					for p in f.file_params.keys():
						file_export_context["$(file_param:"+p+")"] = f.file_params[p]
				var file_name = subst_string(f.file_name, export_context)
				create_file_from_template(f.template, file_name, file_export_context)
				saved_files += 1
				progress_dialog.set_progress(float(saved_files)/float(total_files))
			"buffers":
				var index : int = 1
				if mm_deps.get_render_queue_size() > 0:
					yield(mm_deps, "render_queue_empty")
				for t in preview_texture_dependencies.keys():
					var file_name = subst_string(f.file_name, export_context)
					file_name = file_name.replace("$(buffer_index)", str(index))
					preview_texture_dependencies[t].get_data().save_png(file_name)
					index += 1
					saved_files += 1
					progress_dialog.set_progress(float(saved_files)/float(total_files))
			"buffer_templates":
				var index : int = 1
				for t in preview_texture_dependencies.keys():
					var file_export_context = export_context.duplicate()
					file_export_context["$(buffer_index)"] = str(index)
					if f.has("file_params"):
						for p in f.file_params.keys():
							file_export_context["$(file_param:"+p+")"] = f.file_params[p]
					var file_name = subst_string(f.file_name, export_context)
					file_name = file_name.replace("$(buffer_index)", str(index))
					create_file_from_template(f.template, file_name, file_export_context)
					index += 1
					saved_files += 1
					progress_dialog.set_progress(float(saved_files)/float(total_files))
	if progress_dialog != null:
		progress_dialog.queue_free()

func _serialize_data(data: Dictionary) -> Dictionary:
	data = ._serialize_data(data)
	if export_last_target != "":
		data.export_last_target = export_last_target
	data.export_paths = export_paths
	return data

func _serialize(data: Dictionary) -> Dictionary:
	._serialize(data)
	data.export = {}
	return data

func _deserialize(data : Dictionary) -> void:
	._deserialize(data)
	if data.has("export_last_target") and data.export_last_target != null:
		export_last_target = data.export_last_target
	if data.has("export_paths"):
		export_paths = data.export_paths.duplicate()

func get_shader_model_for_edit():
	var edit_shader_model = shader_model.duplicate()
	edit_shader_model.exports = edit_shader_model.exports.duplicate() if edit_shader_model.has("exports") else {}
	var template_name = get_template_name()
	if template_name != null:
		edit_shader_model.template_name = template_name
		var external_export_targets = mm_loader.get_external_export_targets(template_name)
		for e in external_export_targets.keys():
			edit_shader_model.exports[e] = external_export_targets[e]
			edit_shader_model.exports[e].external = true
	return edit_shader_model

func edit(node) -> void:
	do_edit(node, load("res://material_maker/windows/material_editor/material_editor.tscn"))

func edit_export_targets(node) -> void:
	do_edit(node, load("res://material_maker/windows/material_editor/export_editor.tscn"))
