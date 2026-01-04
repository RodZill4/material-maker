@tool
extends Control

var GutEditorGlobals = load('res://addons/gut/gui/editor_globals.gd')
var GutConfigGui = load('res://addons/gut/gui/gut_config_gui.gd')
var AboutWindow = load("res://addons/gut/gui/about.tscn")

var _interface = null;
var _is_running = false :
	set(val):
		_is_running = val
		_disable_run_buttons(_is_running)

var _gut_config = load('res://addons/gut/gut_config.gd').new()
var _gut_config_gui = null
var _gut_plugin = null
var _light_color = Color(0, 0, 0, .5) :
	set(val):
		_light_color = val
		if(is_inside_tree()):
			_ctrls.light.queue_redraw()
var _panel_button = null
var _user_prefs = null
var _shell_out_panel = null


var menu_manager = null :
	set(val):
		menu_manager = val
		if(val != null):
			_apply_shortcuts()
			menu_manager.toggle_windowed.connect(_on_toggle_windowed)
			menu_manager.about.connect(show_about)
			menu_manager.run_all.connect(_run_all)
			menu_manager.show_gut.connect(_on_show_gut)


@onready var _ctrls = {
	about = %ExtraButtons/About,
	light = %StatusIndicator,
	output_button = %ExtraButtons/OutputBtn,
	run_button = $layout/ControlBar/RunAll,
	run_externally_dialog = $ShellOutOptions,
	run_mode = %ExtraButtons/RunMode,
	run_at_cursor = $layout/ControlBar/RunAtCursor,
	run_results_button = %ExtraButtons/RunResultsBtn,
	settings = $layout/RSplit/sc/Settings,
	settings_button = %ExtraButtons/Settings,
	shortcut_dialog = $ShortcutDialog,
	shortcuts_button = %ExtraButtons/Shortcuts,

	results = {
		bar = $layout/ControlBar2,
		errors = %errors_value,
		failing = %failing_value,
		orphans = %orphans_value,
		passing = %passing_value,
		pending = %pending_value,
		warnings = %warnings_value,
	},
}

@onready var results_v_split = %VSplitResults
@onready var results_h_split = %HSplitResults
@onready var results_tree = %RunResults
@onready var results_text = %OutputText
@onready var make_floating_btn = %MakeFloating


func _ready():
	if(get_parent() is SubViewport):
		return

	GutEditorGlobals.create_temp_directory()

	_user_prefs = GutEditorGlobals.user_prefs
	_gut_config_gui = GutConfigGui.new(_ctrls.settings)

	_ctrls.results.bar.connect('draw', _on_results_bar_draw.bind(_ctrls.results.bar))
	hide_settings(!_ctrls.settings_button.button_pressed)

	_gut_config.load_options(GutEditorGlobals.editor_run_gut_config_path)
	_gut_config_gui.set_options(_gut_config.options)

	_ctrls.shortcuts_button.icon = get_theme_icon('Shortcut', 'EditorIcons')
	_ctrls.settings_button.icon = get_theme_icon('Tools', 'EditorIcons')
	_ctrls.run_results_button.icon = get_theme_icon('AnimationTrackGroup', 'EditorIcons') # Tree
	_ctrls.output_button.icon = get_theme_icon('Font', 'EditorIcons')
	make_floating_btn.icon = get_theme_icon("MakeFloating", 'EditorIcons')
	make_floating_btn.text = ''
	_ctrls.about.icon = get_theme_icon('Info', 'EditorIcons')
	_ctrls.about.text = ''
	_ctrls.run_mode.icon = get_theme_icon("ViewportSpeed", 'EditorIcons')

	results_tree.set_output_control(results_text)

	var check_import = load('res://addons/gut/images/HSplitContainer.svg')
	if(check_import == null):
		results_tree.add_centered_text("GUT got some new images that are not imported yet.  Please restart Godot.")
		print('GUT got some new images that are not imported yet.  Please restart Godot.')
	else:
		results_tree.add_centered_text("Let's run some tests!")

	_ctrls.run_externally_dialog.load_from_file()
	_apply_options_to_controls()

	results_vert_layout()


func _process(_delta):
	if(_is_running):
		if(_ctrls.run_externally_dialog.should_run_externally()):
			if(!is_instance_valid(_shell_out_panel)):
				_is_running = false
				show_me()
		elif(!_interface.is_playing_scene()):
			_is_running = false
			results_text.add_text("\ndone")
			load_result_output()
			show_me()


# ---------------
# Private
# ---------------
func _apply_options_to_controls():
	hide_settings(_user_prefs.hide_settings.value)
	hide_result_tree(_user_prefs.hide_result_tree.value)
	hide_output_text(_user_prefs.hide_output_text.value)
	results_tree.set_show_orphans(!_gut_config.options.hide_orphans)
	var shell_dialog_size = _user_prefs.run_externally_options_dialog_size.value

	if(shell_dialog_size != Vector2i(-1, -1)):
		_ctrls.run_externally_dialog.size = Vector2i(shell_dialog_size)

	if(_user_prefs.shortcuts_dialog_size.value != Vector2i(-1, -1)):
		_ctrls.shortcut_dialog.size = _user_prefs.shortcuts_dialog_size.value

	var mode_ind = 'Ed'
	if(_ctrls.run_externally_dialog.run_mode == _ctrls.run_externally_dialog.RUN_MODE_BLOCKING):
		mode_ind = 'ExB'
	elif(_ctrls.run_externally_dialog.run_mode == _ctrls.run_externally_dialog.RUN_MODE_NON_BLOCKING):
		mode_ind = 'ExN'
	_ctrls.run_mode.text = mode_ind

	_ctrls.run_at_cursor.apply_gut_config(_gut_config)



func _disable_run_buttons(should):
	_ctrls.run_button.disabled = should
	_ctrls.run_at_cursor.disabled = should


func _is_test_script(script):
	var from = script.get_base_script()
	while(from and from.resource_path != 'res://addons/gut/test.gd'):
		from = from.get_base_script()

	return from != null


func _show_errors(errs):
	results_text.clear()
	var text = "Cannot run tests, you have a configuration error:\n"
	for e in errs:
		text += str('*  ', e, "\n")
	text += "Check your settings ----->"
	results_text.add_text(text)
	hide_output_text(false)
	hide_settings(false)


func _save_user_prefs():
	_user_prefs.hide_settings.value = !_ctrls.settings_button.button_pressed
	_user_prefs.hide_result_tree.value = !_ctrls.run_results_button.button_pressed
	_user_prefs.hide_output_text.value = !_ctrls.output_button.button_pressed
	_user_prefs.shortcuts_dialog_size.value = _ctrls.shortcut_dialog.size

	_user_prefs.run_externally.value = _ctrls.run_externally_dialog.run_mode != _ctrls.run_externally_dialog.RUN_MODE_EDITOR
	_user_prefs.run_externally_options_dialog_size.value = _ctrls.run_externally_dialog.size

	_user_prefs.save_it()


func _save_config():
	_save_user_prefs()

	_gut_config.options = _gut_config_gui.get_options(_gut_config.options)
	var w_result = _gut_config.write_options(GutEditorGlobals.editor_run_gut_config_path)
	if(w_result != OK):
		push_error(str('Could not write options to ', GutEditorGlobals.editor_run_gut_config_path, ': ', w_result))
	else:
		_gut_config_gui.mark_saved()


func _run_externally():
	_shell_out_panel = GutUtils.RunExternallyScene.instantiate()
	_shell_out_panel.bottom_panel = self
	_shell_out_panel.blocking_mode = _ctrls.run_externally_dialog.run_mode
	_shell_out_panel.additional_arguments = _ctrls.run_externally_dialog.get_additional_arguments_array()

	add_child(_shell_out_panel)
	_shell_out_panel.run_tests()


func _run_tests():
	show_me()
	if(_is_running):
		push_error("GUT:  Cannot run tests, tests are already running.")
		return

	clear_results()
	GutEditorGlobals.create_temp_directory()
	_light_color = Color.BLUE

	var issues = _gut_config_gui.get_config_issues()
	if(issues.size() > 0):
		_show_errors(issues)
		return

	write_file(GutEditorGlobals.editor_run_bbcode_results_path, 'Run in progress')
	write_file(GutEditorGlobals.editor_run_json_results_path, '')
	_save_config()
	_apply_options_to_controls()

	results_text.clear()
	results_tree.clear()
	results_tree.add_centered_text('Running...')

	_is_running = true
	results_text.add_text('Running...')

	if(_ctrls.run_externally_dialog.should_run_externally()):
		_gut_plugin.make_bottom_panel_item_visible(self)
		_run_externally()
	else:
		_interface.play_custom_scene('res://addons/gut/gui/run_from_editor.tscn')


func _apply_shortcuts():
	if(menu_manager != null):
		menu_manager.apply_gut_shortcuts(_ctrls.shortcut_dialog)

	_ctrls.run_button.shortcut = \
		_ctrls.shortcut_dialog.scbtn_run_all.get_shortcut()
	_ctrls.run_at_cursor.get_script_button().shortcut = \
		_ctrls.shortcut_dialog.scbtn_run_current_script.get_shortcut()
	_ctrls.run_at_cursor.get_inner_button().shortcut = \
		_ctrls.shortcut_dialog.scbtn_run_current_inner.get_shortcut()
	_ctrls.run_at_cursor.get_test_button().shortcut = \
		_ctrls.shortcut_dialog.scbtn_run_current_test.get_shortcut()
	# Took this out because it seems to break using the shortcut when docked.
	# Though it does allow the shortcut to work when windowed.  Shortcuts
	# are weird.
	# make_floating_btn.shortcut = \
	# 	_ctrls.shortcut_dialog.scbtn_windowed.get_shortcut()


	if(_panel_button != null):
		_panel_button.shortcut = _ctrls.shortcut_dialog.scbtn_panel.get_shortcut()


func _run_all():
	_gut_config.options.selected = null
	_gut_config.options.inner_class = null
	_gut_config.options.unit_test_name = null

	_run_tests()


# ---------------
# Events
# ---------------
func _on_results_bar_draw(bar):
	bar.draw_rect(Rect2(Vector2(0, 0), bar.size), Color(0, 0, 0, .2))


func _on_Light_draw():
	var l = _ctrls.light
	l.draw_circle(Vector2(l.size.x / 2, l.size.y / 2), l.size.x / 2, _light_color)


func _on_RunAll_pressed():
	_run_all()


func _on_Shortcuts_pressed():
	_ctrls.shortcut_dialog.popup_centered()


func _on_sortcut_dialog_confirmed() -> void:
	_apply_shortcuts()
	_ctrls.shortcut_dialog.save_shortcuts()
	_save_user_prefs()


func _on_RunAtCursor_run_tests(what):
	_gut_config.options.selected = what.script
	_gut_config.options.inner_class = what.inner_class
	_gut_config.options.unit_test_name = what.method

	_run_tests()


func _on_Settings_pressed():
	hide_settings(!_ctrls.settings_button.button_pressed)
	_save_config()


func _on_OutputBtn_pressed():
	hide_output_text(!_ctrls.output_button.button_pressed)
	_save_config()


func _on_RunResultsBtn_pressed():
	hide_result_tree(! _ctrls.run_results_button.button_pressed)
	_save_config()


# Currently not used, but will be when I figure out how to put
# colors into the text results
func _on_UseColors_pressed():
	pass


func _on_shell_out_options_confirmed() -> void:
	_ctrls.run_externally_dialog.save_to_file()
	_save_user_prefs()
	_apply_options_to_controls()


func _on_run_mode_pressed() -> void:
	_ctrls.run_externally_dialog.popup_centered()


func _on_toggle_windowed():
	_gut_plugin.toggle_windowed()


func _on_to_window_pressed() -> void:
	_gut_plugin.toggle_windowed()


func _on_show_gut() -> void:
	show_hide()


func _on_about_pressed() -> void:
	show_about()

# ---------------
# Public
# ---------------
func load_shortcuts():
	_ctrls.shortcut_dialog.load_shortcuts()
	_apply_shortcuts()


func hide_result_tree(should):
	results_tree.visible = !should
	_ctrls.run_results_button.button_pressed = !should


func hide_settings(should):
	var s_scroll = _ctrls.settings.get_parent()
	s_scroll.visible = !should

	# collapse only collapses the first control, so we move
	# settings around to be the collapsed one
	if(should):
		s_scroll.get_parent().move_child(s_scroll, 0)
	else:
		s_scroll.get_parent().move_child(s_scroll, 1)

	$layout/RSplit.collapsed = should
	_ctrls.settings_button.button_pressed = !should


func hide_output_text(should):
	results_text.visible = !should
	_ctrls.output_button.button_pressed = !should


func clear_results():
	_light_color = Color(0, 0, 0, .5)

	_ctrls.results.passing.text = "0"
	_ctrls.results.passing.get_parent().visible = false

	_ctrls.results.failing.text = "0"
	_ctrls.results.failing.get_parent().visible = false

	_ctrls.results.pending.text = "0"
	_ctrls.results.pending.get_parent().visible = false

	_ctrls.results.errors.text = "0"
	_ctrls.results.errors.get_parent().visible = false

	_ctrls.results.warnings.text = "0"
	_ctrls.results.warnings.get_parent().visible = false

	_ctrls.results.orphans.text = "0"
	_ctrls.results.orphans.get_parent().visible = false


func load_result_json():
	var summary = get_file_as_text(GutEditorGlobals.editor_run_json_results_path)
	var test_json_conv = JSON.new()
	if (test_json_conv.parse(summary) != OK):
		return
	var results = test_json_conv.get_data()

	results_tree.load_json_results(results)

	var summary_json = results['test_scripts']['props']
	_ctrls.results.passing.text = str(int(summary_json.passing))
	_ctrls.results.passing.get_parent().visible = true

	_ctrls.results.failing.text = str(int(summary_json.failures))
	_ctrls.results.failing.get_parent().visible = true

	_ctrls.results.pending.text = str(int(summary_json.pending) + int(summary_json.risky))
	_ctrls.results.pending.get_parent().visible = _ctrls.results.pending.text != '0'

	_ctrls.results.errors.text = str(int(summary_json.errors))
	_ctrls.results.errors.get_parent().visible = _ctrls.results.errors.text != '0'

	_ctrls.results.warnings.text = str(int(summary_json.warnings))
	_ctrls.results.warnings.get_parent().visible = _ctrls.results.warnings.text != '0'

	_ctrls.results.orphans.text = str(int(summary_json.orphans))
	_ctrls.results.orphans.get_parent().visible = _ctrls.results.orphans.text != '0' and !_gut_config.options.hide_orphans

	if(summary_json.tests == 0):
		_light_color = Color(1, 0, 0, .75)
	elif(summary_json.failures != 0):
		_light_color = Color(1, 0, 0, .75)
	elif(summary_json.pending != 0 or summary_json.risky != 0):
		_light_color = Color(1, 1, 0, .75)
	else:
		_light_color = Color(0, 1, 0, .75)

	_ctrls.light.visible = true


func load_result_text():
	results_text.load_file(GutEditorGlobals.editor_run_bbcode_results_path)


func load_result_output():
	load_result_text()
	load_result_json()


func set_interface(value):
	_interface = value
	results_tree.set_interface(_interface)


func set_plugin(value):
	_gut_plugin = value


func set_panel_button(value):
	_panel_button = value


func write_file(path, content):
	var f = FileAccess.open(path, FileAccess.WRITE)
	if(f != null):
		f.store_string(content)
	f = null;

	return FileAccess.get_open_error()


func get_file_as_text(path):
	var to_return = ''
	var f = FileAccess.open(path, FileAccess.READ)
	if(f != null):
		to_return = f.get_as_text()
	f = null
	return to_return


func get_text_output_control():
	return results_text


func add_output_text(text):
	results_text.add_text(text)


func show_about():
	var about = AboutWindow.instantiate()
	add_child(about)
	about.popup_centered()
	about.confirmed.connect(about.queue_free)


func show_me():
	if(owner is Window):
		owner.grab_focus()
	else:
		_gut_plugin.make_bottom_panel_item_visible(self)


func show_hide():
	if(owner is Window):
		if(owner.has_focus()):
			var win_to_focus_on = EditorInterface.get_editor_main_screen().get_parent()
			while(win_to_focus_on != null and win_to_focus_on is not Window):
				win_to_focus_on = win_to_focus_on.get_parent()
			if(win_to_focus_on != null):
				win_to_focus_on.grab_focus()
		else:
			owner.grab_focus()
	else:
		pass
		# We don't have to do anything when we are docked because the GUT
		# bottom panel has the shortcut and it does the toggling all on its
		# own.


func get_shortcut_dialog():
	return _ctrls.shortcut_dialog


func results_vert_layout():
	if(results_tree.get_parent() != results_v_split):
		results_tree.reparent(results_v_split)
		results_text.reparent(results_v_split)
		results_v_split.visible = true
		results_h_split.visible = false


func results_horiz_layout():
	if(results_tree.get_parent() != results_h_split):
		results_tree.reparent(results_h_split)
		results_text.reparent(results_h_split)
		results_v_split.visible = false
		results_h_split.visible = true
