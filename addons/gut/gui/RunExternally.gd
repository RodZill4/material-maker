@tool
extends Control

# I'm probably going to put this back in later and I don't want to create it
# again.  Yeah, yeah, yeah.
# class DotsAnimator:
# 	var text = ''
# 	var dot = '.'
# 	var max_dots = 3
# 	var dot_delay = .5

# 	var _anim_text = ''
# 	var _elapsed_time = 0.0
# 	var _cur_dots = 0

# 	func get_animated_text():
# 		return _anim_text

# 	func add_time(delta):
# 		_elapsed_time += delta
# 		if(_elapsed_time > dot_delay):
# 			_elapsed_time = 0
# 			_cur_dots += 1
# 			if(_cur_dots > max_dots):
# 				_cur_dots = 0

# 			_anim_text = text.rpad(text.length() + _cur_dots, dot)


var GutEditorGlobals = load('res://addons/gut/gui/editor_globals.gd')

@onready var btn_kill_it = $BgControl/VBox/Kill
@onready var bg_control = $BgControl

var _pipe_results = {}
var _debug_mode = false
var _std_thread : Thread
var _escape_regex : RegEx = RegEx.new()
var _text_buffer = ''

var bottom_panel = null :
	set(val):
		bottom_panel = val
		bottom_panel.resized.connect(_on_bottom_panel_resized)
var blocking_mode = "Blocking"
var additional_arguments = []
var remove_escape_characters = true
@export var bg_color = Color.WHITE:
	set(val):
		bg_color = val
		if(is_inside_tree()):
			bg_control.get("theme_override_styles/panel").bg_color = bg_color


func _debug_ready():
	_debug_mode = true
	additional_arguments = ['-gselect', 'test_awaiter.gd', '-gconfig', 'res://.gutconfig.json'] # '-gunit_test_name', 'test_can_clear_spies'
	blocking_mode = "NonBlocking"
	run_tests()


func _ready():
	_escape_regex.compile("\\x1b\\[[0-9;]*m")
	btn_kill_it.visible = false

	if(get_parent() == get_tree().root):
		_debug_ready.call_deferred()
	bg_color = bg_color


func _process(_delta: float) -> void:
	if(_pipe_results != {}):
		if(!OS.is_process_running(_pipe_results.pid)):
			_end_non_blocking()


# ----------
# Private
# ----------
func _center_me():
	position = get_parent().size / 2.0 - size / 2.0


func _output_text(text, should_scroll = true):
	if(_debug_mode):
		print(text)
	else:
		if(remove_escape_characters):
			text = _escape_regex.sub(text, '', true)

		if(bottom_panel != null):
			bottom_panel.add_output_text(text)
			if(should_scroll):
				_scroll_output_pane(-1)
		else:
			_text_buffer += text


func _scroll_output_pane(line):
	if(!_debug_mode and bottom_panel != null):
		var txt_ctrl = bottom_panel.get_text_output_control().get_rich_text_edit()
		if(line == -1):
			line = txt_ctrl.get_line_count()
		txt_ctrl.scroll_vertical = line


func _add_arguments_to_output():
	if(additional_arguments.size() != 0):
		_output_text(
			str("Run Mode arguments: ", ' '.join(additional_arguments), "\n\n")
		)


func _load_json():
	if(_debug_mode):
		pass # could load file and print it if we want.
	elif(bottom_panel != null):
		bottom_panel.load_result_json()


func _run_blocking(options):
	btn_kill_it.visible = false
	var output = []
	await get_tree().create_timer(.1).timeout

	OS.execute(OS.get_executable_path(), options, output, true)

	_output_text(output[0])
	_add_arguments_to_output()
	_scroll_output_pane(-1)

	_load_json()
	queue_free()


func _read_non_blocking_stdio():
	while(OS.is_process_running(_pipe_results.pid)):
		while(_pipe_results.stderr.get_length() > 0):
			_output_text(_pipe_results.stderr.get_line() + "\n")

		while(_pipe_results.stdio.get_length() > 0):
			_output_text(_pipe_results.stdio.get_line() + "\n")

		# without this, things start to lock up.
		await get_tree().process_frame


func _run_non_blocking(options):
	_pipe_results = OS.execute_with_pipe(OS.get_executable_path(), options, false)
	_std_thread = Thread.new()
	_std_thread.start(_read_non_blocking_stdio)
	btn_kill_it.visible = true


func _end_non_blocking():
	_add_arguments_to_output()
	_scroll_output_pane(-1)

	_load_json()

	_pipe_results = {}
	_std_thread.wait_to_finish()
	_std_thread = null
	queue_free()
	if(_debug_mode):
		get_tree().quit()



# ----------------
# Events
# ----------------
func _on_kill_pressed() -> void:
	if(_pipe_results != {} and OS.is_process_running(_pipe_results.pid)):
		OS.kill(_pipe_results.pid)
		btn_kill_it.visible = false


func _on_color_rect_gui_input(event: InputEvent) -> void:
	if(event is InputEventMouseMotion):
		if(event.button_mask == MOUSE_BUTTON_MASK_LEFT):
			position += event.relative


func _on_bottom_panel_resized():
	_center_me()


# ----------------
# Public
# ----------------
func run_tests():
	_center_me()

	var options = ["-s", "res://addons/gut/gut_cmdln.gd", "-graie", "-gdisable_colors",
		"-gconfig", GutEditorGlobals.editor_run_gut_config_path]
	options.append_array(additional_arguments)

	if(blocking_mode == 'Blocking'):
		_run_blocking(options)
	else:
		_run_non_blocking(options)


func get_godot_help():
	_text_buffer = ''
	var options = ["--help", "--headless"]
	await _run_blocking(options)
	return _text_buffer


func get_gut_help():
	_text_buffer = ''
	var options = ["-s", "res://addons/gut/gut_cmdln.gd", "-gh", "--headless"]
	await _run_blocking(options)
	return _text_buffer
