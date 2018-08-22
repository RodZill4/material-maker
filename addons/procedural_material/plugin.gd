tool
extends EditorPlugin

var mm_button = null
var material_maker = null
var edited_object = null

var pt_button = null
var paint_tool = null

func _enter_tree():
	#material_maker = preload("res://addons/procedural_material/pm_material_maker.tscn").instance()
	#add_control_to_bottom_panel(material_maker, "ProceduralMaterial")
	print("Adding menu item")
	mm_button = Button.new()
	mm_button.connect("pressed", self, "open_material_maker")
	mm_button.text = "Material Maker"
	add_control_to_container(CONTAINER_TOOLBAR, mm_button)
	print("done")

func _exit_tree():
	#remove_control_from_bottom_panel(material_maker)
	if mm_button != null:
		remove_control_from_container(CONTAINER_TOOLBAR, mm_button)
		mm_button.queue_free()
	if pt_button != null:
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, pt_button)
		pt_button.queue_free()
		pt_button = null
	if material_maker != null:
		material_maker.hide()
		material_maker.queue_free()
		material_maker = null
	if paint_tool != null:
		paint_tool.hide()
		paint_tool.queue_free()
		paint_tool = null

func _get_state():
	var s = { mm_button=mm_button, material_maker=material_maker }
	return s

func _set_state(s):
	mm_button = s.mm_button
	material_maker = s.material_maker

func open_material_maker():
	if material_maker == null:
		material_maker = load("res://addons/procedural_material/window_dialog.tscn").instance()
		add_child(material_maker)
	material_maker.popup_centered()

func handles(object):
	return object is MeshInstance

func edit(object):
	edited_object = object

func make_visible(b):
	if b:
		pt_button = preload("res://addons/procedural_material/paint_tool/pt_button.tscn").instance()
		pt_button.connect("pressed", self, "paint")
		add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, pt_button)
	else:
		edited_object = null
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, pt_button)
		pt_button.queue_free()
		pt_button = null

func paint():
	paint_tool = preload("res://addons/procedural_material/paint_tool/paint_window.tscn").instance()
	add_child(paint_tool)
	paint_tool.set_object(edited_object)
	paint_tool.connect("popup_hide", self, "free_paint_tool")
	paint_tool.get_node("PaintTool").connect("update_material", self, "assign_material")
	paint_tool.popup_centered()

func free_paint_tool():
	paint_tool.queue_free()
	paint_tool = null
	
func assign_material(m):
	var texture
	var editor_file_system = get_editor_interface().get_resource_filesystem()
	editor_file_system.scan()
	editor_file_system.update_file(m.albedo)
	texture = load(m.albedo)
	m.material.albedo_texture = texture
	editor_file_system.update_file(m.mr)
	texture = load(m.mr)
	m.material.metallic_texture = texture
	m.material.roughness_texture = texture
	editor_file_system.update_file(m.nm)
	texture = load(m.nm)
	m.material.normal_texture = texture
	edited_object.set_surface_material(0, m.material)
