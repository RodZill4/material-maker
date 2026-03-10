var sub_menu : PopupMenu = null

var _menus = {
	# name : {
	# 	index,
	# 	id,
	# 	callback
	# }
}

signal about
signal rerun
signal run_all
signal run_at_cursor
signal run_inner_class
signal run_script
signal run_test
signal show_gut
signal toggle_windowed


func _init():
	sub_menu = PopupMenu.new()
	sub_menu.index_pressed.connect(_on_sub_menu_index_pressed)
	make_menu()


func _invalid_index():
	print("bad menu index")


func _on_sub_menu_index_pressed(index):
	var to_call : Callable = _invalid_index
	for key in _menus:
		if(_menus[key].index == index):
			to_call = _menus[key].callback

	to_call.call()


func add_menu(display_text, sig_to_emit, tooltip=''):
	var index = sub_menu.item_count
	_menus[sig_to_emit.get_name()] = {
		index = index,
		id = index,
		callback = sig_to_emit.emit
	}
	sub_menu.add_item(display_text, index)
	sub_menu.set_item_tooltip(index, tooltip)
	return index



func make_menu():
	add_menu("Toggle Windowed", toggle_windowed, 
		'Toggle GUT in the dock or a floating window')
	add_menu("Show/Hide GUT", show_gut, '')

	sub_menu.add_separator('Run')
	add_menu("Run All", run_all,
		"Run all tests")
	add_menu("Run Script", run_script,
		"Run the currently selected script")
	add_menu("Run Inner Class", run_inner_class,
		"Run the currently selected inner test class")
	add_menu("Run Test", run_test,
		"Run the currently selected test")
	add_menu("Run At Cursor", run_at_cursor,
		"Run the most specific of script/inner class/test based on cursor position")
	add_menu("Rerun", rerun, "Rerun the last test(s) ran", )

	sub_menu.add_separator()
	add_menu("About", about, 'All about GUT')


func set_shortcut(menu_name, accel_or_input_key):
	if(typeof(accel_or_input_key) == TYPE_INT):
		sub_menu.set_item_accelerator(_menus[menu_name].index, accel_or_input_key)
	elif(typeof(accel_or_input_key) == TYPE_OBJECT and accel_or_input_key is InputEventKey):
		sub_menu.set_item_accelerator(_menus[menu_name].index, accel_or_input_key.get_keycode_with_modifiers())


func disable_menu(menu_name, disabled):
	sub_menu.set_item_disabled(_menus[menu_name].index, disabled)


func apply_gut_shortcuts(shortcut_dialog):
	set_shortcut("show_gut",
		shortcut_dialog.scbtn_panel.get_input_event())
	set_shortcut("run_all",
		shortcut_dialog.scbtn_run_all.get_input_event())
	set_shortcut("run_script",
		shortcut_dialog.scbtn_run_current_script.get_input_event())
	set_shortcut("run_inner_class",
		shortcut_dialog.scbtn_run_current_inner.get_input_event())
	set_shortcut("run_test",
		shortcut_dialog.scbtn_run_current_test.get_input_event())
	set_shortcut("run_at_cursor",
		shortcut_dialog.scbtn_run_at_cursor.get_input_event())
	set_shortcut("rerun",
		shortcut_dialog.scbtn_rerun.get_input_event())
	set_shortcut("toggle_windowed",
		shortcut_dialog.scbtn_windowed.get_input_event())
