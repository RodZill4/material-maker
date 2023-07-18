extends Object
class_name MMMapGenerator


const SHADERS_PATH : String = "res://addons/material_maker/map_renderer"
const SHADERS : Dictionary = {
	position = { vertex = "position_vertex", fragment = "common_fragment" },
	normal = { vertex = "normal_vertex", fragment = "normal_fragment" },
	tangent = { vertex = "tangent_vertex", fragment = "normal_fragment" },
	ambient_occlusion = { vertex = "ao_vertex", fragment = "ao_fragment" }
}


static func generate(mesh : Mesh, map : String, size : int, texture : MMTexture):
	var pixels : int = size/4
	var mesh_pipeline : MMMeshRenderingPipeline = MMMeshRenderingPipeline.new()
	mesh_pipeline.mesh = mesh
	var shaders : Dictionary = SHADERS[map]
	var vertex_shader : String = load(SHADERS_PATH+"/"+shaders.vertex+".tres").text
	var fragment_shader : String = load(SHADERS_PATH+"/"+shaders.fragment+".tres").text
	match map:
		"position", "normal", "tangent":
			await mesh_pipeline.set_shader(vertex_shader, fragment_shader)
			await mesh_pipeline.render(Vector2i(size, size), 3, texture)
		"ambient_occlusion":
			var bvh : MMTexture = MMTexture.new()
			bvh.set_texture(MMBvhGenerator.generate(mesh))
			mesh_pipeline.add_parameter_or_texture("bvh_data", "sampler2D", bvh)
			mesh_pipeline.add_parameter_or_texture("prev_iteration_tex", "sampler2D", texture)
			mesh_pipeline.add_parameter_or_texture("max_dist", "float", 50)
			mesh_pipeline.add_parameter_or_texture("bias_dist", "float", 0.1)
			mesh_pipeline.add_parameter_or_texture("iteration", "int", 1)
			await mesh_pipeline.set_shader(vertex_shader, fragment_shader)
			for i in range(128):
				mesh_pipeline.set_parameter("iteration", i+1)
				mesh_pipeline.set_parameter("prev_iteration_tex", texture)
				await mesh_pipeline.render(Vector2i(size, size), 3, texture)
			
			# Denoise
			var compute_pipeline : MMComputeShader = MMComputeShader.new()
			compute_pipeline.clear()
			compute_pipeline.add_parameter_or_texture("tex", "sampler2D", texture)
			compute_pipeline.add_parameter_or_texture("radius", "int", 3)
			await compute_pipeline.set_shader(load("res://addons/material_maker/map_renderer/denoise_compute.tres").text, 3)
			await compute_pipeline.render(texture, size)

	# Extend the map past seams
	if pixels > 0:
		var compute_pipeline : MMComputeShader = MMComputeShader.new()
		compute_pipeline.clear()
		compute_pipeline.add_parameter_or_texture("tex", "sampler2D", texture)
		compute_pipeline.add_parameter_or_texture("pixels", "int", pixels)
		await compute_pipeline.set_shader(load("res://addons/material_maker/map_renderer/dilate_1_compute.tres").text, 3)
		await compute_pipeline.render(texture, size)

		compute_pipeline.clear()
		compute_pipeline.add_parameter_or_texture("tex", "sampler2D", texture)
		compute_pipeline.add_parameter_or_texture("pixels", "int", pixels)
		await compute_pipeline.set_shader(load("res://addons/material_maker/map_renderer/dilate_2_compute.tres").text, 3)
		await compute_pipeline.render(texture, size)

