extends Node

@onready var viewport : SubViewport = $Viewport
@onready var mesh_instance : MeshInstance3D = $Viewport/MeshInstance3D

@export var position_material: ShaderMaterial
@export var normal_material: ShaderMaterial
@export var tangent_material: ShaderMaterial
@export var white_material: ShaderMaterial
@export var curvature_material: ShaderMaterial
@export var ao_material: ShaderMaterial
@export var thickness_material: ShaderMaterial
@export var denoise_pass: ShaderMaterial
@export var dilate_pass1: ShaderMaterial
@export var dilate_pass2: ShaderMaterial
@export var seams_pass1: ShaderMaterial
@export var seams_pass2: ShaderMaterial

func gen_new(mesh: Mesh, map : String, renderer_method : String, arguments : Array, map_size = 512) -> void:
	var map_generator : MMMeshRenderingPipeline = MMMeshRenderingPipeline.new()
	var texture : MMTexture = MMTexture.new()
	await MMMapGenerator.generate(mesh, map, map_size, texture)
	match renderer_method:
		"save_to_file":
			var image = (await texture.get_texture()).get_image()
			if image:
				var file_name : String = arguments[0]
				print("Saving image to "+file_name)
				match file_name.get_extension():
					"png":
						image.save_png(file_name)
					"exr":
						image.save_exr(file_name)

func gen(mesh: Mesh, map : String, renderer_method : String, arguments : Array, map_size = 512) -> void:
	var bake_passes =  {
		position =  { first=position_material, second=dilate_pass1, third=dilate_pass2 },
		normal =    { first=normal_material, second=dilate_pass1, third=dilate_pass2 },
		tangent =   { first=tangent_material, second=dilate_pass1, third=dilate_pass2 },
		curvature = { first=curvature_material, second=dilate_pass1, third=dilate_pass2 },
		thickness = { first=thickness_material, second=dilate_pass1, third=dilate_pass2, map_name="Thickness" },
		ao =        { first=ao_material, second=dilate_pass1, third=dilate_pass2, map_name="Ambient Occlusion" },
		seams =     { first=white_material, second=seams_pass1, third=seams_pass2 }
	}
	
	var passes = bake_passes[map]
	viewport.size = Vector2(map_size, map_size)
	if map == "curvature":
		mesh_instance.mesh = $CurvatureGenerator.generate(mesh)
	else:
		mesh_instance.mesh = mesh
	mesh_instance.set_surface_override_material(0, passes.first)

	var aabb = mesh_instance.get_aabb()
	if map in ["ao", "thickness"]:
		var main_window = mm_globals.main_window
		var ray_count = mm_globals.get_config("bake_ray_count")
		var ao_ray_dist = mm_globals.get_config("bake_ao_ray_dist")
		var ao_ray_bias = mm_globals.get_config("bake_ao_ray_bias")
		var denoise_radius = mm_globals.get_config("bake_denoise_radius")
		var progress_dialog = preload("res://material_maker/windows/progress_window/progress_window.tscn").instantiate()
		progress_dialog.set_text("Generating "+passes.map_name+" map")
		progress_dialog.set_progress(0)
		main_window.add_child(progress_dialog)
		var ray_distance = ao_ray_dist
		if map == "thickness":
			ray_distance = -aabb.size.length()
		var bvh_data: ImageTexture = $BVHGenerator.generate(mesh)
		passes.first.set_shader_parameter("bvh_data", bvh_data)
		passes.first.set_shader_parameter("max_dist", ray_distance)
		passes.first.set_shader_parameter("bias_dist", ao_ray_bias)
		for i in ray_count:
			progress_dialog.set_progress(float(i)/ray_count)
			passes.first.set_shader_parameter("iteration", i+1)
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			await get_tree().process_frame
		mesh_instance.set_surface_override_material(0, denoise_pass)
		denoise_pass.set_shader_parameter("size", map_size)
		denoise_pass.set_shader_parameter("radius", denoise_radius)
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await get_tree().process_frame
		await get_tree().process_frame
		progress_dialog.queue_free()
	else:
		passes.first.set_shader_parameter("position", aabb.position)
		passes.first.set_shader_parameter("size", aabb.size)
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await get_tree().process_frame
		await get_tree().process_frame
	passes.second.set_shader_parameter("tex", viewport.get_texture())
	passes.second.set_shader_parameter("size", map_size)
	var renderer = await mm_renderer.request(self)
	renderer = await renderer.render_material(self, passes.second, map_size)
	var t : ImageTexture = ImageTexture.new()
	renderer.copy_to_texture(t)
	passes.third.set_shader_parameter("tex", t)
	passes.third.set_shader_parameter("size", map_size)
	renderer = await renderer.render_material(self, passes.third, map_size)
	renderer.callv(renderer_method, arguments)
	renderer.release(self)
