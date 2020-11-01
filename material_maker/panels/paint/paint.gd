extends VBoxContainer

const MODE_FREE         = 0
const MODE_LINE         = 1
const MODE_COLOR_PICKER = 2
const MODE_COUNT        = 3

var current_tool = MODE_FREE

var preview_material = null

var previous_position = null
var painting = false
var next_paint_to = null
var next_pressure = null

var key_rotate = Vector2(0.0, 0.0)

var object_name = null
var project_path = null
var model_path = null

var need_save = false

var brush_node = null

onready var view = $VSplitContainer/Painter/View
onready var main_view = $VSplitContainer/Painter/View/MainView
onready var camera = $VSplitContainer/Painter/View/MainView/CameraStand/Camera
onready var camera_stand = $VSplitContainer/Painter/View/MainView/CameraStand
onready var painted_mesh = $VSplitContainer/Painter/View/MainView/PaintedMesh
onready var painter = $Painter
onready var tools = $VSplitContainer/Painter/Tools
onready var layers = $PaintLayers
onready var brush_obsolete = $VSplitContainer/Painter/Brush
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
	# Disable physics process so we avoid useless updates of tex2view textures
	set_physics_process(false)
	set_current_tool(MODE_FREE)
	get_node("/root/MainWindow").create_menus(MENU, self, $Menu)
	initialize_debug_selects()
	graph_edit.node_factory = get_node("/root/MainWindow/NodeFactory")
	graph_edit.new_material({nodes=[{name="Brush", type="brush"}], connections=[]})
	call_deferred("update_brush")

func update_brush() -> void:
	brush_node = graph_edit.generator.get_node("Brush")
	brush_node.connect("parameter_changed", self, "on_brush_changed")
	painter.set_brush_preview_material($VSplitContainer/Painter/BrushView.material)
	painter.set_brush_node(graph_edit.generator.get_node("Brush"))

func get_graph_edit():
	return graph_edit

func init_project(mesh : Mesh, mesh_path : String, resolution : int):
	layers.set_texture_size(resolution)
	var mi = MeshInstance.new()
	mi.mesh = mesh
	layers.add_layer()
	model_path = mesh_path
	set_object(mi)

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
	preview_material.albedo_texture.flags = Texture.FLAGS_DEFAULT
	preview_material.metallic = 1.0
	preview_material.metallic_texture = layers.get_mr_texture()
	preview_material.metallic_texture.flags = Texture.FLAGS_DEFAULT
	preview_material.metallic_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
	preview_material.roughness = 1.0
	preview_material.roughness_texture = layers.get_mr_texture()
	preview_material.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN
	preview_material.emission_enabled = true
	preview_material.emission = Color(0.0, 0.0, 0.0, 0.0)
	preview_material.emission_texture = layers.get_emission_texture()
	preview_material.emission_texture.flags = Texture.FLAGS_DEFAULT
	preview_material.normal_enabled = true
	preview_material.normal_texture = layers.get_normal_map()
	preview_material.normal_texture.flags = Texture.FLAGS_DEFAULT
	preview_material.depth_enabled = true
	preview_material.depth_deep_parallax = true
	preview_material.depth_texture = layers.get_depth_texture()
	preview_material.depth_texture.flags = Texture.FLAGS_DEFAULT
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
			painter.show_pattern(ev.pressed)
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

var is_pressure_supported : bool = false
var last_pressure : float = 1.0
func get_pressure(event : InputEventMouse) -> float:
	if event is InputEventMouseMotion:
		last_pressure = event.pressure
		if !is_pressure_supported:
			if last_pressure > 0.0:
				is_pressure_supported = true
			else:
				last_pressure = 1.0
	return last_pressure

func _on_View_gui_input(ev : InputEvent):
	if ev is InputEventMouseMotion:
		if current_tool == MODE_COLOR_PICKER:
			show_brush(null, null)
		else:
			if current_tool == MODE_LINE and previous_position != null:
				var direction = ev.position-previous_position
				painter.set_brush_angle(atan2(direction.y, direction.x))
			show_brush(ev.position, previous_position)
		if ev.button_mask & BUTTON_MASK_RIGHT != 0:
			if ev.shift:
				camera_stand.translate(-0.2*ev.relative.x*camera.transform.basis.x)
				camera_stand.translate(0.2*ev.relative.y*camera.transform.basis.y)
			else:
				camera_stand.rotate(camera.global_transform.basis.x.normalized(), -0.01*ev.relative.y)
				camera_stand.rotate(camera.global_transform.basis.y.normalized(), -0.01*ev.relative.x)
		elif ev.button_mask & BUTTON_MASK_LEFT != 0:
			if ev.control:
				previous_position = null
				painter.edit_pattern(ev.relative)
			elif ev.shift:
				previous_position = null
				painter.edit_brush(ev.relative)
			elif current_tool == MODE_FREE:
				paint(ev.position, get_pressure(ev))
			elif ev.relative.length_squared() > 50:
				get_pressure(ev)
		else:
			previous_position = null
	elif ev is InputEventMouseButton:
		var pos = ev.position
		if !ev.control and !ev.shift:
			if ev.button_index == BUTTON_LEFT:
				if ev.pressed:
					previous_position = pos
				elif current_tool == MODE_COLOR_PICKER:
					painter.pick_color(pos)
				else:
					if current_tool == MODE_LINE and previous_position != null:
						var direction = pos-previous_position
						painter.set_brush_angle(atan2(direction.y, direction.x))
					paint(pos, get_pressure(ev))
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


var brush_changed_scheduled : bool = false

func on_brush_changed(p, v) -> void:
	if !brush_changed_scheduled:
		call_deferred("do_on_brush_changed")
		brush_changed_scheduled = true

func do_on_brush_changed():
	painter.set_brush_preview_material($VSplitContainer/Painter/BrushView.material)
	painter.do_on_brush_changed()
	brush_changed_scheduled = false

func edit_brush(v : Vector2) -> void:
	painter.edit_brush(v)

func show_brush(p, op = null):
	if p == null:
		$VSplitContainer/Painter/BrushView.hide()
	else:
		$VSplitContainer/Painter/BrushView.show()
		if op == null:
			op = p
		var brush_preview_rect_size = $VSplitContainer/Painter/BrushView.rect_size
		var position = p/brush_preview_rect_size
		var old_position = op/brush_preview_rect_size
		$VSplitContainer/Painter/BrushView.material.set_shader_param("brush_pos", position)
		$VSplitContainer/Painter/BrushView.material.set_shader_param("brush_ppos", old_position)

func paint(pos, pressure = 1.0):
	if painting:
		# if not available for painting, record a paint order
		next_paint_to = pos
		next_pressure = pressure
		return
	painting = true
	if previous_position == null:
		previous_position = pos
	var position = pos/view.rect_size
	var prev_position = previous_position/view.rect_size
	painter.paint(position, prev_position, eraser_button.pressed, pressure)
	previous_position = pos
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	painting = false
	# execute recorded paint order if any
	if next_paint_to != null:
		pos = next_paint_to
		next_paint_to = null
		paint(pos, next_pressure)

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

func load_project(file_name) -> bool:
	var f : File = File.new()
	if f.open(file_name, File.READ) != OK:
		return false
	var data = parse_json(f.get_as_text())
	var obj_loader = load("res://material_maker/tools/obj_loader/obj_loader.gd").new()
	add_child(obj_loader)
	var mesh : Mesh = obj_loader.load_obj_file(data.model)
	obj_loader.queue_free()
	if mesh == null:
		return false
	model_path = data.model
	var mi = MeshInstance.new()
	mi.mesh = mesh
	mi.set_surface_material(0, SpatialMaterial.new())
	set_object(mi)
	set_project_path(file_name)
	layers.set_texture_size(data.texture_size)
	layers.load(data, file_name)
	return true

func save():
	if project_path != null:
		do_save_project(project_path)
	else:
		save_as()

func save_as():
	show_file_dialog(FileDialog.MODE_SAVE_FILE, "*.mmpp;Model painter project", "do_save_project")

func do_save_project(file_name):
	var data = layers.save(file_name)
	data.model = model_path
	var file = File.new()
	if file.open(file_name, File.WRITE) == OK:
		file.store_string(to_json(data))
		file.close()
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
		for p in [ self, $Painter, $PaintLayers ]:
			for i in p.debug_get_texture_names():
				s.add_item(i, index)
				index += 1

func _on_DebugSelect_item_selected(ID, t):
	var texture = [$VSplitContainer/Painter/Debug/Texture1, $VSplitContainer/Painter/Debug/Texture2][t]
	for p in [ self, $Painter, $PaintLayers ]:
		var textures_count = p.debug_get_texture_names().size()
		if ID < textures_count:
			texture.texture = p.debug_get_texture(ID)
			texture.visible = (texture.texture != null)
			if texture.texture != null:
				print(texture.texture.get_size())
			return
		ID -= textures_count
