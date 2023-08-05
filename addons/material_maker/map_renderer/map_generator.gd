extends Object
class_name MMMapGenerator


const SHADERS_PATH : String = "res://addons/material_maker/map_renderer"
const SHADERS : Dictionary = {
	position = { vertex = "position_vertex", fragment = "common_fragment" },
	normal = { vertex = "normal_vertex", fragment = "normal_fragment" },
	tangent = { vertex = "tangent_vertex", fragment = "normal_fragment" },
	ambient_occlusion = { vertex = "ao_vertex", fragment = "ao_fragment", mode=0 },
	bent_normals = { vertex = "ao_vertex", fragment = "ao_fragment", mode=1 },
	thickness = { vertex = "ao_vertex", fragment = "ao_fragment", mode=2 },
	curvature = { vertex = "curvature_vertex", fragment = "common_fragment" }
}


static func generate(mesh : Mesh, map : String, size : int, texture : MMTexture):
	var pixels : int = size/4
	var mesh_pipeline : MMMeshRenderingPipeline = MMMeshRenderingPipeline.new()
	if map == "curvature":
		mesh_pipeline.mesh = MMCurvatureGenerator.generate(mesh)
	else:
		mesh_pipeline.mesh = mesh
	var shaders : Dictionary = SHADERS[map]
	var vertex_shader : String = load(SHADERS_PATH+"/"+shaders.vertex+".tres").text
	var fragment_shader : String = load(SHADERS_PATH+"/"+shaders.fragment+".tres").text
	match map:
		"position", "normal", "tangent", "curvature":
			await mesh_pipeline.set_shader(vertex_shader, fragment_shader)
			await mesh_pipeline.render(Vector2i(size, size), 3, texture)
		"ambient_occlusion", "bent_normals", "thickness":
			var bvh : MMTexture = MMTexture.new()
			bvh.set_texture(MMBvhGenerator.generate(mesh))
			var ray_count = mm_globals.get_config("bake_ray_count")
			var ao_ray_dist = -mesh.get_aabb().size.length() if map == "thickness" else mm_globals.get_config("bake_ao_ray_dist")
			var ao_ray_bias = mm_globals.get_config("bake_ao_ray_bias")
			var denoise_radius = mm_globals.get_config("bake_denoise_radius")
			mesh_pipeline.add_parameter_or_texture("bvh_data", "sampler2D", bvh)
			mesh_pipeline.add_parameter_or_texture("prev_iteration_tex", "sampler2D", texture)
			mesh_pipeline.add_parameter_or_texture("max_dist", "float", ao_ray_dist)
			mesh_pipeline.add_parameter_or_texture("bias_dist", "float",ao_ray_bias)
			mesh_pipeline.add_parameter_or_texture("iteration", "int", 1)
			mesh_pipeline.add_parameter_or_texture("mode", "int", shaders.mode)
			await mesh_pipeline.set_shader(vertex_shader, fragment_shader)
			print("Casting %d rays..." % ray_count)
			for i in range(ray_count):
				mesh_pipeline.set_parameter("iteration", i+1)
				mesh_pipeline.set_parameter("prev_iteration_tex", texture)
				await mesh_pipeline.render(Vector2i(size, size), 3, texture)
			
			if map == "bent_normals":
				print("Normalizing...")
				var normalize_pipeline : MMComputeShader = MMComputeShader.new()
				normalize_pipeline.clear()
				normalize_pipeline.add_parameter_or_texture("tex", "sampler2D", texture)
				await normalize_pipeline.set_shader(load("res://addons/material_maker/map_renderer/normalize_compute.tres").text, 3)
				await normalize_pipeline.render(texture, Vector2i(size, size))
			
			# Denoise
			print("Denoising...")
			var denoise_pipeline : MMComputeShader = MMComputeShader.new()
			denoise_pipeline.clear()
			denoise_pipeline.add_parameter_or_texture("tex", "sampler2D", texture)
			denoise_pipeline.add_parameter_or_texture("radius", "int", 3)
			await denoise_pipeline.set_shader(load("res://addons/material_maker/map_renderer/denoise_compute.tres").text, 3)
			await denoise_pipeline.render(texture, Vector2i(size, size))

	# Extend the map past seams
	if pixels > 0:
		var compute_pipeline : MMComputeShader = MMComputeShader.new()
		compute_pipeline.clear()
		compute_pipeline.add_parameter_or_texture("tex", "sampler2D", texture)
		compute_pipeline.add_parameter_or_texture("pixels", "int", pixels)
		await compute_pipeline.set_shader(load("res://addons/material_maker/map_renderer/dilate_1_compute.tres").text, 3)
		await compute_pipeline.render(texture, Vector2i(size, size))

		compute_pipeline.clear()
		compute_pipeline.add_parameter_or_texture("tex", "sampler2D", texture)
		compute_pipeline.add_parameter_or_texture("pixels", "int", pixels)
		await compute_pipeline.set_shader(load("res://addons/material_maker/map_renderer/dilate_2_compute.tres").text, 3)
		await compute_pipeline.render(texture, Vector2i(size, size))

