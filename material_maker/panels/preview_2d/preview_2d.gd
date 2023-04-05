extends ColorRect

@export var shader_context_defs : String = "" # (String, MULTILINE)
@export var shader : String = "" # (String, MULTILINE)

var generator : MMGenBase = null
var output : int = 0
var is_greyscale : bool = false

var need_generate : bool = false

var last_export_filename : String = ""
var last_export_size : int = 0


const MENU_EXPORT_AGAIN : int = 1000
const MENU_EXPORT_ANIMATION : int = 1001


func _enter_tree():
	mm_deps.create_buffer("preview_"+str(get_instance_id()), self)

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

func generate_preview_shader(source, template) -> String:
	return MMGenBase.generate_preview_shader(source, source.output_type, template)

func do_update_material(source, target_material : ShaderMaterial, template):
	if source.output_type == "":
		return
	is_greyscale = source.output_type == "f"
	# Update shader
	var code = generate_preview_shader(source, template)
	target_material = mm_deps.buffer_create_shader_material("preview_"+str(get_instance_id()), target_material, code)
	# Make sure position/size parameters are setup
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
	if is_instance_valid(generator) and generator.is_connected("parameter_changed",Callable(self,"on_parameter_changed")):
		generator.disconnect("parameter_changed",Callable(self,"on_parameter_changed"))
	var source = MMGenBase.get_default_generated_shader()
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
	else:
		generator = null
	if get_node_or_null("ContextMenu") != null:
		var item_index = $ContextMenu.get_item_index(MENU_EXPORT_ANIMATION)
		if item_index != -1:
			$ContextMenu.set_item_disabled(item_index, !is_instance_valid(g))
	update_material(source)

var refreshing_generator : bool = false
func on_parameter_changed(n : String, v) -> void:
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

func get_preview_material():
	return material

func on_dep_update_value(_buffer_name, parameter_name, value) -> bool:
	get_preview_material().set_shader_parameter(parameter_name, value)
	return false

func on_resized() -> void:
	material.set_shader_parameter("preview_2d_size", size)

func export_again() -> void:
	if last_export_filename == "":
		return
	var filename = last_export_filename
	var extension = filename.get_extension()
	var regex : RegEx = RegEx.new()
	regex.compile("(.*)_(\\d+)$")
	var re_match : RegExMatch = regex.search(filename.get_basename())
	if re_match != null:
		var value = re_match.strings[2].to_int()
		var value_length = re_match.strings[2].length()
		while true:
			value += 1
			filename = "%s_%0*d.%s" % [ re_match.strings[1], value_length, value, extension ]
			if ! FileAccess.file_exists(filename):
				break
	export_as_image_file(filename, last_export_size)

func export_animation() -> void:
	if generator == null:
		return
	var window = load("res://material_maker/windows/export_animation/export_animation.tscn").instantiate()
	add_child(window)
	window.set_source(generator, output)
	window.popup_centered()

func _on_Export_id_pressed(id : int) -> void:
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.png;PNG image file")
	dialog.add_filter("*.exr;EXR image file")
	if mm_globals.config.has_section_key("path", "save_preview"):
		dialog.current_dir = mm_globals.config.get_value("path", "save_preview")
	var files = await dialog.select_files()
	if files.size() == 1:
		export_as_image_file(files[0], 64 << id)

func create_image(renderer_function : String, params : Array, size : int) -> void:
	var source = MMGenBase.get_default_generated_shader()
	if generator != null:
		var gen_output_defs = generator.get_output_defs()
		if ! gen_output_defs.is_empty():
			var context : MMGenContext = MMGenContext.new()
			source = generator.get_shader_code("uv", output, context)
			if source.is_empty():
				source = MMGenBase.get_default_generated_shader()
	# Update shader
	var tmp_material = ShaderMaterial.new()
	tmp_material.shader = Shader.new()
	tmp_material.shader.code = MMGenBase.generate_preview_shader(source, source.type, "uniform vec2 size;\nuniform float mm_chunk_size = 1.0;\nuniform vec2 mm_chunk_offset = vec2(0.0);\nvoid fragment() {COLOR = preview_2d(mm_chunk_offset+mm_chunk_size*UV);}")
	mm_deps.material_update_params(tmp_material)
	var renderer = await mm_renderer.request(self)
	renderer = await renderer.render_material(self, tmp_material, size, source.type != "rgba")
	renderer.callv(renderer_function, params)
	renderer.release(self)

func export_as_image_file(file_name : String, size : int) -> void:
	mm_globals.config.set_value("path", "save_preview", file_name.get_base_dir())
	create_image("save_to_file", [ file_name, is_greyscale ], size)
	last_export_filename = file_name
	last_export_size = size
	$ContextMenu.set_item_disabled($ContextMenu.get_item_index(MENU_EXPORT_AGAIN), false)

func _on_Reference_id_pressed(id : int):
	var texture : ImageTexture = ImageTexture.new()
	var status = await create_image("copy_to_texture", [ texture ], 64 << id)
	mm_globals.main_window.get_panel("Reference").add_reference(texture)

func _on_Preview2D_visibility_changed():
	if need_generate and is_visible_in_tree():
		set_generator(generator, output, true)
