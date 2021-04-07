extends Viewport

export(ShaderMaterial) var mesh_normal_material
export(ShaderMaterial) var inv_uv_material
export(ShaderMaterial) var white_material
export(ShaderMaterial) var curvature_material
export(ShaderMaterial) var ao_material
export(ShaderMaterial) var denoise_pass
export(ShaderMaterial) var dilate_pass1
export(ShaderMaterial) var dilate_pass2
export(ShaderMaterial) var seams_pass1
export(ShaderMaterial) var seams_pass2

func _ready():
	pass

func gen(mesh: Mesh, map : String, renderer_method : String, arguments : Array, map_size = 512) -> void:
	var bake_passes = {
		mesh_normal = { first=mesh_normal_material, second=dilate_pass1, third=dilate_pass2 },
		inv_uv =      { first=inv_uv_material, second=dilate_pass1, third=dilate_pass2 },
		curvature =   { first=curvature_material, second=dilate_pass1, third=dilate_pass2 },
		thickness =   { first=ao_material, second=dilate_pass1, third=dilate_pass2, map_name="Thickness" },
		ao =          { first=ao_material, second=dilate_pass1, third=dilate_pass2, map_name="Ambient Occlusion" },
		seams =       { first=white_material, second=seams_pass1, third=seams_pass2 }
	}
	var passes = bake_passes[map]
	size = Vector2(map_size, map_size)
	if map == "curvature":
		$MeshInstance.mesh = $CurvatureGenerator.generate(mesh)
	else:
		$MeshInstance.mesh = mesh
	$MeshInstance.set_surface_material(0, passes.first)

	var aabb = $MeshInstance.get_aabb()
	if map in ["ao", "thickness"]:
		var main_window = mm_globals.get_main_window()
		var ray_count = main_window.get_config("bake_ray_count")
		var ao_ray_dist = main_window.get_config("bake_ao_ray_dist")
		var denoise_radius = main_window.get_config("bake_denoise_radius")
		var progress_dialog = preload("res://material_maker/windows/progress_window/progress_window.tscn").instance()
		progress_dialog.set_text("Generating "+passes.map_name+" map")
		progress_dialog.set_progress(0)
		main_window.add_child(progress_dialog)
		var ray_distance = ao_ray_dist
		if map == "thickness":
			ray_distance = -aabb.size.length()
		var bvh_data: ImageTexture = $BVHGenerator.generate(mesh)
		ao_material.set_shader_param("bvh_data", bvh_data)
		ao_material.set_shader_param("max_dist", ray_distance)
		for i in ray_count:
			progress_dialog.set_progress(float(i)/ray_count)
			ao_material.set_shader_param("iteration", i+1)
			render_target_update_mode = Viewport.UPDATE_ONCE
			yield(get_tree(), "idle_frame")
		$MeshInstance.set_surface_material(0, denoise_pass)
		denoise_pass.set_shader_param("size", map_size)
		denoise_pass.set_shader_param("radius", denoise_radius)
		render_target_update_mode = Viewport.UPDATE_ONCE
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		progress_dialog.queue_free()
	else:
		inv_uv_material.set_shader_param("position", aabb.position)
		inv_uv_material.set_shader_param("size", aabb.size)
		render_target_update_mode = Viewport.UPDATE_ONCE
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")

	passes.second.set_shader_param("tex", get_texture())
	passes.second.set_shader_param("size", map_size)
	var renderer = mm_renderer.request(self)
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	renderer = renderer.render_material(self, passes.second, map_size)
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	var t : ImageTexture = ImageTexture.new()
	renderer.copy_to_texture(t)
	passes.third.set_shader_param("tex", t)
	passes.third.set_shader_param("size", map_size)
	renderer = renderer.render_material(self, passes.third, map_size)
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	renderer.callv(renderer_method, arguments)
	renderer.release(self)
