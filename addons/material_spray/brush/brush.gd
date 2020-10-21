extends Control

var current_brush = {
	size          = 50.0,
	strength      = 0.5,
	pattern_scale = 10.0,
	texture_angle = 0.0
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
	if brush_node.get_parameter("mode") == 0:
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
	#if current_brush.albedo_texture_mode != 2: $Pattern.visible = false
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
	update_brush()

func brush_selected(brush):
	current_brush = brush
	update_brush()

func _on_Checkbox_pressed():
	update_material()

func _on_Color_color_changed(color):
	update_material()

func _on_HSlider_value_changed(value):
	update_material()

func _on_OptionButton_item_selected(ID):
	update_material()

func _on_Brush_resized():
	update_brush()

func _on_Parameters_item_selected(ID):
	for i in range($BrushUI.get_children().size()-1):
		$BrushUI.get_children()[i].visible = i == ID
