@tool
extends Control

@export var texture_size : int = 256: set = set_texture_size

var generator : MMGenBase = null
var output : int = 0

func _ready():
	set_texture_size(texture_size)

func get_buffer_name() -> String:
	return "histogram_"+str(get_instance_id())

func set_texture_size(ts : int):
	if ! is_inside_tree():
		return
	texture_size = ts
	$ViewportImage.size = Vector2(texture_size, texture_size)
	$ViewportImage/ColorRect.size = Vector2(texture_size, texture_size)
	$ViewportHistogram1.size = Vector2(texture_size, 256)
	$ViewportHistogram1/ColorRect.size = Vector2(texture_size, 256)
	$ViewportHistogram1/ColorRect.material.set_shader_parameter("size", texture_size)
	$ViewportHistogram2.size = Vector2(256, 2)
	$ViewportHistogram2/ColorRect.size = Vector2(256, 2)
	$ViewportHistogram2/ColorRect.material.set_shader_parameter("size", texture_size)
	on_dep_update_buffer(get_buffer_name())

func _enter_tree():
	mm_deps.create_buffer(get_buffer_name(), self)

func _exit_tree():
	mm_deps.delete_buffer(get_buffer_name())

func get_image_texture() -> ImageTexture:
	return $ViewportImage/ColorRect.material.get_shader_parameter("tex")

func get_histogram_texture() -> Texture2D:
	return $Control.material.get_shader_parameter("tex")

func set_generator(g : MMGenBase, o : int = 0, force : bool = false) -> void:
	if ! is_inside_tree():
		return
	if !force and generator == g and output == o:
		return
	if is_instance_valid(generator) and generator.is_connected("parameter_changed",Callable(self,"on_parameter_changed")):
		generator.disconnect("parameter_changed",Callable(self,"on_parameter_changed"))
	var source : MMGenBase.ShaderCode = MMGenBase.get_default_generated_shader()
	if is_instance_valid(g):
		generator = g
		output = o
		generator.connect("parameter_changed",Callable(self,"on_parameter_changed"))
		var gen_output_defs = generator.get_output_defs()
		if ! gen_output_defs.is_empty():
			var context : MMGenContext = MMGenContext.new()
			source = generator.get_shader_code("uv", output, context)
			if source.output_type == "":
				source = MMGenBase.get_default_generated_shader()
	# Update shader
	var shader_code : String = MMGenBase.generate_preview_shader(source, source.output_type, "uniform vec2 mm_texture_size;void fragment() {COLOR = preview_2d(UV);}")
	var shader_material : MMShaderMaterial = MMShaderMaterial.new($ViewportImage/ColorRect.material)
	mm_deps.buffer_create_shader_material(get_buffer_name(), shader_material, shader_code)
	mm_deps.update()

var refreshing_generator : bool = false
func on_parameter_changed(n : String, v) -> void:
	if !is_inside_tree():
		return
	if n == "__output_changed__" and output == v:
		if ! refreshing_generator:
			refreshing_generator = true
			await get_tree().process_frame
			set_generator(generator, output, true)
			refreshing_generator = false
		return
	var p = generator.get_parameter_def(n)
	if p.has("type"):
		match p.type:
			"float", "color", "gradient":
				pass
			_:
				set_generator(generator, output, true)

func on_dep_update_value(_buffer_name, parameter_name, value) -> bool:
	$ViewportImage/ColorRect.material.set_shader_parameter(parameter_name, value)
	return false

func on_dep_update_buffer(_buffer_name) -> bool:
	if ! ( is_inside_tree() and is_visible_in_tree() ):
		return false
	for v in [ $ViewportImage, $ViewportHistogram1, $ViewportHistogram2 ]:
		v.render_target_update_mode = SubViewport.UPDATE_ONCE
		if get_tree() == null:
			return false
		await get_tree().process_frame
		if get_tree() == null:
			return false
		await get_tree().process_frame
	mm_deps.dependency_update("histogram_"+str(get_instance_id()), null, true)
	return true
