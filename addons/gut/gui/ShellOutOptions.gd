@tool
extends ConfirmationDialog

const RUN_MODE_EDITOR = 'Editor'
const RUN_MODE_BLOCKING = 'Blocking'
const RUN_MODE_NON_BLOCKING = 'NonBlocking'

var GutEditorGlobals = load('res://addons/gut/gui/editor_globals.gd')

@onready var _bad_arg_dialog = $AcceptDialog
@onready var _main_container = $ScrollContainer/VBoxContainer

var _blurb_style_box = StyleBoxEmpty.new()
var _opt_maker_setup = false
var _arg_vbox : VBoxContainer = null
var _my_ok_button : Button = null

# Run mode button stuff
var _run_mode_theme = load('res://addons/gut/gui/EditorRadioButton.tres')
var _button_group = ButtonGroup.new()
var _btn_in_editor : Button = null
var _btn_blocking : Button = null
var _btn_non_blocking : Button = null
var _txt_additional_arguments = null
var _btn_godot_help = null
var _btn_gut_help = null


var opt_maker = null
var default_path = GutEditorGlobals.run_externally_options_path
# I like this.  It holds values loaded/saved which makes for an easy
# reset mechanism.  Hit OK; values get written to this object (not the file
# system).  Hit Cancel; values are reloaded from this object.  Call the
# save/load methods to interact with the file system.
#
# Downside:  If the keys/sections in the config file change, this ends up
#            preserving old data.  So you gotta find a way to clean it out
#            somehow.
# Downside solved:  Clear the config file at the start of the save method.
var _config_file = ConfigFile.new()

var _run_mode = RUN_MODE_EDITOR
var run_mode = _run_mode:
	set(val):
		_run_mode = val
		if(is_inside_tree()):
			_btn_in_editor.button_pressed = _run_mode == RUN_MODE_EDITOR
			if(_btn_in_editor.button_pressed):
				_btn_in_editor.pressed.emit()
			_btn_blocking.button_pressed = _run_mode == RUN_MODE_BLOCKING
			if(_btn_blocking.button_pressed):
				_btn_blocking.pressed.emit()
			_btn_non_blocking.button_pressed = _run_mode == RUN_MODE_NON_BLOCKING
			if(_btn_non_blocking.button_pressed):
				_btn_non_blocking.pressed.emit()
	get():
		return _run_mode


var additional_arguments = '' :
	get():
		if(_opt_maker_setup):
			return opt_maker.controls.additional_arguments.value
		else:
			return additional_arguments


func _debug_ready():
	popup_centered()
	default_path = GutEditorGlobals.temp_directory.path_join('test_external_run_options.cfg')
	exclusive = false

	var save_btn = Button.new()
	save_btn.text = 'save'
	save_btn.pressed.connect(func():
		save_to_file()
		print(_config_file.encode_to_text()))
	save_btn.position = Vector2(100, 20)
	save_btn.size = Vector2(100, 100)
	get_tree().root.add_child(save_btn)

	var load_btn = Button.new()
	load_btn.text = 'load'
	load_btn.pressed.connect(func():
		load_from_file()
		print(_config_file.encode_to_text()))
	load_btn.position = Vector2(100, 130)
	load_btn.size = Vector2(100, 100)
	get_tree().root.add_child(load_btn)

	var show_btn = Button.new()
	show_btn.text = 'Show'
	show_btn.pressed.connect(popup_centered)
	show_btn.position = Vector2(100, 250)
	show_btn.size = Vector2(100, 100)
	get_tree().root.add_child(show_btn)


func _ready():
	opt_maker = GutUtils.OptionMaker.new(_main_container)
	_add_controls()

	if(get_parent() == get_tree().root):
		_debug_ready.call_deferred()

	_my_ok_button = Button.new()
	_my_ok_button.text = 'OK'
	_my_ok_button.pressed.connect(_validate_and_confirm)
	get_ok_button().add_sibling(_my_ok_button)
	get_ok_button().modulate.a = 0.0
	get_ok_button().text = ''
	get_ok_button().disabled = true

	canceled.connect(reset)
	_button_group.pressed.connect(_on_mode_button_pressed)
	run_mode = run_mode


func _validate_and_confirm():
	if(validate_arguments()):
		_save_to_config_file(_config_file)
		confirmed.emit()
		hide()
	else:
		var dlg_text = str("Invalid arguments.  The following cannot be used:\n",
			' '.join(_invalid_args))

		if(run_mode == RUN_MODE_BLOCKING):
			dlg_text += str("\nThese cannot be used with blocking mode:\n",
				' '.join(_invalid_blocking_args))

		_bad_arg_dialog.dialog_text = dlg_text
		_bad_arg_dialog.popup_centered()


func _on_mode_button_pressed(which):
	if(which == _btn_in_editor):
		_arg_vbox.modulate.a = .3
	else:
		_arg_vbox.modulate.a = 1.0

	_txt_additional_arguments.value_ctrl.editable = which != _btn_in_editor
	if(which == _btn_in_editor):
		_run_mode = RUN_MODE_EDITOR
	elif(which == _btn_blocking):
		_run_mode = RUN_MODE_BLOCKING
	elif(which == _btn_non_blocking):
		_run_mode = RUN_MODE_NON_BLOCKING


func _add_run_mode_button(text, desc_label, description):
	var btn = Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.toggle_mode = true
	btn.text = text
	btn.button_group = _button_group
	btn.theme = _run_mode_theme
	btn.pressed.connect(func():  desc_label.text = str('[b]', text, "[/b]\n", description))

	return btn


func _add_blurb(text):
	var ctrl = opt_maker.add_blurb(text)
	ctrl.set("theme_override_styles/normal", _blurb_style_box)
	return ctrl


func _add_title(text):
	var ctrl = opt_maker.add_title(text)
	ctrl.get_child(0).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return ctrl


func _add_controls():
	_add_title("Run Modes")
	_add_blurb(
		"Choose how GUT will launch tests.  Normally you just run them through the editor, but now " +
		"you can run them externally.  This is an experimental feature.  It has been tested on Mac " +
		"and Windows.  Your results may vary.  Feedback welcome at [url]https://github.com/bitwes/Gut/issues[/url].\n ")

	var button_desc_box = HBoxContainer.new()
	var button_box = VBoxContainer.new()
	var button_desc = RichTextLabel.new()
	button_desc.fit_content = true
	button_desc.bbcode_enabled = true
	button_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_main_container.add_child(button_desc_box)
	button_desc_box.add_child(button_box)
	button_desc_box.add_child(button_desc)

	_btn_in_editor = _add_run_mode_button("In Editor (default)", button_desc,
		"This is the default.  Runs through the editor.  When an error occurs " +
		"the debugger is invoked.  [b]print[/b] output " +
		"appears in the Output panel and errors show up in the Debugger panel.")
	button_box.add_child(_btn_in_editor)
	_btn_blocking = _add_run_mode_button("Externally - Blocking", button_desc,
		"Debugger is not enabled, and cannot be enabled.  All output (print, errors, warnings, etc) " +
		"appears in the GUT panel, and [b]not[/b] the Output or Debugger panels.  \n" +
		"The Editor cannot be used while tests are running.  If you are trying to test for errors, this " +
		"mode provides the best output.")
	button_box.add_child(_btn_blocking)
	_btn_non_blocking = _add_run_mode_button("Externally - NonBlocking", button_desc,
		"Debugger is not enabled, and cannot be enabled.  All output (print, errors, warnings, etc) " +
		"appears in the GUT panel, and [b]not[/b] the Output or Debugger panels.  \n" +
		"Test output is streamed to the GUT panel.  The editor is not blocked, but can be less " +
		"responsive when there is a lot of output.  This is the only mode that supports the --headless argument." )
	button_box.add_child(_btn_non_blocking)

	_add_title("Command Line Arguments")
	_arg_vbox = VBoxContainer.new()
	_main_container.add_child(_arg_vbox)
	opt_maker.base_container = _arg_vbox
	_txt_additional_arguments = opt_maker.add_value("additional_arguments", additional_arguments, '', '')
	_txt_additional_arguments.value_ctrl.placeholder_text = "Put your arguments here.  Ex:  --verbose -glog 0"
	_txt_additional_arguments.value_ctrl.select_all_on_focus = false
	_add_blurb(
		"Supply any command line options for GUT and/or Godot when running externally.  You cannot use " +
		"spaces in values.  See the Godot and GUT documentation for valid arguments.  GUT arguments " + 
		"specified here take precedence over your config.")
	_add_blurb("[b]Be Careful[/b]  There are plenty of argument combinations that may make this " +
		"act wrong/odd/bad/horrible.  Some arguments you might [i]want[/i] " +
		"to use but [b]shouldn't[/b] are checked for, but not that many.  Choose your arguments carefully (generally good advice).")

	opt_maker.base_container = _main_container
	_add_title("Display CLI Help")
	_add_blurb("You can use these buttons to get a list of valid GUT and Godot options.  They print the CLI help text for each to the [b]Output Panel[/b].")
	_btn_godot_help = Button.new()
	_btn_godot_help.text = "Print Godot CLI Help"
	_main_container.add_child(_btn_godot_help)
	_btn_godot_help.pressed.connect(func():
		await _show_help("get_godot_help"))

	_btn_gut_help = Button.new()
	_btn_gut_help.text = "Print GUT CLI Help"
	_main_container.add_child(_btn_gut_help)
	_btn_gut_help.pressed.connect(func():
		await _show_help("get_gut_help"))

	_opt_maker_setup = true


func _show_help(help_method_name):
	_btn_godot_help.disabled = true
	_btn_gut_help.disabled = true
	var re = GutUtils.RunExternallyScene.instantiate()
	add_child(re)
	re.visible = false
	var text = await re.call(help_method_name)
	print(text)
	re.queue_free()
	_btn_godot_help.disabled = false
	_btn_gut_help.disabled = false
	if(GutEditorGlobals.gut_plugin != null):
		GutEditorGlobals.gut_plugin.show_output_panel()


func _save_to_config_file(f : ConfigFile):
	f.clear()
	f.set_value('main', 'run_mode', run_mode)
	f.set_value('main', 'additional_arguments', opt_maker.controls.additional_arguments.value)


func save_to_file(path = default_path):
	_save_to_config_file(_config_file)
	_config_file.save(path)


func _load_from_config_file(f):
	run_mode = f.get_value('main', 'run_mode', RUN_MODE_EDITOR)
	opt_maker.controls.additional_arguments.value = \
		f.get_value('main', 'additional_arguments', '')


func load_from_file(path = default_path):
	_config_file.load(path)
	_load_from_config_file(_config_file)


func reset():
	_load_from_config_file(_config_file)


func get_additional_arguments_array():
	return additional_arguments.split(" ", false)


func should_run_externally():
	return run_mode != RUN_MODE_EDITOR


var _invalid_args = [
	'-d', '--debug',
	'-s', '--script',
	'-e', '--editor'
]
var _invalid_blocking_args = [
	'--headless'
]
func validate_arguments():
	var arg_array = get_additional_arguments_array()
	var i = 0
	var invalid_found = false
	while i < _invalid_args.size() and !invalid_found:
		if(arg_array.has(_invalid_args[i])):
			invalid_found = true
		i += 1

	if(run_mode == RUN_MODE_BLOCKING):
		i = 0
		while i < _invalid_blocking_args.size() and !invalid_found:
			if(arg_array.has(_invalid_blocking_args[i])):
				invalid_found = true
			i += 1

	return !invalid_found


func get_godot_help():
	return ''
