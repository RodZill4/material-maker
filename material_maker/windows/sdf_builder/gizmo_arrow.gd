@tool
extends Node3D

@export var material : Material : set = set_material
@export_enum("Full", "ArrowOnly", "TorusOnly", "Nothing") var mode : int = 0:
	get:
		return mode
	set(new_value):
		mode = new_value
		match mode:
			0:
				$Arrow.visible = true
				$TranslateArea.visible = true
				$Torus.visible = true
				$RotateArea.visible = true
			1:
				$Arrow.visible = true
				$TranslateArea.visible = true
				$Torus.visible = false
				$RotateArea.visible = false
			2:
				$Arrow.visible = false
				$TranslateArea.visible = false
				$Torus.visible = true
				$RotateArea.visible = true
			_:
				$Arrow.visible = false
				$TranslateArea.visible = false
				$Torus.visible = false
				$RotateArea.visible = false


signal move(v)
signal rotate(v, a)


func _ready():
	set_material(material)

func set_material(m):
	material = m
	if is_inside_tree():
		$Arrow.set_surface_override_material(0, material)
		$Torus.set_surface_override_material(0, material)

func _on_TranslateArea_input_event(camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		$Arrow.get_surface_override_material(0).set_shader_parameter("highlight", 0.1 if event.pressed else 0.0)
	elif event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		var origin : Vector3 = global_transform * Vector3(0, 0, 0)
		var end : Vector3 = global_transform * Vector3(1, 0, 0)
		var direction_2d : Vector2 = camera.unproject_position(end) - camera.unproject_position(origin)
		var direction_2d_length2 : float = direction_2d.length_squared()
		if direction_2d_length2 != 0:
			var amount : float = event.relative.dot(direction_2d)/direction_2d_length2
			emit_signal("move", amount * (global_transform.basis * Vector3(1, 0, 0)))

var rotate_direction_2d : Vector2
func _on_RotateArea_input_event(camera, event, position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		$Torus.get_surface_override_material(0).set_shader_parameter("highlight", 0.1 if event.pressed else 0.0)
		if event.pressed:
			var tangent = (position-global_transform.origin).cross(global_transform.basis * Vector3(1.0, 0.0, 0.0))
			var end : Vector3 = position+tangent
			rotate_direction_2d = camera.unproject_position(end) - camera.unproject_position(position)
	elif event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		var rotate_direction_2d_length2 : float = rotate_direction_2d.length_squared()
		if rotate_direction_2d_length2 != 0:
			var amount : float = -event.relative.dot(rotate_direction_2d)/rotate_direction_2d_length2
			emit_signal("rotate", global_transform.basis * Vector3(1, 0, 0), amount)
