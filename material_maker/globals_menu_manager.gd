extends Node

func _ready():
	pass

func create_menus(menu_def, object, menu_bar) -> void:
	for md in menu_def:
		var menu_name : String = md.menu.split("/")[0]
		if ! menu_bar.has_node(menu_name):
			var menu_button = MenuButton.new()
			menu_button.name = menu_name
			menu_button.text = menu_name
			menu_button.switch_on_hover = true
			menu_bar.add_child(menu_button)
	for m in menu_bar.get_children():
		if ! m is MenuButton:
			continue
		var menu = m.get_popup()
		menu.connect("about_to_show", self, "create_menu", [ menu_def, object, menu, m.name+"/" ])
		create_menu(menu_def, object, menu, m.name+"/")

func create_menu(menu_def : Array, object : Object, menu : PopupMenu, menu_name : String) -> PopupMenu:
	var mode = ""
	if object.has_method("get_current_mode"):
		mode = object.get_current_mode()
	var is_mac : bool = OS.get_name() == "OSX"
	var submenus = {}
	var menu_name_length = menu_name.length()
	menu.clear()
	if !menu.is_connected("id_pressed", self, "on_menu_id_pressed"):
		menu.connect("id_pressed", self, "on_menu_id_pressed", [ menu_def, object ])
	var last_is_separator : bool = false
	for i in menu_def.size():
		if menu_def[i].has("not_in_ports") and menu_def[i].not_in_ports.find(OS.get_name()) != -1:
			continue
		if menu_def[i].has("not_in_ports") and menu_def[i].not_in_ports.find(OS.get_name()) != -1:
			continue
		if menu_def[i].has("standalone_only") and menu_def[i].standalone_only and Engine.editor_hint:
			continue
		if menu_def[i].has("editor_only") and menu_def[i].editor_only and !Engine.editor_hint:
			continue
		if menu_def[i].has("mode") and menu_def[i].mode != mode:
			continue
		if ! menu_def[i].menu.begins_with(menu_name):
			continue
		var menu_item_name = menu_def[i].menu.right(menu_name_length)
		var is_separator = false
		if menu_item_name.find("/") != -1:
			var submenu_name = menu_item_name.split("/")[0]
			if ! submenus.has(submenu_name):
				var submenu : PopupMenu
				if menu.has_node(submenu_name):
					submenu = menu.get_node(submenu_name)
				else:
					submenu = PopupMenu.new()
					submenu.name = submenu_name
					menu.add_child(submenu)
				create_menu(menu_def, object, submenu, menu_name+submenu_name+"/")
				menu.add_submenu_item(submenu_name, submenu.get_name())
				submenus[submenu_name] = submenu
		elif menu_def[i].has("submenu"):
			var submenu_name = "submenu_"+menu_def[i].submenu
			if ! menu.has_node(submenu_name):
				var submenu = PopupMenu.new()
				submenu.name = submenu_name
				var submenu_function = "create_menu_"+menu_def[i].submenu
				if object.has_method(submenu_function):
					submenu.connect("about_to_show", object, submenu_function, [ submenu ]);
				else:
					submenu.connect("about_to_show", self, "create_menu", [ menu_def, object, submenu, menu_def[i].submenu ])
				menu.add_child(submenu)
			menu.add_submenu_item(menu_item_name, submenu_name)
		elif menu_item_name == "" or menu_item_name == "-":
			if !last_is_separator:
				menu.add_separator()
			is_separator = true
		else:
			var shortcut = 0
			if menu_def[i].has("shortcut"):
				for s in menu_def[i].shortcut.split("+"):
					if s == "Alt":
						shortcut |= KEY_MASK_ALT
					elif s == "Control":
						shortcut |= KEY_MASK_CMD if is_mac else KEY_MASK_CTRL
					elif s == "Shift":
						shortcut |= KEY_MASK_SHIFT
					else:
						shortcut |= OS.find_scancode_from_string(s)
			if menu_def[i].has("toggle") and menu_def[i].toggle:
				menu.add_check_item(menu_item_name, i, shortcut)
			else:
				menu.add_item(menu_item_name, i, shortcut)
		last_is_separator = is_separator
	if last_is_separator:
		menu.remove_item(menu.get_item_count()-1)
	on_menu_about_to_show(menu_def, object, menu_name, menu)
	return menu

func on_menu_id_pressed(id, menu_def, object) -> void:
	if menu_def[id].has("command"):
		var command = menu_def[id].command
		if object.has_method(command):
			var parameters = []
			if menu_def[id].has("command_parameter"):
				parameters.append(menu_def[id].command_parameter)
			if menu_def[id].has("toggle") and menu_def[id].toggle:
				parameters.append(!object.callv(command, parameters))
			object.callv(command, parameters)

func on_menu_about_to_show(menu_def, object, name : String, menu : PopupMenu) -> void:
	var mode = ""
	if object.has_method("get_current_mode"):
		mode = object.get_current_mode()
	var name_length : int = name.length()
	for i in menu_def.size():
		if menu_def[i].menu.left(name_length) != name:
			continue
		if menu_def[i].has("submenu"):
			pass
		elif menu_def[i].has("command"):
			var item : int = menu.get_item_index(i)
			var command = menu_def[i].command+"_is_disabled"
			if object.has_method(command):
				var is_disabled = object.call(command)
				menu.set_item_disabled(item, is_disabled)
			if menu_def[i].has("mode"):
				menu.set_item_disabled(item, menu_def[i].mode != mode)
			if menu_def[i].has("toggle") and menu_def[i].toggle:
				command = menu_def[i].command
				var parameters = []
				if menu_def[i].has("command_parameter"):
					parameters.append(menu_def[i].command_parameter)
				if object.has_method(command):
					menu.set_item_checked(item, object.callv(command, parameters))
