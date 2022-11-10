extends Control

var generator : MMGenBase = null
var output : int = 0

func _enter_tree():
	mm_deps.create_buffer("histogram_"+str(get_instance_id()), self)

func _exit_tree():
	mm_deps.delete_buffer("histogram_"+str(get_instance_id()))

func get_image_texture() -> ImageTexture:
	return $ViewportImage/ColorRect.material.get_shader_param("tex")

func get_histogram_texture() -> ImageTexture:
	return $Control.material.get_shader_param("tex")

func set_generator(g : MMGenBase, o : int = 0, force : bool = false) -> void:
	if !force and generator == g and output == o:
		return
	if is_instance_valid(generator) and generator.is_connected("parameter_changed", self, "on_parameter_changed"):
		generator.disconnect("parameter_changed", self, "on_parameter_changed")
	var source = MMGenBase.DEFAULT_GENERATED_SHADER
	if is_instance_valid(g):
		generator = g
		output = o
		generator.connect("parameter_changed", self, "on_parameter_changed")
		var gen_output_defs = generator.get_output_defs()
		if ! gen_output_defs.empty():
			var context : MMGenContext = MMGenContext.new()
			source = generator.get_shader_code("uv", output, context)
			assert(!(source is GDScriptFunctionState))
			if source.empty():
				source = MMGenBase.DEFAULT_GENERATED_SHADER
	# Update shader
	var shader_code : String = MMGenBase.generate_preview_shader(source, source.type, "uniform vec2 size;void fragment() {COLOR = preview_2d(UV);}")
	var buffer_name : String = "histogram_"+str(get_instance_id())
	$ViewportImage/ColorRect.material = mm_deps.buffer_create_shader_material(buffer_name, $ViewportImage/ColorRect.material, shader_code)
	mm_deps.update()

var refreshing_generator : bool = false
func on_parameter_changed(n : String, v) -> void:
	if !is_inside_tree():
		return
	if n == "__output_changed__" and output == v:
		if ! refreshing_generator:
			refreshing_generator = true
			yield(get_tree(), "idle_frame")
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
	$ViewportImage/ColorRect.material.set_shader_param(parameter_name, value)
	return false

func on_dep_update_buffer(buffer_name) -> bool:
	if ! is_visible_in_tree():
		return true
	$ViewportImage.render_target_update_mode = Viewport.UPDATE_ONCE
	$ViewportImage.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	$ViewportHistogram1.render_target_update_mode = Viewport.UPDATE_ONCE
	$ViewportHistogram1.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	$ViewportHistogram2.render_target_update_mode = Viewport.UPDATE_ONCE
	$ViewportHistogram2.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	mm_deps.dependency_update("histogram_"+str(get_instance_id()), null)
	return true
