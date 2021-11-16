extends VBoxContainer

var settings : Dictionary = {
	texture_size=0,
	paint_emission=true,
	paint_normal=true,
	paint_depth=true,
	paint_depth_as_bump=true,
	bump_strength=0.5
}

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

onready var view_3d = $VSplitContainer/HSplitContainer/Painter/View
onready var main_view = $VSplitContainer/HSplitContainer/Painter/View/MainView
onready var camera : Camera = $VSplitContainer/HSplitContainer/Painter/View/MainView/CameraPosition/CameraRotation1/CameraRotation2/Camera
onready var camera_position = $VSplitContainer/HSplitContainer/Painter/View/MainView/CameraPosition
onready var camera_rotation1 = $VSplitContainer/HSplitContainer/Painter/View/MainView/CameraPosition/CameraRotation1
onready var camera_rotation2 = $VSplitContainer/HSplitContainer/Painter/View/MainView/CameraPosition/CameraRotation1/CameraRotation2
onready var painted_mesh = $VSplitContainer/HSplitContainer/Painter/View/MainView/PaintedMesh
onready var painter = $Painter
onready var tools = $VSplitContainer/HSplitContainer/Painter/Tools
onready var layers = $PaintLayers
onready var paint_engine_button = $VSplitContainer/HSplitContainer/Painter/Tools/Engine
onready var eraser_button = $VSplitContainer/HSplitContainer/Painter/Tools/Eraser
onready var graph_edit = $VSplitContainer/GraphEdit

onready var brush_view_3d = $VSplitContainer/HSplitContainer/Painter/BrushView
var brush_view_3d_shown = false

onready var view_2d : ColorRect = $VSplitContainer/HSplitContainer/Painter2D/VBoxContainer/Texture
onready var brush_view_2d = $VSplitContainer/HSplitContainer/Painter2D/VBoxContainer/Texture/BrushView
var brush_view_2d_shown = false

onready var brush_size_control : Control = $VSplitContainer/HSplitContainer/Painter/Options/Grid/BrushSize
onready var brush_hardness_control : Control = $VSplitContainer/HSplitContainer/Painter/Options/Grid/BrushStrength
onready var brush_opacity_control : Control = $VSplitContainer/HSplitContainer/Painter/Options/Grid/BrushOpacity
onready var brush_spacing_control : Control = $VSplitContainer/HSplitContainer/Painter/Options/Grid/BrushSpacing

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
	initialize_2D_paint_select()
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
	painter.set_brush_preview_material(brush_view_3d.material)
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
	settings.texture_size = int(round(log(resolution)/log(2)))
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
	preview_material.metallic_texture = layers.get_metallic_texture()
	preview_material.metallic_texture.flags = Texture.FLAGS_DEFAULT
	preview_material.metallic_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
	preview_material.roughness = 1.0
	preview_material.roughness_texture = layers.get_roughness_texture()
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
	preview_material.ao_enabled = true
	preview_material.ao_light_affect = 1.0
	preview_material.ao_texture = layers.get_occlusion_texture()
	preview_material.ao_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
	painted_mesh.mesh = o.mesh
	painted_mesh.set_surface_material(0, preview_material)
	painter.set_mesh(o.mesh)
	update_view()
	painter.init_textures(mat)

func get_settings() -> Dictionary:
	return settings

func set_settings(s : Dictionary):
	var settings_changed = false
	if s.has("texture_size") and (s.texture_size is int or s.texture_size is float) and s.texture_size != settings.texture_size:
		settings.texture_size = s.texture_size
		layers.set_texture_size(1 << int(settings.texture_size))
		settings_changed = true
	for v in [ "paint_emission", "paint_normal", "paint_depth", "paint_depth_as_bump" ]:
		if s.has(v) and s[v] is bool and s[v] != settings[v]:
			settings[v] = s[v]
			settings_changed = true
	if s.has("bump_strength") and s.bump_strength is float and s.bump_strength != settings.bump_strength:
		settings.bump_strength = s.bump_strength
		settings_changed = true
	if settings_changed:
		preview_material.emission_enabled = settings.paint_emission
		preview_material.normal_enabled = settings.paint_normal or settings.paint_depth_as_bump
		layers.set_normal_options(settings.paint_normal, settings.paint_depth_as_bump, settings.bump_strength)
		preview_material.depth_enabled = settings.paint_depth
		set_need_save(true)

func check_material_feature(variable : String, value : bool) -> void:
	preview_material[variable] = value

func material_feature_is_checked(variable : String) -> bool:
	return preview_material[variable]

func set_texture_size(s):
	settings.texture_size = int(round(log(s)/log(2)))
	layers.set_texture_size(s)

func get_texture_size() -> int:
	return 1 << settings.texture_size

func _on_Engine_toggled(button_pressed):
	if button_pressed:
		$VSplitContainer/HSplitContainer/Painter/Tools/Engine.hint_tooltip = "Texture space paint engine"
	else:
		$VSplitContainer/HSplitContainer/Painter/Tools/Engine.hint_tooltip = "View space paint engine"

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

var last_tilt : Vector2 = Vector2(0, 0)

# UI input for 3D view_3d

const PAINTING_MODE_VIEW = 0
const PAINTING_MODE_TEXTURE = 1
const PAINTING_MODE_TEXTURE_FROM_VIEW = 2

func handle_stroke_input(ev : InputEvent, painting_mode : int = PAINTING_MODE_VIEW):
	var mouse_position : Vector2
	var dont_paint : bool = false
	if ev is InputEventMouseMotion or ev is InputEventMouseButton:
		mouse_position = ev.position
		if painting_mode == PAINTING_MODE_TEXTURE_FROM_VIEW:
			mouse_position = painter.view_to_texture(mouse_position)
			if mouse_position == Vector2(-1, -1):
				dont_paint = true
			else:
				mouse_position *= min(view_3d.rect_size.x, view_3d.rect_size.y)
	if ev is InputEventMouseMotion:
		var pos_delta = mouse_position-last_motion_position
		stroke_length += pos_delta.length()
		pos_delta = pos_delta*0.75+last_motion_vector*0.75
		stroke_angle = atan2(pos_delta.y, pos_delta.x)*180/PI
		last_motion_position = mouse_position
		last_motion_vector = pos_delta
		painter.update_brush_params( { stroke_length=stroke_length, stroke_angle=stroke_angle } )
		if current_tool == MODE_COLOR_PICKER:
			show_brush(null, null)
		else:
			if current_tool == MODE_LINE:
				if previous_position != null:
					var direction = mouse_position-previous_position
					painter.set_brush_angle(-atan2(direction.y, direction.x))
				if dont_paint:
					show_brush(null, null)
				else:
					show_brush(mouse_position, previous_position)
			else:
				if dont_paint:
					show_brush(null, null)
				else:
					show_brush(mouse_position, mouse_position)
		if ev.button_mask & BUTTON_MASK_LEFT != 0:
			if ev.shift:
				reset_stroke()
				brush_size += ev.relative.x*0.1
				brush_size = clamp(brush_size, 0.0, 250.0)
				brush_hardness += ev.relative.y*0.01
				brush_hardness = clamp(brush_hardness, 0.0, 1.0)
				painter.update_brush_params( { brush_size=brush_size, brush_hardness=brush_hardness } )
				$VSplitContainer/HSplitContainer/Painter/Options/Grid/BrushSize.set_value(brush_size)
				$VSplitContainer/HSplitContainer/Painter/Options/Grid/BrushHardness.set_value(brush_hardness)
			elif ev.control:
				reset_stroke()
				pattern_scale += ev.relative.x*0.1
				pattern_scale = clamp(pattern_scale, 0.1, 25.0)
				pattern_angle += fmod(ev.relative.y*0.01, 2.0*PI)
				painter.update_brush_params( { pattern_scale=pattern_scale, pattern_angle=pattern_angle } )
				painter.update_brush()
			elif current_tool == MODE_FREEHAND_DOTS or current_tool == MODE_FREEHAND_LINE:
				paint(mouse_position, get_pressure(ev), ev.tilt, painting_mode)
				last_tilt = ev.tilt
			elif ev.relative.length_squared() > 50:
				get_pressure(ev)
		else:
			reset_stroke()
		painter.update_brush()
	elif ev is InputEventMouseButton:
		if !ev.control and !ev.shift:
			if ev.button_index == BUTTON_LEFT:
				if ev.pressed:
					stroke_length = 0.0
					previous_position = mouse_position
				elif current_tool == MODE_COLOR_PICKER:
					pick_color(ev.position)
				else:
					if current_tool == MODE_LINE:
						var angle = 0
						if previous_position != null:
							var direction = mouse_position-previous_position
							angle = -atan2(direction.y, direction.x)
						painter.set_brush_angle(angle)
					else:
						last_painted_position = mouse_position+Vector2(brush_spacing_control.value, brush_spacing_control.value)
					paint(mouse_position, get_pressure(ev), last_tilt, painting_mode)
					reset_stroke()

func _on_View_gui_input(ev : InputEvent):
	handle_stroke_input(ev, PAINTING_MODE_TEXTURE_FROM_VIEW if paint_engine_button.pressed else PAINTING_MODE_VIEW)
	if ev is InputEventMouseMotion:
		if ev.button_mask & BUTTON_MASK_MIDDLE != 0:
			if ev.shift:
				var factor = 0.0025*camera.translation.z
				camera_position.translate(-factor*ev.relative.x*camera.global_transform.basis.x)
				camera_position.translate(factor*ev.relative.y*camera.global_transform.basis.y)
			elif ev.control:
				camera.translate(Vector3(0.0, 0.0, -0.01*ev.relative.y*camera.transform.origin.z))
				update_view()
				accept_event()
			else:
				camera_rotation1.rotate_y(-0.01*ev.relative.x)
				camera_rotation2.rotate_x(-0.01*ev.relative.y)
	elif ev is InputEventMouseButton:
		var pos = ev.position
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

func _on_View_mouse_entered():
	update_brush_view_3d_visibility()

func _on_View_mouse_exited():
	update_brush_view_3d_visibility()

# UI input for 2D view

var view_2d_center : Vector2 = Vector2(0.5, 0.5)
var view_2d_scale : float = 1.0
var view_2d_dragging : bool = false
var view_2d_zooming : bool = false

func _on_Texture_gui_input(event):
	handle_stroke_input(event, PAINTING_MODE_TEXTURE)
	var need_update : bool = false
	var new_center : Vector2 = view_2d_center
	var multiplier : float = min(rect_size.x, rect_size.y)
	var image_rect : Rect2 = view_2d.get_global_rect()
	var offset_from_center : Vector2 = get_global_mouse_position()-(image_rect.position+0.5*image_rect.size)
	var new_scale : float = view_2d_scale
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_WHEEL_DOWN:
				new_scale = min(new_scale*1.05, 5.0)
			elif event.button_index == BUTTON_WHEEL_UP:
				new_scale = max(new_scale*0.95, 0.005)
			elif event.button_index == BUTTON_MIDDLE:
				view_2d_dragging = true
		else:
			view_2d_dragging = false
			view_2d_zooming = false
	elif event is InputEventMouseMotion:
		if view_2d_dragging:
			new_center = view_2d_center-event.relative*view_2d_scale/multiplier
		elif view_2d_zooming:
			new_scale = clamp(new_scale*(1.0+0.01*event.relative.y), 0.005, 5.0)
	if new_scale != view_2d_scale:
		new_center = view_2d_center+offset_from_center*(view_2d_scale-new_scale)/multiplier
		view_2d_scale = new_scale
		need_update = true
	if new_center != view_2d_center:
		view_2d_center.x = clamp(new_center.x, 0.0, 1.0)
		view_2d_center.y = clamp(new_center.y, 0.0, 1.0)
		need_update = true
	if need_update:
		_on_Texture_resized()

func _on_Texture_resized():
	view_2d.material.set_shader_param("preview_2d_size", view_2d.rect_size)
	view_2d.material.set_shader_param("preview_2d_center", view_2d_center)
	view_2d.material.set_shader_param("preview_2d_scale", view_2d_scale)

# Automatically apply brush to procedural layer

var procedural_update_changed_scheduled : bool = false

func update_procedural_layer() -> void:
	if layers.selected_layer != null and layers.selected_layer.get_layer_type() == Layer.LAYER_PROC and !procedural_update_changed_scheduled:
		call_deferred("do_update_procedural_layer")
		procedural_update_changed_scheduled = true

func do_update_procedural_layer() -> void:
	painter.fill(false, true)
	layers.selected_layer.material = $VSplitContainer/GraphEdit.top_generator.serialize()
	set_need_save()
	procedural_update_changed_scheduled = false

func on_float_parameters_changed(parameter_changes : Dictionary) -> bool:
	update_procedural_layer()
	return true

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
	painter.set_brush_preview_material(brush_view_3d.material)
	painter.update_brush(true)
	brush_changed_scheduled = false
	update_procedural_layer()

func edit_brush(v : Vector2) -> void:
	painter.edit_brush(v)

func show_brush(p, op = null):
	if p == null:
		brush_view_3d_shown = false
	else:
		brush_view_3d_shown = true
		if op == null:
			op = p
		brush_view_3d.material.set_shader_param("texture_space", paint_engine_button.pressed)
		brush_view_3d.material.set_shader_param("brush_pos", p)
		brush_view_3d.material.set_shader_param("brush_ppos", op)
	update_brush_view_3d_visibility()

func update_brush_view_3d_visibility():
	if brush_view_3d_shown and view_3d.get_global_rect().has_point(get_global_mouse_position()):
		brush_view_3d.show()
	else:
		brush_view_3d.hide()

# Paint

var last_painted_position : Vector2

func reset_stroke() -> void:
	stroke_length = 0.0
	previous_position = null

func paint(pos : Vector2, pressure : float = 1.0, tilt : Vector2 = Vector2(0, 0), painting_mode : int = PAINTING_MODE_VIEW):
	if layers.selected_layer == null or layers.selected_layer.get_layer_type() == Layer.LAYER_PROC:
		return
	if current_tool == MODE_FREEHAND_DOTS or current_tool == MODE_FREEHAND_LINE:
		if (pos-last_painted_position).length() < brush_spacing_control.value:
			return
		if current_tool == MODE_FREEHAND_DOTS:
			previous_position = null
	do_paint(pos, pressure, tilt, painting_mode)
	last_painted_position = pos

var next_paint_to = null
var next_pressure = null

func do_paint(pos : Vector2, pressure : float = 1.0, tilt : Vector2 = Vector2(0, 0), painting_mode : int = PAINTING_MODE_VIEW):
	if painting:
		# if not available for painting, record a paint order
		next_paint_to = pos
		next_pressure = pressure
		return
	painting = true
	if previous_position == null:
		previous_position = pos
	var paint_options : Dictionary = {
		texture_space=(painting_mode != PAINTING_MODE_VIEW),
		brush_pos=pos,
		brush_ppos=previous_position,
		brush_opacity=$VSplitContainer/HSplitContainer/Painter/Options/Grid/BrushOpacity.value,
		stroke_length=stroke_length,
		stroke_angle=stroke_angle,
		erase=eraser_button.pressed,
		pressure=pressure,
		tilt=tilt,
		fill=false
	}
	match painting_mode:
		PAINTING_MODE_VIEW:
			paint_options.rect_size = view_3d.rect_size
		PAINTING_MODE_TEXTURE_FROM_VIEW:
			var min_size = min(view_3d.rect_size.x, view_3d.rect_size.y)
			paint_options.texture_center = Vector2(0.5, 0.5)
			paint_options.texture_scale = 1.0
			paint_options.rect_size = Vector2(min_size, min_size)
		PAINTING_MODE_TEXTURE:
			paint_options.rect_size = view_2d.rect_size
			paint_options.texture_center = view_2d_center
			paint_options.texture_scale = view_2d_scale
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
		paint(pos, next_pressure, tilt, painting_mode)

func update_view():
	var mesh_instance = painted_mesh
	var mesh_aabb = mesh_instance.get_aabb()
	var mesh_center = mesh_aabb.position+0.5*mesh_aabb.size
	var mesh_size = 0.5*mesh_aabb.size.length()
	var cam_to_center = (camera.global_transform.origin-mesh_center).length()
	camera.near = max(0.01, 0.99*(cam_to_center-mesh_size))
	camera.far = 1.01*(cam_to_center+mesh_size)
	var transform = camera.global_transform.affine_inverse()*painted_mesh.global_transform
	if painter != null:
		painter.update_view(camera, transform, main_view.size)
	# Force recalculate brush size parameter
	_on_BrushSize_value_changed(brush_size)

func _on_resized():
	call_deferred("update_view")

# Pick color

func pick_color(position : Vector2):
	if remote_node == null:
		return
	
	var uv = painter.view_to_texture(position)
	var colors = {}
	var albedo_image = layers.get_albedo_texture().get_data()
	albedo_image.lock()
	colors["Albedo"] = albedo_image.get_pixelv(uv*albedo_image.get_size())
	albedo_image.unlock()
	
	var metallic_image = layers.get_metallic_texture().get_data()
	metallic_image.lock()
	colors["Metallic"] = metallic_image.get_pixelv(uv*metallic_image.get_size()).r
	metallic_image.unlock()
	
	var roughness_image = layers.get_roughness_texture().get_data()
	roughness_image.lock()
	colors["Roughness"] = roughness_image.get_pixelv(uv*roughness_image.get_size()).r
	roughness_image.unlock()

	var emission_image = layers.get_emission_texture().get_data()
	emission_image.lock()
	colors["Emission"] = emission_image.get_pixelv(uv*emission_image.get_size())
	emission_image.unlock()

	var depth_image = layers.get_depth_texture().get_data()
	depth_image.lock()
	colors["Depth"] = depth_image.get_pixelv(uv*depth_image.get_size()).r
	depth_image.unlock()
	
	var occlusion_image = layers.get_occlusion_texture().get_data()
	occlusion_image.lock()
	colors["Occlusion"] = occlusion_image.get_pixelv(uv*occlusion_image.get_size()).r
	occlusion_image.unlock()

	for p in remote_node.get_parameter_defs():
		if colors.has(p.label):
			remote_node.set_parameter(p.name, colors[p.label])

# Load/save

func dump_texture(texture, filename):
	var image = texture.get_data()
	image.save_png(filename)

func show_file_dialog(mode, filter, callback):
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = mode
	dialog.add_filter(filter)
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() == 1:
		call(callback, files[0])

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
	if data.has("settings"):
		set_settings(data.settings)
	elif data.has("texture_size"):
		set_settings({ texture_size=int(round(log(data.texture_size)/log(2))) })
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
	data.settings = get_settings()
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
		occlusion=layers.get_occlusion_texture(),
		depth=layers.get_depth_texture()
	}
	$Export.setup_material(material_textures)
	$Export.get_material_node().export_material(export_prefix, profile)

# 2D painting

func get_2D_paint_select_texture_sources() -> Array:
	return [ $Painter, $PaintLayers ]

func initialize_2D_paint_select():
	for s in [ $VSplitContainer/HSplitContainer/Painter2D/VBoxContainer/ChannelSelect ]:
		s.clear()
		var index = 0
		for p in get_2D_paint_select_texture_sources():
			for i in p.debug_get_texture_names():
				s.add_item(i, index)
				index += 1

func _on_ChannelSelect_item_selected(ID):
	for p in get_2D_paint_select_texture_sources():
		var textures_count = p.debug_get_texture_names().size()
		if ID < textures_count:
			view_2d.material.set_shader_param("tex", p.debug_get_texture(ID))
			return
		ID -= textures_count

# debug

func debug_get_texture_names():
	return [ "None" ]

func debug_get_texture(_ID):
	return null

func initialize_debug_selects():
	for s in [ $VSplitContainer/HSplitContainer/Painter/Debug/Select1, $VSplitContainer/HSplitContainer/Painter/Debug/Select2 ]:
		s.clear()
		var index = 0
		for p in [ self, $Painter, $PaintLayers ]:
			for i in p.debug_get_texture_names():
				s.add_item(i, index)
				index += 1

func _on_DebugSelect_item_selected(ID, t):
	var texture = [$VSplitContainer/HSplitContainer/Painter/Debug/Texture1, $VSplitContainer/HSplitContainer/Painter/Debug/Texture2][t]
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
	if $VSplitContainer/HSplitContainer/Painter/Options.visible:
		$VSplitContainer/HSplitContainer/Painter/Options.rect_size = $VSplitContainer/HSplitContainer/Painter/Options.rect_min_size
		$VSplitContainer/HSplitContainer/Painter/OptionsButton.margin_top = $VSplitContainer/HSplitContainer/Painter/Options.rect_size.y
		$VSplitContainer/HSplitContainer/Painter/OptionsButton.text = "-"
	else:
		$VSplitContainer/HSplitContainer/Painter/OptionsButton.margin_top = 0
		$VSplitContainer/HSplitContainer/Painter/OptionsButton.text = "+"

func _on_OptionsButton_pressed() -> void:
	$VSplitContainer/HSplitContainer/Painter/Options.visible = !$VSplitContainer/HSplitContainer/Painter/Options.visible
	replace_brush_options_button()

func set_environment(index) -> void:
	var environment_manager = get_node("/root/MainWindow/EnvironmentManager")
	var environment = $VSplitContainer/HSplitContainer/Painter/View/MainView/CameraPosition/CameraRotation1/CameraRotation2/Camera.environment
	var sun = $VSplitContainer/HSplitContainer/Painter/View/MainView/Sun
	environment_manager.apply_environment(index, environment, sun)
