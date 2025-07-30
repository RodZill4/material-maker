extends "res://material_maker/panels/preview_2d/preview_2d.gd"


enum Modes {CUSTOM_PREVIEW=0, PREVIEW_1=1, PREVIEW_2=2}
var preview_mode := Modes.CUSTOM_PREVIEW:
	set(preview):
		preview_mode = preview
		if preview_mode == Modes.PREVIEW_2:
			config_var_suffix = "_2"
		else:
			config_var_suffix = ""


@export var config_var_suffix : String = ""

@export_multiline var shader_accumulate : String = "" # (String, MULTILINE)
@export_multiline var shader_divide : String = "" # (String, MULTILINE)
@export var control_target : NodePath

var center : Vector2 = Vector2(0.5, 0.5)
var view_scale : float = 1.2

var view_mode : int = 2:
	set(v):
		if v == view_mode:
			return
		view_mode = v
		material.set_shader_parameter("mode", view_mode)
		mm_globals.set_config("preview"+config_var_suffix+"_view_mode", view_mode)

var view_filter : int = 0:
	set(v):
		if v == view_filter:
			return
		view_filter = v
		set_generator(generator, output, true)
		mm_globals.set_config("preview"+config_var_suffix+"_view_postprocess", view_filter)

const POSTPROCESS_OPTIONS : Array = [
	{ name="None", function="preview_2d(uv)" },
	{ name="Lowres 32x32", function="preview_2d((floor(uv*32.0)+vec2(0.5))/32.0)" },
	{ name="Lowres 64x64", function="preview_2d((floor(uv*64.0)+vec2(0.5))/64.0)" },
	{ name="Lowres 128x128", function="preview_2d((floor(uv*128.0)+vec2(0.5))/128.0)" },
	{ name="Lowres 256x256", function="preview_2d((floor(uv*256.0)+vec2(0.5))/256.0)" },
	{ name="Lowres 512x512", function="preview_2d((floor(uv*512.0)+vec2(0.5))/512.0)" }
]


func _ready():
	var content_scale_factor = mm_globals.get_window().content_scale_factor
	%GuidesColor.get_popup().content_scale_factor = content_scale_factor
	%GuidesColor.get_popup().min_size = %GuidesColor.get_popup().get_contents_minimum_size() * content_scale_factor

	%ResetViewButton.tooltip_text += " (%s)" % [ %ResetViewButton.shortcut.get_as_text() ]

	clear()
	reset_view()
	if mm_globals.has_config("preview"+config_var_suffix+"_view_mode"):
		view_mode = mm_globals.get_config("preview"+config_var_suffix+"_view_mode")
	if mm_globals.has_config("preview"+config_var_suffix+"_view_postprocess"):
		view_filter = mm_globals.get_config("preview"+config_var_suffix+"_view_postprocess")


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		update_shader_options()


func clear() -> void:
	set_generator(null)
	%PreviewLocked.button_pressed = false

	%PreviewLocked.visible = false
	%ExportMenu.visible = preview_mode != Modes.CUSTOM_PREVIEW


func get_shader_custom_functions():
	return "vec4 preview_2d_postprocessed(vec2 uv) { return %s; }\n" % POSTPROCESS_OPTIONS[view_filter].function


func set_generator(g : MMGenBase, o : int = 0, force : bool = false) -> void:
	super.set_generator(g, o, force)
	update_shader_options()

	%PreviewLocked.visible = g != null and preview_mode != Modes.CUSTOM_PREVIEW

	if preview_mode != Modes.CUSTOM_PREVIEW and is_inside_tree():
		var current_graph: MMGraphEdit = mm_globals.main_window.get_current_graph_edit()
		if current_graph:
			%PreviewLocked.button_pressed = current_graph.locked_preview[preview_mode-1] != null


func update_material(source):
	super.update_material(source)
	material.set_shader_parameter("mode", view_mode)
	material.set_shader_parameter("background_color", get_theme_stylebox("panel", "MM_PanelBackground").bg_color)
	material.set_shader_parameter("background_color_1", Color(0.4, 0.4, 0.4))
	material.set_shader_parameter("background_color_2", Color(0.6, 0.6, 0.6))


func set_preview_shader_parameter(parameter_name, value):
	material.set_shader_parameter(parameter_name, value)

func on_dep_update_value(buffer_name, parameter_name, value) -> bool:
	super.on_dep_update_value(buffer_name, parameter_name, value)
	return false


var setup_controls_filter : String = ""
func setup_controls(filter : String = "") -> void:
	if filter == "previous":
		filter = setup_controls_filter
	else:
		setup_controls_filter = filter
	if is_instance_valid(generator):
		var param_defs = []
		if filter != "":
			param_defs = generator.get_filtered_parameter_defs(filter)
		else:
			param_defs = generator.get_parameter_defs()
		var float_param_defs = []
		var complex_param_defs = []
		for p in param_defs:
			if p.type == "polygon" or  p.type == "polyline" or  p.type == "splines" or  p.type == "pixels" or  p.type == "lattice":
				complex_param_defs.append(p)
			else:
				float_param_defs.append(p)
		for c in get_children():
			if c.has_method("set_view_rect"):
				var s : float = min(size.x, size.y)/view_scale
				c.set_view_rect(0.5*size-center*s, Vector2(s, s))
			if c == $PolygonEditor or c == $SplinesEditor or c == $PixelsEditor or c == $LatticeEditor:
				continue
			if c.has_method("setup_control"):
				c.setup_control(generator, float_param_defs)
		var edited_parameter : Array = []
		match complex_param_defs.size():
			0:
				%ComplexParameters.clear()
				%ComplexParameters.visible = false
			1:
				edited_parameter = [complex_param_defs[0]]
				%ComplexParameters.clear()
				%ComplexParameters.visible = false
			_:
				if %ComplexParameters.item_count == complex_param_defs.size():
					var changed : bool = false
					for i in %ComplexParameters.item_count:
						if %ComplexParameters.get_item_text(i) != complex_param_defs[i].name:
							changed = true
					if not changed:
						return
				edited_parameter = [complex_param_defs[0]]
				%ComplexParameters.clear()
				for i in range(complex_param_defs.size()):
					%ComplexParameters.add_item(complex_param_defs[i].name, i)
					%ComplexParameters.set_item_metadata(i, complex_param_defs[i])
				%ComplexParameters.selected = 0
				%ComplexParameters.visible = true

		for e in [ $PolygonEditor, $SplinesEditor, $PixelsEditor, $LatticeEditor ]:
			e.setup_control(generator, edited_parameter)
	else:
		%ComplexParameters.visible = false
		for c in get_children():
			if c.has_method("setup_control"):
				c.setup_control(null, [])
		for e in [ $PolygonEditor, $SplinesEditor, $PixelsEditor, $LatticeEditor ]:
			e.setup_control(null, [])


func _on_complex_parameters_item_selected(index):
	var parameter = %ComplexParameters.get_item_metadata(index)
	for e in [ $PolygonEditor, $SplinesEditor, $PixelsEditor, $LatticeEditor ]:
		e.setup_control(generator, [ parameter ])


var center_transform : Transform2D = Transform2D(0, Vector2(0.0, 0.0))
var local_rotate : float = 0.0
var local_scale : float = 1.0


func set_center_transform(t):
	center_transform = t


func set_local_transform(r : float, s : float):
	local_rotate = r
	local_scale = s


func value_to_pos(value : Vector2, apply_parent_transform : bool = false, apply_local_transform : bool = false) -> Vector2:
	if apply_parent_transform:
		value = center_transform * (value)
	if apply_local_transform:
		value = value.rotated(deg_to_rad(local_rotate))
		value *= local_scale
	return (value-center+Vector2(0.5, 0.5))*min(size.x, size.y)/view_scale+0.5*size


func pos_to_value(pos : Vector2, apply_parent_transform : bool = false, apply_local_transform : bool = false) -> Vector2:
	var value = (pos-0.5*size)*view_scale/min(size.x, size.y)+center-Vector2(0.5, 0.5)
	if apply_local_transform:
		value /= local_scale
		value = value.rotated(-deg_to_rad(local_rotate))
	if apply_parent_transform:
		value = center_transform.affine_inverse() * (value)
	return value

func update_shader_options() -> void:
	on_resized()


func on_resized() -> void:
	super.on_resized()
	material.set_shader_parameter("background_color", get_theme_stylebox("panel", "MM_PanelBackground").bg_color)
	material.set_shader_parameter("preview_2d_center", center)
	material.set_shader_parameter("preview_2d_scale", view_scale)
	setup_controls("previous")
	$Guides.queue_redraw()


var dragging : bool = false
var zooming : bool = false

func _input(event):
	if event.is_pressed():
		mm_globals.propagate_shortcuts(self, event)

func _on_gui_input(event):
	var need_update : bool = false
	var new_center : Vector2 = center
	var multiplier : float = min(size.x, size.y)
	var image_rect : Rect2 = get_global_rect()
	var offset_from_center : Vector2 = get_viewport().get_mouse_position()-(image_rect.position+0.5*image_rect.size)
	var new_scale : float = view_scale
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_DOWN:
					new_scale = min(new_scale*1.05, 5.0)
				MOUSE_BUTTON_WHEEL_UP:
					new_scale = max(new_scale*0.95, 0.005)
				MOUSE_BUTTON_MIDDLE:
					dragging = true
				MOUSE_BUTTON_LEFT:
					if event.shift_pressed:
						dragging = true
					elif event.is_command_or_control_pressed():
						zooming = true
		else:
			dragging = false
			zooming = false
	elif event is InputEventMouseMotion:
		if dragging:
			new_center = center-event.relative*view_scale/multiplier
		elif zooming:
			new_scale = clamp(new_scale*(1.0+0.01*event.relative.y), 0.005, 5.0)
	elif event is InputEventPanGesture:
		new_center = center-event.delta*10.0*view_scale/multiplier
	elif event is InputEventMagnifyGesture:
		new_scale = clamp(new_scale/event.factor, 0.005, 5.0)
	if new_scale != view_scale:
		new_center = center+offset_from_center*(view_scale-new_scale)/multiplier
		view_scale = new_scale
		need_update = true
	if new_center != center:
		center.x = clamp(new_center.x, 0.0, 1.0)
		center.y = clamp(new_center.y, 0.0, 1.0)
		need_update = true
	if need_update:
		on_resized()


#region MENUS

func add_menu_bar(menu_bar:Control, editor:Control) -> void:
	%MenuBar.get_child(0).add_child(menu_bar)
	editor.visibility_changed.connect(func(): menu_bar.visible = editor.visible)
	menu_bar.visible = editor.visible


#region VIEW MENU METHODS

func reset_view() -> void:
	center = Vector2(0.5, 0.5)
	view_scale = 1.2
	update_shader_options()

#endregion


func _on_Preview2D_mouse_entered():
	mm_globals.set_tip_text("#MMB: Pan, Mouse wheel: Zoom", 3)


func _on_preview_locked_toggled(toggled_on: bool) -> void:
	if preview_mode == Modes.CUSTOM_PREVIEW:
		return

	var current_graph: MMGraphEdit = find_parent("MainWindow").get_current_graph_edit()
	if current_graph.locked_preview[preview_mode-1] != null and toggled_on:
		return
	if current_graph.locked_preview[preview_mode-1] == null and not toggled_on:
		return
	var prev = current_graph.get_current_preview(preview_mode-1)
	if not prev:
		return
	current_graph.set_current_preview(preview_mode-1, prev.node, prev.output_index, toggled_on, not toggled_on)
