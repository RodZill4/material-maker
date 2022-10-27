extends WindowDialog

export(String, MULTILINE) var shader : String = ""

var generator
var output : int

onready var value_size = $VBox/Settings/Size
onready var value_begin = $VBox/Settings/Begin
onready var value_end = $VBox/Settings/End
onready var value_images = $VBox/Settings/Images
onready var value_spritesheet : OptionButton = $VBox/Settings/Spritesheet

onready var image_begin = $VBox/Images/HBox/Begin/Viewport/Image
onready var image_end = $VBox/Images/HBox/End/Viewport/Image
onready var image_diff = $VBox/Images/HBox/Animated/Diff
onready var image_anim = $VBox/Images/HBox/Animated

onready var animation_player = $VBox/Images/HBox/Animated/AnimationPlayer
onready var timer = $VBox/Images/HBox/Animated/Timer

func _ready():
	pass # Replace with function body.

func set_source(g, o):
	generator = g
	output = o
	var context : MMGenContext = MMGenContext.new()
	var source = generator.get_shader_code("uv", output, context)
	assert(!(source is GDScriptFunctionState))
	if source.empty():
		source = MMGenBase.DEFAULT_GENERATED_SHADER
	var code = MMGenBase.generate_preview_shader(source, source.type, shader)
	var ends_code = code;
	ends_code = ends_code.replace("varying float elapsed_time;", "uniform float elapsed_time;");
	ends_code = ends_code.replace("elapsed_time = TIME;", "");
	image_begin.material.shader.code = ends_code
	image_end.material.shader.code = ends_code
	var anim_code = code;
	anim_code = anim_code.replace("varying float elapsed_time;", "uniform float begin;\nuniform float end;\nvarying float elapsed_time;");
	anim_code = anim_code.replace("elapsed_time = TIME;", "elapsed_time = (begin == end) ? begin : begin+sign(end-begin)*mod(TIME, abs(end-begin));");
	image_anim.material.shader.code = anim_code
	for i in [ image_begin, image_anim, image_end ]:
		# Get parameter values from the shader code
		MMGenBase.define_shader_float_parameters(i.material.shader.code, i.material)
		# Set texture params
		if source.has("textures"):
			for k in source.textures.keys():
				i.material.set_shader_param(k, source.textures[k])
	var begin : float = value_begin.value
	var end : float = value_end.value
	image_begin.material.set_shader_param("elapsed_time", begin)
	image_end.material.set_shader_param("elapsed_time", end)
	image_anim.material.set_shader_param("begin", begin)
	image_anim.material.set_shader_param("end", end)

func show_diff():
	if ! animation_player.is_playing() and ! image_diff.visible:
		animation_player.play("show")
	timer.stop()
	timer.start(0)

func _on_Begin_value_changed(value):
	image_begin.material.set_shader_param("elapsed_time", value)
	image_anim.material.set_shader_param("begin", value)
	show_diff()

func _on_End_value_changed(value):
	image_end.material.set_shader_param("elapsed_time", value)
	image_anim.material.set_shader_param("end", value)
	show_diff()

func _on_Timer_timeout():
	animation_player.play_backwards("show")


func _on_Export_pressed():
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.png;PNG image files")
	add_child(dialog)
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
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
		var renderer = mm_renderer.request(self)
		while renderer is GDScriptFunctionState:
			renderer = yield(renderer, "completed")
		image_anim.material.set_shader_param("begin", begin)
		image_anim.material.set_shader_param("end", begin)
		var spritesheet : Image
		var filename_fmt
		if spritesheet_lines != 0:
			if spritesheet_lines > 0:
				spritesheet_columns = (images-1)/spritesheet_lines+1
			else:
				spritesheet_columns = -spritesheet_lines
				spritesheet_lines = (images-1)/spritesheet_columns+1
			spritesheet = Image.new()
			spritesheet.create(size * spritesheet_columns, size * spritesheet_lines, false, Image.FORMAT_RGBA8)
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
			image_anim.material.set_shader_param("begin", time)
			image_anim.material.set_shader_param("end", time)
			renderer = renderer.render_material(self, image_anim.material, size, false)
			while renderer is GDScriptFunctionState:
				renderer = yield(renderer, "completed")
			if spritesheet_lines > 0:
				var image : Image = renderer.get_image()
				spritesheet.blit_rect(image, Rect2(0, 0, size, size), Vector2(size*(i%spritesheet_columns), size*(i/spritesheet_columns)))
			else:
				renderer.save_to_file(filename_fmt % (i+1))
		renderer.release(self)
		if spritesheet_lines > 0:
			spritesheet.save_png(filename)
		image_anim.material.set_shader_param("begin", begin)
		image_anim.material.set_shader_param("end", end)
		image_anim.material.set_shader_param("mm_chunk_size", 1.0)
		image_anim.material.set_shader_param("mm_chunk_offset", Vector2(0.0, 0.0))


func _on_VBox_minimum_size_changed():
	rect_size = $VBox.rect_size+Vector2(4, 4)
