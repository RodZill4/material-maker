extends Node

var theme_overrides = {}
var library_manager = null

func create_node(generator : MMGenBase) -> Node:
	var model = generator.get_template_name() if generator.is_template() else ""
	var type : String = generator.get_type()
	var node_type = null
	var node = null
	var file_name = "res://material_maker/nodes/"+model+"/"+model+".tscn"
	if ! ResourceLoader.exists(file_name):
		file_name = "res://material_maker/nodes/"+type+"/"+type+".tscn"
	if ResourceLoader.exists(file_name):
		node_type = load(file_name)
	if node_type != null:
		node = node_type.instantiate()
	if node == null:
		node = preload("res://material_maker/nodes/generic/generic.tscn").instantiate()
	set_theme_overrides(node, generator)
	return node

func set_theme_overrides(node, generator : MMGenBase = null) -> void:
	var theme : Theme = mm_globals.main_window.theme
	if node.theme != null && node.theme != theme:
		return
	if generator == null:
		generator = node.generator
	if library_manager == null:
		library_manager = get_node("/root/MainWindow/NodeLibraryManager")
		if library_manager == null:
			return
	var node_title = generator.get_template_name()
	if ! mm_loader.predefined_generators.has(node_title) or ! library_manager.node_sections.has(node_title):
		node_title = generator.get_type_name()
	if ! library_manager.node_sections.has(node_title):
		node_title = generator.get_type()
	if library_manager.node_sections.has(node_title):
		var section = library_manager.node_sections[node_title]
		if ! theme_overrides.has(section):
			theme_overrides[section] = {}
			var color = library_manager.get_section_color(section)
			if color != null:
				for s in [ "titlebar", "titlebar_selected" ]:
					var frame : StyleBoxFlat = theme.get_stylebox(s, "GraphNode").duplicate(true) as StyleBoxFlat
					color.a = frame.bg_color.a
					frame.bg_color = color
					theme_overrides[section][s] = frame
		for s in theme_overrides[section].keys():
			node.add_theme_stylebox_override(s, theme_overrides[section][s])

func on_theme_changed():
	theme_overrides = {}
	for n in get_tree().get_nodes_in_group("generator_node"):
		set_theme_overrides(n)
