extends Node

var item_types : Array = []
var item_ids : Dictionary = {}

func _ready():
	item_types.clear()
	item_ids.clear()
	create_item_list()

func create_item_list(parent : Node = self):
	for c in parent.get_children():
		if c.get("item_type") == null:
			create_item_list(c)
		else:
			item_ids[c.item_type] = item_types.size()
			item_types.push_back(c)

func get_items_menu(category : String, target : Object, method : String, binds : Array = [], filter : Array = [], parent : Node = self) -> PopupMenu:
	var menu : PopupMenu = PopupMenu.new()
	var sole_submenu : PopupMenu = null
	for c in parent.get_children():
		if c.get("item_type") == null:
			var submenu : PopupMenu = get_items_menu(category, target, method, binds, filter, c)
			if submenu.get_item_count() > 0:
				submenu.name = c.name
				menu.add_child(submenu)
				menu.add_submenu_item(c.name, c.name)
				sole_submenu = submenu
			else:
				submenu.free()
				submenu = null
		elif c.item_category in filter:
			var icon : Texture = c.get("icon")
			if icon != null:
				menu.add_icon_item(icon, c.name, item_ids[c.item_type])
			else:
				menu.add_item(c.name, item_ids[c.item_type])
	menu.connect("id_pressed", target, method, binds)
	if menu.get_item_count() == 1 and sole_submenu != null:
		menu.clear()
		menu.remove_child(sole_submenu)
		menu.free()
		return sole_submenu
	return menu

func get_shape_names() -> Array:
	var names = []
	for c in get_children():
		names.push_back(c.name)
	return names

func get_includes(scene : Dictionary) -> Array:
	if scene.has("hidden") and scene.hidden:
		return []
	var includes : Array = []
	var type = item_types[item_ids[scene.type]]
	if type.has_method("get_includes"):
		for i in type.get_includes():
			if !includes.has(i):
				includes.push_back(i)
	if scene.has("children"):
		for c in scene.children:
			for i in get_includes(c):
				if !includes.has(i):
					includes.push_back(i)
	return includes

func add_parameters(scene : Dictionary, data : Dictionary, parameter_defs : Array):
	pass

func scene_get_type(scene : Dictionary):
	return item_types[item_ids[scene.type]]

func serialize_scene(s : Array) -> Array:
	var serialized = []
	for i in s:
		var new_i = i.duplicate()
		if i.has("children"):
			new_i.children = serialize_scene(i.children)
		if i.has("parameters"):
			new_i.parameters = {}
			for k in i.parameters.keys():
				new_i.parameters[k] = MMType.serialize_value(i.parameters[k])
		serialized.push_back(new_i)
	return serialized

func deserialize_scene(s : Array) -> Array:
	var deserialized = []
	for i in s:
		var new_i = i.duplicate()
		if i.has("children"):
			new_i.children = serialize_scene(i.children)
		if i.has("parameters"):
			new_i.parameters = {}
			for k in i.parameters.keys():
				new_i.parameters[k] = MMType.deserialize_value(i.parameters[k])
		deserialized.push_back(new_i)
	return deserialized

func replace_parameters(scene : Dictionary, string : String) -> String:
	var scene_node = scene_get_type(scene)
	for p in scene_node.get_parameter_defs():
		var new_name = "n%d_%s" % [ scene.index, p.name ]
		string = string.replace("$"+p.name, "$"+new_name)
	return string

func replace_parameter_values(scene : Dictionary, string : String) -> String:
	var scene_node = scene_get_type(scene)
	for p in scene_node.get_parameter_defs():
		var value
		if scene.parameters.has(p.name):
			value = scene.parameters[p.name]
		else:
			value = p.default
		match p.type:
			"boolean":
				string = string.replace("$"+p.name, "true" if value else "false")
			"enum":
				string = string.replace("$"+p.name, p.values[value].value)
			"float":
				string = string.replace("$"+p.name, "%.09f" % value)
			"color":
				string = string.replace("$"+p.name, "vec4(%.09f, %.09f, %.09f, %.09f)" % [ value.r, value.g, value.b, value.a ] )
			_:
				print("Unsupported parameter %s of type %s" % [ p.name, p.type ])
				return "%ERROR%"
	return string

func scene_to_shader_model(scene : Dictionary, uv : String = "$uv", editor : bool = false) -> Dictionary:
	if scene.has("hidden") and scene.hidden:
		return {}
	var scene_node = scene_get_type(scene)
	var shader_model = scene_node.scene_to_shader_model(scene, uv, editor)
	if editor:
		for p in scene_node.get_parameter_defs():
			p = p.duplicate(true)
			if scene.parameters.has(p.name):
				p.default = scene.parameters[p.name]
			var new_name = "n%d_%s" % [ scene.index, p.name ]
			if shader_model.has("code"):
				shader_model.code = replace_parameters(scene, shader_model.code)
			p.name = new_name
			shader_model.parameters.push_back(p)
	else:
		if shader_model.has("code"):
			shader_model.code = replace_parameter_values(scene, shader_model.code)
	if ! shader_model.empty():
		shader_model.includes = get_includes(scene)
	return shader_model

func get_color_code(scene : Dictionary, ctxt : Dictionary = { uv="$uv" }, editor : bool = false):
	if scene.has("hidden") and scene.hidden:
		return ""
	var scene_node = scene_get_type(scene)
	var rv : String = scene_node.get_color_code(scene, ctxt, editor)
	if editor:
		rv = replace_parameters(scene, rv)
	else:
		rv = replace_parameter_values(scene, rv)
	return rv

func generate_rotate_3d(variable, _scene) -> String:
	var rv : String = ""
	rv += "%s.zx = rotate(%s.zx, radians($angle_y));\n" % [ variable, variable ]
	rv += "%s.yz = rotate(%s.yz, radians($angle_x));\n" % [ variable, variable ]
	rv += "%s.xy = rotate(%s.xy, radians($angle_z));\n" % [ variable, variable ]
	return rv
