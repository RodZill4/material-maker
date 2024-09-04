extends ColorRect

@export_multiline var shader_context_defs : String = "" # (String, MULTILINE)
@export_multiline var shader : String = "" # (String, MULTILINE)

var generator : MMGenBase = null
var output : int = 0
var is_greyscale : bool = false

var need_generate : bool = false

var last_export_filename : String = ""
var last_export_size = 4


const MENU_EXPORT_AGAIN : int = 1000
const MENU_EXPORT_ANIMATION : int = 1001
const MENU_EXPORT_TAA_RENDER : int = 1002
const MENU_EXPORT_CUSTOM_SIZE : int = 1003

signal generator_changed

func _enter_tree():
	mm_deps.create_buffer("preview_"+str(get_instance_id()), self)


func generate_preview_shader(source, template) -> String:
	return MMGenBase.generate_preview_shader(source, source.output_type, template)


func do_update_material(source, target_material : ShaderMaterial, template : String):
	if source.output_type == "":
		return
	is_greyscale = source.output_type == "f"
	# Update shader
	if template.find("TIME") != -1:
		print("Template has time") # This should not happen
	var code = generate_preview_shader(source, template)
	await mm_deps.buffer_create_shader_material("preview_"+str(get_instance_id()), MMShaderMaterial.new(target_material), code)
	for u in source.uniforms:
		if u.value:
			if u.value is MMTexture:
				target_material.set_shader_parameter(u.name, u.value.get_texture())
			else:
				target_material.set_shader_parameter(u.name, u.value)
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

	generator_changed.emit()
	update_material(source)

var refreshing_generator : bool = false
func on_parameter_changed(n : String, v) -> void:
	if n == "__output_changed__" and output == v:
		if ! refreshing_generator and is_inside_tree():
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

func set_preview_shader_parameter(parameter_name, value):
	material.set_shader_parameter(parameter_name, value)

func on_dep_update_value(_buffer_name, parameter_name, value) -> bool:
	if value is MMTexture:
		value = await value.get_texture()
	set_preview_shader_parameter(parameter_name, value)
	return false

func on_resized() -> void:
	material.set_shader_parameter("preview_2d_size", size)

#func export_again() -> void:
	#if last_export_filename == "":
		#return
	#var filename = last_export_filename
	#var extension = filename.get_extension()
	#var regex : RegEx = RegEx.new()
	#regex.compile("(.*)_(\\d+)$")
	#var re_match : RegExMatch = regex.search(filename.get_basename())
	#if re_match != null:
		#var value = re_match.strings[2].to_int()
		#var value_length = re_match.strings[2].length()
		#while true:
			#value += 1
			#filename = "%s_%0*d.%s" % [ re_match.strings[1], value_length, value, extension ]
			#if ! FileAccess.file_exists(filename):
				#break
	#export_as_image_file(filename, last_export_size)

func export_animation() -> void:
	if generator == null:
		return
	var window = load("res://material_maker/windows/export_animation/export_animation.tscn").instantiate()
	mm_globals.main_window.add_dialog(window)
	window.set_source(generator, output)
	window.exclusive = true
	window.popup_centered()#e(get_window(), Rect2(get_window().size())

func export_taa() -> void:
	if generator == null:
		return
	var window = load("res://material_maker/windows/export_taa/export_taa.tscn").instantiate()
	mm_globals.main_window.add_dialog(window)
	window.set_source(generator, output)
	window.popup_centered()

func _on_Export_id_pressed(id : int) -> void:
	var export_size
	if id == MENU_EXPORT_CUSTOM_SIZE:
		var custom_size_dialog = load("res://material_maker/panels/preview_2d/custom_size_dialog.tscn").instantiate()
		mm_globals.main_window.add_dialog(custom_size_dialog)
		export_size = await custom_size_dialog.ask()
		if ! export_size.has("size"):
			return
		export_size = export_size.size
	else:
		export_size = 64 << id
	var file_dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	file_dialog.min_size = Vector2(500, 500)
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.add_filter("*.png;PNG image file")
	file_dialog.add_filter("*.exr;EXR image file")
	if mm_globals.config.has_section_key("path", "save_preview"):
		file_dialog.current_dir = mm_globals.config.get_value("path", "save_preview")
	var files = await file_dialog.select_files()
	if files.size() == 1:
		# TODO: fix custom export size here
		export_as_image_file(files[0], 64 << id)

func create_image(renderer_function : String, params : Array, image_size : int) -> void:
	var source = MMGenBase.get_default_generated_shader()
	if generator != null:
		var gen_output_defs = generator.get_output_defs()
		if ! gen_output_defs.is_empty():
			var context : MMGenContext = MMGenContext.new()
			source = generator.get_shader_code("uv", output, context)
			if source.output_type == "":
				source = MMGenBase.get_default_generated_shader()
	# Update shader
	var tmp_material = ShaderMaterial.new()
	tmp_material.shader = Shader.new()
	tmp_material.shader.code = MMGenBase.generate_preview_shader(source, source.output_type, "uniform vec2 mm_texture_size;\nuniform float mm_chunk_size = 1.0;\nuniform vec2 mm_chunk_offset = vec2(0.0);\nvoid fragment() {COLOR = preview_2d(mm_chunk_offset+mm_chunk_size*UV);}")
	mm_deps.material_update_params(MMShaderMaterial.new(tmp_material))
	var renderer = await mm_renderer.request(self)
	renderer = await renderer.render_material(self, tmp_material, image_size, source.output_type != "rgba")
	renderer.callv(renderer_function, params)
	renderer.release(self)

func export_as_image_file(file_name : String, image_size : int) -> void:
	mm_globals.config.set_value("path", "save_preview", file_name.get_base_dir())
	create_image("save_to_file", [ file_name, is_greyscale ], image_size)
	last_export_filename = file_name
	last_export_size = image_size


func export_to_reference(resolution_id : int):
	var texture : ImageTexture = ImageTexture.new()
	await create_image("copy_to_texture", [ texture ], 64 << resolution_id)
	mm_globals.main_window.get_panel("Reference").add_reference(texture)

func _on_Preview2D_visibility_changed():
	if need_generate and is_visible_in_tree():
		set_generator(generator, output, true)
