extends Window


@export_multiline var shader : String = "" # (String, MULTILINE)


var generator
var output : int

@onready var value_size = $VBox/Settings/Size
@onready var value_begin = $VBox/Settings/Begin
@onready var value_end = $VBox/Settings/End
@onready var value_images = $VBox/Settings/Images
@onready var value_spritesheet : OptionButton = $VBox/Settings/Spritesheet

@onready var image_begin = $VBox/Images/HBox/Begin/SubViewport/Image
@onready var image_end = $VBox/Images/HBox/End/SubViewport/Image
@onready var image_diff = $VBox/Images/HBox/Animated/Diff
@onready var image_anim = $VBox/Images/HBox/Animated
@onready var buffer_images : Array = [ image_begin, image_end, image_anim ]

@onready var animation_player = $VBox/Images/HBox/Animated/AnimationPlayer
@onready var timer = $VBox/Images/HBox/Animated/Timer


const BUFFER_NAMES = [ "export_animation_buffer_begin", "export_animation_buffer_end", "export_animation_buffer_anim" ]


func _ready():
	size = $VBox.get_combined_minimum_size()
	for i in range(BUFFER_NAMES.size()):
		mm_deps.create_buffer(BUFFER_NAMES[i], self)

func set_source(g, o):
	generator = g
	output = o
	var context : MMGenContext = MMGenContext.new()
	var source = generator.get_shader_code("uv", output, context)
	if source.output_type == "":
		source = MMGenBase.get_default_generated_shader()
	var code = MMGenBase.generate_preview_shader(source, source.output_type, shader)
	var ends_code = code;
	ends_code = ends_code.replace("varying float elapsed_time;", "uniform float elapsed_time;");
	ends_code = ends_code.replace("elapsed_time = TIME;", "");
	image_begin.material.shader.code = ends_code
	image_end.material.shader.code = ends_code
	var anim_code = code;
	anim_code = anim_code.replace("varying float elapsed_time;", "uniform float begin;\nuniform float end;\nvarying float elapsed_time;");
	anim_code = anim_code.replace("elapsed_time = TIME;", "elapsed_time = (begin == end) ? begin : begin+sign(end-begin)*mod(TIME, abs(end-begin));");
	image_anim.material.shader.code = anim_code
	for u in source.uniforms:
		image_begin.material.set_shader_parameter(u.name, u.value)
		image_anim.material.set_shader_parameter(u.name, u.value)
		image_end.material.set_shader_parameter(u.name, u.value)
	for image_index in range(BUFFER_NAMES.size()):
		var i = buffer_images[image_index]
		var b : String = BUFFER_NAMES[image_index]
		# Get parameter values from the shader code
		mm_deps.buffer_create_shader_material(b, MMShaderMaterial.new(i.material), i.material.shader.code)
	var begin : float = value_begin.value
	var end : float = value_end.value
	image_begin.material.set_shader_parameter("elapsed_time", begin)
	image_end.material.set_shader_parameter("elapsed_time", end)
	image_anim.material.set_shader_parameter("begin", begin)
	image_anim.material.set_shader_parameter("end", end)

func show_diff():
	if ! animation_player.is_playing() and ! image_diff.visible:
		animation_player.play("show")
	timer.stop()
	timer.start(0)

func _on_Begin_value_changed(value):
	image_begin.material.set_shader_parameter("elapsed_time", value)
	image_anim.material.set_shader_parameter("begin", value)
	show_diff()

func _on_End_value_changed(value):
	image_end.material.set_shader_parameter("elapsed_time", value)
	image_anim.material.set_shader_parameter("end", value)
	show_diff()

func _on_Timer_timeout():
	animation_player.play_backwards("show")


func _on_Export_pressed():
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.png;PNG image files")
	add_child(dialog)
	var files = await dialog.select_files()
	if files.size() > 0:
		var filename : String = files[0]
		var size : int = 1 << value_size.size_value
		var begin : float = value_begin.value
		var end : float = value_end.value
		var images : int = value_images.value
		var spritesheet_lines : int = value_spritesheet.get_item_id(value_spritesheet.selected) 
		if spritesheet_lines > 500:
			spritesheet_lines = 1000-spritesheet_lines
		var spritesheet_columns : int
		var renderer = await mm_renderer.request(self)
		image_anim.material.set_shader_parameter("begin", begin)
		image_anim.material.set_shader_parameter("end", begin)
		var spritesheet : Image
		var filename_fmt
		if spritesheet_lines != 0:
			if spritesheet_lines > 0:
				spritesheet_columns = (images-1)/spritesheet_lines+1
			else:
				spritesheet_columns = -spritesheet_lines
				spritesheet_lines = (images-1)/spritesheet_columns+1
			spritesheet = Image.create(size * spritesheet_columns, size * spritesheet_lines, false, Image.FORMAT_RGBA8)
		else:
			var regex : RegEx = RegEx.new()
			regex.compile("#+")
			var regex_match : Array = regex.search_all(filename)
			if regex_match.size() > 1:
				renderer.release(self)
				return
			elif regex_match.size() == 1:
				filename_fmt = filename.replace(regex_match[0].strings[0], "%0"+str(regex_match[0].strings[0].length())+"d")
			else:
				filename_fmt = filename.get_basename()+"_%d."+filename.get_extension()
		for i in range(0, images):
			var time : float = begin+(end-begin)*float(i)/float(images)
			image_anim.material.set_shader_parameter("begin", time)
			image_anim.material.set_shader_parameter("end", time)
			renderer = await renderer.render_material(self, image_anim.material, size, false)
			if spritesheet_lines > 0:
				var image : Image = renderer.get_image()
				spritesheet.blit_rect(image, Rect2(0, 0, size, size), Vector2(size*(i%spritesheet_columns), size*(i/spritesheet_columns)))
			else:
				renderer.save_to_file(filename_fmt % (i+1))
		renderer.release(self)
		if spritesheet_lines > 0:
			spritesheet.save_png(filename)
		image_anim.material.set_shader_parameter("begin", begin)
		image_anim.material.set_shader_parameter("end", end)
		image_anim.material.set_shader_parameter("mm_chunk_size", 1.0)
		image_anim.material.set_shader_parameter("mm_chunk_offset", Vector2(0.0, 0.0))


func _on_VBox_minimum_size_changed():
	size = $VBox.size+Vector2(4, 4)
