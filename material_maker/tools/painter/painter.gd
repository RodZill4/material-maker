extends Node

var mesh : Mesh

var texture_size : float = 0

var initialized : bool = false

var v2t_texture : MMTexture = MMTexture.new()
var v2t_pipeline : MMMeshRenderingPipeline

var t2v_texture : MMTexture = MMTexture.new()
var t2v_pipeline : MMMeshRenderingPipeline

var view_to_texture_image : Image

var mesh_seams_tex : MMTexture = MMTexture.new()

var id_map_set : bool = false
var id_map_tex : MMTexture = MMTexture.new()
var id_mask_set : bool = false
var id_mask_color : Color

class PaintChannel:
	var texture : MMTexture
	var stroke : MMTexture
	var next_texture : MMTexture
	
	func _init():
		texture = MMTexture.new()
		stroke = MMTexture.new()
		next_texture = MMTexture.new()

var paint_channels : Array[PaintChannel] = []
var paint_textures : Array[MMTexture] = []
var paint_textures_by_name : Dictionary = {}
enum {
	CHANNEL_ALBEDO,
	CHANNEL_MR,
	CHANNEL_EMISSION,
	CHANNEL_NORMAL,
	CHANNEL_DO,
	CHANNEL_MAX
}
const PAINT_CHANNELS : Array[Dictionary] = [
	{
		name="albedo",
		type="rgba",
		conditions=[ "has_albedo" ],
		output_index=1
	},
	{
		name="mr",
		type="ggaa",
		conditions=[ "has_metallic", "has_roughness" ],
		output_index=2
	},
	{
		name="emission",
		type="rgba",
		conditions=[ "has_emission" ],
		output_index=3
	},
	{
		name="normal",
		type="rgba",
		conditions=[ "has_normal" ],
		output_index=4
	},
	{
		name="do",
		type="ggaa",
		conditions=[ "has_depth", "has_ao" ],
		output_index=5
	}
]
const PAINT_CHANNELS_MASK : Array[Dictionary] = [
	{
		name="albedo",
		type="111a",
		conditions=[ "has_albedo" ],
		output_index=6
	}
]

var init_shader : MMComputeShader = MMComputeShader.new()
var paint_shader_wrapper : MMShaderCompute = MMShaderCompute.new()
var paint_shader : MMComputeShader = paint_shader_wrapper.compute_shader

var projection : Projection
var transform : Transform3D
var viewport_size : Vector2i

var brush_node = null
var paint_mask : bool = false
var brush_params = {
	brush_size = 1.0,
	brush_hardness = 0.5,
	pattern_scale  = 10.0,
	pattern_angle  = 0.0
}

var has_channel : Dictionary = {}

var brush_preview_material : ShaderMaterial
var pattern_shown : bool = false
#var brush_textures : Dictionary = {}

var mesh_aabb : AABB
var mesh_position_tex : MMTexture = MMTexture.new()
var mesh_normal_tex : MMTexture = MMTexture.new()
var mesh_tangent_tex : MMTexture = MMTexture.new()

const VIEW_TO_TEXTURE_RATIO = 1.0

# shader files
var shader_files : Dictionary = {}
const CACHE_SHADER_FILES : bool = false


signal painted(painted_channels)
signal end_of_stroke(stroke_state)

func _init():
	for i in range(CHANNEL_MAX):
		paint_textures_by_name[PAINT_CHANNELS[i].name] = i
	paint_textures_by_name["mask"] = 0
	
	# Compile initialization shader
	var shader_template : String = load("res://material_maker/tools/painter/shaders/init_copy_shader.tres").text
	var texture_defs : Array[Dictionary] = [
		{
			name="output_image",
			type=MMPipeline.TEXTURE_TYPE_RGBA16F,
			writeonly=true,
			keep=true
		}
	]
	init_shader.add_parameter_or_texture("modulate", "vec4", Color(1.0, 1.0, 1.0, 1.0))
	init_shader.add_parameter_or_texture("use_input_image", "bool", true)
	init_shader.add_parameter_or_texture("input_image", "sampler2D", null)
	await init_shader.set_shader_ext(shader_template, texture_defs)

func _ready():
	mm_deps.create_buffer("painter_%d:brush" % get_instance_id(), self)
	mm_deps.create_buffer("painter_%d:paint" % get_instance_id(), self)
	
	var vertex_shader : String
	var fragment_shader : String
	v2t_pipeline = MMMeshRenderingPipeline.new()
	vertex_shader = preload("res://material_maker/tools/painter/shaders/v2t_vertex.tres").text
	fragment_shader = preload("res://material_maker/tools/painter/shaders/v2t_fragment.tres").text
	v2t_pipeline.add_parameter_or_texture("transform", "mat4x4", Projection())
	await v2t_pipeline.set_shader(vertex_shader, fragment_shader)
	
	t2v_pipeline = MMMeshRenderingPipeline.new()
	vertex_shader = preload("res://material_maker/tools/painter/shaders/t2v_vertex.tres").text
	fragment_shader = preload("res://material_maker/tools/painter/shaders/t2v_fragment.tres").text
	t2v_pipeline.add_parameter_or_texture("viewport_size", "vec2", viewport_size)
	t2v_pipeline.add_parameter_or_texture("transform", "mat4x4", Projection())
	t2v_pipeline.add_parameter_or_texture("v2t", "sampler2D", v2t_texture)
	await t2v_pipeline.set_shader(vertex_shader, fragment_shader)
	
	initialized = true
	
	update_view_textures()
	

func update_view_textures():
	if not initialized or mesh == null or viewport_size.x <= 0 or viewport_size.y <= 0:
		return
	
	# Generate v2t texture
	v2t_pipeline.mesh = mesh
	v2t_pipeline.set_parameter("transform", projection)
	await v2t_pipeline.render(viewport_size, 3, v2t_texture, true)
	view_to_texture_image = (await v2t_texture.get_texture()).get_image()
	
	# Generate t2v texture
	t2v_pipeline.mesh = mesh
	t2v_pipeline.set_parameter("viewport_size", viewport_size)
	t2v_pipeline.set_parameter("transform", projection)
	t2v_pipeline.set_parameter("v2t", v2t_texture)
	await t2v_pipeline.render(Vector2i(texture_size, texture_size), 3, t2v_texture)
	t2v_texture.get_texture()

func update_textures() -> void:
	await MMMapGenerator.generate(mesh, "seams", texture_size, mesh_seams_tex)
	
	update_view_textures()
	
	# position texture
	await MMMapGenerator.generate(mesh, "position", texture_size, mesh_position_tex)
	# normal texture
	await MMMapGenerator.generate(mesh, "normal", texture_size, mesh_normal_tex)
	
	# tangent texture
	await MMMapGenerator.generate(mesh, "tangent", texture_size, mesh_tangent_tex)
	mesh_aabb = mesh.get_aabb()

func set_mesh(m : Mesh):
	mesh = m
	update_textures()

func has_id_map() -> bool:
	return id_map_set

func get_id_map() -> Texture2D:
	return await id_map_tex.get_texture()

func set_id_map(file_name : String):
	var image : Image = Image.load_from_file(file_name)
	if image:
		var texture : ImageTexture = ImageTexture.create_from_image(image)
		id_map_tex.set_texture(texture)
		id_map_set = true

func set_id_mask(c : Color):
	id_mask_set = true
	id_mask_color = c
	paint_shader.set_parameter("use_id_mask", id_mask_set)
	paint_shader.set_parameter("id_mask_color", id_mask_color)

func unset_id_mask():
	id_mask_set = false
	paint_shader.set_parameter("use_id_mask", id_mask_set)

func calculate_mask(value : float, channel : int) -> Color:
	if (channel == StandardMaterial3D.TEXTURE_CHANNEL_RED):
		return Color(value, 0, 0, 0)
	elif (channel == StandardMaterial3D.TEXTURE_CHANNEL_GREEN):
		return Color(0, value, 0, 0)
	elif (channel == StandardMaterial3D.TEXTURE_CHANNEL_BLUE):
		return Color(0, 0, value, 0)
	elif (channel == StandardMaterial3D.TEXTURE_CHANNEL_ALPHA):
		return Color(0, 0, 0, value)
	return Color(0, 0, 0, 0)


func init_rgba_texture(channel_index : int, color : Color = Color(0.0, 0.0, 0.0, 0.0), texture : Texture2D = null):
	var tmp : MMTexture = MMTexture.new()
	if texture != null and texture.get_image() != null:
		tmp.set_texture(texture)
	var paint_channel : PaintChannel = get_paint_channel(channel_index)
	init_shader.set_parameter("modulate", color)
	init_shader.set_parameter("use_input_image", texture != null)
	init_shader.set_parameter("input_image", tmp)
	await init_shader.render_ext([ paint_channel.texture ], Vector2i(texture_size, texture_size))
	await init_shader.render_ext([ paint_channel.next_texture ], Vector2i(texture_size, texture_size))
	paint_channel.texture.get_texture()
	paint_channel.next_texture.get_texture()

func init_rgba_texture_by_name(channel_name : String, color : Color = Color(0.0, 0.0, 0.0, 0.0), texture : Texture2D = null):
	print("Initializing %s channel" % channel_name)
	if paint_textures_by_name.has(channel_name):
		await init_rgba_texture(paint_textures_by_name[channel_name], color, texture)
	else:
		push_error("Cannot find paint channel '%s'" % channel_name)

func init_mr_texture_channels(metallic : float = 1.0, metallic_texture : Texture2D = null, metallic_channel : int = StandardMaterial3D.TEXTURE_CHANNEL_RED, roughness : float = 1.0, roughness_texture : Texture2D = null, roughness_channel : int = StandardMaterial3D.TEXTURE_CHANNEL_GREEN):
	pass
	# TODO
	# mr_viewport.init_channels(metallic_texture, calculate_mask(metallic, metallic_channel), roughness_texture, calculate_mask(roughness, roughness_channel), null, Color(1.0, 0.0, 0.0, 0.0), null, Color(1.0, 0.0, 0.0, 0.0))

func init_do_texture_channels(depth : float = 1.0, depth_texture : Texture2D = null, occlusion : float = 1.0, occlusion_texture : Texture2D = null, occlusion_channel : int = StandardMaterial3D.TEXTURE_CHANNEL_GREEN):
	pass
	# TODO
	# do_viewport.init_channels(depth_texture, calculate_mask(depth, StandardMaterial3D.TEXTURE_CHANNEL_RED), occlusion_texture, calculate_mask(occlusion, occlusion_channel), null, Color(1.0, 0.0, 0.0, 0.0), null, Color(1.0, 0.0, 0.0, 0.0))

func init_textures(m : StandardMaterial3D):
	await init_rgba_texture(CHANNEL_ALBEDO, m.albedo_color, m.albedo_texture)
	await init_mr_texture_channels(m.metallic, m.metallic_texture, m.metallic_texture_channel, m.roughness, m.roughness_texture, m.roughness_texture_channel)
	if m.emission_enabled:
		var emission_color = m.emission
		emission_color.a = 1.0
		await init_rgba_texture(CHANNEL_EMISSION, emission_color, m.emission_texture)
	else:
		await init_rgba_texture(CHANNEL_EMISSION, Color(0.0, 0.0, 0.0), null)
	if m.normal_enabled:
		await init_rgba_texture(CHANNEL_NORMAL, Color(1.0, 1.0, 1.0), m.n_texture)
	else:
		await init_rgba_texture(CHANNEL_NORMAL, Color(0.5, 0.5, 0.0), null)
	if m.heightmap_enabled or m.ao_enabled:
		await init_do_texture_channels(m.depth_scale if m.heightmap_enabled else 0.0, m.depth_texture, m.ao_light_affect if m.ao_enabled else 1.0, m.ao_texture, m.ao_texture_channel)
	else:
		await init_rgba_texture(CHANNEL_DO, Color(0.0, 1.0, 0.0, 0.0), null)

func set_texture_size(s : float):
	if texture_size != s:
		texture_size = s
		if mesh:
			update_textures()

func update_view(p : Projection, t : Transform3D, s : Vector2i):
	projection = p*Projection(t)
	transform = t
	viewport_size = s
	brush_params.view_back = Vector3(0.0, 0.0, 1.0) * transform.basis.orthonormalized()
	brush_params.view_right = Vector3(1.0, 0.0, 0.0) * transform.basis.orthonormalized()
	brush_params.view_up = Vector3(0.0, 1.0, 0.0) * transform.basis.orthonormalized()
	print("back: "+str(brush_params.view_back))
	update_view_textures()
	update_brush()

# Brush methods

func get_brush_mode() -> String:
	return brush_node.get_parameter_defs()[0].values[brush_node.get_parameter("mode")].value

func set_brush_node(node, is_mask : bool) -> void:
	brush_node = node
	paint_mask = is_mask
	update_brush(true)

func set_brush_preview_material(m : ShaderMaterial) -> void:
	brush_preview_material = m

func get_brush_preview_shader(mode : String) -> String:
	return mm_preprocessor.preprocess_file("res://material_maker/tools/painter/shaders/brush_%s.gdshader" % mode)

func set_brush_angle(a) -> void:
	brush_params.pattern_angle = a
	update_brush()

func update_brush_params(shader_params : Dictionary) -> void:
	for p in shader_params.keys():
		brush_params[p] = shader_params[p]
		if brush_preview_material != null:
			if brush_params[p] is MMTexture:
				print("Setting texture")
			else:
				brush_preview_material.set_shader_parameter(p, brush_params[p])
		paint_shader.set_parameter(p, shader_params[p])

func show_pattern(b):
	if pattern_shown != b:
		pattern_shown = b
		update_brush()

func replace_predefs(s : String) -> String:
	s = s.replace("mesh_aabb_position", "vec3(%.09f, %.09f, %.09f)" % [ mesh_aabb.position.x, mesh_aabb.position.y, mesh_aabb.position.z ])
	s = s.replace("mesh_aabb_size", "vec3(%.09f, %.09f, %.09f)" % [ mesh_aabb.size.x, mesh_aabb.size.y, mesh_aabb.size.z ])
	s = s.replace("mesh_inv_uv_tex", "mesh_%d_position" % [ abs(mesh.get_instance_id()) ])
	s = s.replace("mesh_normal_tex", "mesh_%d_normal" % [ abs(mesh.get_instance_id()) ])
	s = s.replace("mesh_tangent_tex", "mesh_%d_tangent" % [ abs(mesh.get_instance_id()) ])
	return s

func update_brush(update_shaders : bool = false):
	#if brush_params.albedo_texture_mode != 2: $Pattern.visible = false
	if brush_preview_material != null:
		if update_shaders:
			var brush_shader_file : String = "res://material_maker/tools/painter/shaders/brush.gdshader"
			var output_code : Dictionary = get_output_code(1)
			update_shader("painter_%d:brush" % get_instance_id(), brush_preview_material, brush_shader_file, { BRUSH_MODE="\""+get_brush_mode()+"\"", GENERATED_CODE = output_code.code }, output_code.uniforms)
		brush_preview_material.set_shader_parameter("rect_size", viewport_size)
		brush_preview_material.set_shader_parameter("view2tex_tex", await v2t_texture.get_texture())
		brush_preview_material.set_shader_parameter("mesh_inv_uv_tex", await mesh_position_tex.get_texture())
		brush_preview_material.set_shader_parameter("mesh_aabb_position", mesh_aabb.position)
		brush_preview_material.set_shader_parameter("mesh_aabb_size", mesh_aabb.size)
		brush_preview_material.set_shader_parameter("mesh_normal_tex", await mesh_normal_tex.get_texture())
		brush_preview_material.set_shader_parameter("mesh_tangent_tex", await mesh_tangent_tex.get_texture())
		brush_preview_material.set_shader_parameter("layer_albedo_tex", await get_albedo_texture())
		brush_preview_material.set_shader_parameter("layer_mr_tex", await get_mr_texture())
		brush_preview_material.set_shader_parameter("layer_emission_tex", await get_emission_texture())
		brush_preview_material.set_shader_parameter("layer_normal_tex", await get_normal_texture())
		brush_preview_material.set_shader_parameter("layer_do_tex", await get_do_texture())
		for p in brush_params.keys():
			brush_preview_material.set_shader_parameter(p, brush_params[p])
		brush_preview_material.set_shader_parameter("pattern_alpha", 0.5 if pattern_shown else 0.0)
	if brush_node == null:
		return
	# Mode
	var mode : String = get_brush_mode()
	for c in [ "albedo", "emission", "normal" ]:
		has_channel[c] = brush_node.get_parameter("has_"+c)
	has_channel["mr"] = brush_node.get_parameter("has_metallic") or brush_node.get_parameter("has_roughness")
	has_channel["do"] = brush_node.get_parameter("has_depth") or brush_node.get_parameter("has_ao")
	# Update shaders
	if update_shaders:
		var shader_template : String = load("res://material_maker/tools/painter/shaders/paint_shader_template.tres").text
		paint_shader.clear()
		paint_shader.add_parameter_or_texture("texture_space", "bool", false)
		paint_shader.add_parameter_or_texture("viewport_size", "vec2", viewport_size)
		paint_shader.add_parameter_or_texture("texture_center", "vec2", Vector2(0.5, 0.5))
		paint_shader.add_parameter_or_texture("texture_scale", "float", 1.0)
		paint_shader.add_parameter_or_texture("tex2view_tex", "sampler2D", t2v_texture)
		paint_shader.add_parameter_or_texture("view_back", "vec3", brush_params.view_back)
		paint_shader.add_parameter_or_texture("view_right", "vec3", brush_params.view_right)
		paint_shader.add_parameter_or_texture("view_up", "vec3", brush_params.view_up)
		paint_shader.add_parameter_or_texture("seams", "sampler2D", mesh_seams_tex)
		paint_shader.add_parameter_or_texture("mesh_%d_position" % [ abs(mesh.get_instance_id()) ], "sampler2D", mesh_position_tex)
		paint_shader.add_parameter_or_texture("mesh_%d_normal" % [ abs(mesh.get_instance_id()) ], "sampler2D", mesh_normal_tex)
		paint_shader.add_parameter_or_texture("mesh_%d_tangent" % [ abs(mesh.get_instance_id()) ], "sampler2D", mesh_tangent_tex)
		paint_shader.add_parameter_or_texture("seams_multiplier", "float", 256.0)
		
		paint_shader.add_parameter_or_texture("id_map_tex", "sampler2D", id_map_tex)
		paint_shader.add_parameter_or_texture("use_id_mask", "bool", id_mask_set)
		paint_shader.add_parameter_or_texture("id_mask_color", "vec4", id_mask_color)
		
		paint_shader.add_parameter_or_texture("fill", "bool", false)
		paint_shader.add_parameter_or_texture("erase", "bool", false)
		paint_shader.add_parameter_or_texture("reset", "bool", false)
		
		paint_shader.add_parameter_or_texture("brush_position", "vec2", Vector2(0, 0))
		paint_shader.add_parameter_or_texture("brush_previous_position", "vec2", Vector2(0, 0))
		paint_shader.add_parameter_or_texture("brush_size", "float", brush_params.brush_size)
		paint_shader.add_parameter_or_texture("brush_opacity", "float", 1.0)
		paint_shader.add_parameter_or_texture("brush_hardness", "float", brush_params.brush_hardness)
		
		paint_shader.add_parameter_or_texture("pressure", "float", 1.0)
		paint_shader.add_parameter_or_texture("tilt", "vec2", Vector2(0, 0))
		
		paint_shader.add_parameter_or_texture("pattern_angle", "float", brush_params.pattern_angle)
		paint_shader.add_parameter_or_texture("pattern_scale", "float", brush_params.pattern_scale)
		
		paint_shader.add_parameter_or_texture("jitter", "bool", true)
		paint_shader.add_parameter_or_texture("jitter_position", "float", 0.0)
		paint_shader.add_parameter_or_texture("jitter_size", "float", 0.0)
		paint_shader.add_parameter_or_texture("jitter_angle", "float", 0.0)
		paint_shader.add_parameter_or_texture("jitter_opacity", "float", 0.0)
		
		paint_shader.add_parameter_or_texture("stroke_seed", "float", 0.0)
		paint_shader.add_parameter_or_texture("stroke_length", "float", 0.0)
		paint_shader.add_parameter_or_texture("stroke_angle", "float", 0.0)
		
		var context : MMGenContext = MMGenContext.new()
		var brush_shader_code : MMGenBase.ShaderCode = brush_node.get_shader_code("brush_uv", 0, context)
		paint_shader.set_parameters_from_shadercode(brush_shader_code, false)
		
		var definitions : String = ""
		var brush_code : String = ""
		brush_code += brush_shader_code.code
		brush_code += "brush_value = %s;" % brush_shader_code.output_values.f
		definitions += brush_shader_code.defs
		
		var texture_defs : Array[Dictionary] = []
		paint_textures = []

		if paint_mask:
			print("Painting mask")
		else:
			print("Not painting mask")
		var pattern_code : String = ""
		var paint_channels : Array[Dictionary] = PAINT_CHANNELS_MASK if paint_mask else PAINT_CHANNELS
		for i in range(paint_channels.size()):
			var c : Dictionary = paint_channels[i]
			var has_channel : bool = false
			for condition in c.conditions:
				if condition == "has_mask":
					pass
				elif brush_node.get_parameter(condition):
					has_channel = true
					break
			if not has_channel:
				continue
			# Declare input/output images
			texture_defs.append({name=c.name+"_layer", type=MMPipeline.TEXTURE_TYPE_RGBA16F, readonly=true, writeonly=false, keep=true})
			texture_defs.append({name=c.name+"_stroke", type=MMPipeline.TEXTURE_TYPE_RGBA16F, writeonly=false, keep=true})
			texture_defs.append({name=c.name+"_layer_next", type=MMPipeline.TEXTURE_TYPE_RGBA16F, writeonly=true, keep=true})
			# Assign input/output textures
			var paint_channel : PaintChannel = get_paint_channel(i)
			paint_textures.append(paint_channel.texture)
			paint_textures.append(paint_channel.stroke)
			paint_textures.append(paint_channel.next_texture)
			# Generate code for this channel
			var pattern_definitions : String = ""
			var pattern_shader_code : MMGenBase.ShaderCode = brush_node.get_shader_code("pattern_uv", c.output_index, context)
			brush_shader_code.add_globals(pattern_shader_code.globals)
			paint_shader.set_parameters_from_shadercode(pattern_shader_code, false)
			pattern_code += pattern_shader_code.code
			pattern_code += "vec4 %s_value = %s;\n" % [ c.name, pattern_shader_code.output_values.rgba ]
			pattern_code += "vec4 old_%s_stroke_value = imageLoad(%s_stroke, pixel);\n" % [ c.name, c.name ]
			pattern_code += "vec4 old_%s_layer_value = reset ? vec4(0.0) : imageLoad(%s_layer, pixel);\n" % [ c.name, c.name ]
			pattern_code += "vec4 new_%s_stroke_value;\n" % [ c.name ]
			pattern_code += "vec4 new_%s_layer_value;\n" % [ c.name ]
			pattern_code += "do_paint_%s(%s_value, brush_value, old_%s_stroke_value, old_%s_layer_value, new_%s_stroke_value, new_%s_layer_value);\n" % [ c.type, c.name, c.name, c.name, c.name, c.name ]
			pattern_code += "imageStore(%s_stroke, pixel, new_%s_stroke_value);\n" % [ c.name, c.name ]
			pattern_code += "imageStore(%s_layer_next, pixel, new_%s_layer_value);\n" % [ c.name, c.name ]
			definitions += pattern_shader_code.defs
		
		var global_definitions : String = ""
		global_definitions += brush_shader_code.get_globals_string(definitions+brush_code+pattern_code)
		
		var replaces : Dictionary = {
			BRUSH_MODE="\""+get_brush_mode()+"\"",
			TEXTURE_TYPE="\"paint\"",
			DEFINITIONS=replace_predefs(global_definitions+definitions),
			BRUSH_CODE=replace_predefs(brush_code),
			PATTERN_CODE=replace_predefs(pattern_code)
		}
		if not texture_defs.is_empty():
			replaces["GENERATED_IMAGE"] = texture_defs[0].name
		replaces["@MISC_FUNCTIONS"] = load("res://addons/material_maker/shader_functions.tres").text
		await paint_shader.set_shader_ext(shader_template, texture_defs, replaces)
		mm_deps.buffer_create_compute_material("painter_%d:paint" % get_instance_id(), paint_shader_wrapper)
	paint_shader.set_parameter("viewport_size", Vector2(viewport_size))

func get_output_code(index : int) -> Dictionary:
	if brush_node == null or !is_instance_valid(brush_node):
		brush_node = null
		return {}
	var context : MMGenContext = MMGenContext.new()
	var source_mask : MMGenBase.ShaderCode = brush_node.get_shader_code("uv", 0, context)
	context = MMGenContext.new(context)
	var source : MMGenBase.ShaderCode = brush_node.get_shader_code("uv", index, context)
	var new_code : String = mm_renderer.common_shader
	new_code += "\n"
	var definitions : MMGenBase.ShaderCode = MMGenBase.ShaderCode.new()
	definitions.add_globals(source.globals)
	definitions.add_globals(source_mask.globals)
	new_code += definitions.get_globals_string()
	definitions.add_uniforms(source.uniforms)
	definitions.add_uniforms(source_mask.uniforms)
	new_code += definitions.uniforms_as_strings()
	for t in source.textures.keys():
		if !source_mask.textures.has(t):
			source_mask.textures[t] = source.textures[t]
	#brush_textures = source_mask.textures
	new_code += source_mask.defs+"\n"
	new_code += "\nfloat brush_function(vec2 uv) {\n"
	new_code += "float _seed_variation_ = 0.0;\n"
	new_code += source_mask.code+"\n"
	new_code += "vec2 __brush_box = abs(uv-vec2(0.5));\n"
	new_code += "return (max(__brush_box.x, __brush_box.y) < 0.5) ? "+source_mask.output_values.f+" : 0.0;\n"
	new_code += "}\n"
	new_code += source.defs+"\n"
	new_code += "\nvec4 pattern_function(vec2 uv) {\n"
	new_code += "float _seed_variation_ = 0.0;\n"
	new_code += source.code+"\n"
	new_code += "return "+source.output_values.rgba+";\n"
	new_code += "}\n"
	return { code=new_code, uniforms=definitions.uniforms }

func update_shader(buffer_name : String, shader_material : ShaderMaterial, shader_file : String, defines : Dictionary, uniforms : Array) -> void:
	if shader_material == null:
		print("no shader material")
		return
	var shader_wrapper : MMShaderMaterial = MMShaderMaterial.new(shader_material)
	await mm_deps.buffer_create_shader_material(buffer_name, shader_wrapper, mm_preprocessor.preprocess_file(shader_file, defines))
	for u in uniforms:
		shader_material.set_shader_parameter(u.name, u.value)
	if get_parent().has_method("update_procedural_layer"):
		get_parent().update_procedural_layer()

const PARAMETER_RENAMES : Dictionary = {
	brush_pos = "brush_position",
	brush_ppos = "brush_previous_position",
	rect_size = "viewport_size"
}

func on_dep_update_value(buffer_name : String, parameter_name : String, value) -> bool:
	if value != null:
		print(buffer_name)
		print(parameter_name)
		var suffix = buffer_name.right(-(buffer_name.find(":")+1))
		if suffix == "brush":
			print("brush")
			if value is MMTexture:
				print("Is a texture")
				brush_preview_material.set_shader_parameter(parameter_name, value.get_texture())
			else:
				brush_preview_material.set_shader_parameter(parameter_name, value)
		elif suffix == "paint":
			var n : String
			if PARAMETER_RENAMES.has(parameter_name):
				n = PARAMETER_RENAMES[parameter_name]
			else:
				n = parameter_name
			paint_shader.set_parameter(n, value)
	
	if get_parent().has_method("update_procedural_layer"):
		get_parent().update_procedural_layer()
	
	return false

func paint(shader_params : Dictionary, end_of_stroke : bool = false, emit_end_of_stroke : bool = true, on_mask : bool = false) -> void:
	var channels_infos : Array[Dictionary] = PAINT_CHANNELS_MASK if on_mask else PAINT_CHANNELS
	for p in shader_params.keys():
		var n : String
		if PARAMETER_RENAMES.has(p):
			n = PARAMETER_RENAMES[p]
		else:
			n = p
		paint_shader.set_parameter(n, shader_params[p], true)
	await paint_shader.render_ext(paint_textures, Vector2i(texture_size, texture_size))
	for i in range(paint_textures.size()/3):
		if OS.is_debug_build():
			paint_textures[i*3+1].get_texture()	# Update stroke texture
		paint_textures[i*3+2].get_texture() 	# Update painted texture
	emit_signal("painted")
	if end_of_stroke and emit_end_of_stroke:
		for i in range(paint_textures.size()/3):
			init_shader.set_parameter("modulate", Color(1.0, 1.0, 1.0, 1.0))
			init_shader.set_parameter("use_input_image", true)
			init_shader.set_parameter("input_image", paint_textures[i*3+2])
			await init_shader.render_ext([ paint_textures[i*3] ], Vector2i(texture_size, texture_size))
			paint_textures[i*3].get_texture()
			init_shader.set_parameter("modulate", Color(0.0, 0.0, 0.0, 0.0))
			init_shader.set_parameter("use_input_image", false)
			await init_shader.render_ext([ paint_textures[i*3+1] ], Vector2i(texture_size, texture_size))
			paint_textures[i*3+1].get_texture()
		var stroke_state = {}
		for c in channels_infos.size():
			var channel_name : String = channels_infos[c].name
			if has_channel[channel_name]:
				stroke_state[channel_name] = get_paint_channel(c).next_texture
		emit_signal("end_of_stroke", stroke_state)

func fill(erase : bool, reset : bool = false, emit_end_of_stroke : bool = true) -> void:
	paint({ brush_pos=Vector2(0, 0), brush_ppos=Vector2(0, 0), erase=erase, pressure=1.0, fill=true, reset=reset }, true, emit_end_of_stroke)

func view_to_texture(position : Vector2) -> Vector2:
	if view_to_texture_image == null:
		return Vector2(-1, -1)
	var position_in_texture : Color = view_to_texture_image.get_pixelv(position*VIEW_TO_TEXTURE_RATIO)
	if position_in_texture.r == position_in_texture.b && position_in_texture.g == position_in_texture.b:
		return Vector2(-1, -1)
	else:
		return Vector2(position_in_texture.r, position_in_texture.g)

func get_paint_channel(channel_index : int):
	if paint_channels.is_empty():
		paint_channels.resize(CHANNEL_MAX)
	if paint_channels[channel_index] == null:
		paint_channels[channel_index] = PaintChannel.new()
	return paint_channels[channel_index]

func get_texture_by_name(channel_name : String) -> Texture2D:
	return await get_paint_channel(paint_textures_by_name[channel_name]).next_texture.get_texture()
	
func get_albedo_texture() -> Texture2D:
	return await get_paint_channel(CHANNEL_ALBEDO).next_texture.get_texture()

func get_mr_texture() -> Texture2D:
	return await get_paint_channel(CHANNEL_MR).next_texture.get_texture()

func get_emission_texture() -> Texture2D:
	return await get_paint_channel(CHANNEL_EMISSION).next_texture.get_texture()

func get_normal_texture() -> Texture2D:
	return await get_paint_channel(CHANNEL_NORMAL).next_texture.get_texture()

func get_do_texture() -> Texture2D:
	return await get_paint_channel(CHANNEL_DO).next_texture.get_texture()

func save_viewport(v : SubViewport, f : String):
	v.get_texture().get_data().save_png(f)

func debug_get_texture_names():
	if OS.is_debug_build():
		return [
				"View to texture",
				"Texture to view",
				"Seams",
				"Albedo (current layer)",
				"Albedo previous (current layer)",
				"Albedo stroke (current layer)",
				"Metallic/Roughness (current layer)",
				"Metallic/Roughness stroke (current layer)",
				"Emission (current layer)",
				"Emission stroke (current layer)",
				"Normal (current layer)",
				"Normal stroke (current layer)",
				"Depth/Occlusion (current layer)",
				"Depth/Occlusion stroke (current layer)",
				"Mesh position map",
				"Mesh normal map",
				"Mesh tangent map"
			]
	else:
		return [
				"Albedo (current layer)",
				"Metallic/Roughness (current layer)",
				"Emission (current layer)",
				"Normal (current layer)",
				"Depth/Occlusion (current layer)"
			]

# Localization strings
# tr("View to texture")
# tr("Texture to view")
# tr("Seams")
# tr("Albedo (current layer)")
# tr("Metallic/Roughness (current layer)")
# tr("Emission (current layer)")
# tr("Normal (current layer)")
# tr("Depth/Occlusion (current layer)")
# tr("Mask (current layer)")

func debug_get_texture(ID):
	match debug_get_texture_names()[ID]:
		"View to texture":
			return await v2t_texture.get_texture()
		"Texture to view":
			return await t2v_texture.get_texture()
		"Seams":
			return await mesh_seams_tex.get_texture()
		"Albedo (current layer)":
			return await get_paint_channel(CHANNEL_ALBEDO).next_texture.get_texture()
		"Albedo previous (current layer)":
			return await get_paint_channel(CHANNEL_ALBEDO).texture.get_texture()
		"Albedo stroke (current layer)":
			return await get_paint_channel(CHANNEL_ALBEDO).stroke.get_texture()
		"Metallic/Roughness (current layer)":
			return await get_paint_channel(CHANNEL_MR).next_texture.get_texture()
		"Metallic/Roughness stroke (current layer)":
			return await get_paint_channel(CHANNEL_MR).stroke.get_texture()
		"Emission (current layer)":
			return await get_paint_channel(CHANNEL_EMISSION).next_texture.get_texture()
		"Emission stroke (current layer)":
			return await get_paint_channel(CHANNEL_EMISSION).stroke.get_texture()
		"Normal (current layer)":
			return await get_paint_channel(CHANNEL_NORMAL).next_texture.get_texture()
		"Normal stroke (current layer)":
			return await get_paint_channel(CHANNEL_NORMAL).stroke.get_texture()
		"Depth/Occlusion (current layer)":
			return await get_paint_channel(CHANNEL_DO).next_texture.get_texture()
		"Depth/Occlusion stroke (current layer)":
			return await get_paint_channel(CHANNEL_DO).stroke.get_texture()
		"Mesh position map":
			return mesh_position_tex
		"Mesh normal map":
			return mesh_normal_tex
		"Mesh tangent map":
			return mesh_tangent_tex
	return null
