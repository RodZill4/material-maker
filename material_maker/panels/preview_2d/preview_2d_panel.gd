extends "res://material_maker/panels/preview_2d/preview_2d.gd"

@export var config_var_suffix : String = ""

@export var shader_accumulate : String = "" # (String, MULTILINE)
@export var shader_divide : String = "" # (String, MULTILINE)
# warning-ignore:unused_class_variable
@export var control_target : NodePath

var center : Vector2 = Vector2(0.5, 0.5)
var view_scale : float = 1.2

var view_mode : int = 0

var temporal_aa : bool = false
var temporal_aa_current : bool = false

var current_postprocess_option = 0
const POSTPROCESS_OPTIONS : Array = [
	{ name="None", function="preview_2d(uv)" },
	{ name="Lowres 32x32", function="preview_2d((floor(uv*32.0)+vec2(0.5))/32.0)" },
	{ name="Lowres 64x64", function="preview_2d((floor(uv*64.0)+vec2(0.5))/64.0)" },
	{ name="Lowres 128x128", function="preview_2d((floor(uv*128.0)+vec2(0.5))/128.0)" },
	{ name="Lowres 256x256", function="preview_2d((floor(uv*256.0)+vec2(0.5))/256.0)" },
	{ name="Lowres 512x512", function="preview_2d((floor(uv*512.0)+vec2(0.5))/512.0)" }
]


const VIEW_EXTEND : int = 0
const VIEW_REPEAT : int = 1
const VIEW_CLAMP : int = 2
const VIEW_TEMPORAL_AA : int = 3
const VIEW_TEMPORAL_AA22 : int = 4


func _ready():
	update_shader_options()
	update_view_menu()
	update_Guides_menu()
	update_export_menu()
	update_postprocess_menu()

func update_view_menu() -> void:
	$ContextMenu.add_submenu_item("View", "View")

func update_Guides_menu() -> void:
	$ContextMenu/Guides.clear()
	for s in $Guides.STYLES:
		$ContextMenu/Guides.add_item(s)
	$ContextMenu/Guides.add_submenu_item("Grid", "Grid")
	$ContextMenu/Guides.add_separator()
	$ContextMenu/Guides.add_item("Change color", 1000)
	$ContextMenu.add_submenu_item("Guides", "Guides")
	if mm_globals.has_config("preview"+config_var_suffix+"_view_mode"):
		_on_View_id_pressed(mm_globals.get_config("preview"+config_var_suffix+"_view_mode"))
	if mm_globals.has_config("preview"+config_var_suffix+"_view_postprocess"):
		_on_PostProcess_id_pressed(mm_globals.get_config("preview"+config_var_suffix+"_view_postprocess"))

func update_postprocess_menu() -> void:
	$ContextMenu/PostProcess.clear()
	for o in POSTPROCESS_OPTIONS:
		$ContextMenu/PostProcess.add_item(o.name)
	$ContextMenu.add_submenu_item("Post Process", "PostProcess")

func get_shader_custom_functions():
	return "vec4 preview_2d_postprocessed(vec2 uv) { return %s; }\n" % POSTPROCESS_OPTIONS[current_postprocess_option].function

func set_generator(g : MMGenBase, o : int = 0, force : bool = false) -> void:
	#center = Vector2(0.5, 0.5)
	#view_scale = 1.2
	super.set_generator(g, o, force)
	setup_controls("previous")
	update_shader_options()

func update_material(source):
	temporal_aa_current = temporal_aa
	# Here we could detect $time to disable temporal AA
	if temporal_aa_current:
		do_update_material(source, $Accumulate/Iteration.material, shader_context_defs+shader_accumulate)
		material.gdshader.code = shader_divide
		material.set_shader_parameter("sum", $Accumulate.get_texture())
		start_accumulate()
	else:
		super.update_material(source)
		material.set_shader_parameter("mode", view_mode)
		material.set_shader_parameter("background_color_1", Color(0.4, 0.4, 0.4))
		material.set_shader_parameter("background_color_2", Color(0.6, 0.6, 0.6))

var started : bool = false
var divide : int = 0

func set_temporal_aa(v : bool):
	if v != temporal_aa:
		temporal_aa = v
		if ! temporal_aa:
			# stop AA loop
			started = false
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().process_frame
		set_generator(generator, output, true)
	if temporal_aa:
		material.set_shader_parameter("exponent", 1.0/2.2 if view_mode == VIEW_TEMPORAL_AA22 else 1.0 )

var start_accumulate_trigger : bool = false

func start_accumulate():
	if !temporal_aa_current:
		return
	if !start_accumulate_trigger:
		start_accumulate_trigger = true
		call_deferred("do_start_accumulate")

func do_start_accumulate():
	started = false
	await get_tree().process_frame
	await get_tree().process_frame
	start_accumulate_trigger = false
	$Accumulate/Iteration.material.set_shader_parameter("sum", $Accumulate.get_texture())
	$Accumulate/Iteration.material.set_shader_parameter("clear", true)
	divide = 1
	started = true
	while started:
		$Accumulate.render_target_update_mode = SubViewport.UPDATE_ONCE
		$Accumulate.update_worlds()
		material.set_shader_parameter("divide", divide)
		await get_tree().process_frame
		await get_tree().process_frame
		$Accumulate/Iteration.material.set_shader_parameter("clear", false)
		divide += 1
		if divide > 100000:
			started = false
			break

func get_preview_material():
	return $Accumulate/Iteration.material if temporal_aa_current else material

func on_dep_update_value(buffer_name, parameter_name, value) -> bool:
	super.on_dep_update_value(buffer_name, parameter_name, value)
	start_accumulate()
	return false

var setup_controls_filter : String = ""
func setup_controls(filter : String = "") -> void:
	if filter == "previous":
		filter = setup_controls_filter
	else:
		setup_controls_filter = filter
	var param_defs = []
	if is_instance_valid(generator):
		if filter != "":
			param_defs = generator.get_filtered_parameter_defs(filter)
		else:
			param_defs = generator.get_parameter_defs() 
	for c in get_children():
		if c.has_method("setup_control"):
			c.setup_control(generator, param_defs)

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
		value = center_transform * value
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
		value = center_transform.affine_inverse() * value
	return value

func update_shader_options() -> void:
	on_resized()

func on_resized() -> void:
	super.on_resized()
	$Accumulate.size = size
	$Accumulate/Iteration.position = Vector2(0, 0)
	$Accumulate/Iteration.size = size
	material.set_shader_parameter("preview_2d_center", center)
	material.set_shader_parameter("preview_2d_scale", view_scale)
	$Accumulate/Iteration.material.set_shader_parameter("preview_2d_center", center)
	$Accumulate/Iteration.material.set_shader_parameter("preview_2d_scale", view_scale)
	$Accumulate/Iteration.material.set_shader_parameter("preview_2d_size", size)
	setup_controls("previous")
	$Guides.queue_redraw()
	start_accumulate()

var dragging : bool = false
var zooming : bool = false

func _on_gui_input(event):
	var need_update : bool = false
	var new_center : Vector2 = center
	var multiplier : float = min(size.x, size.y)
	var image_rect : Rect2 = get_global_rect()
	var offset_from_center : Vector2 = get_global_mouse_position()-(image_rect.position+0.5*image_rect.size)
	var new_scale : float = view_scale
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				new_scale = min(new_scale*1.05, 5.0)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				new_scale = max(new_scale*0.95, 0.005)
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				dragging = true
			elif event.button_index == MOUSE_BUTTON_LEFT:
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
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			$ContextMenu.popup(Rect2(get_global_mouse_position(), Vector2(0, 0)))
	if need_update:
		on_resized()

func _on_ContextMenu_id_pressed(id) -> void:
	match id:
		0:
			center = Vector2(0.5, 0.5)
			view_scale = 1.2
			update_shader_options()
		MENU_EXPORT_AGAIN:
			export_again()
		MENU_EXPORT_ANIMATION:
			export_animation()
		_:
			print("unsupported id "+str(id))

func _on_View_id_pressed(id):
	if id == view_mode:
		return
	$ContextMenu/View.set_item_checked(view_mode, false)
	view_mode = id
	set_temporal_aa(view_mode >= VIEW_TEMPORAL_AA)
	$ContextMenu/View.set_item_checked(view_mode, true)
	material.set_shader_parameter("mode", view_mode)
	mm_globals.set_config("preview"+config_var_suffix+"_view_mode", view_mode)

func _on_Guides_id_pressed(id):
	if id == 1000:
		var color_picker_popup = preload("res://material_maker/widgets/color_picker_popup/color_picker_popup.tscn").instantiate()
		add_child(color_picker_popup)
		var color_picker = color_picker_popup.get_node("ColorPicker")
		color_picker.color = $Guides.color
		color_picker.connect("color_changed",Callable($Guides,"set_color"))
		color_picker_popup.position = get_global_mouse_position()
		color_picker_popup.connect("popup_hide",Callable(color_picker_popup,"queue_free"))
		color_picker_popup.popup()
	else:
		$Guides.style = id

func _on_GridSize_value_changed(value):
	$Guides.show_grid(value)


func _on_PostProcess_id_pressed(id):
	current_postprocess_option = id
	set_generator(generator, output, true)
	mm_globals.set_config("preview"+config_var_suffix+"_view_postprocess", current_postprocess_option)

func _on_Preview2D_mouse_entered():
	mm_globals.set_tip_text("#MMB: Pan, Mouse wheel: Zoom, #RMB: Context menu", 3)
