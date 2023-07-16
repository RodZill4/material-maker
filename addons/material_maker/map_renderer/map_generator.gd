extends Object
class_name MMMapGenerator

static func generate(mesh : Mesh, map : String, size : int, texture : MMTexture):
	var pixels : int = size/2
	
	var mesh_pipeline : MMMeshRenderingPipeline = MMMeshRenderingPipeline.new()
	mesh_pipeline.mesh = mesh
	var vertex_shader : String
	var fragment_shader : String
	match map:
		"position":
			vertex_shader = load("res://addons/material_maker/map_renderer/position_map_vertex.tres").text
			fragment_shader = load("res://addons/material_maker/map_renderer/common_fragment.tres").text
		"normal":
			vertex_shader = load("res://addons/material_maker/map_renderer/normal_map_vertex.tres").text
			fragment_shader = load("res://addons/material_maker/map_renderer/normal_fragment.tres").text
		"tangent":
			vertex_shader = load("res://addons/material_maker/map_renderer/tangent_map_vertex.tres").text
			fragment_shader = load("res://addons/material_maker/map_renderer/normal_fragment.tres").text
	await mesh_pipeline.render(vertex_shader, fragment_shader, Vector2i(size, size), 3, texture)
	
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

