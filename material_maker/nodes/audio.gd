extends MMGraphNodeBase

onready var playback = $AudioStreamPlayer.get_stream_playback()
onready var shader_material = $ViewportContainer/Viewport/ColorRect.material

var samples_played : int
var mutex = Mutex.new()

const MIDI_VOICES = 32

func _ready():
	set_process(false)
	OS.open_midi_inputs()
	if OS.get_connected_midi_inputs().empty():
		$Midi.disabled = true
		$Keyboard.visible = false

func set_generator(g) -> void:
	.set_generator(g)
	generator.connect("parameter_changed", self, "on_parameter_changed")
	on_parameter_changed(null, null)

func on_parameter_changed(p, v):
	$Timer.start()

func update_shader():
	var src = generator.get_source(0)
	var result = { code="", defs="", sound="vec2(0.0)", globals=[] }
	if src != null:
		var context : MMGenContext = MMGenContext.new()
		result = src.generator.get_shader_code("t", src.output_index, context)
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
	var code : String = "shader_type canvas_item;\n"
	code += "render_mode blend_disabled;\n"
	code += mm_renderer.common_shader
	code += "uniform float start_time = 0.0;\n"
	code += "const float buffer_size = 64.0;\n"
	code += "float s2ttime(vec2 uv, float t) {\nreturn t+(floor(uv.x*buffer_size)+buffer_size*floor(uv.y*buffer_size))/44100.0;\n}\n"
	#code += "vec4 au2tex(vec2 s) {\nvec2 v = floor((0.5+0.5*s)*65536.0);\nvec2 vl = mod(v, 256.0)/255.0;\nvec2 vh = floor(v/256.0)/255.0;\nreturn vec4(vh.x, vl.x, vh.y, vl.y);\n}\n"
	code += "vec4 au2tex(vec2 s) {\nreturn vec4(s.x, s.y, 1.0, 1.0);\n}\n"
	for g in result.globals:
		code += g
	code += result.defs;
	code += "vec2 sound(vec3 t) {\n"
	code += result.code;
	code += "return "+result.sound+";"
	code += "}"
	if $Midi.pressed:
		for v in range(MIDI_VOICES):
			code += "uniform float voice_"+str(v)+"_velocity = 0.0;\n"
			code += "uniform float voice_"+str(v)+"_time_scale = 1.0;\n"
			code += "uniform float voice_"+str(v)+"_current_time = 0.0;\n"
			code += "uniform float voice_"+str(v)+"_envelope_time = 0.0;\n"
	code += "void fragment() {\n"
	if $Midi.pressed:
		code += "vec2 s = vec2(0.0);\n"
		for v in range(MIDI_VOICES):
			code += "s += voice_"+str(v)+"_velocity*sound(vec3(voice_"+str(v)+"_time_scale*s2ttime(UV, voice_"+str(v)+"_current_time), s2ttime(UV, voice_"+str(v)+"_envelope_time), s2ttime(UV, voice_"+str(v)+"_current_time)));"
		code += "COLOR = au2tex(s);\n"
	else:
		code += "COLOR = au2tex(sound(vec3(s2ttime(UV, start_time))));"
	code += "}"
	shader_material.shader.code = code
	samples_played = 0
	shader_material.set_shader_param("start_time", 0.0)
	if $Midi.pressed:
		shader_material.set_shader_param("envelope_time", 100.0)
	else:
		shader_material.set_shader_param("envelope_time", 1.0)


func on_float_parameters_changed(parameter_changes : Dictionary) -> void:
	for n in parameter_changes.keys():
		for p in VisualServer.shader_get_param_list(shader_material.shader.get_rid()):
			if p.name == n:
				shader_material.set_shader_param(n, parameter_changes[n])
				break

func _on_Button_pressed():
	if $AudioStreamPlayer.playing:
		$AudioStreamPlayer.stop()
		set_process(false)
		$Button.text = "Play"
	else:
		update_shader()
		samples_played = 0
		shader_material.set_shader_param("start_time", 0.0)
		$AudioStreamPlayer.play()
		set_process(true)
		$Button.text = "Stop"

func _on_Midi_toggled(button_pressed):
	$Keyboard.visible = button_pressed
	update_shader()

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
	shader_material.set_shader_param("start_time", samples_played/44100.0)
	var release = 0
	if $Midi.pressed:
		var source = generator.get_source(0)
		if source != null:
			if source.generator.parameters.has("release"):
				release = source.generator.parameters.release
		mutex.lock()
		var notes = $Keyboard.notes.keys()
		for v in notes:
			if $Keyboard.notes[v].has("released") and $Keyboard.notes[v].envelope > 100+release:
				$Keyboard.notes.erase(v)
				$Keyboard.update()
		notes = $Keyboard.notes.keys()
		var note = 0
		for v in notes:
			if !$Keyboard.notes[v].has("current"):
				$Keyboard.notes[v].current = 0
				$Keyboard.notes[v].envelope = 0
			else:
				$Keyboard.notes[v].current += to_fill/44100.0
				$Keyboard.notes[v].envelope += to_fill/44100.0
			if $Keyboard.notes[v].has("released") and $Keyboard.notes[v].envelope == $Keyboard.notes[v].current:
				$Keyboard.notes[v].envelope = 100.0
			shader_material.set_shader_param("voice_"+str(note)+"_velocity", $Keyboard.notes[v].velocity/127.0)
			shader_material.set_shader_param("voice_"+str(note)+"_current_time", $Keyboard.notes[v].current)
			shader_material.set_shader_param("voice_"+str(note)+"_envelope_time", $Keyboard.notes[v].envelope)
			shader_material.set_shader_param("voice_"+str(note)+"_time_scale", pow(1.05946309436, v-69))
			note += 1
		while note < MIDI_VOICES:
			shader_material.set_shader_param("voice_"+str(note)+"_velocity", 0.0)
			note += 1
		mutex.unlock()

func _unhandled_input(event):
	if event is InputEventMIDI and $AudioStreamPlayer.playing and $Midi.pressed:
		mutex.lock()
		$Keyboard.process_midi_event(event)
		mutex.unlock()
