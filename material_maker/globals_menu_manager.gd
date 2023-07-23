extends Node
class_name MMMenuManager

class MenuBase:
	func clear():
		pass
	
	func connect_id_pressed(_callable : Callable):
		pass
	
	func add_item(_label: String, _id: int = -1, _accel: Key = 0 as Key):
		pass
	
	func add_icon_item(_icon: Texture, _label: String, _id: int = -1, _accel: Key = 0 as Key):
		pass
	
	func add_check_item(_label: String, _id: int = -1, _accel: Key = 0 as Key):
		pass
	
	func add_radio_check_item(_label: String, _id: int = -1, _accel: Key = 0 as Key):
		pass
	
	func add_separator():
		pass
	
	func set_item_disabled(_i : int, _disabled : bool):
		pass
	
	func set_item_checked(_i : int, _checked : bool):
		pass
	
	func add_submenu(_name : String) -> MenuBase:
		return null

class MenuBarBase:
	func create_menus(_menu_def : Array, _object : Object):
		pass


class MenuGodot:
	extends MenuBase
	
	var popup_menu : PopupMenu
	
	func _init(pm : PopupMenu):
		popup_menu = pm
	
	func connect_id_pressed(callable : Callable):
		if ! popup_menu.is_connected("id_pressed", callable):
			popup_menu.connect("id_pressed", callable)
	
	func clear():
		# apply UI scale?
		#popup_menu.content_scale_aspect = mm_globals.main_window.get_viewport().content_scale_aspect
		#popup_menu.content_scale_factor = mm_globals.main_window.get_viewport().content_scale_factor
		#popup_menu.content_scale_mode = mm_globals.main_window.get_viewport().content_scale_mode
		#popup_menu.content_scale_size = Vector2i(0, 0)
		popup_menu.clear()
		while popup_menu.get_child_count() > 0:
			var c : Node = popup_menu.get_child(0)
			popup_menu.remove_child(c)
			c.free()
	
	func add_item(label: String, id: int = -1, accel: Key = 0 as Key):
		popup_menu.add_item(label, id, accel)
	
	func add_icon_item(icon: Texture, label: String, id: int = -1, accel: Key = 0 as Key):
		popup_menu.add_icon_item(icon, label, id, accel)
	
	func add_check_item(label: String, id: int = -1, accel: Key = 0 as Key):
		popup_menu.add_check_item(label, id, accel)
	
	func add_radio_check_item(label: String, id: int = -1, accel: Key = 0 as Key):
		popup_menu.add_radio_check_item(label, id, accel)
	
	func add_separator():
		popup_menu.add_separator()
	
	func set_item_disabled(i : int, disabled : bool):
		popup_menu.set_item_disabled(popup_menu.get_item_index(i), disabled)
	
	func set_item_checked(i : int, checked : bool):
		popup_menu.set_item_checked(popup_menu.get_item_index(i), checked)
	
	func add_submenu(submenu_name : String) -> MenuBase:
		var submenu : PopupMenu
		if popup_menu.has_node(submenu_name):
			submenu = popup_menu.get_node(submenu_name)
		else:
			submenu = PopupMenu.new()
			submenu.name = submenu_name
			popup_menu.add_child(submenu)
		popup_menu.add_submenu_item(submenu_name, submenu.get_name())
		return MenuGodot.new(submenu)

class MenuBarGodot:
	extends MenuBarBase
	
	var menu_bar : Control
	
	func _init(mb : Control):
		menu_bar = mb
	
	func create_menus(menu_def : Array, object : Object):
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
			menu.connect("about_to_popup", Callable(self,"create_menu").bind(menu_def, object, menu, m.name+"/"))
			mm_globals.menu_manager.create_menu(menu_def, object, m.name+"/", MenuGodot.new(menu))

class MenuDisplayServer:
	extends MenuBase
	
	var menu_name : String
	var indexes : Dictionary
	
	func _init(m : String):
		menu_name = m
	
	func clear():
		while DisplayServer.global_menu_get_item_count(menu_name) > 0:
			DisplayServer.global_menu_remove_item(menu_name, 0)
	
	func connect_id_pressed(callable : Callable):
		mm_globals.menu_manager.menu_callables[get_instance_id()] = callable
	
	func add_item(label: String, id: int = -1, accel : Key = 0 as Key):
		if accel & KEY_MASK_CTRL:
			accel = ((accel & ~KEY_MASK_CTRL) | KEY_MASK_META) as Key
		var key = str(get_instance_id())+","+str(id)
		var index : int = DisplayServer.global_menu_add_item(menu_name, label, mm_globals.menu_manager.my_callback, mm_globals.menu_manager.my_callback, key, accel)
		indexes[id] = index
	
	func add_icon_item(_icon: Texture, label: String, id: int = -1, accel: Key = 0 as Key):
		add_item(label, id, accel)
	
	func add_check_item(label: String, id: int = -1, accel : Key = 0 as Key):
		if accel & KEY_MASK_CTRL:
			accel = ((accel & ~KEY_MASK_CTRL) | KEY_MASK_META) as Key
		var key = str(get_instance_id())+","+str(id)
		var index : int = DisplayServer.global_menu_add_check_item(menu_name, label, mm_globals.menu_manager.my_callback, mm_globals.menu_manager.my_callback, key, accel)
		indexes[id] = index
			
	func add_separator():
		DisplayServer.global_menu_add_separator(menu_name)
	
	func set_item_disabled(id : int, disabled : bool):
		if indexes.has(id):
			DisplayServer.global_menu_set_item_disabled(menu_name, indexes[id], disabled)
	
	func set_item_checked(id : int, checked : bool):
		if indexes.has(id):
			DisplayServer.global_menu_set_item_checked(menu_name, indexes[id], checked)
	
	func add_submenu(name : String) -> MenuBase:
		var full_name : String = menu_name+"/"+name
		DisplayServer.global_menu_add_submenu_item(menu_name, name, full_name)
		return MenuDisplayServer.new(full_name)

class MenuBarDisplayServer:
	extends MenuBarBase
	
	func create_menus(menu_def : Array, object : Object):
		DisplayServer.global_menu_clear("_main")
		var menus : Array[String] = []
		for md in menu_def:
			var menu_name : String = md.menu.split("/")[0]
			if menus.find(menu_name) == -1:
				DisplayServer.global_menu_add_submenu_item("_main", menu_name, "_main/"+menu_name)
				menus.append(menu_name)
		for m in menus:
			mm_globals.menu_manager.create_menu(menu_def, object, m+"/", MenuDisplayServer.new("_main/"+m))

func _ready():
	pass

var menu_callables : Dictionary = {}
func my_callback(param):
	var split_param : PackedStringArray = param.split(",")
	var callable : Callable = menu_callables[split_param[0].to_int()]
	callable.call(split_param[1].to_int())

func create_menus(menu_def, object, menu_bar : MenuBarBase) -> void:
	menu_bar.create_menus(menu_def, object)

func create_menu(menu_def : Array, object : Object, menu_name : String, menu : MenuBase) -> MenuBase:
	var mode = ""
	if object.has_method("get_current_mode"):
		mode = object.get_current_mode()
	var submenus = {}
	var menu_name_length = menu_name.length()
	menu.clear()
	menu.connect_id_pressed(mm_globals.menu_manager.on_menu_id_pressed.bind(menu_def, object))
	var last_is_separator : bool = false
	for i in menu_def.size():
		if menu_def[i].has("not_in_ports") and menu_def[i].not_in_ports.find(OS.get_name()) != -1:
			continue
		if menu_def[i].has("not_in_ports") and menu_def[i].not_in_ports.find(OS.get_name()) != -1:
			continue
		if menu_def[i].has("standalone_only") and menu_def[i].standalone_only and Engine.is_editor_hint():
			continue
		if menu_def[i].has("editor_only") and menu_def[i].editor_only and !Engine.is_editor_hint():
			continue
		if menu_def[i].has("mode") and menu_def[i].mode != mode:
			continue
		if ! menu_def[i].menu.begins_with(menu_name):
			continue
		var menu_item_name = menu_def[i].menu.right(-menu_name_length)
		var is_separator = false
		if menu_item_name.find("/") != -1:
			var submenu_name = menu_item_name.split("/")[0]
			if ! submenus.has(submenu_name):
				var submenu : MenuBase = menu.add_submenu(submenu_name)
				create_menu(menu_def, object, menu_name+submenu_name+"/", submenu)
				submenus[submenu_name] = submenu
		elif menu_def[i].has("submenu"):
			#var submenu_name = "submenu_"+menu_def[i].submenu
			var submenu_function = "create_menu_"+menu_def[i].submenu
			#TODO: submenu must be created here
			var submenu : MenuBase = menu.add_submenu(menu_item_name)
			if object.has_method(submenu_function):
				object.call(submenu_function, submenu)
			else:
				create_menu(menu_def, object, menu_def[i].submenu, submenu)
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
						shortcut |= KEY_MASK_CTRL
					elif s == "Shift":
						shortcut |= KEY_MASK_SHIFT
					else:
						shortcut |= OS.find_keycode_from_string(s)
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

func on_menu_about_to_show(menu_def, object, menu_name : String, menu : MenuBase) -> void:
	var mode = ""
	if object.has_method("get_current_mode"):
		mode = object.get_current_mode()
	var name_length : int = menu_name.length()
	for i in menu_def.size():
		if menu_def[i].menu.left(name_length) != menu_name:
			continue
		if menu_def[i].has("submenu"):
			pass
		elif menu_def[i].has("command"):
			var command = menu_def[i].command+"_is_disabled"
			var is_disabled : bool = false
			if menu_def[i].has("mode"):
				is_disabled = menu_def[i].mode != mode
			if object.has_method(command):
				is_disabled = is_disabled or object.call(command)
			menu.set_item_disabled(i, is_disabled)
			if menu_def[i].has("toggle") and menu_def[i].toggle:
				command = menu_def[i].command
				var parameters = []
				if menu_def[i].has("command_parameter"):
					parameters.append(menu_def[i].command_parameter)
				if object.has_method(command):
					menu.set_item_checked(i, object.callv(command, parameters))
