extends VBoxContainer

const MODE_FREEHAND_DOTS = 0
const MODE_FREEHAND_LINE = 1
const MODE_LINE          = 2
const MODE_FILL          = 3
const MODE_COLOR_PICKER  = 4
const MODE_COUNT         = 5
const MODE_NAMES : Array = [ "FreeDots", "FreeLine", "Line", "Fill", "ColorPicker" ]

var current_tool = MODE_FREEHAND_DOTS

var preview_material = null

var previous_position = null
var painting = false

var key_rotate = Vector2(0.0, 0.0)

var object_name = null
var model_path = null

var save_path = null
var need_save = false

var brush_graph = null
var brush_node = null
var remote_node = null

var brush_size : float = 50.0
var brush_hardness : float = 0.5
var pattern_scale : float = 10.0
var pattern_angle : float = 0.0

onready var view = $VSplitContainer/Painter/View
onready var main_view = $VSplitContainer/Painter/View/MainView
onready var camera : Camera = $VSplitContainer/Painter/View/MainView/CameraPosition/CameraRotation1/CameraRotation2/Camera
onready var camera_position = $VSplitContainer/Painter/View/MainView/CameraPosition
onready var camera_rotation1 = $VSplitContainer/Painter/View/MainView/CameraPosition/CameraRotation1
onready var camera_rotation2 = $VSplitContainer/Painter/View/MainView/CameraPosition/CameraRotation1/CameraRotation2
onready var painted_mesh = $VSplitContainer/Painter/View/MainView/PaintedMesh
onready var painter = $Painter
onready var tools = $VSplitContainer/Painter/Tools
onready var layers = $PaintLayers
onready var eraser_button = $VSplitContainer/Painter/Tools/Eraser
onready var graph_edit = $VSplitContainer/GraphEdit

onready var brush_size_control : Control = $VSplitContainer/Painter/Options/Grid/BrushSize
onready var brush_hardness_control : Control = $VSplitContainer/Painter/Options/Grid/BrushStrength
onready var brush_opacity_control : Control = $VSplitContainer/Painter/Options/Grid/BrushOpacity
onready var brush_spacing_control : Control = $VSplitContainer/Painter/Options/Grid/BrushSpacing

var last_motion_position : Vector2
var last_motion_vector : Vector2 = Vector2(0, 0)
var stroke_length : float = 0.0
var stroke_angle : float = 0.0


const Layer = preload("res://material_maker/panels/paint/layer_types/layer.gd")


signal update_material


func _ready():
	# Assign all textures to painted mesh
	painted_mesh.set_surface_material(0, SpatialMaterial.new())
	# Updated Texture2View wrt current camera position
	update_view()
	# Disable physics process so we avoid useless updates of tex2view textures
	set_physics_process(false)
	set_current_tool(MODE_FREEHAND_DOTS)
	initialize_debug_selects()
	graph_edit.node_factory = get_node("/root/MainWindow/NodeFactory")
	graph_edit.new_material({nodes=[{name="Brush", type="brush"}], connections=[]})
	update_brush_graph()
	call_deferred("update_brush")
	set_environment(0)

func update_tab_title() -> void:
	if !get_parent().has_method("set_tab_title"):
		#print("no set_tab_title method")
		return
	var title = "[unnamed]"
	if save_path != null:
		title = save_path.right(save_path.rfind("/")+1)
	if need_save:
		title += " *"
	if get_parent().has_method("set_tab_title"):
		get_parent().set_tab_title(get_index(), title)

func set_project_path(p):
	save_path = p
	update_tab_title()

func set_need_save(b : bool = true) -> void:
	if need_save != b:
		need_save = b
		update_tab_title()

func get_project_type() -> String:
	return "paint"

func get_remote():
	for c in graph_edit.top_generator.get_children():
		if c.get_type() == "remote":
			return c
	return null

func update_brush_graph():
	if brush_graph != graph_edit.top_generator:
		brush_graph = graph_edit.top_generator
		brush_graph.connect("graph_changed", self, "on_brush_graph_changed")
		on_brush_graph_changed()

func on_brush_graph_changed() -> void:
	var new_remote = get_remote()
	if new_remote != remote_node:
		remote_node = new_remote
		get_node("/root/MainWindow").get_panel("Parameters").set_generator(remote_node)

# called when the project's tab is selected
func project_selected() -> void:
	var main_window = get_node("/root/MainWindow")
	main_window.get_panel("Layers").set_layers($PaintLayers)
	remote_node = get_remote()
	main_window.get_panel("Parameters").set_generator(remote_node)

func update_brush() -> void:
	brush_node = graph_edit.generator.get_node("Brush")
	brush_node.connect("parameter_changed", self, "on_brush_changed")
	painter.set_brush_preview_material($VSplitContainer/Painter/BrushView.material)
	painter.set_brush_node(graph_edit.generator.get_node("Brush"))

func set_brush(data) -> void:
	var parameters_panel = get_node("/root/MainWindow").get_panel("Parameters")
	parameters_panel.set_generator(null)
	graph_edit.new_material(data)
	update_brush()
	update_brush_graph()

func get_brush_preview() -> Texture:
	var preview = get_tree().get_root().get_node("BrushPreviewGenerator")
	if preview == null:
		print("Create preview")
		preview = load("res://material_maker/tools/painter/brush_preview.tscn").instance()
		preview.name = "BrushPreviewGenerator"
		get_tree().get_root().add_child(preview)
	var status = preview.set_brush(graph_edit.generator.get_node("Brush"))
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	return status

func get_graph_edit():
	return graph_edit

func init_project(mesh : Mesh, mesh_file_path : String, resolution : int, project_file_path : String):
	layers.set_texture_size(resolution)
	var mi = MeshInstance.new()
	mi.mesh = mesh
	layers.add_layer()
	model_path = mesh_file_path
	set_object(mi)
	set_project_path(project_file_path)

func set_object(o):
	object_name = o.name
	set_project_path(null)
	var mat = o.get_surface_material(0)
	if mat == null:
		mat = o.mesh.surface_get_material(0)
	if mat == null:
		mat = SpatialMaterial.new()
	"""
	for t in [ "albedo_texture", "metallic_texture", "roughness_texture" ]:
		if mat[t] != null:
			var size = mat[t].get_size()
			if size.x == size.y:
				layers.set_texture_size(size.x)
				break
	"""
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

func check_material_feature(variable : String, value : bool) -> void:
	preview_material[variable] = value
	
func material_feature_is_checked(variable : String) -> bool:
	return preview_material[variable]

func set_texture_size(s):
	layers.set_texture_size(s)

func get_texture_size() -> int:
	return layers.texture_size

func set_current_tool(m):
	current_tool = m
	for i in range(MODE_COUNT):
		tools.get_node(MODE_NAMES[i]).pressed = (i == m)

func _on_Fill_pressed():
	if layers.selected_layer == null or layers.selected_layer.get_layer_type() == Layer.LAYER_PROC:
		return
	painter.fill(eraser_button.pressed)
	set_need_save()

func _physics_process(delta):
	camera_rotation1.rotate(camera.global_transform.basis.x.normalized(), -key_rotate.y*delta)
	camera_rotation2.rotate(Vector3(0, 1, 0), -key_rotate.x*delta)
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
		var pos_delta = ev.position-last_motion_position
		stroke_length += pos_delta.length()
		pos_delta = pos_delta*0.75+last_motion_vector*0.75
		stroke_angle = atan2(pos_delta.y, pos_delta.x)*180/PI
		last_motion_position = ev.position
		last_motion_vector = pos_delta
		painter.update_brush_params( { stroke_length=stroke_length, stroke_angle=stroke_angle } )
		if current_tool == MODE_COLOR_PICKER:
			show_brush(null, null)
		else:
			if current_tool == MODE_LINE:
				if previous_position != null:
					var direction = ev.position-previous_position
					painter.set_brush_angle(-atan2(direction.y, direction.x))
				show_brush(ev.position, previous_position)
			else:
				show_brush(ev.position, ev.position)
		if ev.button_mask & BUTTON_MASK_MIDDLE != 0:
			if ev.shift:
				var factor = 0.0025*camera.translation.z
				camera_position.translate(-factor*ev.relative.x*camera.global_transform.basis.x)
				camera_position.translate(factor*ev.relative.y*camera.global_transform.basis.y)
			else:
				camera_rotation2.rotate_x(-0.01*ev.relative.y)
				camera_rotation1.rotate_y(-0.01*ev.relative.x)
		elif ev.button_mask & BUTTON_MASK_LEFT != 0:
			if ev.shift:
				reset_stroke()
				brush_size += ev.relative.x*0.1
				brush_size = clamp(brush_size, 0.0, 250.0)
				brush_hardness += ev.relative.y*0.01
				brush_hardness = clamp(brush_hardness, 0.0, 1.0)
				painter.update_brush_params( { brush_size=brush_size, brush_hardness=brush_hardness } )
				$VSplitContainer/Painter/Options/Grid/BrushSize.set_value(brush_size)
				$VSplitContainer/Painter/Options/Grid/BrushHardness.set_value(brush_hardness)
			elif ev.control:
				reset_stroke()
				pattern_scale += ev.relative.x*0.1
				pattern_scale = clamp(pattern_scale, 0.1, 25.0)
				pattern_angle += fmod(ev.relative.y*0.01, 2.0*PI)
				painter.update_brush_params( { pattern_scale=pattern_scale, pattern_angle=pattern_angle } )
				painter.update_brush()
			elif current_tool == MODE_FREEHAND_DOTS or current_tool == MODE_FREEHAND_LINE:
				paint(ev.position, get_pressure(ev))
			elif ev.relative.length_squared() > 50:
				get_pressure(ev)
		else:
			reset_stroke()
		painter.update_brush()
	elif ev is InputEventMouseButton:
		var pos = ev.position
		if !ev.control and !ev.shift:
			if ev.button_index == BUTTON_LEFT:
				if ev.pressed:
					stroke_length = 0.0
					previous_position = pos
				elif current_tool == MODE_COLOR_PICKER:
					painter.pick_color(pos)
				else:
					if current_tool == MODE_LINE:
						var angle = 0
						if previous_position != null:
							var direction = pos-previous_position
							angle = -atan2(direction.y, direction.x)
						painter.set_brush_angle(angle)
					else:
						last_painted_position = pos+Vector2(brush_spacing_control.value, brush_spacing_control.value)
					paint(pos, get_pressure(ev))
					reset_stroke()
		if !ev.pressed and ev.button_index == BUTTON_MIDDLE:
			update_view()
		# Mouse wheel
		if ev.control:
			if ev.button_index == BUTTON_WHEEL_UP:
				camera.fov += 1
			elif ev.button_index == BUTTON_WHEEL_DOWN:
				camera.fov -= 1
			else:
				return
			update_view()
			accept_event()
		else:
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

# Automatically apply brush to procedural layer

var procedural_update_changed_scheduled : bool = false

func update_procedural_layer() -> void:
	if layers.selected_layer != null and layers.selected_layer.get_layer_type() == Layer.LAYER_PROC and !procedural_update_changed_scheduled:
		call_deferred("do_update_procedural_layer")

func do_update_procedural_layer() -> void:
	painter.fill(false)
	layers.selected_layer.material = $VSplitContainer/GraphEdit.top_generator.serialize()
	set_need_save()

func on_float_parameters_changed(parameter_changes : Dictionary) -> void:
	update_procedural_layer()

func on_texture_changed(n : String) -> void:
	update_procedural_layer()

var saved_brush = null

func _on_PaintLayers_layer_selected(layer):
	if layer.get_layer_type() == Layer.LAYER_PROC:
		if saved_brush == null:
			saved_brush = $VSplitContainer/GraphEdit.top_generator.serialize()
		if ! layer.material.empty():
			set_brush(layer.material)
	elif saved_brush != null:
		set_brush(saved_brush)
		saved_brush = null

var brush_changed_scheduled : bool = false

func on_brush_changed(_p, _v) -> void:
	if !brush_changed_scheduled:
		call_deferred("do_on_brush_changed")
		brush_changed_scheduled = true

func do_on_brush_changed():
	painter.set_brush_preview_material($VSplitContainer/Painter/BrushView.material)
	painter.update_brush(true)
	brush_changed_scheduled = false
	update_procedural_layer()

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

# Paint

var last_painted_position : Vector2

func reset_stroke() -> void:
	stroke_length = 0.0
	previous_position = null

func paint(pos, pressure = 1.0):
	if layers.selected_layer == null or layers.selected_layer.get_layer_type() == Layer.LAYER_PROC:
		return
	if current_tool == MODE_FREEHAND_DOTS or current_tool == MODE_FREEHAND_LINE:
		if (pos-last_painted_position).length() < brush_spacing_control.value:
			return
		if current_tool == MODE_FREEHAND_DOTS:
			previous_position = null
	do_paint(pos, pressure)
	last_painted_position = pos

var next_paint_to = null
var next_pressure = null

func do_paint(pos, pressure = 1.0):
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
	var paint_options : Dictionary = {
		brush_pos=position,
		brush_ppos=prev_position,
		brush_opacity=$VSplitContainer/Painter/Options/Grid/BrushOpacity.value,
		stroke_length=stroke_length,
		stroke_angle=stroke_angle,
		erase=eraser_button.pressed,
		pressure=pressure,
		fill=false
	}
	painter.paint(paint_options)
	previous_position = pos
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	painting = false
	set_need_save()
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
	camera.near = max(0.01, 0.9*(cam_to_center-mesh_size))
	camera.far = 1.1*(cam_to_center+mesh_size)
	var transform = camera.global_transform.affine_inverse()*painted_mesh.global_transform
	if painter != null:
		painter.update_view(camera, transform, main_view.size)
	# Force recalculate brush size parameter
	_on_BrushSize_value_changed(brush_size)

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
	set_need_save(false)
	return true

func save():
	if save_path != null:
		do_save_project(save_path)
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
	set_need_save(false)

# Export

func get_material_node() -> MMGenMaterial:
	return $Export.get_material_node()

func export_material(export_prefix, profile) -> void:
	var material_textures = {
		albedo=layers.get_albedo_texture(),
		metallic=layers.get_metallic_texture(),
		roughness=layers.get_roughness_texture(),
		emission=layers.get_emission_texture(),
		normal=layers.get_normal_map(),
		depth=layers.get_depth_texture()
	}
	$Export.setup_material(material_textures)
	$Export.get_material_node().export_material(export_prefix, profile)

# debug

func debug_get_texture_names():
	return [ "None" ]

func debug_get_texture(_ID):
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
			return
		ID -= textures_count

# Brush options UI

func _on_BrushSize_value_changed(value) -> void:
	brush_size = value
	painter.update_brush_params( { brush_size=brush_size } )

func _on_BrushHardness_value_changed(value) -> void:
	brush_hardness = value
	painter.update_brush_params( { brush_hardness=brush_hardness } )

func replace_brush_options_button() -> void:
	if $VSplitContainer/Painter/Options.visible:
		$VSplitContainer/Painter/Options.rect_size = $VSplitContainer/Painter/Options.rect_min_size
		$VSplitContainer/Painter/OptionsButton.margin_top = $VSplitContainer/Painter/Options.rect_size.y
		$VSplitContainer/Painter/OptionsButton.text = "-"
	else:
		$VSplitContainer/Painter/OptionsButton.margin_top = 0
		$VSplitContainer/Painter/OptionsButton.text = "+"

func _on_OptionsButton_pressed() -> void:
	$VSplitContainer/Painter/Options.visible = !$VSplitContainer/Painter/Options.visible
	replace_brush_options_button()

func set_environment(index) -> void:
	var environment_manager = get_node("/root/MainWindow/EnvironmentManager")
	var environment = $VSplitContainer/Painter/View/MainView/CameraPosition/CameraRotation1/CameraRotation2/Camera.environment
	var sun = $VSplitContainer/Painter/View/MainView/Sun
	environment_manager.apply_environment(index, environment, sun)


