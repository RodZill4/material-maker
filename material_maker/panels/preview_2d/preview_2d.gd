extends ColorRect

export(String, MULTILINE) var shader : String = ""

var generator : MMGenBase = null
var output : int = 0

func update_export_menu() -> void:
	$ContextMenu/Export.clear()
	for i in range(7):
		var s = 64 << i
		$ContextMenu/Export.add_item(str(s)+"x"+str(s), i)
	$ContextMenu.add_submenu_item("Export", "Export")

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
	else:
		generator = null
	# Update shader
	material.shader.code = MMGenBase.generate_preview_shader(source, source.type, shader)
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

func _on_Export_id_pressed(id):
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

func export_as_image_file(file_name : String, size : int) -> void:
	if get_node("/root/MainWindow") != null:
		var config_cache = get_node("/root/MainWindow").config_cache
		config_cache.set_value("path", "save_preview", file_name.get_base_dir())
	var previous_size = material.get_shader_param("size")
	var previous_margin = material.get_shader_param("margin")
	var previous_show_tiling = material.get_shader_param("show_tiling")
	material.set_shader_param("size", Vector2(size, size))
	material.set_shader_param("margin", 0.0)
	material.set_shader_param("show_tiling", false)
	material.set_shader_param("export", true)
	var renderer = mm_renderer.request(self)
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	renderer = renderer.render_material(self, material, size, false)
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	renderer.save_to_file(file_name)
	renderer.release(self)
	material.set_shader_param("size", previous_size)
	material.set_shader_param("margin", previous_margin)
	material.set_shader_param("show_tiling", previous_show_tiling)
	material.set_shader_param("export", false)
