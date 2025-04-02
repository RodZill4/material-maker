extends Window


var acc_texture : MMTexture
var avg_texture : MMTexture
var accumulate_render : MMComputeShader
var divide_render : MMComputeShader

var iteration : int = 0
var force_update : bool = false
var render_size : Vector2i = Vector2i(512, 512)

func _ready():
	content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	min_size = $VBoxContainer.get_combined_minimum_size() * content_scale_factor
	acc_texture = MMTexture.new()
	avg_texture = MMTexture.new()
	accumulate_render = MMComputeShader.new()
	divide_render = MMComputeShader.new()
	_on_denoise_item_selected(0)

func set_source(generator, output):
	var context : MMGenContext = MMGenContext.new()
	var source : MMGenBase.ShaderCode = generator.get_shader_code("uv", output, context)
	var shader_template : String = load("res://material_maker/windows/export_taa/accumulate_compute.tres").text
	var extra_parameters : Array[Dictionary] = []
	extra_parameters.append({ name="elapsed_time", type="float", value=0.0 })
	extra_parameters.append({ name="mm_iteration", type="int", value=0 })
	extra_parameters.append({ name="mm_accumulate_previous", type="sampler2D", value=acc_texture })
	var output_textures : Array[Dictionary] = [{name="OUTPUT_TEXTURE", type=MMPipeline.TEXTURE_TYPE_RGBA32F, writeonly=false, keep=true}]
	await accumulate_render.set_shader_from_shadercode_ext(shader_template, source, output_textures, extra_parameters, true, [])
	divide_render.add_parameter_or_texture("mm_iteration", "float", 0)
	divide_render.add_parameter_or_texture("mm_texture_acc", "sampler2D", acc_texture)
	divide_render.add_parameter_or_texture("mm_exponent", "float", 1)
	divide_render.add_parameter_or_texture("mm_denoise", "int", 0)
	divide_render.add_parameter_or_texture("mm_denoise_radius", "int", 1)
	divide_render.add_parameter_or_texture("mm_denoise_sigma", "float", 1)
	divide_render.add_parameter_or_texture("mm_denoise_ksigma", "float", 1)
	divide_render.add_parameter_or_texture("mm_denoise_threshold", "float", 1)
	shader_template = load("res://material_maker/windows/export_taa/divide_compute.tres").text
	divide_render.set_shader(shader_template, 3)
	while true:
		var new_size : Vector2i = Vector2i($VBoxContainer/Settings/Width.value, $VBoxContainer/Settings/Height.value)
		if render_size != new_size:
			render_size = new_size
			iteration = 0
		iteration += 1
		accumulate_render.set_parameter("mm_iteration", iteration)
		accumulate_render.set_parameter("elapsed_time", float(Time.get_ticks_usec())*0.000001)
		await accumulate_render.render(acc_texture, render_size)
		if force_update or (iteration & 15) == 0:
			var label : String = "Iteration: %d" % iteration
			$VBoxContainer/Settings/Iteration.text = label
			await divide_render.render(avg_texture, render_size)
			divide_render.set_parameter("mm_iteration", iteration)
			divide_render.set_parameter("mm_texture_acc", acc_texture)
			divide_render.set_parameter("mm_exponent", 1.0/$VBoxContainer/Settings/Gamma.value)
			divide_render.set_parameter("mm_denoise", $VBoxContainer/Denoise/Denoise.selected)
			divide_render.set_parameter("mm_denoise_radius", int($VBoxContainer/Denoise/Radius.value))
			divide_render.set_parameter("mm_denoise_sigma", $VBoxContainer/Denoise/Sigma.value)
			divide_render.set_parameter("mm_denoise_ksigma", $VBoxContainer/Denoise/kSigma.value)
			divide_render.set_parameter("mm_denoise_threshold", $VBoxContainer/Denoise/Threshold.value)
			$VBoxContainer/TextureRect.texture = await avg_texture.get_texture()
			force_update = false

func _on_Export_pressed():
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.exr;EXR image file")
	dialog.add_filter("*.jpg;JPG image file")
	dialog.add_filter("*.png;PNG image file")
	dialog.add_filter("*.webp;WEBP image file")
	if mm_globals.config.has_section_key("path", "save_preview"):
		dialog.current_dir = mm_globals.config.get_value("path", "save_preview")
	var files = await dialog.select_files()
	if files.size() == 1:
		await avg_texture.save_to_file(files[0])

func _on_denoise_item_selected(index):
	force_update = true
	const HIDE_NODES : Array[PackedStringArray] = [
		[ "RadiusLabel", "Radius", "SigmaLabel", "Sigma", "kSigmaLabel", "kSigma", "ThresholdLabel", "Threshold" ],
		[ "SigmaLabel", "Sigma", "kSigmaLabel", "kSigma", "ThresholdLabel", "Threshold" ],
		[ "RadiusLabel", "Radius" ]
	]
	for c in $VBoxContainer/Denoise.get_children():
		c.visible = (HIDE_NODES[index].find(c.name) == -1)

func _on_denoise_value_changed(value):
	force_update = true
