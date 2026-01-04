# ##############################################################################
#
# This holds all the configuratoin values for GUT.  It can load and save values
# to a json file.  It is also responsible for applying these settings to GUT.
#
# ##############################################################################
const FAIL_ERROR_TYPE_ENGINE = &'engine'
const FAIL_ERROR_TYPE_PUSH_ERROR = &'push_error'
const FAIL_ERROR_TYPE_GUT = &'gut'



var valid_fonts = GutUtils.gut_fonts.get_font_names()
var _deprecated_values = {
	"errors_do_not_cause_failure": "Use failure_error_types instead."
}

var default_options = {
	background_color = Color(.15, .15, .15, 1).to_html(),
	config_file = 'res://.gutconfig.json',
	# used by editor to handle enabled/disabled dirs.  All dirs configured go
	# here and only the enabled dirs go into dirs
	configured_dirs = [],
	dirs = [],
	disable_colors = false,
	# double strategy can be the name of the enum value, the enum value or
	# lowercase name with spaces:  0/SCRIPT_ONLY/script only
	# The GUI gut config expects the value to be the enum value and not a string
	# when saved.
	double_strategy = 'SCRIPT_ONLY',
	font_color = Color(.8, .8, .8, 1).to_html(),
	font_name = GutUtils.gut_fonts.DEFAULT_CUSTOM_FONT_NAME,
	font_size = 16,
	hide_orphans = false,
	ignore_pause = false,
	include_subdirs = false,
	inner_class = '',
	junit_xml_file = '',
	junit_xml_timestamp = false,
	log_level = 1,
	opacity = 100,
	paint_after = .1,
	post_run_script = '',
	pre_run_script = '',
	prefix = 'test_',
	selected = '',
	should_exit_on_success = false,
	should_exit = false,
	should_maximize = false,
	compact_mode = false,
	show_help = false,
	suffix = '.gd',
	tests = [],
	unit_test_name = '',

	no_error_tracking = false,
	failure_error_types = ["engine", "gut", "push_error"],
	wait_log_delay = .5,

	gut_on_top = true,
}


var options = default_options.duplicate()
var logger = GutUtils.get_logger()

func _null_copy(h):
	var new_hash = {}
	for key in h:
		new_hash[key] = null
	return new_hash


func _load_options_from_config_file(file_path, into):
	if(!FileAccess.file_exists(file_path)):
		# Default files are ok to be missing.  Maybe this is too deep a place
		# to implement this, but here it is.
		if(file_path != 'res://.gutconfig.json' and file_path != GutUtils.EditorGlobals.editor_run_gut_config_path):
			logger.error(str('Config File "', file_path, '" does not exist.'))
			return -1
		else:
			return 1

	var f = FileAccess.open(file_path, FileAccess.READ)
	if(f == null):
		var result = FileAccess.get_open_error()
		logger.error(str("Could not load data ", file_path, ' ', result))
		return result

	var json = f.get_as_text()
	f = null # close file

	var test_json_conv = JSON.new()
	test_json_conv.parse(json)
	var results = test_json_conv.get_data()
	# SHORTCIRCUIT
	if(results == null):
		logger.error(str("Could not parse file:  ", file_path))
		return -1

	# Get all the options out of the config file using the option name.  The
	# options hash is now the default source of truth for the name of an option.
	_load_dict_into(results, into)

	return 1


func _load_dict_into(source, dest):
	for key in dest:
		if(source.has(key)):
			if(source[key] != null):
				if(typeof(source[key]) == TYPE_DICTIONARY):
					_load_dict_into(source[key], dest[key])
				else:
					dest[key] = source[key]


# Apply all the options specified to tester.  This is where the rubber meets
# the road.
func _apply_options(opts, gut):
	for entry in _deprecated_values.keys():
		if(opts.has(entry)):
			# Use gut.logger instead of our own for testing purposes.
			logger.deprecated(str('Config value "', entry, '" is deprecated.  ', _deprecated_values[entry]))

	gut.include_subdirectories = opts.include_subdirs

	if(opts.inner_class != ''):
		gut.inner_class_name = opts.inner_class
	gut.log_level = opts.log_level
	gut.ignore_pause_before_teardown = opts.ignore_pause

	gut.select_script(opts.selected)

	for i in range(opts.dirs.size()):
		gut.add_directory(opts.dirs[i], opts.prefix, opts.suffix)

	for i in range(opts.tests.size()):
		gut.add_script(opts.tests[i])

	# Sometimes it is the index, sometimes it's a string.  This sets it regardless
	gut.double_strategy = GutUtils.get_enum_value(
		opts.double_strategy, GutUtils.DOUBLE_STRATEGY,
		GutUtils.DOUBLE_STRATEGY.SCRIPT_ONLY)

	gut.unit_test_name = opts.unit_test_name
	gut.pre_run_script = opts.pre_run_script
	gut.post_run_script = opts.post_run_script
	gut.color_output = !opts.disable_colors
	gut.show_orphans(!opts.hide_orphans)
	gut.junit_xml_file = opts.junit_xml_file
	gut.junit_xml_timestamp = opts.junit_xml_timestamp
	gut.paint_after = str(opts.paint_after).to_float()
	gut.wait_log_delay = opts.wait_log_delay

	# These error_tracker options default to true.  Don't trust this comment.
	if(!opts.failure_error_types.has(FAIL_ERROR_TYPE_ENGINE)):
		gut.error_tracker.treat_engine_errors_as = GutUtils.TREAT_AS.NOTHING

	if(!opts.failure_error_types.has(FAIL_ERROR_TYPE_PUSH_ERROR)):
		gut.error_tracker.treat_push_error_as = GutUtils.TREAT_AS.NOTHING

	if(!opts.failure_error_types.has(FAIL_ERROR_TYPE_GUT)):
		gut.error_tracker.treat_gut_errors_as = GutUtils.TREAT_AS.NOTHING

	gut.error_tracker.register_loggers = !opts.no_error_tracking

	return gut


# --------------------------
# Public
# --------------------------
func write_options(path):
	var content = JSON.stringify(options, ' ')

	var f = FileAccess.open(path, FileAccess.WRITE)
	var result = FileAccess.get_open_error()
	if(f != null):
		f.store_string(content)
		f = null # closes file
	else:
		logger.error(str("Could not open file ", path, ' ', result))
	return result


# consistent name
func save_file(path):
	write_options(path)


func load_options(path):
	return _load_options_from_config_file(path, options)


# consistent name
func load_file(path):
	return load_options(path)


func load_options_no_defaults(path):
	options = _null_copy(default_options)
	return _load_options_from_config_file(path, options)


func apply_options(gut):
	_apply_options(options, gut)




# ##############################################################################
# The MIT License (MIT)
# =====================
#
# Copyright (c) 2025 Tom "Butch" Wesley
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# ##############################################################################
