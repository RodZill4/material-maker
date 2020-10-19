extends Control

var current_brush = {
	size          = 50.0,
	strength      = 0.5,
	pattern_scale = 10.0,
	texture_angle = 0.0,
	has_albedo = false,
	albedo_color = Color(0.0, 0.0, 0.0),
	albedo_texture_mode = 0,
	albedo_texture = null,
	albedo_texture_file_name = null,
	has_metallic = false,
	metallic = 0.0,
	has_roughness = false,
	roughness = 0.0,
	has_emission = false,
	emission_color = Color(0.0, 0.0, 0.0),
	emission_texture_mode = 0,
	emission_texture = null,
	emission_texture_file_name = null,
	has_depth = false,
	depth_color = Color(0.0, 0.0, 0.0),
	depth_texture_mode = 0,
	depth_texture = null,
	depth_texture_file_name = null,
}

var brush_node = null
var albedo_texture_filename = null
var albedo_texture = null
var emission_texture_filename = null
var emission_texture = null
var depth_texture_filename = null
var depth_texture = null

onready var brush_material = $Brush.material
onready var pattern_material = $Pattern.material

signal brush_changed(new_brush, update_shader)

func _ready():
	$BrushUI/AMR/AlbedoTexture.material = $BrushUI/AMR/AlbedoTexture.material.duplicate()
	$BrushUI/Emission/EmissionTexture.material = $BrushUI/Emission/EmissionTexture.material.duplicate()
	$BrushUI/Depth/DepthTexture.material = $BrushUI/Depth/DepthTexture.material.duplicate()
	update_material()

func show_brush(p, op = null):
	if p == null:
		$Brush.hide()
	else:
		$Brush.show()
		if op == null:
			op = p
		var position = p/rect_size
		var old_position = op/rect_size
		brush_material.set_shader_param("brush_pos", position)
		brush_material.set_shader_param("brush_ppos", old_position)

func edit_brush(s):
	current_brush.size += s.x*0.1
	current_brush.size = clamp(current_brush.size, 0.0, 250.0)
	if current_brush.albedo_texture_mode == 1:
		current_brush.texture_angle += fmod(s.y*0.01, 2.0*PI)
	else:
		current_brush.strength += s.y*0.01
		current_brush.strength = clamp(current_brush.strength, 0.0, 0.99999)
	update_brush()

func show_pattern(b):
	$Pattern.visible = b and ($BrushUI/AMR/AlbedoTextureMode.selected == 2)

func edit_pattern(s):
	current_brush.pattern_scale += s.x*0.1
	current_brush.pattern_scale = clamp(current_brush.pattern_scale, 0.1, 25.0)
	current_brush.texture_angle += fmod(s.y*0.01, 2.0*PI)
	update_brush()

func set_brush_node(node) -> void:
	brush_node = node
	brush_node.connect("parameter_changed", self, "on_brush_changed")

func get_output_code(index : int) -> String:
	if brush_node == null:
		return ""
	var context : MMGenContext = MMGenContext.new()
	var source_mask = brush_node.get_shader_code("uv", 0, context)
	context = MMGenContext.new(context)
	var source = brush_node.get_shader_code("uv", index, context)
	var new_code : String = mm_renderer.common_shader
	new_code += "\n"
	for g in source.globals:
		if source_mask.globals.find(g) == -1:
			source_mask.globals.append(g)
	for g in source_mask.globals:
		new_code += g
	new_code += source_mask.defs+"\n"
	new_code += "\nfloat brush_function(vec2 uv) {\n"
	new_code += source_mask.code+"\n"
	new_code += "vec2 __brush_box = abs(uv-vec2(0.5));\n"
	new_code += "return (max(__brush_box.x, __brush_box.y) < 0.5) ? "+source_mask.f+" : 0.0;\n"
	new_code += "}\n"
	new_code += source.defs+"\n"
	new_code += "\nvec4 pattern_function(vec2 uv) {\n"
	new_code += source.code+"\n"
	new_code += "return "+source.rgba+";\n"
	new_code += "}\n"
	return new_code

var brush_changed_scheduled : bool = false

func on_brush_changed(p, v) -> void:
	if !brush_changed_scheduled:
		call_deferred("do_on_brush_changed")
		brush_changed_scheduled = true

func do_on_brush_changed():
	var code : String = get_output_code(1)
	update_shader($Brush.material, $Brush.material.shader.code, code)
	update_shader($Pattern.material, $Pattern.material.shader.code, code)
	update_material()
	update_brush(true)
	brush_changed_scheduled = false

func update_shader(shader_material : ShaderMaterial, shader_template : String, shader_code : String) -> void:
	if shader_material == null:
		print("no shader material")
		return
	var new_code = shader_template.left(shader_template.find("// BEGIN_PATTERN"))+"// BEGIN_PATTERN\n"+shader_code+shader_template.right(shader_template.find("// END_PATTERN"))
	shader_material.shader.code = new_code
	# Get parameter values from the shader code
	MMGenBase.define_shader_float_parameters(shader_material.shader.code, shader_material)

func on_float_parameters_changed(parameter_changes : Dictionary) -> void:
	mm_renderer.update_float_parameters($Brush.material, parameter_changes)
	mm_renderer.update_float_parameters($Pattern.material, parameter_changes)

func update_brush(update_shaders = false):
	if current_brush.albedo_texture_mode != 2:
		$Pattern.visible = false
	var brush_size_vector = Vector2(current_brush.size, current_brush.size)/rect_size
	if brush_material != null:
		brush_material.set_shader_param("brush_size", brush_size_vector)
		brush_material.set_shader_param("brush_strength", current_brush.strength)
		brush_material.set_shader_param("pattern_scale", current_brush.pattern_scale)
		brush_material.set_shader_param("texture_angle", current_brush.texture_angle)
		brush_material.set_shader_param("brush_texture", null)
		brush_material.set_shader_param("stamp_mode", 0)
	if pattern_material != null:
		pattern_material.set_shader_param("brush_size", brush_size_vector)
		pattern_material.set_shader_param("pattern_scale", current_brush.pattern_scale)
		pattern_material.set_shader_param("texture_angle", current_brush.texture_angle)
		pattern_material.set_shader_param("brush_texture", null)
	for parameter in [ "albedo", "emission", "depth" ]:
		if current_brush.get("has_"+parameter):
			if brush_material != null:
				brush_material.set_shader_param("brush_texture", current_brush.get(parameter+"_texture"))
				brush_material.set_shader_param("stamp_mode", current_brush.get(parameter+"_texture_mode") == 1)
			if pattern_material != null:
				pattern_material.set_shader_param("brush_texture", current_brush.get(parameter+"_texture"))
	emit_signal("brush_changed", current_brush, update_shaders)

func update_material():
	# AMR
	current_brush.has_albedo = brush_node.get_parameter("has_albedo") if brush_node != null else false
	current_brush.albedo_color = $BrushUI/AMR/AlbedoColor.color
	current_brush.albedo_texture_mode = $BrushUI/AMR/AlbedoTextureMode.selected
	if current_brush.albedo_texture_mode != 0:
		current_brush.albedo_texture = albedo_texture
		current_brush.albedo_texture_file_name = albedo_texture_filename
	else:
		current_brush.albedo_texture = null
		current_brush.albedo_texture_file_name = null
	current_brush.has_metallic = brush_node.get_parameter("has_metallic") if brush_node != null else false
	current_brush.metallic = $BrushUI/AMR/MetallicValue.value
	current_brush.has_roughness = brush_node.get_parameter("has_roughness") if brush_node != null else false
	current_brush.roughness = $BrushUI/AMR/RoughnessValue.value
	# Emission
	current_brush.has_emission = brush_node.get_parameter("has_emission") if brush_node != null else false
	current_brush.emission_color = $BrushUI/Emission/EmissionColor.color
	current_brush.emission_texture_mode = $BrushUI/Emission/EmissionTextureMode.selected
	if current_brush.emission_texture_mode != 0:
		current_brush.emission_texture = emission_texture
		current_brush.emission_texture_file_name = emission_texture_filename
	else:
		current_brush.emission_texture = null
		current_brush.emission_texture_file_name = null
	# Depth
	current_brush.has_depth = $BrushUI/Depth/Depth.pressed
	current_brush.depth_color = $BrushUI/Depth/DepthColor.color
	current_brush.depth_texture_mode = $BrushUI/Depth/DepthTextureMode.selected
	if current_brush.depth_texture_mode != 0:
		current_brush.depth_texture = depth_texture
		current_brush.depth_texture_file_name = depth_texture_filename
	else:
		current_brush.depth_texture = null
		current_brush.depth_texture_file_name = null
	update_brush()

func brush_selected(brush):
	current_brush = brush
	# AMR
	$BrushUI/AMR/Albedo.pressed = current_brush.has_albedo
	$BrushUI/AMR/AlbedoColor.color = current_brush.albedo_color
	$BrushUI/AMR/AlbedoTextureMode.selected = current_brush.albedo_texture_mode
	if current_brush.albedo_texture_mode != 0:
		albedo_texture_filename = current_brush.albedo_texture_file_name
		albedo_texture = load(albedo_texture_filename) if albedo_texture_filename != null else null
		current_brush.albedo_texture = albedo_texture
		$BrushUI/AMR/AlbedoTexture.material.set_shader_param("tex", albedo_texture)
	else:
		albedo_texture = null
		albedo_texture_filename = null
		$BrushUI/AMR/AlbedoTexture.material.set_shader_param("tex", preload("res://addons/material_spray/materials/empty.png"))
	$BrushUI/AMR/Metallic.pressed = current_brush.has_metallic
	$BrushUI/AMR/MetallicValue.value = current_brush.metallic
	$BrushUI/AMR/Roughness.pressed = current_brush.has_roughness
	$BrushUI/AMR/RoughnessValue.value = current_brush.roughness
	# Emission
	$BrushUI/Emission/Emission.pressed = current_brush.has_emission
	$BrushUI/Emission/EmissionColor.color = current_brush.emission_color
	$BrushUI/Emission/EmissionTextureMode.selected = current_brush.emission_texture_mode
	if current_brush.emission_texture_mode != 0:
		emission_texture_filename = current_brush.emission_texture_file_name
		emission_texture = load(emission_texture_filename) if emission_texture_filename != null else null
		current_brush.emission_texture = emission_texture
		$BrushUI/Emission/EmissionTexture.material.set_shader_param("tex", emission_texture)
	else:
		emission_texture = null
		emission_texture_filename = null
		$BrushUI/Emission/EmissionTexture.material.set_shader_param("tex", preload("res://addons/material_spray/materials/empty.png"))
	# Depth
	$BrushUI/Depth/Depth.pressed = current_brush.has_depth
	$BrushUI/Depth/DepthColor.color = current_brush.depth_color
	$BrushUI/Depth/DepthTextureMode.selected = current_brush.depth_texture_mode
	if current_brush.depth_texture_mode != 0:
		depth_texture_filename = current_brush.depth_texture_file_name
		depth_texture = load(depth_texture_filename) if depth_texture_filename != null else null
		current_brush.depth_texture = depth_texture
		$BrushUI/Depth/DepthTexture.material.set_shader_param("tex", depth_texture)
	else:
		depth_texture = null
		depth_texture_filename = null
		$BrushUI/Depth/DepthTexture.material.set_shader_param("tex", preload("res://addons/material_spray/materials/empty.png"))
	update_brush()

func _on_Checkbox_pressed():
	update_material()

func _on_Color_color_changed(color):
	update_material()

func _on_HSlider_value_changed(value):
	update_material()

func _on_OptionButton_item_selected(ID):
	update_material()

func _on_Texture_gui_input(event, parameter):
	if event is InputEventMouseButton:
		var dialog = FileDialog.new()
		add_child(dialog)
		dialog.rect_min_size = Vector2(500, 500)
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.mode = FileDialog.MODE_OPEN_FILE
		dialog.add_filter("*.png;PNG image")
		dialog.connect("file_selected", self, "do_load_"+parameter+"_texture")
		dialog.popup_centered()

func do_load_albedo_texture(filename):
	albedo_texture_filename = filename
	albedo_texture = load(filename)
	$BrushUI/AMR/AlbedoTexture.material.set_shader_param("tex", albedo_texture)
	update_material()
	
func do_load_emission_texture(filename):
	emission_texture_filename = filename
	emission_texture = load(filename)
	$BrushUI/Emission/EmissionTexture.material.set_shader_param("tex", emission_texture)
	update_material()
	
func do_load_depth_texture(filename):
	depth_texture_filename = filename
	depth_texture = load(filename)
	$BrushUI/Depth/DepthTexture.material.set_shader_param("tex", depth_texture)
	update_material()

func _on_Brush_resized():
	update_brush()

func _on_Parameters_item_selected(ID):
	for i in range($BrushUI.get_children().size()-1):
		$BrushUI.get_children()[i].visible = i == ID
