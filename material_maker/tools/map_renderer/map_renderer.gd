extends Viewport

export(ShaderMaterial) var mesh_normal_material
export(ShaderMaterial) var mesh_tangent_material
export(ShaderMaterial) var inv_uv_material
export(ShaderMaterial) var white_material
export(ShaderMaterial) var curvature_material
export(ShaderMaterial) var ao_material
export(ShaderMaterial) var thickness_material
export(ShaderMaterial) var normal_hp_lp_material
export(ShaderMaterial) var depth_hp_lp_material
export(ShaderMaterial) var depth_normals_hp_lp_material
export(ShaderMaterial) var worldnormal_hp_lp_material
export(ShaderMaterial) var ao_hp_lp_material
export(ShaderMaterial) var denoise_pass
export(ShaderMaterial) var dilate_pass1
export(ShaderMaterial) var dilate_pass2
export(ShaderMaterial) var seams_pass1
export(ShaderMaterial) var seams_pass2

func _ready():
	pass


func store_bhv_cache(bhv_texture: ImageTexture, location: String) -> void:
	#TODO: maybe add some information about bvh_tree cache version & stored vertex data
	var file = File.new()
	file.open(location, File.WRITE)
	file.store_var(bhv_texture.get_data(), true)
	file.close()


func load_bvh_cache(location: String) -> ImageTexture:
	var file = File.new()
	var img_tex = ImageTexture.new()
	if not file.file_exists(location):
		return null
	file.open(location, File.READ)
	var data = file.get_var(true)
	img_tex.create_from_image(data, 0)
	file.close()
	return img_tex


func get_bvh(location: String) -> ImageTexture:
	var bvh_cache_location = location + ".bvh_cache"
	var bvh_cache := load_bvh_cache(bvh_cache_location)
	if bvh_cache != null:
		return bvh_cache
	#bvh tree doesnt exists so generate one & store in cache file
	var obj_loader = preload("res://material_maker/tools/obj_loader/obj_loader.gd").new()
	add_child(obj_loader)
	var bvh_mesh: Mesh = obj_loader.load_obj_file(location)
	obj_loader.queue_free()
	var bvh_data: ImageTexture = $BVHGenerator.generate(bvh_mesh, true)
	store_bhv_cache(bvh_data, bvh_cache_location)
	return bvh_data


func _close_vertex(vert: Vector3) -> Vector3:
	return Vector3(
		stepify(vert.x, 0.01),
		stepify(vert.y, 0.01),
		stepify(vert.z, 0.01)
	)


func pack_normal(normal: Vector3) -> Color:
	normal = normal/2.0 + Vector3(0.5, 0.5, 0.5);
	normal.x = clamp(normal.x, 0.0,1.0)
	normal.y = clamp(normal.y, 0.0,1.0)
	normal.z = clamp(normal.z, 0.0,1.0)
	return Color(normal.x, normal.y, normal.z)


func add_smooth_normals_in_color(mesh: Mesh) -> Mesh:
	var mdt := MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	var vertex_normals := {}
	for i in range(mdt.get_vertex_count()):
		var vertex = _close_vertex(mdt.get_vertex(i))
		if not vertex in vertex_normals:
			vertex_normals[vertex] = {"acc": Vector3.ZERO,"cnt": 0}
		vertex_normals[vertex]["acc"] += mdt.get_vertex_normal(i)
		vertex_normals[vertex]["cnt"] += 1
	for i in range(mdt.get_vertex_count()):
		var vertex := _close_vertex(mdt.get_vertex(i))
		var smooth_normal: Vector3 = vertex_normals[vertex]["acc"]/vertex_normals[vertex]["cnt"]
		mdt.set_vertex_color(i,pack_normal(smooth_normal))
	mesh.surface_remove(0)
	mdt.commit_to_surface(mesh)
	return mesh


func add_normals_in_color(mesh: Mesh) -> Mesh:
	var mdt := MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	for i in range(mdt.get_vertex_count()):
		var vertex := _close_vertex(mdt.get_vertex(i))
	#	# Save your change.
		var normal: Vector3 = mdt.get_vertex_normal(i)
		mdt.set_vertex_color(i,pack_normal(normal))
	mesh.surface_remove(0)
	mdt.commit_to_surface(mesh)
	return mesh


func get_hp_model_path() -> String:
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
	var main_window = get_node("/root/MainWindow")
	main_window.add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.obj;OBJ model File")
	if get_node("/root/MainWindow").config_cache.has_section_key("path", "mesh"):
		dialog.current_dir = get_node("/root/MainWindow").config_cache.get_value("path", "mesh")
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() == 1:
		return files[0]
	return null


func gen_hp_lp(lp_mesh: Mesh, hp_mesh_path: String, map : String, renderer_method : String, arguments : Array, map_size = 512) -> void:
	var bakers= {
		hp_lp_normal = { baker=normal_hp_lp_material, passes=[dilate_pass1, dilate_pass2], map_name="Normal" },
		hp_lp_depth = { baker=depth_hp_lp_material, passes=[dilate_pass1, dilate_pass2], map_name="Depth" },
		hp_lp_worldnormal = { baker=worldnormal_hp_lp_material, passes=[dilate_pass1, dilate_pass2], map_name="World Normal" },
		hp_lp_ao = { baker=ao_hp_lp_material, passes=[dilate_pass1, dilate_pass2], map_name="AO", dn_prepass=true, iterative=true, denoise=true }
	}
	if hp_mesh_path == null or lp_mesh == null:
		return
	var main_window = get_node("/root/MainWindow")
	var progress_dialog = preload("res://material_maker/windows/progress_window/progress_window.tscn").instance()
	progress_dialog.set_text("Generating bvh tree... ")
	progress_dialog.set_progress(0)
	main_window.add_child(progress_dialog)
	var bvh_data: ImageTexture = get_bvh(hp_mesh_path)
	var baker_data = bakers[map]
	var local_lp_mesh := lp_mesh.duplicate()
	var depth_prepass_texture: ImageTexture = ImageTexture.new()

	#TODO those settngs should came from dedicated UI
	var use_smooth_cage = main_window.get_config("bake_smooth_cage")
	var cage_offset = main_window.get_config("bake_cage_f_distance")
	#notice "-" as we move form lp cage to hp
	var cage_depth = -(cage_offset + main_window.get_config("bake_cage_r_distance"))
	var ao_ray_dist = main_window.get_config("bake_ao_ray_dist")
	var ao_ray_bias = main_window.get_config("bake_ao_ray_bias")
	var ray_count = main_window.get_config("bake_ray_count")
	var denoise_radius = main_window.get_config("bake_denoise_radius")
	if not baker_data.has("iterative"):
		ray_count = 1

	if use_smooth_cage:
		add_smooth_normals_in_color(local_lp_mesh)
	else:
		add_normals_in_color(local_lp_mesh)
	$MeshInstance.mesh = local_lp_mesh

	if baker_data.has("dn_prepass"):
		progress_dialog.set_text("Generating depth pre-pass map")
		$MeshInstance.set_surface_material(0, depth_normals_hp_lp_material)
		depth_normals_hp_lp_material.set_shader_param("bvh_data", bvh_data)
		depth_normals_hp_lp_material.set_shader_param("cage_depth", cage_depth)
		depth_normals_hp_lp_material.set_shader_param("cage_offset", cage_offset)
		render_target_update_mode = Viewport.UPDATE_ONCE
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		var image: Image = get_texture().get_data()
		depth_prepass_texture.create_from_image(image)

	progress_dialog.set_text("Generating " + baker_data.map_name + " map")
	$MeshInstance.set_surface_material(0, baker_data.baker)
	baker_data.baker.set_shader_param("bvh_data", bvh_data)
	baker_data.baker.set_shader_param("cage_depth", cage_depth)
	baker_data.baker.set_shader_param("ao_ray_dist", ao_ray_dist)
	baker_data.baker.set_shader_param("ao_ray_bias", ao_ray_bias)
	baker_data.baker.set_shader_param("cage_offset", cage_offset)
	if baker_data.has("dn_prepass"):
		baker_data.baker.set_shader_param("depth_texture", depth_prepass_texture)

	for i in ray_count:
		progress_dialog.set_progress(float(i)/ray_count)
		baker_data.baker.set_shader_param("iteration", i+1)
		render_target_update_mode = Viewport.UPDATE_ONCE
		yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")

	if baker_data.has("denoise"):
		$MeshInstance.set_surface_material(0, denoise_pass)
		denoise_pass.set_shader_param("size", map_size)
		denoise_pass.set_shader_param("radius", denoise_radius)
		render_target_update_mode = Viewport.UPDATE_ONCE
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")

	var temp_text: Texture = get_texture()
	var renderer = mm_renderer.request(self)
	for ps in baker_data.passes:
		ps.set_shader_param("tex", temp_text)
		ps.set_shader_param("size", map_size)
		while renderer is GDScriptFunctionState:
			renderer = yield(renderer, "completed")
		renderer = renderer.render_material(self, ps, map_size)
		while renderer is GDScriptFunctionState:
			renderer = yield(renderer, "completed")
		var t : ImageTexture = ImageTexture.new()
		renderer.copy_to_texture(t)
		temp_text = t
	renderer.callv(renderer_method, arguments)
	renderer.release(self)
	progress_dialog.queue_free()


func gen(mesh: Mesh, map : String, renderer_method : String, arguments : Array, map_size = 512) -> void:
	if "hp_lp_" in map:
		var _hp_mesh = get_hp_model_path()
		while _hp_mesh is GDScriptFunctionState:
			_hp_mesh = yield(_hp_mesh, "completed")
		return gen_hp_lp(mesh, _hp_mesh,map,renderer_method,arguments,map_size)
	var bake_passes =  {
		mesh_normal =  { first=mesh_normal_material, second=dilate_pass1, third=dilate_pass2 },
		mesh_tangent = { first=mesh_tangent_material, second=dilate_pass1, third=dilate_pass2 },
		inv_uv =       { first=inv_uv_material, second=dilate_pass1, third=dilate_pass2 },
		curvature =    { first=curvature_material, second=dilate_pass1, third=dilate_pass2 },
		thickness =    { first=thickness_material, second=dilate_pass1, third=dilate_pass2, map_name="Thickness" },
		ao =           { first=ao_material, second=dilate_pass1, third=dilate_pass2, map_name="Ambient Occlusion" },
		seams =        { first=white_material, second=seams_pass1, third=seams_pass2 }
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
		var main_window = get_node("/root/MainWindow")
		var ray_count = main_window.get_config("bake_ray_count")
		var ao_ray_dist = main_window.get_config("bake_ao_ray_dist")
		var ao_ray_bias = main_window.get_config("bake_ao_ray_bias")
		var denoise_radius = main_window.get_config("bake_denoise_radius")
		var progress_dialog = preload("res://material_maker/windows/progress_window/progress_window.tscn").instance()
		progress_dialog.set_text("Generating "+passes.map_name+" map")
		progress_dialog.set_progress(0)
		main_window.add_child(progress_dialog)
		var ray_distance = ao_ray_dist
		if map == "thickness":
			ray_distance = -aabb.size.length()
		var bvh_data: ImageTexture = $BVHGenerator.generate(mesh)
		passes.first.set_shader_param("bvh_data", bvh_data)
		passes.first.set_shader_param("ao_ray_dist", ray_distance)
		passes.first.set_shader_param("bias_dist", ao_ray_bias)
		for i in ray_count:
			progress_dialog.set_progress(float(i)/ray_count)
			passes.first.set_shader_param("iteration", i+1)
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
