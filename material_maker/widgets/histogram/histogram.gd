extends Control

var generator : MMGenBase = null
var output : int = 0

var updating : bool = false
var update_again : bool = false

func get_image_texture() -> ImageTexture:
	return $ViewportImage/ColorRect.material.get_shader_param("tex")

func get_histogram_texture() -> ImageTexture:
	return $Control.material.get_shader_param("tex")

func set_generator(g : MMGenBase, o : int = 0) -> void:
	if is_instance_valid(generator):
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
			while source is GDScriptFunctionState:
				source = yield(source, "completed")
			if source.empty():
				source = MMGenBase.DEFAULT_GENERATED_SHADER
	# Update shader
	$ViewportImage/ColorRect.material.shader.code = MMGenBase.generate_preview_shader(source, source.type, "uniform vec2 size;void fragment() {COLOR = preview_2d(UV);}")
	# Get parameter values from the shader code
	var regex = RegEx.new()
	regex.compile("uniform\\s+(\\w+)\\s+([\\w_\\d]+)\\s*=\\s*([^;]+);")
	for p in regex.search_all($ViewportImage/ColorRect.material.shader.code):
		$ViewportImage/ColorRect.material.set_shader_param(p.strings[2], float(p.strings[3]))
	# Set texture params
	if source.has("textures"):
		for k in source.textures.keys():
			$ViewportImage/ColorRect.material.set_shader_param(k, source.textures[k])
	update_histogram()

func on_parameter_changed(n : String, _v) -> void:
	if n == "__input_changed__":
		set_generator(generator, output)
	var p = generator.get_parameter_def(n)
	if p.has("type"):
		match p.type:
			"float", "color", "gradient":
				pass
			_:
				set_generator(generator, output)

func on_float_parameters_changed(parameter_changes : Dictionary) -> void:
	var need_update : bool = false
	for n in parameter_changes.keys():
		for p in VisualServer.shader_get_param_list($ViewportImage/ColorRect.material.shader.get_rid()):
			if p.name == n:
				$ViewportImage/ColorRect.material.set_shader_param(n, parameter_changes[n])
				need_update = true
				break
	if need_update:
		update_histogram()

func update_histogram() -> void:
	update_again = true
	if !updating && is_visible_in_tree():
		updating = true
		while update_again:
			update_again = false
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
		updating = false

func _on_Histogram_visibility_changed():
	if is_visible_in_tree():
		update_histogram()
