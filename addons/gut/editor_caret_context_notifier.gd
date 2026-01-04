@tool
extends Node
# ##############################################################################
#
# Watches script editors and emits a signal whenever the method, inner class,
# or script changes based on cursor position and other stuff.
#
# Basically, whenever this thing's signal is emitted, then the RunAtCursor
# buttons should be updated to match the data passed to the signal.
# ##############################################################################
# In the editor, whenever a script is opened you get these new things that
# hang off of EditorInterface.get_script_editor()
# 	* ScriptEditorBase
#		* CodeEdit
# ##############################################################################


var _last_info : Dictionary = {}
var _last_line = -1
# This is the control that holds all the individual editors.
var _current_script_editor : ScriptEditor = null
# Reference to the GDScript for the last script we were notified about.
var _current_script = null
var _current_script_is_test_script = false
var _current_editor_base : ScriptEditorBase = null
var _current_editor : CodeEdit = null
# Quick lookup of editors based on the current script.
var _editors_for_scripts : Dictionary= {}


# In order to keep the data that comes back from the emitted signal way more
# usable, we have to know what GUT looks for for an inner-test-class prefix.
# If we didn't do this, then this thing would have to return all the inner
# classes and then we'd have to determine if we were in an inner-test-class
# outside of here by traversing all the classes returned.  It makes this thing
# less generic and know too much, but this is probably already too generic as
# it is.
var inner_class_prefix = "Test"
var method_prefix = "test_"
var script_prefix = "test_"
var script_suffix = ".gd"


# Based on cursor and open editors, this will be emitted.  You do what you
# want with it.
signal it_changed(change_data)


func _ready():
	# This will not change, and should not change, over the course of a session.
	_current_script_editor = EditorInterface.get_script_editor()
	_current_script_editor.editor_script_changed.connect(_on_editor_script_changed)
	_current_script_editor.script_close.connect(_on_editor_script_close)


func _handle_caret_location(which):
	var current_line = which.get_caret_line(0) + 1
	if(_last_line != current_line):
		_last_line = current_line

		if(_current_script_is_test_script):
			var new_info = _make_info(which, _current_script, _current_script_is_test_script)
			if(_last_info != new_info):
				_last_info = new_info
				it_changed.emit(_last_info.duplicate())


func _get_func_name_from_line(text):
	text = text.strip_edges()
	var left = text.split("(")[0]
	var func_name = left.split(" ")[1]
	return func_name


func _get_class_name_from_line(text):
	text = text.strip_edges()
	var right = text.split(" ")[1]
	var the_name = right.rstrip(":")
	return the_name


func _make_info(editor, script, test_script_flag):
	if(editor == null):
		return

	var info = {
		script = script,
		inner_class = null,
		method = null,
		is_test_script = test_script_flag
	}

	var start_line = editor.get_caret_line()
	var line = start_line
	var done_func = false
	var done_inner = false
	while(line > 0 and (!done_func or !done_inner)):
		if(editor.can_fold_line(line)):
			var text = editor.get_line(line)
			var strip_text = text.strip_edges(true, false) # only left

			if(!done_func and strip_text.begins_with("func ")):
				info.method = _get_func_name_from_line(text)
				done_func = true
				# If the func line is left justified then there won't be any
				# inner classes above it.
				if(editor.get_indent_level(line) == 0):
					done_inner = true

			if(!done_inner and strip_text.begins_with("class")):
				var inner_name = _get_class_name_from_line(text)
				# See note about inner_class_prefix, this knows too much, but
				# if it was to know less it would insanely more difficult
				# everywhere.
				if(inner_name.begins_with(inner_class_prefix)):
					info.inner_class = inner_name
					done_inner = true
					done_func = true
		line -= 1

	# print('parsed lines:  ', start_line - line, '(', info.inner_class, ':', info.method, ')')
	return info
# -------------
# Events
# -------------

# Fired whenever the script changes.  This does not fire if you select something
# other than a script from the tree.  So if you click a help file and then
# back to the same file, then this will fire for the same script
#
# This can fire multiple times for the same script when a script is opened.
func _on_editor_script_changed(script):
	_last_line = -1
	_current_script = script
	_current_editor_base = _current_script_editor.get_current_editor()
	if(_current_editor_base.get_base_editor() is CodeEdit):
		_current_editor = _current_editor_base.get_base_editor()
		if(!_current_editor.caret_changed.is_connected(_on_caret_changed)):
			_current_editor.caret_changed.connect(_on_caret_changed.bind(_current_editor))
	else:
		_current_editor = null
	_editors_for_scripts[script] = _current_editor
	_current_script_is_test_script = is_test_script(_current_script)

	_handle_caret_location(_current_editor)


func _on_editor_script_close(script):
	var script_editor = _editors_for_scripts.get(script, null)
	if(script_editor != null):
		if(script_editor.caret_changed.is_connected(_on_caret_changed)):
			script_editor.caret_changed.disconnect(_on_caret_changed)
			_editors_for_scripts.erase(script)


func _on_caret_changed(which):
	# Sometimes this is fired for editors that are not the current.  I could
	# make this fire by saving a file in an external editor.  I was unable to
	# get useful data out when it wasn't the current editor so I'm only doing
	# anything when it is the current editor.
	if(which == _current_editor):
		_handle_caret_location(which)


func _could_be_test_script(script):
	return 	script.resource_path.get_file().begins_with(script_prefix) and \
		script.resource_path.get_file().ends_with(script_suffix)

# -------------
# Public
# -------------
var _scripts_that_have_been_warned_about = []
var _we_have_warned_enough = false
var _max_warnings = 5
func is_test_script(script):
	var base = script.get_base_script()
	if(base == null and script.get_script_method_list().size() == 0 and _could_be_test_script(script)):
		if(OS.is_stdout_verbose() or (!_scripts_that_have_been_warned_about.has(script.resource_path) and !_we_have_warned_enough)):
			_scripts_that_have_been_warned_about.append(script.resource_path)
			push_warning(str('[GUT] Treating ', script.resource_path, " as test script:  ",
				"GUT was not able to retrieve information about this script.  If this is ",
				"a new script you can ignore this warning.  Otherwise, this may ",
				"have to do with having VSCode open.  Restarting Godot sometimes helps.  See ",
				"https://github.com/bitwes/Gut/issues/754"))
			if(!OS.is_stdout_verbose() and _scripts_that_have_been_warned_about.size() >= _max_warnings):
				print("[GUT] Disabling warning.")
				_we_have_warned_enough = true

		# We can't know if this is a test script.  It's more usable if we
		# assume this is a test script.
		return true
	else:
		while(base and base.resource_path != 'res://addons/gut/test.gd'):
			base = base.get_base_script()
		return base != null


func get_info():
	return _last_info.duplicate()


func log_values():
	print("---------------------------------------------------------------")
	print("script                   ", _current_script)
	print("script_editor            ", _current_script_editor)
	print("editor_base              ", _current_editor_base)
	print("editor                   ", _current_editor)
