extends SubViewportContainer


@export var control_target : NodePath
@export var mode : int = 1:
	get:
		return mode
	set(new_value):
		mode = new_value
		$SubViewport/Gizmo.mode = mode
		update_viewport()


@onready var viewport = $SubViewport
@onready var camera_position = $SubViewport/CameraPosition
@onready var camera_rotation1 = $SubViewport/CameraPosition/CameraRotation1
@onready var camera_rotation2 = $SubViewport/CameraPosition/CameraRotation1/CameraRotation2
@onready var camera : Camera3D = $SubViewport/CameraPosition/CameraRotation1/CameraRotation2/Camera3D
@onready var plane : MeshInstance3D = $SubViewport/CameraPosition/CameraRotation1/CameraRotation2/Camera3D/Plane
@onready var gizmo : Node3D = $SubViewport/Gizmo

var generator : MMGenBase = null

var gizmo_is_local = false


func _enter_tree():
	mm_deps.create_buffer("preview_"+str(get_instance_id()), self)

func _ready():
	_on_Preview3D_resized()

func update_viewport():
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func set_generator(g : MMGenBase, o : int = 0, force : bool = false) -> void:
	if is_instance_valid(g) and (force or g != generator):
		generator = g
		var context : MMGenContext = MMGenContext.new()
		var source = g.get_shader_code("uv", o, context)
		if source.output_type == "":
			source = MMGenBase.get_default_generated_shader()
		var material = plane.get_surface_override_material(0)
		var variables : Dictionary = {}
		variables.GENERATED_GLOBALS = "\n".join(PackedStringArray(source.globals))
		variables.GENERATED_INSTANCE = source.defs
		variables.GENERATED_CODE = source.code
		variables.GENERATED_OUTPUT = source.output_values.sdf3d
		var node_prefix = source.output_values.sdf3d.left(source.output_values.sdf3d.find("_"))
		variables.DIST_FCT = node_prefix+"_d"
		variables.COLOR_FCT = node_prefix+"_c"
		variables.INDEX_UNIFORM = "p_"+node_prefix+"_index"
		var shader_code : String = mm_preprocessor.preprocess_file("res://material_maker/windows/sdf_builder/preview_3d.gdshader", variables)
		material = mm_deps.buffer_create_shader_material("preview_"+str(get_instance_id()), MMShaderMaterial.new(material), shader_code)

var setup_controls_filter : String = ""
func setup_controls(filter : String = "") -> void:
	if filter == "previous":
		filter = setup_controls_filter
	else:
		setup_controls_filter = filter

var parent_transform : Transform3D
var local_transform : Transform3D
var euler_2d : Vector3 = Vector3(0, 0, 0)

func update_gizmo_position():
	gizmo.position = (parent_transform*local_transform).origin
	if gizmo_is_local:
		gizmo.transform.basis = Basis.from_euler((parent_transform.basis*local_transform.basis).get_euler())
	else:
		gizmo.transform.basis = Basis.from_euler(euler_2d)

func set_local_transform(t : Transform3D):
	local_transform = t
	update_gizmo_position()

func set_parent_transform(t : Transform3D):
	parent_transform = t
	update_gizmo_position()

func set_2d_orientation(e : Vector3):
	euler_2d = e
	update_gizmo_position()

func _on_Gizmo_translated(_v : Vector3):
	var local_position : Vector3 = parent_transform.affine_inverse() * gizmo.position
	var parameters : Dictionary = {}
	parameters[setup_controls_filter+"_position_x"] = local_position.x
	parameters[setup_controls_filter+"_position_y"] = local_position.y
	parameters[setup_controls_filter+"_position_z"] = local_position.z
	get_node(control_target).set_node_parameters(generator, parameters)
	update_viewport()

func _on_Gizmo_rotated(v, a):
	var axis : Vector3 = parent_transform.affine_inverse().basis * v.normalized()
	var local_rotation : Vector3 = local_transform.basis.rotated(axis, a).get_euler()
	var parameters : Dictionary = {}
	parameters[setup_controls_filter+"_angle_x"] = rad_to_deg(local_rotation.x)
	parameters[setup_controls_filter+"_angle_y"] = rad_to_deg(local_rotation.y)
	parameters[setup_controls_filter+"_angle_z"] = rad_to_deg(local_rotation.z)
	parameters[setup_controls_filter+"_angle"] = rad_to_deg(local_rotation.z)
	get_node(control_target).set_node_parameters(generator, parameters)
	update_viewport()

func on_dep_update_value(_buffer_name, parameter_name, value) -> bool:
	plane.get_surface_override_material(0).set_shader_parameter(parameter_name, value)
	update_viewport()
	return false

func _on_Preview3D_resized():
	if viewport != null:
		viewport.size = size
		update_viewport()

func _input(ev):
	return
	_unhandled_input(ev)
	
func navigation_input(ev) -> bool:
	if ! get_global_rect().has_point(get_global_mouse_position()):
		return false
	if ev is InputEventMouseMotion:
		if ev.button_mask & MOUSE_BUTTON_MASK_MIDDLE != 0:
			if ev.shift_pressed:
				var factor = 0.0025*camera.position.z
				camera_position.translate(-factor*ev.relative.x*camera.global_transform.basis.x)
				camera_position.translate(factor*ev.relative.y*camera.global_transform.basis.y)
			else:
				camera_rotation2.rotate_x(-0.01*ev.relative.y)
				camera_rotation1.rotate_y(-0.01*ev.relative.x)
			return true
	elif ev is InputEventMouseButton:
		if ev.is_command_or_control_pressed():
			if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera.fov += 1
			elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera.fov -= 1
			else:
				return false
			return true
		else:
			var zoom = 0.0
			if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom -= 1.0
			elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom += 1.0
			if zoom != 0.0:
				camera.translate(Vector3(0.0, 0.0, zoom*(1.0 if ev.shift_pressed else 0.1)))
			return true
	return false


func _on_Background_input_event(_camera, event, _position, _normal, _shape_idx):
	if navigation_input(event):
		accept_event()
		update_viewport()

func _on_GizmoButton_toggled(button_pressed):
	gizmo.visible = button_pressed

func _on_LocalButton_toggled(button_pressed):
	gizmo_is_local = button_pressed
	update_gizmo_position()
