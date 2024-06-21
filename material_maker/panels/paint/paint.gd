extends VBoxContainer


@export var mask_selection_material_template : ShaderMaterial

var settings : Dictionary = {
	texture_size=0,
	paint_emission=true,
	paint_normal=true,
	paint_depth=true,
	paint_depth_as_bump=true,
	bump_strength=0.5
}

const MODE_FREEHAND_DOTS  = 0
const MODE_FREEHAND_LINE  = 1
const MODE_LINE           = 2
const MODE_STAMP          = 3
const MODE_COLOR_PICKER   = 4
const MODE_MASK_SELECTOR  = 5
const MODE_COUNT          = 6
const MODE_NAMES : Array = [ "FreeDots", "FreeLine", "Line", "Stamp", "ColorPicker", "MaskSelector" ]

var current_tool = MODE_FREEHAND_DOTS

var preview_material : StandardMaterial3D = null
var mask_selection_material : ShaderMaterial = null

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

var brush_parameters : Dictionary = {
	brush_size = 50.0,
	brush_hardness = 0.5,
	pattern_scale = 10.0,
	pattern_angle = 0.0
}

var idmap_filename : String = ""
var mask : MMTexture = MMTexture.new()

@onready var view_3d = $VSplitContainer/HSplitContainer/Painter/View
@onready var main_view = $VSplitContainer/HSplitContainer/Painter/View/MainView
@onready var camera : Camera3D = $VSplitContainer/HSplitContainer/Painter/View/MainView/CameraPosition/CameraRotation1/CameraRotation2/Camera3D
@onready var camera_position = $VSplitContainer/HSplitContainer/Painter/View/MainView/CameraPosition
@onready var camera_rotation1 = $VSplitContainer/HSplitContainer/Painter/View/MainView/CameraPosition/CameraRotation1
@onready var camera_rotation2 = $VSplitContainer/HSplitContainer/Painter/View/MainView/CameraPosition/CameraRotation1/CameraRotation2
@onready var painted_mesh = $VSplitContainer/HSplitContainer/Painter/View/MainView/PaintedMesh
@onready var painter = $Painter
@onready var tools = $VSplitContainer/HSplitContainer/Painter/Tools
@onready var layers = $PaintLayers
@onready var paint_engine_button = $VSplitContainer/HSplitContainer/Painter/Tools/Engine
@onready var eraser_button = $VSplitContainer/HSplitContainer/Painter/Tools/Eraser
@onready var graph_edit = $VSplitContainer/GraphEdit
@onready var undoredo = $UndoRedo

@onready var brush_view_3d : ColorRect = $VSplitContainer/HSplitContainer/Painter/BrushView
var brush_view_3d_shown : bool = false

@onready var view_2d : ColorRect = $VSplitContainer/HSplitContainer/Painter2D/VBoxContainer/Texture2D
@onready var brush_view_2d = $VSplitContainer/HSplitContainer/Painter2D/VBoxContainer/Texture2D/BrushView
var brush_view_2d_shown = false

@onready var brush_size_control : Control = %BrushSize
@onready var brush_spacing_control : Control = %BrushSpacing
@onready var brush_opacity_control : Control = %BrushOpacity
@onready var brush_hardness_control : Control = %BrushHardness

var last_motion_position : Vector2
var last_motion_vector : Vector2 = Vector2(0, 0)
var stroke_length : float = 0.0
var stroke_angle : float = 0.0
var stroke_seed : float = 0.0


const Layer = preload("res://material_maker/panels/paint/layer_types/layer.gd")


signal update_material


func _ready():
	# Assign all textures to painted mesh
	painted_mesh.set_surface_override_material(0, StandardMaterial3D.new())
	# Updated Texture2View wrt current camera position
	update_view()
	# Disable physics process so we avoid useless updates of tex2view textures
	set_physics_process(false)
	set_current_tool(MODE_FREEHAND_DOTS)
	initialize_2D_paint_select()
	graph_edit.undoredo.disable()
	graph_edit.node_factory = get_node("/root/MainWindow/NodeFactory")
	graph_edit.new_material({nodes=[{name="Brush", type="brush"}], connections=[]})
	update_brush_graph()
	call_deferred("update_brush")
	set_environment(0)
	# Create white mask
	var mask_texture : ImageTexture = ImageTexture.new()
	var image = Image.new()
	image = Image.create(16, 16, 0, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1))
	mask_texture.set_image(image)
	mask.set_texture(mask_texture)


func update_tab_title() -> void:
	if !get_parent().has_method("set_tab_title"):
		#print("no set_tab_title method")
		return
	var title = "[unnamed]"
	if save_path != null:
		title = save_path.right(-(save_path.rfind("/")+1))
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
		brush_graph.set_current_mesh(painted_mesh.mesh)
		brush_graph.connect("graph_changed", Callable(self, "on_brush_graph_changed"))
		on_brush_graph_changed()

func on_brush_graph_changed() -> void:
	var new_remote = get_remote()
	if new_remote != remote_node:
		remote_node = new_remote
		mm_globals.main_window.get_panel("Parameters").set_generator(remote_node)

# called when the project's tab is selected
func project_selected() -> void:
	var main_window = mm_globals.main_window
	main_window.get_panel("Layers").set_layers($PaintLayers)
	remote_node = get_remote()
	main_window.get_panel("Parameters").set_generator(remote_node)

func update_brush() -> void:
	brush_node = graph_edit.generator.get_node("Brush")
	brush_node.parameter_changed.connect(self.on_brush_changed)
	painter.set_brush_preview_material(brush_view_3d.material)
	if layers.selected_layer:
		painter.set_brush_node(graph_edit.generator.get_node("Brush"), layers.selected_layer.get_layer_type() == Layer.LAYER_MASK)

func set_brush(data) -> void:
	var parameters_panel = mm_globals.main_window.get_panel("Parameters")
	parameters_panel.set_generator(null)
	graph_edit.new_material(data)
	update_brush()
	update_brush_graph()

func get_brush_preview() -> Texture2D:
	var preview = get_tree().get_root().get_node("BrushPreviewGenerator")
	if preview == null:
		print("Create preview")
		preview = load("res://material_maker/tools/painter/brush_preview.tscn").instantiate()
		preview.name = "BrushPreviewGenerator"
		get_tree().get_root().add_child(preview)
	var status = await preview.set_brush(graph_edit.generator.get_node("Brush"))
	return status

func get_graph_edit():
	return graph_edit

func init_project(mesh : Mesh, mesh_file_path : String, resolution : int, project_file_path : String):
	settings.texture_size = int(round(log(resolution)/log(2)))
	layers.set_texture_size(resolution)
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	layers.add_layer()
	model_path = mesh_file_path
	set_object(mi)
	set_project_path(project_file_path)
	initialize_layers_history()

func set_object(o):
	object_name = o.name
	set_project_path(null)
	var mat = o.get_surface_override_material(0)
	if mat == null:
		mat = o.mesh.surface_get_material(0)
	if mat == null:
		mat = StandardMaterial3D.new()
	preview_material = StandardMaterial3D.new()
	preview_material.albedo_texture = layers.get_albedo_texture()
	#preview_material.albedo_texture.flags = Texture2D.FLAGS_DEFAULT
	preview_material.metallic = 1.0
	preview_material.metallic_texture = layers.get_metallic_texture()
	#preview_material.metallic_texture.flags = Texture2D.FLAGS_DEFAULT
	preview_material.metallic_texture_channel = StandardMaterial3D.TEXTURE_CHANNEL_RED
	preview_material.roughness = 1.0
	preview_material.roughness_texture = layers.get_roughness_texture()
	preview_material.roughness_texture_channel = StandardMaterial3D.TEXTURE_CHANNEL_GREEN
	preview_material.emission_enabled = true
	preview_material.emission = Color(0.0, 0.0, 0.0, 0.0)
	preview_material.emission_texture = layers.get_emission_texture()
	#preview_material.emission_texture.flags = Texture2D.FLAGS_DEFAULT
	preview_material.normal_enabled = true
	preview_material.normal_texture = layers.get_normal_map()
	#preview_material.normal_texture.flags = Texture2D.FLAGS_DEFAULT
	preview_material.heightmap_enabled = true
	preview_material.heightmap_deep_parallax = true
	preview_material.heightmap_flip_texture = true
	preview_material.heightmap_texture = layers.get_depth_texture()
	#preview_material.depth_texture.flags = Texture2D.FLAGS_DEFAULT
	preview_material.ao_enabled = true
	preview_material.ao_light_affect = 1.0
	preview_material.ao_texture = layers.get_occlusion_texture()
	preview_material.ao_texture_channel = StandardMaterial3D.TEXTURE_CHANNEL_RED
	painted_mesh.mesh = o.mesh
	painted_mesh.set_surface_override_material(0, preview_material)
	# Center camera on  mesh
	var aabb : AABB = painted_mesh.get_aabb()
	camera_position.transform.origin = aabb.position+0.5*aabb.size
	update_camera()
	# Set the painter target mesh
	painter.set_mesh(o.mesh)
	update_view()
	painter.init_textures(mat)

func get_settings() -> Dictionary:
	return settings

func set_settings(s : Dictionary):
	var changed = false
	if s.has("texture_size") and (s.texture_size is int or s.texture_size is float) and s.texture_size != settings.texture_size:
		settings.texture_size = s.texture_size
		layers.set_texture_size(1 << int(settings.texture_size))
		changed = true
	for v in [ "paint_emission", "paint_normal", "paint_depth", "paint_depth_as_bump" ]:
		if s.has(v) and s[v] is bool and s[v] != settings[v]:
			settings[v] = s[v]
			changed = true
	if s.has("bump_strength") and s.bump_strength is float and s.bump_strength != settings.bump_strength:
		settings.bump_strength = s.bump_strength
		changed = true
	if changed:
		preview_material.emission_enabled = settings.paint_emission
		preview_material.normal_enabled = settings.paint_normal or settings.paint_depth_as_bump
		layers.set_normal_options(settings.paint_normal, settings.paint_depth_as_bump, settings.bump_strength)
		preview_material.heightmap_enabled = settings.paint_depth
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
		$VSplitContainer/HSplitContainer/Painter/Tools/Engine.tooltip_text = "Texture2D space paint engine"
	else:
		$VSplitContainer/HSplitContainer/Painter/Tools/Engine.tooltip_text = "View space paint engine"

func load_id_map() -> bool:
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.png;PNG image file")
	var files = await dialog.select_files()
	if files.size() == 1:
		painter.set_id_map(files[0])
		if not painter.has_id_map():
			return false
	else:
		return false
	return true

func set_current_tool(m):
	#preview_material.albedo_texture = painter.t2v_texture.get_texture()
	var ignore = false
	if m == MODE_MASK_SELECTOR:
		if not painter.has_id_map():
			ignore = not await load_id_map()
	if not ignore:
		if current_tool == MODE_MASK_SELECTOR:
			painted_mesh.set_surface_override_material(0, preview_material)
		current_tool = m
		if current_tool == MODE_MASK_SELECTOR:
			mask_selection_material = mask_selection_material_template.duplicate()
			mask_selection_material.set_shader_parameter("id_map", painter.get_id_map())
			mask_selection_material.set_shader_parameter("id_selected", false)
			painted_mesh.set_surface_override_material(0, mask_selection_material)
			painter.unset_id_mask()
	for i in range(MODE_COUNT):
		tools.get_node(MODE_NAMES[i]).button_pressed = (i == current_tool)

func _on_Fill_pressed():
	if layers.selected_layer == null or layers.selected_layer.get_layer_type() == Layer.LAYER_PROC:
		return
	painter.fill(eraser_button.button_pressed)
	set_need_save()

func _on_Eraser_toggled(button_pressed):
	view_3d.mouse_default_cursor_shape = Control.CURSOR_CROSS if button_pressed else Control.CURSOR_POINTING_HAND

func _physics_process(delta):
	camera_rotation1.rotate(camera.global_transform.basis.x.normalized(), -key_rotate.y*delta)
	camera_rotation2.rotate(Vector3(0, 1, 0), -key_rotate.x*delta)
	update_view()

func __input(ev : InputEvent):
	if ev is InputEventKey:
		if ev.keycode == KEY_CTRL:
			#TODO: move this to another shortcut, this is too annoying
			#painter.show_pattern(ev.pressed)
			accept_event()
		elif ev.keycode == KEY_LEFT or ev.keycode == KEY_RIGHT or ev.keycode == KEY_UP or ev.keycode == KEY_DOWN:
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

var stamp_center : Vector2

func painter_update_brush_params(paint_params : Dictionary) -> void:
	for k in paint_params.keys():
		match k:
			"brush_size":
				if %PressureSize.button_pressed:
					paint_params.brush_size *= next_pressure
			"brush_opacity":
				if %PressureOpacity.button_pressed:
					paint_params.brush_opacity *= next_pressure
			"brush_hardness":
				if %PressureHardness.button_pressed:
					paint_params.brush_hardness *= next_pressure
	painter.update_brush_params(paint_params)

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
				mouse_position *= min(view_3d.size.x, view_3d.size.y)
	if ev is InputEventMouseMotion:
		var pressure = get_pressure(ev)
		var pos_delta = mouse_position-last_motion_position
		stroke_length += pos_delta.length()
		pos_delta = pos_delta*0.75+last_motion_vector*0.75
		stroke_angle = atan2(pos_delta.y, pos_delta.x)*180/PI
		last_motion_position = mouse_position
		last_motion_vector = pos_delta
		painter_update_brush_params( { pressure=pressure, stroke_length=stroke_length, stroke_angle=stroke_angle, stroke_seed=stroke_seed } )
		if current_tool == MODE_COLOR_PICKER or current_tool == MODE_MASK_SELECTOR:
			show_brush(null, null)
		elif current_tool == MODE_LINE:
			if previous_position != null:
				var direction = mouse_position-previous_position
				painter_update_brush_params( { pattern_angle=-atan2(direction.y, direction.x) } )
			if dont_paint:
				show_brush(null, null)
			else:
				show_brush(mouse_position, previous_position)
		elif current_tool == MODE_STAMP and ev.button_mask & MOUSE_BUTTON_MASK_LEFT != 0:
			var stamp_offset = mouse_position - stamp_center
			var stamp_size = stamp_offset.length()
			var stamp_angle = -stamp_offset.angle()
			painter_update_brush_params( { brush_size=stamp_size, pattern_angle=stamp_angle } )
			show_brush(stamp_center, stamp_center)
		else:
			if dont_paint:
				show_brush(null, null)
			else:
				show_brush(mouse_position, mouse_position)
		if ev.button_mask & MOUSE_BUTTON_MASK_LEFT != 0:
			if ev.shift_pressed:
				next_pressure = 1.0
				reset_stroke()
				brush_parameters.brush_size += ev.relative.x*0.1
				brush_parameters.brush_size = clamp(brush_parameters.brush_size, 0.0, 250.0)
				brush_parameters.brush_hardness += ev.relative.y*0.01
				brush_parameters.brush_hardness = clamp(brush_parameters.brush_hardness, 0.0, 1.0)
				painter_update_brush_params( { brush_size=brush_parameters.brush_size, brush_hardness=brush_parameters.brush_hardness } )
				%BrushSize.set_value(brush_parameters.brush_size)
				%BrushHardness.set_value(brush_parameters.brush_hardness)
			elif ev.is_command_or_control_pressed():
				next_pressure = 1.0
				reset_stroke()
				brush_parameters.pattern_scale += ev.relative.x*0.1
				brush_parameters.pattern_scale = clamp(brush_parameters.pattern_scale, 0.1, 25.0)
				brush_parameters.pattern_angle = 0.5+(brush_parameters.pattern_angle+ev.relative.y*0.01)/TAU
				brush_parameters.pattern_angle = TAU*(brush_parameters.pattern_angle-floor(brush_parameters.pattern_angle)-0.5)
				painter_update_brush_params( { pattern_scale=brush_parameters.pattern_scale, pattern_angle=brush_parameters.pattern_angle } )
				%BrushAngle.set_value(brush_parameters.pattern_angle*57.2957795131)
			elif current_tool == MODE_FREEHAND_DOTS or current_tool == MODE_FREEHAND_LINE:
				paint(mouse_position, pressure, ev.tilt, painting_mode)
				last_tilt = ev.tilt
			painter_update_brush_params( { brush_size=brush_parameters.brush_size, brush_hardness=brush_parameters.brush_hardness } )
		else:
			reset_stroke()
		painter.update_brush()
	elif ev is InputEventMouseButton:
		var pressure = get_pressure(ev)
		if !ev.is_command_or_control_pressed() and !ev.shift_pressed:
			if ev.button_index == MOUSE_BUTTON_LEFT:
				if ev.pressed:
					stroke_length = 0.0
					previous_position = mouse_position
					if current_tool == MODE_STAMP:
						stamp_center = mouse_position
						painter_update_brush_params( { brush_size=0 } )
						show_brush(stamp_center, stamp_center)
				elif current_tool == MODE_STAMP:
					paint(stamp_center, pressure, last_tilt, painting_mode, true)
				elif current_tool == MODE_COLOR_PICKER:
					pick_color(ev.position, false)
				elif current_tool == MODE_MASK_SELECTOR:
					pick_color(ev.position, true)
				else:
					if current_tool == MODE_LINE:
						var angle = 0
						if previous_position != null:
							var direction = mouse_position-previous_position
							angle = -atan2(direction.y, direction.x)
						painter_update_brush_params( { pattern_angle=angle } )
						painter.update_brush()
					else:
						last_painted_position = mouse_position+Vector2(brush_spacing_control.value, brush_spacing_control.value)
					paint(mouse_position, get_pressure(ev), last_tilt, painting_mode, true)
					reset_stroke()

func _on_View_gui_input(ev : InputEvent):
	handle_stroke_input(ev, PAINTING_MODE_TEXTURE_FROM_VIEW if paint_engine_button.button_pressed else PAINTING_MODE_VIEW)
	if ev is InputEventPanGesture:
		camera_rotation1.rotate_y(-0.1*ev.delta.x)
		camera_rotation2.rotate_x(-0.1*ev.delta.y)
		update_view()
		accept_event()
	elif ev is InputEventMagnifyGesture:
		camera.translate(Vector3(0.0, 0.0, ev.factor-1.0))
		update_view()
		accept_event()
	elif ev is InputEventMouseMotion:
		if ev.button_mask & MOUSE_BUTTON_MASK_MIDDLE != 0:
			if ev.shift_pressed:
				var factor = 0.0025*camera.position.z
				camera_position.translate(-factor*ev.relative.x*camera.global_transform.basis.x)
				camera_position.translate(factor*ev.relative.y*camera.global_transform.basis.y)
				#update_view()
				accept_event()
			elif ev.is_command_or_control_pressed():
				camera.translate(Vector3(0.0, 0.0, -0.01*ev.relative.y*camera.transform.origin.z))
				#update_view()
				accept_event()
			else:
				camera_rotation1.rotate_y(-0.01*ev.relative.x)
				camera_rotation2.rotate_x(-0.01*ev.relative.y)
				#update_view()
				accept_event()
	elif ev is InputEventMouseButton:
		if !ev.pressed and ev.button_index == MOUSE_BUTTON_MIDDLE:
			update_view()
		# Mouse wheel
		if ev.is_command_or_control_pressed():
			if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera.fov += 1
			elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera.fov -= 1
			else:
				return
			update_view()
			accept_event()
		else:
			var zoom = 0.0
			if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom -= 1.0
			elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom += 1.0
			if zoom != 0.0:
				camera.translate(Vector3(0.0, 0.0, zoom*(1.0 if ev.shift_pressed else 0.1)))
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
	var multiplier : float = min(size.x, size.y)
	var image_rect : Rect2 = view_2d.get_global_rect()
	var offset_from_center : Vector2 = get_global_mouse_position()-(image_rect.position+0.5*image_rect.size)
	var new_scale : float = view_2d_scale
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				new_scale = min(new_scale*1.05, 5.0)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				new_scale = max(new_scale*0.95, 0.005)
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
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
	view_2d.material.set_shader_parameter("preview_2d_size", view_2d.size)
	view_2d.material.set_shader_parameter("preview_2d_center", view_2d_center)
	view_2d.material.set_shader_parameter("preview_2d_scale", view_2d_scale)

# Automatically apply brush to procedural layer

var procedural_update_changed_scheduled : bool = false

func update_procedural_layer() -> void:
	if layers.selected_layer != null and layers.selected_layer.get_layer_type() == Layer.LAYER_PROC and ! procedural_update_changed_scheduled:
		procedural_update_changed_scheduled = true
		await do_update_procedural_layer()

func do_update_procedural_layer() -> void:
	await painter.fill(false, true, false)
	layers.selected_layer.material = $VSplitContainer/GraphEdit.top_generator.serialize()
	set_need_save()
	procedural_update_changed_scheduled = false

var saved_brush = null

func _on_PaintLayers_layer_selected(layer):
	var brush_updated : bool = false
	if layer.get_layer_type() == Layer.LAYER_PROC:
		if saved_brush == null:
			saved_brush = $VSplitContainer/GraphEdit.top_generator.serialize()
		if ! layer.material.is_empty():
			set_brush(layer.material)
			brush_updated = true
	elif saved_brush != null:
		set_brush(saved_brush)
		saved_brush = null
		brush_updated = true
	if not brush_updated:
		painter.set_brush_node(graph_edit.generator.get_node("Brush"), layers.selected_layer.get_layer_type() == Layer.LAYER_MASK)

var brush_changed_scheduled : bool = false

func on_brush_changed(_p, _v) -> void:
	if !brush_changed_scheduled:
		brush_changed_scheduled = true
		call_deferred("do_on_brush_changed")

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
		brush_view_3d.material.set_shader_parameter("texture_space", paint_engine_button.button_pressed)
		brush_view_3d.material.set_shader_parameter("brush_pos", p)
		brush_view_3d.material.set_shader_parameter("brush_ppos", op)
		brush_view_3d.material.set_shader_parameter("mask_tex", mask)
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

func paint(pos : Vector2, pressure : float = 1.0, tilt : Vector2 = Vector2(0, 0), painting_mode : int = PAINTING_MODE_VIEW, end_of_stroke : bool = false):
	if layers.selected_layer == null or layers.selected_layer.get_layer_type() == Layer.LAYER_PROC:
		return
	if current_tool == MODE_FREEHAND_DOTS or current_tool == MODE_FREEHAND_LINE:
		if ! end_of_stroke and (pos-last_painted_position).length() < brush_spacing_control.value:
			return
		if current_tool == MODE_FREEHAND_DOTS:
			previous_position = null
	do_paint(pos, pressure, tilt, painting_mode, end_of_stroke, layers.selected_layer.get_layer_type() == Layer.LAYER_MASK)
	last_painted_position = pos

var next_paint_to = null
var next_pressure = null

func do_paint(pos : Vector2, pressure : float = 1.0, tilt : Vector2 = Vector2(0, 0), painting_mode : int = PAINTING_MODE_VIEW, end_of_stroke : bool = false, on_mask : bool = false):
	if !end_of_stroke and painting:
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
		brush_size=%BrushSize.value*pressure if %PressureSize.button_pressed else %BrushSize.value,
		brush_opacity=%BrushOpacity.value*pressure if %PressureOpacity.button_pressed else %BrushOpacity.value,
		stroke_length=stroke_length,
		stroke_angle=stroke_angle,
		stroke_seed=stroke_seed,
		erase=eraser_button.button_pressed,
		pressure=pressure,
		tilt=tilt,
		mask_tex=mask,
		use_mask=true,
		fill=false
	}
	match painting_mode:
		PAINTING_MODE_VIEW:
			paint_options.rect_size = view_3d.size
		PAINTING_MODE_TEXTURE_FROM_VIEW:
			var min_size = min(view_3d.size.x, view_3d.size.y)
			paint_options.texture_center = Vector2(0.5, 0.5)
			paint_options.texture_scale = 1.0
			paint_options.rect_size = Vector2(min_size, min_size)
		PAINTING_MODE_TEXTURE:
			paint_options.rect_size = view_2d.size
			paint_options.texture_center = view_2d_center
			paint_options.texture_scale = view_2d_scale
	await painter.paint(paint_options, end_of_stroke, true, on_mask)
	previous_position = pos
	await get_tree().process_frame
	await get_tree().process_frame
	painting = false
	set_need_save()
	# execute recorded paint order if any
	if next_paint_to != null:
		pos = next_paint_to
		next_paint_to = null
		paint(pos, next_pressure, tilt, painting_mode, end_of_stroke)
	if end_of_stroke:
		stroke_seed = randf()

func update_camera():
	var mesh_aabb = painted_mesh.get_aabb()
	var mesh_center = mesh_aabb.position+0.5*mesh_aabb.size
	var mesh_size = mesh_aabb.size.length()
	var cam_to_center = (camera.global_transform.origin-mesh_center).length()
	camera.near = max(0.01, 0.99*(cam_to_center-mesh_size))
	camera.far = 1.01*(cam_to_center+mesh_size)

func update_view():
	update_camera()
	var transform = camera.global_transform.affine_inverse()*painted_mesh.global_transform
	if painter != null:
		painter.update_view(camera.get_camera_projection(), transform, main_view.size)
		# DEBUG: show tex2view texture on model
		#for i in range(10):
		#	await get_tree().process_frame
		#painted_mesh.get_surface_override_material(0).albedo_texture = painter.debug_get_texture(1)
	# Force recalculate brush size parameter
	#_on_Brush_value_changed(brush_parameters.brush_size, "brush_size")

func _on_resized():
	call_deferred("update_view")

# Pick color

func pick_color(pick_position : Vector2, id_map : bool):
	if not id_map and remote_node == null:
		return
	
	var uv : Vector2 = painter.view_to_texture(pick_position)
	if id_map:
		var id_map_image = painter.get_id_map().get_image()
		var id_color : Color = id_map_image.get_pixelv(uv*Vector2(id_map_image.get_size()))
		mask_selection_material.set_shader_parameter("id_selected", true)
		mask_selection_material.set_shader_parameter("id", id_color)
		painter.set_id_mask(id_color)
	else:
		var colors = {}
		var albedo_image = layers.get_albedo_texture().get_image()
		colors["Albedo"] = albedo_image.get_pixelv(uv*Vector2(albedo_image.get_size()))
		
		var metallic_image = layers.get_metallic_texture().get_image()
		colors["Metallic"] = metallic_image.get_pixelv(uv*Vector2(metallic_image.get_size())).r
		
		var roughness_image = layers.get_roughness_texture().get_image()
		colors["Roughness"] = roughness_image.get_pixelv(uv*Vector2(roughness_image.get_size())).r

		var emission_image = layers.get_emission_texture().get_image()
		colors["Emission"] = emission_image.get_pixelv(uv*Vector2(emission_image.get_size()))

		var depth_image = layers.get_depth_texture().get_image()
		colors["Depth"] = depth_image.get_pixelv(uv*Vector2(depth_image.get_size())).r
		
		var occlusion_image = layers.get_occlusion_texture().get_image()
		colors["Occlusion"] = occlusion_image.get_pixelv(uv*Vector2(occlusion_image.get_size())).r

		for p in remote_node.get_parameter_defs():
			if colors.has(p.label):
				remote_node.set_parameter(p.name, colors[p.label])

# Load/save

func dump_texture(texture, filename):
	var image = texture.get_data()
	image.save_png(filename)

func show_file_dialog(file_mode : FileDialog.FileMode, filter, callback):
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = file_mode
	dialog.add_filter(filter)
	var files = await dialog.select_files()
	if files.size() == 1:
		call(callback, files[0])

func load_project(file_name) -> bool:
	var f : FileAccess = FileAccess.open(file_name, FileAccess.READ)
	if f == null:
		return false
	var test_json_conv = JSON.new()
	test_json_conv.parse(f.get_as_text())
	var data = test_json_conv.get_data()
	var mesh : Mesh = MMMeshLoader.load_mesh(data.model)
	if mesh == null:
		return false
	model_path = data.model
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.set_surface_override_material(0, StandardMaterial3D.new())
	set_object(mi)
	set_project_path(file_name)
	if data.has("settings"):
		set_settings(data.settings)
	elif data.has("texture_size"):
		set_settings({ texture_size=int(round(log(data.texture_size)/log(2))) })
	if data.has("idmap"):
		idmap_filename = data.idmap
	layers.load(data, file_name)
	set_need_save(false)
	initialize_layers_history()
	return true

func save() -> bool:
	if save_path != null:
		do_save_project(save_path)
	else:
		save_as()
	return true

func save_as():
	show_file_dialog(FileDialog.FILE_MODE_SAVE_FILE, "*.mmpp;Model painter project", "do_save_project")

func do_save_project(file_name):
	var data = layers.save(file_name)
	data.model = model_path
	data.settings = get_settings()
	if idmap_filename != "":
		data.idmap = idmap_filename
	var file : FileAccess = FileAccess.open(file_name, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))
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
	return [ $Painter, $PaintLayers, self ]

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
			view_2d.material.set_shader_parameter("tex", await p.debug_get_texture(ID))
			return
		ID -= textures_count

# debug

func debug_get_texture_names():
	return [ "Mask" ]

func debug_get_texture(_ID):
	return mask

# Brush options UI

var ignore_button_toggle : bool = false
func _on_Button_toggled(button_pressed : bool, button : String):
	if ignore_button_toggle:
		return
	var panel = $VSplitContainer/HSplitContainer/Painter/Options/OptionsPanel
	if button_pressed:
		var buttons = $VSplitContainer/HSplitContainer/Painter/Options/Buttons
		var shown = false
		for c in panel.get_children():
			c.visible = (button == c.name)
			if c.visible:
				shown = true
		panel.visible = shown
		ignore_button_toggle = true
		for c in buttons.get_children():
			c.button_pressed = (button == c.name)
		ignore_button_toggle = false
		$VSplitContainer/HSplitContainer/Painter/Options.offset_left = -3-$VSplitContainer/HSplitContainer/Painter/Options.get_minimum_size().x
		$VSplitContainer/HSplitContainer/Painter/Options.offset_right = -3
	else:
		panel.visible = false

func _on_Brush_value_changed(value, brush_parameter):
	brush_parameters[brush_parameter] = value
	var params_update : Dictionary = { brush_parameter:value }
	painter_update_brush_params(params_update)

func set_environment(index) -> void:
	var environment_manager = get_node("/root/MainWindow/EnvironmentManager")
	var environment = $VSplitContainer/HSplitContainer/Painter/View/MainView/CameraPosition/CameraRotation1/CameraRotation2/Camera3D.environment
	var sun = $VSplitContainer/HSplitContainer/Painter/View/MainView/Sun
	environment_manager.apply_environment(index, environment, sun)

# Undo/Redo

var stroke_history = { layers={} }

func undoredo_command(command : Dictionary) -> void:
	match command.type:
		"reload_layer_state":
			var layer = command.layer
			var state = stroke_history.layers[layer].history[command.index]
			if layer == layers.selected_layer:
				painter.set_state(state)
			else:
				layer.set_state(state)
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().process_frame
			layers._on_layers_changed()
			stroke_history.layers[layer].current = command.index

func initialize_layer_history(layer):
	if stroke_history.layers.has(layer):
		return
	var channels = {}
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	for c in layer.get_channels():
		var texture = layer.get_channel_texture(c)
		if texture is ViewportTexture:
			var image = texture.get_image()
			texture = ImageTexture.new()
			texture.set_image(image)
		channels[c] = texture
	stroke_history.layers[layer] = { history=[channels], current=0 }

func initialize_layers_history(layer_list = null):
	if layer_list == null:
		for i in range(20):
			await get_tree().process_frame
		layer_list = layers.layers
	for l in layer_list:
		initialize_layer_history(l)
		initialize_layers_history(l.layers)

# Undo/Redo for strokes
func _on_Painter_end_of_stroke(stroke_state):
	var layer = layers.selected_layer
	var layer_history = stroke_history.layers[layer]
	while layer_history.history.size() > layer_history.current+1:
		layer_history.history.pop_back()
	var new_history_item = layer_history.history.back().duplicate()
	# Copy relevant channels into stroke state
	for c in stroke_state.keys():
		if c in layer.get_channels():
			new_history_item[c] = stroke_state[c]
	layer_history.history.push_back(new_history_item)
	var undo_command = { type="reload_layer_state", layer=layer, index=layer_history.current }
	layer_history.current += 1
	var redo_command = { type="reload_layer_state", layer=layer, index=layer_history.current }
	undoredo.add("Paint Stroke", [undo_command], [redo_command])


var last_hsplit_offset : int = 0

func _on_h_split_container_dragged(offset):
	var hsplit_offset : int = $VSplitContainer/HSplitContainer.size.x - offset
	if last_hsplit_offset > hsplit_offset and hsplit_offset < 25:
		$VSplitContainer/HSplitContainer/Painter2D.visible = false
		$VSplitContainer/HSplitContainer/Painter/Show2DPaint.visible = true
	last_hsplit_offset = hsplit_offset

func _on_show_2d_paint_pressed():
	$VSplitContainer/HSplitContainer/Painter2D.visible = true
	$VSplitContainer/HSplitContainer/Painter/Show2DPaint.visible = false
	$VSplitContainer/HSplitContainer.split_offset = $VSplitContainer/HSplitContainer.size.x - 100

var last_vsplit_offset : int = 0

func _on_v_split_container_dragged(offset):
	var vsplit_offset : int = $VSplitContainer.size.y - offset
	if last_vsplit_offset > vsplit_offset and vsplit_offset < 25:
		$VSplitContainer/GraphEdit.visible = false
		$VSplitContainer/HSplitContainer/Painter/ShowBrushGraph.visible = true
	last_vsplit_offset = vsplit_offset

func _on_show_brush_graph_pressed():
	$VSplitContainer/GraphEdit.visible = true
	$VSplitContainer/HSplitContainer/Painter/ShowBrushGraph.visible = false
	$VSplitContainer.split_offset = $VSplitContainer.size.y - 100


func _on_options_panel_minimum_size_changed():
	%OptionsPanel.position.x += %OptionsPanel.size.x-%OptionsPanel.get_combined_minimum_size().x
	%OptionsPanel.size = %OptionsPanel.get_combined_minimum_size()

func _on_mask_selector_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			await load_id_map()
			set_current_tool(MODE_MASK_SELECTOR)
