class GutEditorPref:
	var gut_pref_prefix = 'gut/'
	var pname = '__not_set__'
	var default = null
	var value = '__not_set__'
	var _settings = null

	func _init(n, d, s):
		pname = n
		default = d
		_settings = s
		load_it()

	func _prefstr():
		var to_return = str(gut_pref_prefix, pname)
		return to_return

	func save_it():
		_settings.set_setting(_prefstr(), value)

	func load_it():
		if(_settings.has_setting(_prefstr())):
			value = _settings.get_setting(_prefstr())
		else:
			value = default

	func erase():
		_settings.erase(_prefstr())


const EMPTY = '-- NOT_SET --'

# -- Editor ONLY Settings --
var output_font_name = null
var output_font_size = null
var hide_result_tree = null
var hide_output_text = null
var hide_settings = null
var use_colors = null	# ? might be output panel
var run_externally = null
var run_externally_options_dialog_size = null
var shortcuts_dialog_size = null
var gut_window_size = null
var gut_window_on_top = null


func _init(editor_settings):
	output_font_name = GutEditorPref.new('output_font_name', 'CourierPrime', editor_settings)
	output_font_size = GutEditorPref.new('output_font_size', 30, editor_settings)
	hide_result_tree = GutEditorPref.new('hide_result_tree', false, editor_settings)
	hide_output_text = GutEditorPref.new('hide_output_text', false, editor_settings)
	hide_settings = GutEditorPref.new('hide_settings', false, editor_settings)
	use_colors = GutEditorPref.new('use_colors', true, editor_settings)
	run_externally = GutEditorPref.new('run_externally', false, editor_settings)
	run_externally_options_dialog_size = GutEditorPref.new('run_externally_options_dialog_size', Vector2i(-1, -1), editor_settings)
	shortcuts_dialog_size = GutEditorPref.new('shortcuts_dialog_size', Vector2i(-1, -1), editor_settings)
	gut_window_size = GutEditorPref.new('editor_window_size', Vector2i(-1, -1), editor_settings)
	gut_window_on_top = GutEditorPref.new('editor_window_on_top', false, editor_settings)


func save_it():
	for prop in get_property_list():
		var val = get(prop.name)
		if(val is GutEditorPref):
			val.save_it()


func load_it():
	for prop in get_property_list():
		var val = get(prop.name)
		if(val is GutEditorPref):
			val.load_it()


func erase_all():
	for prop in get_property_list():
		var val = get(prop.name)
		if(val is GutEditorPref):
			val.erase()
