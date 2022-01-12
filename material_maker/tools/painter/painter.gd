extends Node

onready var view_to_texture_viewport = $View2Texture
onready var view_to_texture_mesh = $View2Texture/PaintedMesh
onready var view_to_texture_camera = $View2Texture/Camera
var view_to_texture_image: Image

onready var texture_to_view_viewport = $Texture2View
onready var texture_to_view_mesh = $Texture2View/PaintedMesh

onready var mesh_seams_tex: ImageTexture = ImageTexture.new()

onready var albedo_viewport = $AlbedoPaint
onready var mr_viewport = $MRPaint
onready var emission_viewport = $EmissionPaint
onready var normal_viewport = $NormalPaint
onready var do_viewport = $DOPaint
onready var mask_viewport = $MaskPaint
const viewport_names: Array = ["albedo", "mr", "emission", "normal", "do", "mask"]
onready var viewports: Dictionary = {
	albedo = albedo_viewport,
	mr = mr_viewport,
	emission = emission_viewport,
	normal = normal_viewport,
	do = do_viewport,
	mask = mask_viewport
}

var camera
var transform
var viewport_size

var brush_node = null
var brush_params = {
	brush_size = 1.0, brush_hardness = 0.5, pattern_scale = 10.0, pattern_angle = 0.0
}

var has_channel: Dictionary = {}

var brush_preview_material: ShaderMaterial
var pattern_shown: bool = false
var brush_textures: Dictionary = {}

var mesh_aabb: AABB
var mesh_inv_uv_tex: ImageTexture = null
var mesh_normal_tex: ImageTexture = null
var mesh_tangent_tex: ImageTexture = null

const VIEW_TO_TEXTURE_RATIO = 2.0

# shader files
var shader_files: Dictionary = {}
const CACHE_SHADER_FILES: bool = false

signal painted(painted_channels)
signal end_of_stroke(stroke_state)


func _ready():
	var v2t_tex = view_to_texture_viewport.get_texture()
	var t2v_tex = texture_to_view_viewport.get_texture()
	# shader debug
	# add View2Texture as input of Texture2View (to ignore non-visible parts of the mesh)
	texture_to_view_mesh.get_surface_material(0).set_shader_param("view2texture", v2t_tex)
	# Add Texture2ViewWithoutSeams as input to all painted textures
	for v in viewports.keys():
		viewports[v].set_intermediate_textures(t2v_tex, mesh_seams_tex)


func update_seams_texture(_m: Mesh = null) -> void:
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	texture_to_view_viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	var map_renderer = load("res://material_maker/tools/map_renderer/map_renderer.tscn").instance()
	add_child(map_renderer)
	var result = map_renderer.gen(
		texture_to_view_mesh.mesh,
		"seams",
		"copy_to_texture",
		[mesh_seams_tex],
		texture_to_view_viewport.size.x
	)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	map_renderer.queue_free()


func update_inv_uv_texture(m: Mesh) -> void:
	var map_renderer = load("res://material_maker/tools/map_renderer/map_renderer.tscn").instance()
	add_child(map_renderer)
	if mesh_inv_uv_tex == null:
		mesh_inv_uv_tex = ImageTexture.new()
	var result = map_renderer.gen(
		m, "inv_uv", "copy_to_texture", [mesh_inv_uv_tex], texture_to_view_viewport.size.x
	)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	if mesh_normal_tex == null:
		mesh_normal_tex = ImageTexture.new()
	result = map_renderer.gen(
		m, "mesh_normal", "copy_to_texture", [mesh_normal_tex], texture_to_view_viewport.size.x
	)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	if mesh_tangent_tex == null:
		mesh_tangent_tex = ImageTexture.new()
	result = map_renderer.gen(
		m, "mesh_tangent", "copy_to_texture", [mesh_tangent_tex], texture_to_view_viewport.size.x
	)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	map_renderer.queue_free()
	mesh_aabb = m.get_aabb()


func set_mesh(m: Mesh):
	var mat: Material
	mat = texture_to_view_mesh.get_surface_material(0)
	texture_to_view_mesh.mesh = m
	texture_to_view_mesh.set_surface_material(0, mat)
	mat = view_to_texture_mesh.get_surface_material(0)
	view_to_texture_mesh.mesh = m
	view_to_texture_mesh.set_surface_material(0, mat)
	for init_fct in ["update_seams_texture", "update_inv_uv_texture"]:
		var result = call(init_fct, m)
		while result is GDScriptFunctionState:
			result = yield(result, "completed")


func calculate_mask(value: float, channel: int) -> Color:
	if channel == SpatialMaterial.TEXTURE_CHANNEL_RED:
		return Color(value, 0, 0, 0)
	elif channel == SpatialMaterial.TEXTURE_CHANNEL_GREEN:
		return Color(0, value, 0, 0)
	elif channel == SpatialMaterial.TEXTURE_CHANNEL_BLUE:
		return Color(0, 0, value, 0)
	elif channel == SpatialMaterial.TEXTURE_CHANNEL_ALPHA:
		return Color(0, 0, 0, value)
	return Color(0, 0, 0, 0)


func init_albedo_texture(color: Color = Color(0.0, 0.0, 0.0, 0.0), texture: Texture = null):
	albedo_viewport.init(color, texture)


func init_mr_texture(color: Color = Color(0.0, 0.0, 0.0, 0.0), texture: Texture = null):
	mr_viewport.init(color, texture)


func init_mr_texture_channels(
	metallic: float = 1.0,
	metallic_texture: Texture = null,
	metallic_channel: int = SpatialMaterial.TEXTURE_CHANNEL_RED,
	roughness: float = 1.0,
	roughness_texture: Texture = null,
	roughness_channel: int = SpatialMaterial.TEXTURE_CHANNEL_GREEN
):
	mr_viewport.init_channels(
		metallic_texture,
		calculate_mask(metallic, metallic_channel),
		roughness_texture,
		calculate_mask(roughness, roughness_channel),
		null,
		Color(1.0, 0.0, 0.0, 0.0),
		null,
		Color(1.0, 0.0, 0.0, 0.0)
	)


func init_emission_texture(color: Color = Color(0.0, 0.0, 0.0, 0.0), texture: Texture = null):
	emission_viewport.init(color, texture)


func init_normal_texture(color: Color = Color(0.0, 0.0, 0.0, 0.0), texture: Texture = null):
	normal_viewport.init(color, texture)


func init_do_texture(color: Color = Color(0.0, 0.0, 0.0, 0.0), texture: Texture = null):
	do_viewport.init(color, texture)


func init_do_texture_channels(
	depth: float = 1.0,
	depth_texture: Texture = null,
	occlusion: float = 1.0,
	occlusion_texture: Texture = null,
	occlusion_channel: int = SpatialMaterial.TEXTURE_CHANNEL_GREEN
):
	do_viewport.init_channels(
		depth_texture,
		calculate_mask(depth, SpatialMaterial.TEXTURE_CHANNEL_RED),
		occlusion_texture,
		calculate_mask(occlusion, occlusion_channel),
		null,
		Color(1.0, 0.0, 0.0, 0.0),
		null,
		Color(1.0, 0.0, 0.0, 0.0)
	)


func init_mask_texture(color: Color = Color(0.0, 0.0, 0.0, 1.0), texture: Texture = null):
	mask_viewport.init(color, texture)


func init_textures(m: SpatialMaterial):
	init_mask_texture()
	init_albedo_texture(m.albedo_color, m.albedo_texture)
	init_mr_texture_channels(
		m.metallic,
		m.metallic_texture,
		m.metallic_texture_channel,
		m.roughness,
		m.roughness_texture,
		m.roughness_texture_channel
	)
	if m.emission_enabled:
		var emission_color = m.emission
		emission_color.a = 1.0
		init_emission_texture(emission_color, m.emission_texture)
	else:
		init_emission_texture(Color(0.0, 0.0, 0.0), null)
	if m.normal_enabled:
		init_normal_texture(Color(1.0, 1.0, 1.0), m.n_texture)
	else:
		init_normal_texture(Color(0.5, 0.5, 0.0), null)
	if m.depth_enabled or m.ao_enabled:
		init_do_texture_channels(
			m.depth_scale if m.depth_enabled else 0.0,
			m.depth_texture,
			m.ao_light_affect if m.ao_enabled else 1.0,
			m.ao_texture,
			m.ao_texture_channel
		)
	else:
		init_do_texture(Color(0.0, 1.0, 0.0, 0.0), null)


func set_texture_size(s: float):
	if texture_to_view_viewport.size.x != s:
		texture_to_view_viewport.size = Vector2(s, s)
		for v in viewports.keys():
			viewports[v].set_texture_size(s)
		update_seams_texture()


func update_view(c, t, s):
	camera = c
	transform = t
	viewport_size = s
	brush_params.view_back = transform.basis.xform_inv(Vector3(0.0, 0.0, 1.0)).normalized()
	brush_params.view_right = transform.basis.xform_inv(Vector3(1.0, 0.0, 0.0)).normalized()
	brush_params.view_up = transform.basis.xform_inv(Vector3(0.0, 1.0, 0.0)).normalized()
	update_tex2view()
	update_brush()


func update_tex2view():
	if viewport_size.y <= 0:
		return
	var aspect = viewport_size.x / viewport_size.y
	view_to_texture_viewport.size = VIEW_TO_TEXTURE_RATIO * viewport_size
	view_to_texture_camera.transform = camera.global_transform
	view_to_texture_camera.fov = camera.fov
	view_to_texture_camera.near = camera.near
	view_to_texture_camera.far = camera.far
	var mat: ShaderMaterial = view_to_texture_mesh.get_surface_material(0)
	if true:
		var shader_file = File.new()
		shader_file.open(
			"res://material_maker/tools/painter/shaders/view2texture.shader", File.READ
		)
		mat.shader.code = shader_file.get_as_text()
	mat.set_shader_param("near", camera.near)
	mat.set_shader_param("far", camera.far)
	view_to_texture_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	view_to_texture_viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	view_to_texture_image = view_to_texture_viewport.get_texture().get_data()
	view_to_texture_image.lock()
	mat = texture_to_view_mesh.get_surface_material(0)
	if true:
		var shader_file = File.new()
		shader_file.open(
			"res://material_maker/tools/painter/shaders/texture2view.shader", File.READ
		)
		mat.shader.code = shader_file.get_as_text()
	mat.set_shader_param("model_transform", transform)
	mat.set_shader_param("fovy_degrees", camera.fov)
	mat.set_shader_param("z_near", camera.near)
	mat.set_shader_param("z_far", camera.far)
	mat.set_shader_param("aspect", aspect)
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	texture_to_view_viewport.update_worlds()


# Shader methods


func get_shader_file(file_name: String) -> String:
	var shader_text = ""
	if CACHE_SHADER_FILES and shader_files.has(file_name):
		shader_text = shader_files[file_name]
	else:
		var file = File.new()
		if (
			file.open(
				"res://material_maker/tools/painter/shaders/" + file_name + ".shader", File.READ
			)
			== OK
		):
			shader_text = file.get_as_text()
		else:
			print("Cannot open %s.shader" % file_name)
		shader_files[file_name] = shader_text
	return shader_text


func preprocess_shader(shader_text: String) -> String:
	var regex: RegEx = RegEx.new()
	regex.compile("#include\\s+(\\w+)")
	while true:
		var result: RegExMatch = regex.search(shader_text)
		if result == null:
			break
		shader_text = shader_text.replace(result.strings[0], get_shader_file(result.strings[1]))
	return shader_text


# Brush methods


func get_brush_mode() -> String:
	return brush_node.get_parameter_defs()[0].values[brush_node.get_parameter("mode")].value


func set_brush_node(node) -> void:
	brush_node = node
	update_brush(true)


func set_brush_preview_material(m: ShaderMaterial) -> void:
	brush_preview_material = m


func get_brush_preview_shader(mode: String) -> String:
	var shader_text: String = get_shader_file("brush_%s" % mode)
	shader_text = preprocess_shader(shader_text)
	return shader_text


func set_brush_angle(a) -> void:
	brush_params.pattern_angle = a
	update_brush()


func update_brush_params(shader_params: Dictionary) -> void:
	for p in shader_params.keys():
		brush_params[p] = shader_params[p]
		if brush_preview_material != null:
			brush_preview_material.set_shader_param(p, brush_params[p])


func show_pattern(b):
	if pattern_shown != b:
		pattern_shown = b
		update_brush()


func update_brush(update_shaders: bool = false):
	#if brush_params.albedo_texture_mode != 2: $Pattern.visible = false
	if brush_preview_material != null:
		if update_shaders:
			var code: String = get_output_code(1)
			update_shader(brush_preview_material, get_brush_preview_shader(get_brush_mode()), code)
		var v2t_tex = view_to_texture_viewport.get_texture()
		brush_preview_material.set_shader_param("rect_size", viewport_size)
		brush_preview_material.set_shader_param("view2tex_tex", v2t_tex)
		brush_preview_material.set_shader_param("mesh_inv_uv_tex", mesh_inv_uv_tex)
		brush_preview_material.set_shader_param("mesh_aabb_position", mesh_aabb.position)
		brush_preview_material.set_shader_param("mesh_aabb_size", mesh_aabb.size)
		brush_preview_material.set_shader_param("mesh_normal_tex", mesh_normal_tex)
		brush_preview_material.set_shader_param("mesh_tangent_tex", mesh_tangent_tex)
		brush_preview_material.set_shader_param("layer_albedo_tex", get_albedo_texture())
		brush_preview_material.set_shader_param("layer_mr_tex", get_mr_texture())
		brush_preview_material.set_shader_param("layer_emission_tex", get_emission_texture())
		brush_preview_material.set_shader_param("layer_normal_tex", get_normal_texture())
		brush_preview_material.set_shader_param("layer_do_tex", get_do_texture())
		for p in brush_params.keys():
			brush_preview_material.set_shader_param(p, brush_params[p])
		brush_preview_material.set_shader_param("pattern_alpha", 0.5 if pattern_shown else 0.0)
	if brush_node == null:
		return
	# Mode
	var mode: String = get_brush_mode()
	for c in ["albedo", "emission", "normal"]:
		has_channel[c] = brush_node.get_parameter("has_" + c)
	has_channel["mr"] = (
		brush_node.get_parameter("has_metallic")
		or brush_node.get_parameter("has_roughness")
	)
	has_channel["do"] = brush_node.get_parameter("has_depth") or brush_node.get_parameter("has_ao")
	has_channel["mask"] = true
	# Update shaders
	if update_shaders:
		for index in viewport_names.size():
			var viewport = viewports[viewport_names[index]]
			var shader_text = get_shader_file(viewport.get_shader_prefix() + "_" + mode)
			shader_text = preprocess_shader(shader_text)
			update_shader(viewport.get_paint_material(), shader_text, get_output_code(index + 1))
			viewport.set_mesh_textures(
				mesh_aabb, mesh_inv_uv_tex, mesh_normal_tex, mesh_tangent_tex
			)
			viewport.set_layer_textures(
				{
					albedo = get_albedo_texture(),
					mr = get_mr_texture(),
					emission = get_emission_texture(),
					normal = get_normal_texture(),
					do = get_do_texture(),
					mask = get_mask_texture()
				}
			)
	for v in viewports.keys():
		viewports[v].set_brush(brush_params)


func get_output_code(index: int) -> String:
	if brush_node == null or !is_instance_valid(brush_node):
		brush_node = null
		return ""
	var context: MMGenContext = MMGenContext.new()
	var source_mask = brush_node.get_shader_code("uv", 0, context)
	context = MMGenContext.new(context)
	var source = brush_node.get_shader_code("uv", index, context)
	var new_code: String = mm_renderer.common_shader
	new_code += "\n"
	for g in source.globals:
		if source_mask.globals.find(g) == -1:
			source_mask.globals.append(g)
	for g in source_mask.globals:
		new_code += g
	for t in source.textures.keys():
		if !source_mask.textures.has(t):
			source_mask.textures[t] = source.textures[t]
	brush_textures = source_mask.textures
	new_code += source_mask.defs + "\n"
	new_code += "\nfloat brush_function(vec2 uv) {\n"
	new_code += "float _seed_variation_ = 0.0;\n"
	new_code += source_mask.code + "\n"
	new_code += "vec2 __brush_box = abs(uv-vec2(0.5));\n"
	new_code += "return (max(__brush_box.x, __brush_box.y) < 0.5) ? " + source_mask.f + " : 0.0;\n"
	new_code += "}\n"
	new_code += source.defs + "\n"
	new_code += "\nvec4 pattern_function(vec2 uv) {\n"
	new_code += "float _seed_variation_ = 0.0;\n"
	new_code += source.code + "\n"
	new_code += "return " + source.rgba + ";\n"
	new_code += "}\n"
	return new_code


func update_shader(shader_material: ShaderMaterial, shader_template: String, shader_code: String) -> void:
	if shader_material == null:
		print("no shader material")
		return
	var new_code = (
		shader_template.left(shader_template.find("// BEGIN_PATTERN"))
		+ "// BEGIN_PATTERN\n"
		+ shader_code
		+ shader_template.right(shader_template.find("// END_PATTERN"))
	)
	shader_material.shader.code = new_code
	# Get parameter values from the shader code
	MMGenBase.define_shader_float_parameters(shader_material.shader.code, shader_material)
	for t in brush_textures.keys():
		shader_material.set_shader_param(t, brush_textures[t])


func on_float_parameters_changed(parameter_changes: Dictionary) -> bool:
	for v in viewports.keys():
		mm_renderer.update_float_parameters(viewports[v].paint_material, parameter_changes)
	mm_renderer.update_float_parameters(brush_preview_material, parameter_changes)
	return true


func paint(shader_params: Dictionary, end_of_stroke: bool = false, emit_end_of_stroke: bool = true) -> void:
	var active_viewports: Array = []
	for v in viewports.keys():
		if has_channel[v]:
			active_viewports.push_back(v)
			viewports[v].do_paint(shader_params, end_of_stroke)
	var finished: bool = false
	while !finished:
		yield(get_tree(), "idle_frame")
		finished = true
		for v in active_viewports:
			if viewports[v].painting > 0:
				finished = false
				break
	emit_signal("painted")
	if end_of_stroke and emit_end_of_stroke:
		var stroke_state = {}
		for v in active_viewports:
			stroke_state[v] = viewports[v].get_current_state()
		emit_signal("end_of_stroke", stroke_state)


func set_state(s):
	for c in s.keys():
		if viewports.has(c):
			viewports[c].init(Color(1, 1, 1, 1), s[c])
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	emit_signal("painted")


func fill(erase: bool, reset: bool = false, emit_end_of_stroke: bool = true) -> void:
	paint(
		{
			brush_pos = Vector2(0, 0),
			brush_ppos = Vector2(0, 0),
			erase = erase,
			pressure = 1.0,
			fill = true,
			reset = reset
		},
		true,
		emit_end_of_stroke
	)


func view_to_texture(position: Vector2) -> Vector2:
	var position_in_texture: Color = view_to_texture_image.get_pixelv(
		position * VIEW_TO_TEXTURE_RATIO
	)
	if (
		position_in_texture.r == position_in_texture.b
		&& position_in_texture.g == position_in_texture.b
	):
		return Vector2(-1, -1)
	else:
		return Vector2(position_in_texture.r, position_in_texture.g)


func get_albedo_texture():
	return albedo_viewport.get_texture()


func get_mr_texture():
	return mr_viewport.get_texture()


func get_emission_texture():
	return emission_viewport.get_texture()


func get_normal_texture():
	return normal_viewport.get_texture()


func get_do_texture():
	return do_viewport.get_texture()


func get_mask_texture():
	return mask_viewport.get_texture()


func save_viewport(v: Viewport, f: String):
	v.get_texture().get_data().save_png(f)


func debug_get_texture_names():
	if OS.is_debug_build():
		return [
			"View to texture",
			"Texture to view",
			"Seams",
			"Albedo (current layer)",
			"Metallic/Roughness (current layer)",
			"Emission (current layer)",
			"Normal (current layer)",
			"Depth/Occlusion (current layer)",
			"Mask (current layer)"
		]
	else:
		return [
			"Albedo (current layer)",
			"Metallic/Roughness (current layer)",
			"Emission (current layer)",
			"Normal (current layer)",
			"Depth/Occlusion (current layer)",
			"Mask (current layer)"
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
	if !OS.is_debug_build():
		ID -= 3
	match ID:
		0:
			return view_to_texture_viewport.get_texture()
		1:
			return texture_to_view_viewport.get_texture()
		2:
			return mesh_seams_tex
		3:
			return albedo_viewport.get_texture()
		4:
			return mr_viewport.get_texture()
		5:
			return emission_viewport.get_texture()
		6:
			return normal_viewport.get_texture()
		7:
			return do_viewport.get_texture()
		8:
			return mask_viewport.get_texture()
	return null
