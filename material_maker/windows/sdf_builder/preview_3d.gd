extends ViewportContainer

onready var viewport = $Viewport
onready var camera_position = $Viewport/CameraPosition
onready var camera_rotation1 = $Viewport/CameraPosition/CameraRotation1
onready var camera_rotation2 = $Viewport/CameraPosition/CameraRotation1/CameraRotation2
onready var camera : Camera = $Viewport/CameraPosition/CameraRotation1/CameraRotation2/Camera
onready var plane : MeshInstance = $Viewport/CameraPosition/CameraRotation1/CameraRotation2/Camera/Plane

func _ready():
	_on_Preview3D_resized()

func set_generator(g : MMGenBase, o : int = 0, force : bool = false) -> void:
	if is_instance_valid(g):
		var context : MMGenContext = MMGenContext.new()
		var source = g.get_shader_code("uv", o, context)
		assert(!(source is GDScriptFunctionState))
		if source.empty():
			source = MMGenBase.DEFAULT_GENERATED_SHADER
		var material = plane.get_surface_material(0)
		var variables : Dictionary = {}
		variables.GENERATED_GLOBALS = PoolStringArray(source.globals).join("\n")
		variables.GENERATED_INSTANCE = source.defs
		variables.GENERATED_CODE = source.code
		variables.GENERATED_OUTPUT = source.sdf3d
		material.shader.code = mm_preprocessor.preprocess_file("res://material_maker/windows/sdf_builder/preview_3d.shader", variables)

func setup_controls(filter : String = "") -> void:
	pass

func on_float_parameters_changed(parameter_changes : Dictionary) -> bool:
	var return_value : bool = false
	var m : ShaderMaterial = plane.get_surface_material(0)
	for n in parameter_changes.keys():
		for p in VisualServer.shader_get_param_list(m.shader.get_rid()):
			if p.name == n:
				return_value = true
				m.set_shader_param(n, parameter_changes[n])
				break
	return return_value

func _on_Preview3D_resized():
	if viewport != null:
		viewport.size = rect_size

func _input(ev):
	_unhandled_input(ev)
	
func navigation_input(ev) -> bool:
	if ev is InputEventMouseMotion:
		if ev.button_mask & BUTTON_MASK_MIDDLE != 0:
			if ev.shift:
				var factor = 0.0025*camera.translation.z
				camera_position.translate(-factor*ev.relative.x*camera.global_transform.basis.x)
				camera_position.translate(factor*ev.relative.y*camera.global_transform.basis.y)
			else:
				camera_rotation2.rotate_x(-0.01*ev.relative.y)
				camera_rotation1.rotate_y(-0.01*ev.relative.x)
			return true
	elif ev is InputEventMouseButton:
		if ev.control:
			if ev.button_index == BUTTON_WHEEL_UP:
				camera.fov += 1
			elif ev.button_index == BUTTON_WHEEL_DOWN:
				camera.fov -= 1
			else:
				return false
			return true
		else:
			var zoom = 0.0
			if ev.button_index == BUTTON_WHEEL_UP:
				zoom -= 1.0
			elif ev.button_index == BUTTON_WHEEL_DOWN:
				zoom += 1.0
			if zoom != 0.0:
				camera.translate(Vector3(0.0, 0.0, zoom*(1.0 if ev.shift else 0.1)))
			return true
	return false

func _on_Background_input_event(camera, event, position, normal, shape_idx):
	if navigation_input(event):
		accept_event()
