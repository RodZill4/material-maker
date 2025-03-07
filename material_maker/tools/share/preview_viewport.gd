extends SubViewport


@onready var camera : Camera3D = $PreviewScene/Pivot/CameraAnchor/Camera3D


func _ready():
	await $PreviewScene/Pivot/Cylinder.update_mesh()
	await $PreviewScene/Pivot/Cube.update_mesh()

func get_materials() -> Array:
	var materials : Array = []
	materials.append($PreviewScene/Pivot/Sphere.get_surface_override_material(0))
	materials.append($PreviewScene/Pivot/Cube.material)
	materials.append($PreviewScene/Pivot/Cylinder.material)
	return materials

func get_preview(index : int) -> ImageTexture:
	camera.transform = Transform3D(Basis(Vector3(1, 0, 0), 0), Vector3(0, 0, 0))
	camera.fov = 30
	camera.near = 0.5
	camera.far = 10
	match index:
		0:
			$PreviewScene/Pivot/Sphere.visible = true
			$PreviewScene/Pivot/Cylinder.visible = false
			$PreviewScene/Pivot/Cube.visible = false
			$PreviewScene/Pivot/Custom.visible = false
			var material : ShaderMaterial = $PreviewScene/Pivot/Sphere.get_surface_override_material(0)
			material.set_shader_parameter("uv1_scale", Vector3(4, 2, 1))
			material.set_shader_parameter("uv1_offset", Vector3(0, 0.5, 0))
			material.set_shader_parameter("depth_offset", 0.8)
		1:
			$PreviewScene/Pivot/Sphere.visible = false
			$PreviewScene/Pivot/Cylinder.visible = true
			$PreviewScene/Pivot/Cube.visible = false
			$PreviewScene/Pivot/Custom.visible = false
			var material : ShaderMaterial = $PreviewScene/Pivot/Cylinder.material
			material.set_shader_parameter("uv1_scale", Vector3(3, 1, 1))
			material.set_shader_parameter("uv1_offset", Vector3(0.5, 0, 0))
			material.set_shader_parameter("depth_offset", 0.8)
		2:
			$PreviewScene/Pivot/Sphere.visible = false
			$PreviewScene/Pivot/Cylinder.visible = false
			$PreviewScene/Pivot/Cube.visible = true
			$PreviewScene/Pivot/Custom.visible = false
			var material : ShaderMaterial = $PreviewScene/Pivot/Cube.material
			material.set_shader_parameter("uv1_scale", Vector3(3, 2, 1))
			material.set_shader_parameter("uv1_offset", Vector3(0, 0, 0))
			material.set_shader_parameter("depth_offset", 0.8)
		3:
			$PreviewScene/Pivot/Sphere.visible = false
			$PreviewScene/Pivot/Cylinder.visible = false
			$PreviewScene/Pivot/Cube.visible = false
			$PreviewScene/Pivot/Custom.visible = true
			var preview_3d_panel : Control = mm_globals.main_window.get_panel("Preview3D")
			var preview_settings : Dictionary = preview_3d_panel.get_preview_settings()
			$PreviewScene/Pivot/Custom.mesh = preview_settings.object_mesh
			$PreviewScene/Pivot/Custom.set_surface_override_material(0, preview_settings.object_material)
			$PreviewScene/Pivot/Custom.global_transform = preview_settings.object_transform
			camera.global_transform = preview_settings.camera_transform
			camera.fov = preview_settings.camera_fov
			camera.near = preview_settings.camera_near
			camera.far = preview_settings.camera_far
			var material : ShaderMaterial = $PreviewScene/Pivot/Cube.material
			material.set_shader_parameter("uv1_scale", Vector3(3, 2, 1))
			material.set_shader_parameter("uv1_offset", Vector3(0, 0, 0))
			material.set_shader_parameter("depth_offset", 0.8)
		_:
			return null
	render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame
	return ImageTexture.create_from_image(get_texture().get_image())
