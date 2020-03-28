extends MMGraphNodeBase

onready var playback = $AudioStreamPlayer.get_stream_playback()

var samples_played = 0

func _ready():
	set_process(false)

func set_generator(g) -> void:
	.set_generator(g)
	generator.connect("parameter_changed", self, "on_parameter_changed")
	on_parameter_changed(null, null)

func on_parameter_changed(p, v):
	$Timer.start()

func update_shader():
	var src = generator.get_source(0)
	var result = { code="", sound="vec2(0.0)", globals=[] }
	if src != null:
		var context : MMGenContext = MMGenContext.new()
		result = src.generator.get_shader_code("vec3(s2ttime(UV))", src.output_index, context)
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
	var code : String = "shader_type canvas_item;\n"
	code += "render_mode blend_disabled;\n"
	code += "uniform float start_time = 0.0;\n"
	code += "const float buffer_size = 64.0;\n"
	code += "float s2ttime(vec2 uv) {\nreturn start_time+(floor(uv.x*buffer_size)+buffer_size*floor(uv.y*buffer_size))/44100.0;\n}\n"
	#code += "vec4 au2tex(vec2 s) {\nvec2 v = floor((0.5+0.5*s)*65536.0);\nvec2 vl = mod(v, 256.0)/255.0;\nvec2 vh = floor(v/256.0)/255.0;\nreturn vec4(vh.x, vl.x, vh.y, vl.y);\n}\n"
	code += "vec4 au2tex(vec2 s) {\nreturn vec4(s.x, s.y, 0.0, 0.0);\n}\n"
	for g in result.globals:
		code += g
	code += "void fragment() {\n"
	code += result.code;
	code += "COLOR = au2tex("+result.sound+");"
	code += "}"
	$ViewportContainer/Viewport/ColorRect.material.shader.code = code
	samples_played = 0
	$ViewportContainer/Viewport/ColorRect.material.set_shader_param("start_time", 0.0)

func _on_Button_pressed():
	if $AudioStreamPlayer.playing:
		$AudioStreamPlayer.stop()
		set_process(false)
		$Button.text = "Play"
	else:
		update_shader()
		samples_played = 0
		$ViewportContainer/Viewport/ColorRect.material.set_shader_param("start_time", 0.0)
		$AudioStreamPlayer.play()
		set_process(true)
		$Button.text = "Stop"

func _process(delta):
	var image = $ViewportContainer/Viewport.get_texture().get_data()
	var to_fill = min(playback.get_frames_available(), image.data.width*image.data.height)
	var i : int = 0
	image.lock()
	for j in range(to_fill):
		var p = image.get_pixel(j%image.data.width, j/image.data.width)
		var left = p.r
		var right = p.g
		playback.push_frame(Vector2(left, right))
		i += 4
	samples_played += to_fill
	image.unlock()
	$ViewportContainer/Viewport/ColorRect.material.set_shader_param("start_time", samples_played/44100.0)

