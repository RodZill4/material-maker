extends VBoxContainer

const MODE_FREE         = 0
const MODE_LINE         = 1
const MODE_LINE_STRIP   = 2
const MODE_COLOR_PICKER = 3
const MODE_COUNT        = 4

var current_tool = MODE_FREE

var preview_material = null

var previous_position = null
var painting = false
var next_paint_to = null

var key_rotate = Vector2(0.0, 0.0)

var object_name = null
var project_path = null

var need_save = false

var brush_node = null

onready var view = $VSplitContainer/Painter/View
onready var main_view = $VSplitContainer/Painter/View/MainView
onready var camera = $VSplitContainer/Painter/View/MainView/CameraStand/Camera
onready var camera_stand = $VSplitContainer/Painter/View/MainView/CameraStand
onready var painted_mesh = $VSplitContainer/Painter/View/MainView/PaintedMesh
onready var painter = $Painter
onready var tools = $VSplitContainer/Painter/Tools
onready var layers = $VSplitContainer/Painter/Layers
onready var brush = $VSplitContainer/Painter/Brush
onready var eraser_button = $VSplitContainer/Painter/Tools/Eraser
onready var graph_edit = $VSplitContainer/GraphEdit

signal update_material

const MENU = [
	{ menu="File", command="load_project", shortcut="Control+O", description="Load project" },
	{ menu="File", command="save_project", shortcut="Control+S", description="Save project" },
	{ menu="File", command="save_project_as", shortcut="Control+Shift+S", description="Save project as..." },
	{ menu="File" },
	{ menu="File", command="export_material", shortcut="Control+E", description="Export textures" },
	{ menu="Material", command="toggle_material_feature", description="Emission", command_parameter="emission_enabled" },
	{ menu="Material", command="toggle_material_feature", description="Normal", command_parameter="normal_enabled" },
	{ menu="Material", command="toggle_material_feature", description="Depth", command_parameter="depth_enabled" },
	{ menu="Material/TextureSize", command="set_texture_size", description="256x256", command_parameter=256  },
	{ menu="Material/TextureSize", command="set_texture_size", description="512x512", command_parameter=512  },
	{ menu="Material/TextureSize", command="set_texture_size", description="1024x1024", command_parameter=1024  },
	{ menu="Material/TextureSize", command="set_texture_size", description="2048x2048", command_parameter=2048  },
]

func _ready():
	# Assign all textures to painted mesh
	painted_mesh.set_surface_material(0, SpatialMaterial.new())
	# Updated Texture2View wrt current camera position
	update_view()
	# Set size of painted textures
	layers.set_texture_size(2048)
	# Disable physics process so we avoid useless updates of tex2view textures
	set_physics_process(false)
	set_current_tool(MODE_FREE)
	get_node("/root/MainWindow").create_menus(MENU, self, $Menu)
	initialize_debug_selects()
	graph_edit.node_factory = get_node("/root/MainWindow/NodeFactory")
	graph_edit.new_material({nodes=[{name="Brush", type="brush"}], connections=[]})
	brush.set_brush_node(graph_edit.generator.get_node("Brush"))

func get_graph_edit():
	return graph_edit

func set_object(o):
	object_name = o.name
	project_path = null
	var mat = o.get_surface_material(0)
	if mat == null:
		mat = o.mesh.surface_get_material(0)
	if mat == null:
		mat = SpatialMaterial.new()
	for t in [ "albedo_texture", "metallic_texture", "roughness_texture" ]:
		if mat[t] != null:
			var size = mat[t].get_size()
			if size.x == size.y:
				layers.set_texture_size(size.x)
				break
	preview_material = SpatialMaterial.new()
	preview_material.albedo_texture = layers.get_albedo_texture()
	preview_material.metallic = 1.0
	preview_material.metallic_texture = layers.get_mr_texture()
	preview_material.metallic_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
	preview_material.roughness = 1.0
	preview_material.roughness_texture = layers.get_mr_texture()
	preview_material.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN
	preview_material.emission_enabled = true
	preview_material.emission = Color(0.0, 0.0, 0.0, 0.0)
	preview_material.emission_texture = layers.get_emission_texture()
	preview_material.normal_enabled = true
	preview_material.normal_texture = layers.get_normal_map()
	preview_material.depth_enabled = true
	preview_material.depth_deep_parallax = true
	preview_material.depth_texture = layers.get_depth_texture()
	painted_mesh.mesh = o.mesh
	painted_mesh.set_surface_material(0, preview_material)
	painter.set_mesh(o.mesh)
	update_view()
	painter.init_textures(mat)

func toggle_material_feature(variable):
	preview_material[variable] = !preview_material[variable]
	
func toggle_material_feature_is_checked(variable):
	return preview_material[variable]

func set_texture_size(s):
	layers.set_texture_size(s)

func set_texture_size_is_checked(s):
	return s == layers.texture_size

func set_current_tool(m):
	current_tool = m
	for i in range(MODE_COUNT):
		tools.get_child(i).pressed = (i == m)

func _physics_process(delta):
	camera_stand.rotate(camera.global_transform.basis.x.normalized(), -key_rotate.y*delta)
	camera_stand.rotate(Vector3(0, 1, 0), -key_rotate.x*delta)
	update_view()

func __input(ev : InputEvent):
	if ev is InputEventKey:
		if ev.scancode == KEY_CONTROL:
			brush.show_pattern(ev.pressed)
			accept_event()
		elif ev.scancode == KEY_LEFT or ev.scancode == KEY_RIGHT or ev.scancode == KEY_UP or ev.scancode == KEY_DOWN:
			var new_key_rotate = Vector2(0.0, 0.0)
			if Input.is_key_pressed(KEY_UP):
				key_rotate.y -= 1.0
			if Input.is_key_pressed(KEY_DOWN):
				key_rotate.y += 1.0
			if Input.is_key_pressed(KEY_LEFT):
				key_rotate.x -= 1.0
			if Input.is_key_pressed(KEY_RIGHT):
				key_rotate.x += 1.0
			if new_key_rotate != key_rotate:
				key_rotate = new_key_rotate
				set_physics_process(key_rotate != Vector2(0.0, 0.0))
				accept_event()

func _on_View_gui_input(ev : InputEvent):
	if ev is InputEventMouseMotion:
		if current_tool == MODE_COLOR_PICKER:
			brush.show_brush(null, null)
		else:
			brush.show_brush(ev.position, previous_position)
		if ev.button_mask & BUTTON_MASK_RIGHT != 0:
			if ev.shift:
				camera_stand.translate(-0.2*ev.relative.x*camera.transform.basis.x)
				camera_stand.translate(0.2*ev.relative.y*camera.transform.basis.y)
			else:
				camera_stand.rotate(camera.global_transform.basis.x.normalized(), -0.01*ev.relative.y)
				camera_stand.rotate(camera.global_transform.basis.y.normalized(), -0.01*ev.relative.x)
		if ev.button_mask & BUTTON_MASK_LEFT != 0:
			if ev.control:
				previous_position = null
				brush.edit_pattern(ev.relative)
			elif ev.shift:
				previous_position = null
				brush.edit_brush(ev.relative)
			elif current_tool == MODE_FREE:
				paint(ev.position)
		elif current_tool != MODE_LINE_STRIP:
			previous_position = null
	elif ev is InputEventMouseButton:
		var pos = ev.position
		if !ev.control and !ev.shift:
			if ev.button_index == BUTTON_LEFT:
				if ev.pressed:
					if current_tool == MODE_LINE_STRIP && previous_position != null:
						paint(pos)
						if ev.doubleclick:
							pos = null
					previous_position = pos
				elif current_tool == MODE_COLOR_PICKER:
					painter.pick_color(pos)
				elif current_tool != MODE_LINE_STRIP:
					paint(pos)
					previous_position = null
		if !ev.pressed and ev.button_index == BUTTON_RIGHT:
			update_view()
		# Mouse wheel
		var zoom = 0.0
		if ev.button_index == BUTTON_WHEEL_UP:
			zoom -= 1.0
		elif ev.button_index == BUTTON_WHEEL_DOWN:
			zoom += 1.0
		if zoom != 0.0:
			camera.translate(Vector3(0.0, 0.0, zoom*(1.0 if ev.shift else 0.1)))
			update_view()
			accept_event()
	else:
		__input(ev)

func paint(p):
	if painting:
		# if not available for painting, record a paint order
		next_paint_to = p
		return
	painting = true
	if previous_position == null:
		previous_position = p
	var position = p/view.rect_size
	var prev_position = previous_position/view.rect_size
	painter.paint(position, prev_position, eraser_button.pressed)
	previous_position = p
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	painting = false
	# execute recorded paint order if any
	if next_paint_to != null:
		p = next_paint_to
		next_paint_to = null
		paint(p)

func update_view():
	var mesh_instance = painted_mesh
	var mesh_aabb = mesh_instance.get_aabb()
	var mesh_center = mesh_aabb.position+0.5*mesh_aabb.size
	var mesh_size = 0.5*mesh_aabb.size.length()
	var cam_to_center = (camera.global_transform.origin-mesh_center).length()
	camera.near = max(0.2, 0.5*(cam_to_center-mesh_size))
	camera.far = 2.0*(cam_to_center+mesh_size)
	var transform = camera.global_transform.affine_inverse()*painted_mesh.global_transform
	if painter != null:
		painter.update_view(camera, transform, main_view.size)

func _on_resized():
	call_deferred("update_view")

func dump_texture(texture, filename):
	var image = texture.get_data()
	image.save_png(filename)

func show_file_dialog(mode, filter, callback):
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = mode
	dialog.add_filter(filter)
	dialog.connect("file_selected", self, callback)
	dialog.popup_centered()

func set_project_path(p):
	project_path = p
	var parent = get_parent()
	if parent.has_method("set_project_path"):
		parent.set_project_path(p)

func load_project():
	show_file_dialog(FileDialog.MODE_OPEN_FILE, "*.masp;Material Spray project", "do_load_project")

func do_load_project(file_name):
	layers.load(file_name)
	set_project_path(file_name)

func save_project():
	if project_path != null:
		do_save_project(project_path)
	else:
		save_project_as()

func save_project_as():
	show_file_dialog(FileDialog.MODE_SAVE_FILE, "*.masp;Material Spray project", "do_save_project")

func do_save_project(file_name):
	layers.save(file_name)
	set_project_path(file_name)

func export_material():
	show_file_dialog(FileDialog.MODE_SAVE_FILE, "*.tres;Spatial material", "do_export_material")

func do_export_material(file_name):
	var prefix = file_name.replace(".tres", "")
	var mat = painted_mesh.get_surface_material(0).duplicate()
	var desc = { material=mat, material_file=file_name }
	dump_texture(layers.get_albedo_texture(), prefix+"_albedo.png")
	desc.albedo = prefix+"_albedo.png"
	dump_texture(layers.get_mr_texture(), prefix+"_mr.png")
	desc.mr = prefix+"_mr.png"
	if mat.emission_enabled:
		dump_texture(layers.get_emission_texture(), prefix+"_emission.png")
		desc.emission = prefix+"_emission.png"
	if mat.normal_enabled:
		dump_texture(layers.get_normal_map(), prefix+"_nm.png")
		desc.nm = prefix+"_nm.png"
	if mat.depth_enabled:
		dump_texture(layers.get_depth_texture(), prefix+"_depth.png")
		desc.depth = prefix+"_depth.png"
	emit_signal("update_material", desc)

# debug

func debug_get_texture_names():
	return [ "None" ]

func debug_get_texture(ID):
	return null

func initialize_debug_selects():
	for s in [ $VSplitContainer/Painter/Debug/Select1, $VSplitContainer/Painter/Debug/Select2 ]:
		s.clear()
		var index = 0
		for p in [ self, $Painter, $VSplitContainer/Painter/Layers ]:
			for i in p.debug_get_texture_names():
				s.add_item(i, index)
				index += 1

func _on_DebugSelect_item_selected(ID, t):
	var texture = [$VSplitContainer/Painter/Debug/Texture1, $VSplitContainer/Painter/Debug/Texture2][t]
	for p in [ self, $Painter, $VSplitContainer/Painter/Layers ]:
		var textures_count = p.debug_get_texture_names().size()
		if ID < textures_count:
			texture.texture = p.debug_get_texture(ID)
			texture.visible = (texture.texture != null)
			if texture.texture != null:
				print(texture.texture.get_size())
			return
		ID -= textures_count
