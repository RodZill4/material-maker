tool
extends MMGenShader
class_name MMGenMaterial

var export_paths = {}

var material : SpatialMaterial
var shader_materials = {}
var need_update = {}
var need_render = {}
var generated_textures = {}
var updating : bool = false
var update_again : bool = false
var render_not_ready : bool = false

const TEXTURE_LIST = [
	{ port=0, texture="albedo", sources=[0] },
	{ port=1, texture="orm", sources=[1, 2, 5] },
	{ port=2, texture="emission", sources=[3] },
	{ port=3, texture="normal", sources=[4] },
	{ port=4, texture="depth", sources=[6] },
	{ port=5, texture="sss", sources=[8] }
]

const INPUT_ALBEDO    : int = 0
const INPUT_METALLIC  : int = 1
const INPUT_ROUGHNESS : int = 2
const INPUT_EMISSION  : int = 3
const INPUT_NORMAL    : int = 4
const INPUT_OCCLUSION : int = 5
const INPUT_DEPTH     : int = 6
const INPUT_SSS       : int = 8

# The minimum allowed texture size as a power-of-two exponent
const TEXTURE_SIZE_MIN = 4  # 16x16

# The maximum allowed texture size as a power-of-two exponent
const TEXTURE_SIZE_MAX = 12  # 4096x4096

# The default texture size as a power-of-two exponent
const TEXTURE_SIZE_DEFAULT = 10  # 1024x1024


func _ready() -> void:
	for t in TEXTURE_LIST:
		generated_textures[t.texture] = null
		need_update[t.texture] = true
		need_render[t.texture] = true
		shader_materials[t.texture] = ShaderMaterial.new()
		shader_materials[t.texture].shader = Shader.new()
	material = SpatialMaterial.new()
	add_to_group("preview")

func accept_float_expressions() -> bool:
	return false

func can_be_deleted() -> bool:
	return false

func toggle_editable() -> bool:
	return false

func get_type() -> String:
	return "material"

func get_type_name() -> String:
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

func set_parameter(p, v) -> void:
	.set_parameter(p, v)
	update_preview()

func source_changed(input_index : int) -> void:
	for t in TEXTURE_LIST:
		if t.has("sources") and t.sources.find(input_index) != -1:
			need_update[t.texture] = true
	update_preview()

func all_sources_changed() -> void:
	for t in TEXTURE_LIST:
		need_update[t.texture] = true
	update_preview()

func render_textures() -> void:
	for t in TEXTURE_LIST:
		var renderer
		if t.has("port"):
			if !need_update[t.texture]:
				continue
			var context : MMGenContext = MMGenContext.new()
			var source = get_shader_code("uv", t.port, context)
			while source is GDScriptFunctionState:
				source = yield(source, "completed")
			if source.empty():
				source = DEFAULT_GENERATED_SHADER
			shader_materials[t.texture].shader.code = mm_renderer.generate_shader(source)
			# Get parameter values from the shader code
			define_shader_float_parameters(shader_materials[t.texture].shader.code, shader_materials[t.texture])
			# Set texture params
			if source.has("textures"):
				for k in source.textures.keys():
					shader_materials[t.texture].set_shader_param(k, source.textures[k])
		else:
			generated_textures[t.texture] = null
			need_update[t.texture] = false
			continue
		renderer = mm_renderer.request(self)
		while renderer is GDScriptFunctionState:
			renderer = yield(renderer, "completed")
		renderer = renderer.render_material(self, shader_materials[t.texture], get_image_size(), false)
		while renderer is GDScriptFunctionState:
			renderer = yield(renderer, "completed")
		if generated_textures[t.texture] == null:
			generated_textures[t.texture] = ImageTexture.new()
		var texture = generated_textures[t.texture]
		renderer.copy_to_texture(texture)
		renderer.release(self)
		# To work, this must be set after calling `copy_to_texture()`
		texture.flags |= ImageTexture.FLAG_ANISOTROPIC_FILTER
		# Disable filtering for small textures, as they're considered to be used
		# for a pixel art style
		if texture.get_size().x <= 128:
			texture.flags ^= ImageTexture.FLAG_FILTER
		need_update[t.texture] = false

func on_float_parameters_changed(parameter_changes : Dictionary) -> void:
	var do_update : bool = false
	for t in TEXTURE_LIST:
		if generated_textures[t.texture] != null:
			for n in parameter_changes.keys():
				for p in VisualServer.shader_get_param_list(shader_materials[t.texture].shader.get_rid()):
					if p.name == n:
						shader_materials[t.texture].set_shader_param(n, parameter_changes[n])
						need_render[t.texture] = true
						do_update = true
						break
	if do_update:
		update_textures()

func on_texture_changed(n : String) -> void:
	render_not_ready = true
	var do_update : bool = false
	for t in TEXTURE_LIST:
		if generated_textures[t.texture] != null:
			for p in VisualServer.shader_get_param_list(shader_materials[t.texture].shader.get_rid()):
				if p.name == n:
					need_render[t.texture] = true
					do_update = true
					break
	if do_update:
		update_textures()

func update_textures() -> void:
	update_again = true
	if !updating:
		var image_size = get_image_size()
		updating = true
		while update_again:
			update_again = false
			for t in TEXTURE_LIST:
				if need_render[t.texture]:
					var renderer = mm_renderer.request(self)
					while renderer is GDScriptFunctionState:
						renderer = yield(renderer, "completed")
					renderer = renderer.render_material(self, shader_materials[t.texture], image_size, false)
					while renderer is GDScriptFunctionState:
						renderer = yield(renderer, "completed")
					renderer.copy_to_texture(generated_textures[t.texture])
					renderer.release(self)
		updating = false

func update_materials(material_list) -> void:
	render_textures()
	for m in material_list:
		update_material(m)

func get_generated_texture(slot, file_prefix = null) -> ImageTexture:
	if file_prefix != null:
		var file_name = "%s_%s.png" % [ file_prefix, slot ]
		if File.new().file_exists(file_name):
			var texture = load(file_name)
			return texture
		else:
			return null
	else:
		return generated_textures[slot]

func update_material(m, file_prefix = null) -> void:
	if m is SpatialMaterial:
		# Make the material double-sided for better visiblity in the preview
		m.params_cull_mode = SpatialMaterial.CULL_DISABLED
		# Albedo
		m.albedo_color = parameters.albedo_color
		m.albedo_texture = get_generated_texture("albedo", file_prefix)
		# Ambient occlusion
		if get_source(INPUT_OCCLUSION) != null:
			m.ao_enabled = true
			m.ao_light_affect = parameters.ao
			m.ao_texture = get_generated_texture("orm", file_prefix)
			m.ao_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
		else:
			m.ao_enabled = false
		# Roughness
		m.roughness = parameters.roughness
		if get_source(INPUT_ROUGHNESS) != null:
			m.roughness_texture = get_generated_texture("orm", file_prefix)
			m.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN
		else:
			m.roughness_texture = null
		# Metallic
		m.metallic = parameters.metallic
		if get_source(INPUT_METALLIC) != null:
			m.metallic_texture = get_generated_texture("orm", file_prefix)
			m.metallic_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_BLUE
		else:
			m.metallic_texture = null
		# Emission
		if get_source(INPUT_EMISSION) != null:
			m.emission_enabled = true
			m.emission_energy = parameters.emission_energy
			m.emission_texture = get_generated_texture("emission", file_prefix)
		else:
			m.emission_enabled = false
		# Normal map
		if get_source(INPUT_NORMAL) != null:
			m.normal_enabled = true
			m.normal_texture = get_generated_texture("normal", file_prefix)
			m.normal_scale = parameters.normal
		else:
			m.normal_enabled = false
		# Depth
		if get_source(INPUT_DEPTH) != null and parameters.depth_scale > 0:
			m.depth_enabled = true
			m.depth_deep_parallax = true
			m.depth_scale = parameters.depth_scale * 0.2
			m.depth_texture = get_generated_texture("depth", file_prefix)
		else:
			m.depth_enabled = false
		# Transparency
		if parameters.has("flags_transparent"):
			m.flags_transparent = parameters.flags_transparent
			if m.flags_transparent:
				m.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_ALWAYS
				m.params_use_alpha_scissor = true
			else:
				m.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_OPAQUE_ONLY
				m.params_use_alpha_scissor = false
		# Subsurface scattering
		if get_source(INPUT_SSS) != null:
			m.subsurf_scatter_enabled = true
			m.subsurf_scatter_strength = parameters.sss
			m.subsurf_scatter_texture = get_generated_texture("sss", file_prefix)
		else:
			m.subsurf_scatter_enabled = false
	else:
		m.set_shader_param("albedo", parameters.albedo_color)
		m.set_shader_param("texture_albedo", get_generated_texture("albedo", file_prefix))
		m.set_shader_param("texture_orm", get_generated_texture("orm", file_prefix))
		m.set_shader_param("metallic", parameters.metallic)
		m.set_shader_param("roughness", parameters.roughness)
		m.set_shader_param("emission_energy", parameters.emission_energy)
		m.set_shader_param("texture_emission", get_generated_texture("emission", file_prefix))
		m.set_shader_param("normal_scale", parameters.normal)
		m.set_shader_param("texture_normal", get_generated_texture("normal", file_prefix))
		m.set_shader_param("depth_scale", parameters.depth_scale * 0.2)
		m.set_shader_param("texture_depth", get_generated_texture("depth", file_prefix))
		m.set_shader_param("ao_light_affect", parameters.ao)

# Export

func get_export_profiles() -> Array:
	return shader_model.exports.keys()

func get_export_extension(profile : String) -> String:
	return shader_model.exports[profile].export_extension

func get_export_path(profile : String) -> String:
	if export_paths.has(profile):
		return export_paths[profile]
	return ""

func subst_string(s : String, export_context : Dictionary) -> String:
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

func create_file_from_template(template : String, file_name : String, export_context : Dictionary) -> bool:
	var in_file = File.new()
	var out_file = File.new()
	if in_file.open(MMPaths.STD_GENDEF_PATH+"/"+template, File.READ) != OK:
		if in_file.open(OS.get_executable_path().get_base_dir()+"/nodes/"+template, File.READ) != OK:
			print("Cannot find template file "+template)
			return false
	Directory.new().remove(file_name)
	if out_file.open(file_name, File.WRITE) != OK:
		print("Cannot write file '"+file_name+"' ("+str(out_file.get_error())+")")
		return false
	var skip_state : Array = [ false ]
	while ! in_file.eof_reached():
		var l = in_file.get_line()
		if l.left(4) == "$if ":
			var condition = subst_string(l.right(4), export_context)
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
			out_file.store_line(subst_string(l, export_context))
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

func _deserialize(data : Dictionary) -> void:
	._deserialize(data)
	if data.has("export_paths"):
		export_paths = data.export_paths.duplicate()
