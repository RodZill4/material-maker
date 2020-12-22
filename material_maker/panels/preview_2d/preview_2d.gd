extends ColorRect

export(String, MULTILINE) var shader : String = ""

var generator : MMGenBase = null
var output : int = 0

var need_generate : bool = false

func update_export_menu() -> void:
	$ContextMenu/Export.clear()
	$ContextMenu/Reference.clear()
	for i in range(7):
		var s = 64 << i
		$ContextMenu/Export.add_item(str(s)+"x"+str(s), i)
		$ContextMenu/Reference.add_item(str(s)+"x"+str(s), i)
	$ContextMenu.add_submenu_item("Export", "Export")
	$ContextMenu.add_submenu_item("Reference", "Reference")

func set_generator(g : MMGenBase, o : int = 0) -> void:
	if !is_visible_in_tree():
		generator = g
		output = o
		need_generate = true
		return
	need_generate = false
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
			assert(!(source is GDScriptFunctionState))
			if source.empty():
				source = MMGenBase.DEFAULT_GENERATED_SHADER
	else:
		generator = null
	# Update shader
	var code = MMGenBase.generate_preview_shader(source, source.type, shader)
	material.shader.code = code
	# Get parameter values from the shader code
	MMGenBase.define_shader_float_parameters(material.shader.code, material)
	# Set texture params
	if source.has("textures"):
		for k in source.textures.keys():
			material.set_shader_param(k, source.textures[k])

func on_parameter_changed(n : String, v) -> void:
	if n == "__output_changed__" and output == v:
		set_generator(generator, output)
	var p = generator.get_parameter_def(n)
	if p.has("type"):
		match p.type:
			"float", "color", "gradient":
				pass
			_:
				set_generator(generator, output)

func on_float_parameters_changed(parameter_changes : Dictionary) -> void:
	for n in parameter_changes.keys():
		for p in VisualServer.shader_get_param_list(material.shader.get_rid()):
			if p.name == n:
				material.set_shader_param(n, parameter_changes[n])
				break

func on_resized() -> void:
	material.set_shader_param("size", rect_size)

func _on_Export_id_pressed(id : int):
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.png;PNG image file")
	dialog.add_filter("*.exr;EXR image file")
	if get_node("/root/MainWindow") != null:
		var config_cache = get_node("/root/MainWindow").config_cache
		if config_cache.has_section_key("path", "save_preview"):
			dialog.current_dir = config_cache.get_value("path", "save_preview")
	dialog.connect("file_selected", self, "export_as_image_file", [ 64 << id ])
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.popup_centered()

func create_image(renderer_function : String, params : Array, size : int) -> void:
	var source = MMGenBase.DEFAULT_GENERATED_SHADER
	if generator != null:
		var gen_output_defs = generator.get_output_defs()
		if ! gen_output_defs.empty():
			var context : MMGenContext = MMGenContext.new()
			source = generator.get_shader_code("uv", output, context)
			assert(!(source is GDScriptFunctionState))
			if source.empty():
				source = MMGenBase.DEFAULT_GENERATED_SHADER
	# Update shader
	var tmp_material = ShaderMaterial.new()
	tmp_material.shader = Shader.new()
	tmp_material.shader.code = MMGenBase.generate_preview_shader(source, source.type, "uniform vec2 size;void fragment() {COLOR = preview_2d(UV);}")
	# Set texture params
	if source.has("textures"):
		for k in source.textures.keys():
			tmp_material.set_shader_param(k, source.textures[k])
	var renderer = mm_renderer.request(self)
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	renderer = renderer.render_material(self, tmp_material, size, false)
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	renderer.callv(renderer_function, params)
	renderer.release(self)

func export_as_image_file(file_name : String, size : int) -> void:
	var main_window = get_node("/root/MainWindow")
	if main_window != null:
		var config_cache = main_window.config_cache
		config_cache.set_value("path", "save_preview", file_name.get_base_dir())
	create_image("save_to_file", [ file_name ], size)

func _on_Reference_id_pressed(id : int):
	var texture : ImageTexture = ImageTexture.new()
	var status = create_image("copy_to_texture", [ texture ], 64 << id)
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	get_node("/root/MainWindow").get_panel("Reference").add_reference(texture)

func _on_Preview2D_visibility_changed():
	if need_generate and is_visible_in_tree():
		set_generator(generator, output)
