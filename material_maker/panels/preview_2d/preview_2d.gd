extends ColorRect

export(String, MULTILINE) var shader_context_defs : String = ""
export(String, MULTILINE) var shader : String = ""

var generator : MMGenBase = null
var output : int = 0
var is_greyscale : bool = false

var need_generate : bool = false

var last_export_filename : String = ""
var last_export_size : int = 0

const MENU_EXPORT_AGAIN : int = 1000
const MENU_EXPORT_ANIMATION : int = 1001
const MENU_TEMPORAL_AA : int = 1002

func update_export_menu() -> void:
	$ContextMenu/Export.clear()
	$ContextMenu/Reference.clear()
	for i in range(8):
		var s = 64 << i
		$ContextMenu/Export.add_item(str(s)+"x"+str(s), i)
		$ContextMenu/Reference.add_item(str(s)+"x"+str(s), i)
	$ContextMenu.add_submenu_item("Export", "Export")
	$ContextMenu.add_item("Export again", MENU_EXPORT_AGAIN)
	$ContextMenu.set_item_disabled($ContextMenu.get_item_index(MENU_EXPORT_AGAIN), true)
	$ContextMenu.add_item("Export animation", MENU_EXPORT_ANIMATION)
	$ContextMenu.set_item_disabled($ContextMenu.get_item_index(MENU_EXPORT_ANIMATION), true)
	$ContextMenu.add_submenu_item("Reference", "Reference")

func do_update_material(source, target_material, template):
	is_greyscale = source.has("type") and source.type == "f"
	# Update shader
	var code = MMGenBase.generate_preview_shader(source, source.type, template)
	target_material.shader.code = code
	# Get parameter values from the shader code
	MMGenBase.define_shader_float_parameters(target_material.shader.code, target_material)
	# Set texture params
	if source.has("textures"):
		for k in source.textures.keys():
			target_material.set_shader_param(k, source.textures[k])
	on_resized()

func update_material(source):
	do_update_material(source, material, shader_context_defs+get_shader_custom_functions()+shader)

func get_shader_custom_functions():
	return ""

func set_generator(g : MMGenBase, o : int = 0, force : bool = false) -> void:
	if !is_visible_in_tree():
		generator = g
		output = o
		need_generate = true
		return
	if !force and generator == g and output == o:
		return
	need_generate = false
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
		if get_node_or_null("ContextMenu") != null:
			$ContextMenu.set_item_disabled($ContextMenu.get_item_index(MENU_EXPORT_ANIMATION), false)
	else:
		generator = null
		if get_node_or_null("ContextMenu") != null:
			$ContextMenu.set_item_disabled($ContextMenu.get_item_index(MENU_EXPORT_ANIMATION), true)
	update_material(source)

func on_parameter_changed(n : String, v) -> void:
	if n == "__output_changed__" and output == v:
		set_generator(generator, output, true)
	var p = generator.get_parameter_def(n)
	if p.has("type"):
		match p.type:
			"float", "color", "gradient":
				pass
			_:
				set_generator(generator, output, true)

func get_preview_material():
	return material

func on_float_parameters_changed(parameter_changes : Dictionary) -> bool:
	var return_value : bool = false
	var m : ShaderMaterial = get_preview_material()
	for n in parameter_changes.keys():
		for p in VisualServer.shader_get_param_list(m.shader.get_rid()):
			if p.name == n:
				return_value = true
				m.set_shader_param(n, parameter_changes[n])
				break
	return return_value

func on_resized() -> void:
	material.set_shader_param("preview_2d_size", rect_size)

func export_again() -> void:
	if last_export_filename == "":
		return
	var filename = last_export_filename
	var extension = filename.get_extension()
	var regex : RegEx = RegEx.new()
	regex.compile("(.*)_(\\d+)$")
	var file : File = File.new()
	var re_match : RegExMatch = regex.search(filename.get_basename())
	if re_match != null:
		var value = re_match.strings[2].to_int()
		var value_length = re_match.strings[2].length()
		while true:
			value += 1
			filename = "%s_%0*d.%s" % [ re_match.strings[1], value_length, value, extension ]
			if !file.file_exists(filename):
				break
	export_as_image_file(filename, last_export_size)

func export_animation() -> void:
	if generator == null:
		return
	var window = load("res://material_maker/windows/export_animation/export_animation.tscn").instance()
	add_child(window)
	window.set_source(generator, output)
	window.popup_centered()

func _on_Export_id_pressed(id : int) -> void:
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
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
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() == 1:
		export_as_image_file(files[0], 64 << id)

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
	renderer = renderer.render_material(self, tmp_material, size, source.type != "rgba")
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	renderer.callv(renderer_function, params)
	renderer.release(self)

func export_as_image_file(file_name : String, size : int) -> void:
	var main_window = get_node("/root/MainWindow")
	if main_window != null:
		var config_cache = main_window.config_cache
		config_cache.set_value("path", "save_preview", file_name.get_base_dir())
	create_image("save_to_file", [ file_name, is_greyscale ], size)
	last_export_filename = file_name
	last_export_size = size
	$ContextMenu.set_item_disabled($ContextMenu.get_item_index(MENU_EXPORT_AGAIN), false)

func _on_Reference_id_pressed(id : int):
	var texture : ImageTexture = ImageTexture.new()
	var status = create_image("copy_to_texture", [ texture ], 64 << id)
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	get_node("/root/MainWindow").get_panel("Reference").add_reference(texture)

func _on_Preview2D_visibility_changed():
	if need_generate and is_visible_in_tree():
		set_generator(generator, output, true)
