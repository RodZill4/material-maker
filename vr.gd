extends Spatial

onready var ovr_init_config
onready var ovr_performance

func _ready():
	var interface = ARVRServer.find_interface("OVRMobile")
	if interface:
		ovr_init_config = preload("res://addons/godot_ovrmobile/OvrInitConfig.gdns").new()
		ovr_init_config.set_render_target_size_multiplier(1)
		if interface.initialize():
			get_viewport().arvr = true
		ovr_performance = preload("res://addons/godot_ovrmobile/OvrPerformance.gdns").new()
		$ARVROrigin/ARVRCamera.current = true
		yield(get_tree(), "idle_frame")
		ovr_performance.set_clock_levels(1, 1)
		ovr_performance.set_extra_latency_mode(1)
	set_process_unhandled_input(true)

var collider

func _process(delta):
	collider = $ARVROrigin/RightHand/RayCast.get_collider()
	var distance = 0.5
	if collider != null:
		var collision_point = $ARVROrigin/RightHand/RayCast.get_collision_point()
		distance = (collision_point-$ARVROrigin/RightHand/RayCast.global_transform.origin).length()
		$ARVROrigin/RightHand/RayCast/Ray.get_surface_material(0).albedo_color = Color(1.0, 0.0, 0.0)
		if collider.has_method("ui_raycast_hit_event"):
			collider.ui_raycast_hit_event(collision_point, false, false)
	else:
		$ARVROrigin/RightHand/RayCast/Ray.get_surface_material(0).albedo_color = Color(1.0, 1.0, 1.0)
	$ARVROrigin/RightHand/RayCast/Ray.translation.x = -0.5*distance
	$ARVROrigin/RightHand/RayCast/Ray.mesh.height = distance

func _unhandled_input(event):
	if event is InputEventJoypadButton:
		match event.device:
			0:
				match event.button_index:
					7:
						pass
					1:
						pass
					15:
						pass
					2:
						pass
			1:
				match event.button_index:
					15:
						if collider != null:
							var collision_point = $ARVROrigin/RightHand/RayCast.get_collision_point()
							if collider.has_method("ui_raycast_hit_event"):
								collider.ui_raycast_hit_event(collision_point, event.pressed, !event.pressed)
					2:
						pass
	elif event is InputEventJoypadMotion:
		match event.device:
			0:
				match event.axis:
					0:
						pass
					1:
						pass
			1:
				match event.axis:
					0:
						pass
					1:
						pass
