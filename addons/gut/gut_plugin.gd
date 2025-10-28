@tool
extends EditorPlugin

var VersionConversion = load("res://addons/gut/version_conversion.gd")
var MenuManager = load("res://addons/gut/gut_menu.gd")
var GutWindow = load("res://addons/gut/gui/GutEditorWindow.tscn")
var BottomPanelScene = preload('res://addons/gut/gui/GutBottomPanel.tscn')
var GutEditorGlobals = load('res://addons/gut/gui/editor_globals.gd')

var _bottom_panel : Control = null
var _menu_mgr = null
var _gut_button = null
var _gut_window = null
var _dock_mode = 'none'


func _init():
	if(VersionConversion.error_if_not_all_classes_imported()):
		return


func _enter_tree():
	if(!_version_conversion()):
		return

	_bottom_panel = BottomPanelScene.instantiate()
	gut_as_panel()

	# ---------
	# I removed this delay because it was causing issues with the shortcut button.
	# The shortcut button wouldn't work right until load_shortcuts is called., but
	# the delay gave you 3 seconds to click it before they were loaded.  This
	# await came with the conversion to 4 and probably isn't needed anymore.
	# I'm leaving it here becuase I don't know why it showed up to begin with
	# and if it's needed, it will be pretty hard to debug without seeing this.
	#
	# This should be deleted after the next release or two if not needed.
	#
	# I added it back in when doing the window stuff.  Starting in a window
	# made it angry (don't remember how) until I added it back in.
	await get_tree().create_timer(1).timeout
	# ---

	_bottom_panel.set_interface(get_editor_interface())
	_bottom_panel.set_plugin(self)
	_bottom_panel.load_shortcuts()

	_menu_mgr = MenuManager.new()
	_bottom_panel._ctrls.run_at_cursor.menu_manager = _menu_mgr
	_bottom_panel.menu_manager = _menu_mgr
	add_tool_submenu_item("GUT", _menu_mgr.sub_menu)

	GutEditorGlobals.gut_plugin = self



func _version_conversion():
	var EditorGlobals = load("res://addons/gut/gui/editor_globals.gd")
	EditorGlobals.create_temp_directory()

	if(VersionConversion.error_if_not_all_classes_imported()):
		return false

	VersionConversion.convert()
	return true


func gut_as_window():
	if(_gut_window == null):
		_gut_window = GutWindow.instantiate()
		_gut_window.gut_plugin = self
		add_child(_gut_window)
		_gut_window.theme = get_tree().root.theme
		_gut_window.interface = get_editor_interface()

	_gut_window.add_gut_panel(_bottom_panel)
	_bottom_panel.make_floating_btn.visible = false
	_gut_button = null
	_dock_mode = 'window'


func gut_as_panel():
	_gut_button = add_control_to_bottom_panel(_bottom_panel, 'GUT')
	_bottom_panel.set_panel_button(_gut_button)
	_gut_button.shortcut_in_tooltip = true
	_dock_mode = 'panel'
	_bottom_panel._apply_shortcuts()
	_bottom_panel.results_horiz_layout()
	_bottom_panel.make_floating_btn.visible = true

	if(_gut_window != null):
		_gut_window.queue_free()
		_gut_window = null


func toggle_windowed():
	_deparent_bottom_panel()
	if(_dock_mode == 'window' or _dock_mode == 'none'):
		gut_as_panel()
	elif(_dock_mode == 'panel'):
		gut_as_window()
	_bottom_panel.show_me()


func _deparent_bottom_panel():
	if(_dock_mode == 'window'):
		_gut_window.remove_panel()
	elif(_dock_mode == 'panel'):
		remove_control_from_bottom_panel(_bottom_panel)



func _exit_tree():
	remove_tool_menu_item("GUT")
	_menu_mgr = null
	GutEditorGlobals.user_prefs.save_it()
	# Clean-up of the plugin goes here
	# Always remember to remove_at it from the engine when deactivated
	_deparent_bottom_panel()
	if(_gut_window != null):
		_gut_window.queue_free()

	_bottom_panel.menu_manager = null
	_bottom_panel.queue_free()

	remove_tool_menu_item("GUT") # made by _menu_mgr


func show_output_panel():
	if(_bottom_panel == null):
		return

	var panel = null
	var kids = _bottom_panel.get_parent().get_children()
	var idx = 0

	while(idx < kids.size() and panel == null):
		if(str(kids[idx]).contains("<EditorLog#")):
			panel = kids[idx]
		idx += 1

	if(panel != null):
		make_bottom_panel_item_visible(panel)