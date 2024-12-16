extends Object
class_name MMMapGenerator


static var mesh_maps : Dictionary = {}
static var debug_index : int = 0

static var error_texture : MMTexture


const SHADERS_PATH : String = "res://addons/material_maker/map_generator"
const MAP_DEFINITIONS : Dictionary = {
	position = {
		type="simple",
		vertex = "position_vertex",
		fragment = "common_fragment",
		postprocess=["dilate"],
		dependencies=["seams"]
	},
	normal = {
		type="simple",
		vertex = "normal_vertex",
		fragment = "normal_fragment",
		postprocess=["dilate"],
		dependencies=["seams"]
	},
	tangent = {
		type="simple",
		vertex = "tangent_vertex",
		fragment = "normal_fragment",
		postprocess=["dilate"],
		dependencies=["seams"]
	},
	ambient_occlusion = {
		type="bvh",
		vertex = "ao_vertex",
		fragment = "ao_fragment",
		mode=0,
		postprocess=["dilate"],
		dependencies=["seams"]
	},
	bent_normals = {
		type="bvh",
		vertex = "ao_vertex",
		fragment = "ao_fragment",
		mode=1,
		postprocess=["dilate"],
		dependencies=["seams"]
	},
	thickness = {
		type="bvh",
		vertex = "ao_vertex",
		fragment = "ao_fragment",
		mode=2,
		postprocess=["dilate"],
		dependencies=["seams"]
	},
	curvature = {
		type="curvature",
		vertex = "curvature_vertex",
		fragment = "common_fragment",
		postprocess=["dilate"],
		dependencies=["seams"]
	},
	seams = {
		type="simple",
		vertex = "position_vertex",
		fragment = "common_fragment",
		postprocess=["seams_1", "seams_2"]
	},
	adjacency = {
		type="adjacency",
		vertex = "normal_vertex",
		fragment = "common_fragment",
		postprocess=["adjacency_dilate"],
		dependencies=["seams"]
	}
}


class DefaultProgress:
	var text : String
	var progress : int = 0
	
	func set_text(t : String):
		text = t
	
	func set_progress(v : float):
		if int(v*100.0) > progress:
			progress = int(v*100.0)
			print(text+" ("+str(progress)+"%)")


class UIProgress:
	var text : String
	var progress : int = 0
	
	func set_text(t : String):
		text = t
	
	func set_progress(v : float):
		if int(v*100.0) > progress:
			progress = int(v*100.0)
			mm_globals.main_window.set_tip_text(text+" ("+str(progress)+"%)", 0.0 if (progress >= 100) else 1.0)


static func generate(mesh : Mesh, map : String, size : int, texture : MMTexture):
	assert(mesh != null)
	print.call_deferred("Generating %s map for mesh %s" % [ map, str(mesh) ])
	var progress
	if mm_globals.main_window:
		progress = UIProgress.new()
	else:
		progress = DefaultProgress.new()
	progress.set_text.call_deferred("Generating "+map+" map")
	progress.set_progress.call_deferred(0)
	var pixels : int = size/4
	var map_definition : Dictionary = MAP_DEFINITIONS[map]
	var mesh_pipeline : MMMeshRenderingPipeline = MMMeshRenderingPipeline.new()
	var vertex_shader : String = load(SHADERS_PATH+"/"+map_definition.vertex+".tres").text
	var fragment_shader : String = load(SHADERS_PATH+"/"+map_definition.fragment+".tres").text
	match map_definition.type:
		"simple":
			mesh_pipeline.mesh = mesh
			mesh_pipeline.set_shader(vertex_shader, fragment_shader)
			mesh_pipeline.in_thread_render(Vector2i(size, size), 3, texture)
		"curvature":
			var curvature_generator : MMCurvatureGenerator = MMCurvatureGenerator.new()
			mesh_pipeline.mesh = curvature_generator.generate(mesh)
			mesh_pipeline.set_shader(vertex_shader, fragment_shader)
			mesh_pipeline.in_thread_render(Vector2i(size, size), 3, texture)
		"adjacency":
			var adjacency_generator : MMAdjacencyGenerator = MMAdjacencyGenerator.new()
			mesh_pipeline.mesh = adjacency_generator.generate(mesh)
			mesh_pipeline.set_shader(vertex_shader, fragment_shader)
			mesh_pipeline.in_thread_render(Vector2i(size, size), 3, texture)
		"bvh":
			mesh_pipeline.mesh = mesh
			var bvh : MMTexture = MMTexture.new()
			bvh.set_texture(MMBvhGenerator.generate(mesh))
			var ray_count = mm_globals.get_config("bake_ray_count")
			var ao_ray_dist = -mesh.get_aabb().size.length() if map == "thickness" else mm_globals.get_config("bake_ao_ray_dist")
			var ao_ray_bias = mm_globals.get_config("bake_ao_ray_bias")
			var denoise_radius = mm_globals.get_config("bake_denoise_radius")
			mesh_pipeline.add_parameter_or_texture("bvh_data", "sampler2D", bvh)
			mesh_pipeline.add_parameter_or_texture("prev_iteration_tex", "sampler2D", texture)
			mesh_pipeline.add_parameter_or_texture("max_dist", "float", ao_ray_dist)
			mesh_pipeline.add_parameter_or_texture("bias_dist", "float", ao_ray_bias)
			mesh_pipeline.add_parameter_or_texture("iteration", "int", 1)
			mesh_pipeline.add_parameter_or_texture("mode", "int", map_definition.mode)
			await mesh_pipeline.set_shader(vertex_shader, fragment_shader)
			print.call_deferred("Casting %d rays..." % ray_count)
			for i in range(ray_count):
				progress.set_progress.call_deferred(float(i)/ray_count)
				mesh_pipeline.set_parameter("iteration", i+1)
				mesh_pipeline.set_parameter("prev_iteration_tex", texture)
				mesh_pipeline.in_thread_render(Vector2i(size, size), 3, texture)
			
			if map == "bent_normals":
				print.call_deferred("Normalizing...")
				var normalize_pipeline : MMComputeShader = MMComputeShader.new()
				normalize_pipeline.clear()
				normalize_pipeline.add_parameter_or_texture("tex", "sampler2D", texture)
				normalize_pipeline.set_shader(load("res://addons/material_maker/map_generator/normalize_compute.tres").text, 3)
				normalize_pipeline.in_thread_render_ext([texture], Vector2i(size, size))
			
			# Denoise
			if true:
				print.call_deferred("Denoising...")
				var denoise_pipeline : MMComputeShader = MMComputeShader.new()
				denoise_pipeline.clear()
				denoise_pipeline.add_parameter_or_texture("tex", "sampler2D", texture)
				denoise_pipeline.add_parameter_or_texture("radius", "int", 3)
				denoise_pipeline.set_shader(load("res://addons/material_maker/map_generator/denoise_compute.tres").text, 3)
				denoise_pipeline.in_thread_render_ext([texture], Vector2i(size, size))

	# Extend the map past seams
	if pixels > 0 and map_definition.has("postprocess"):
		print.call_deferred("Postprocessing...")
		#texture.save_to_file("d:/debug_x_%d.png" % debug_index)
		debug_index += 1
		for p in map_definition.postprocess:
			var postprocess_pipeline : MMComputeShader = MMComputeShader.new()
			postprocess_pipeline.clear()
			postprocess_pipeline.add_parameter_or_texture("tex", "sampler2D", texture)
			postprocess_pipeline.add_parameter_or_texture("pixels", "int", pixels)
			match p:
				"adjacency_dilate", "dilate":
					var seams_map : MMTexture = mesh_maps[mesh]["seams:"+str(size)]
					postprocess_pipeline.add_parameter_or_texture("seams_map", "sampler2D", seams_map)
			var shader_string : String = load("res://addons/material_maker/map_generator/"+p+"_compute.tres").text
			postprocess_pipeline.set_shader(shader_string, 3)
			postprocess_pipeline.in_thread_render_ext([texture], Vector2i(size, size))
			#texture.save_to_file("d:/debug_%d.png" % debug_index)
			debug_index += 1
		progress.set_progress.call_deferred(1.0)

static var busy : bool = false

static func get_map(mesh : Mesh, map : String, size : int = 2048, force_generate : bool = false) -> MMTexture:
	if mesh == null or size <= 0:
		if error_texture == null:
			error_texture = MMTexture.new()
			var image : Image = Image.create(1, 1, 0, Image.FORMAT_RGBAH)
			image.fill(Color(1.0, 0.0, 0.0))
			error_texture.set_texture(ImageTexture.create_from_image(image))
		return error_texture
	if ! mesh_maps.has(mesh):
		mesh_maps[mesh] = {}
	var field_name : String = map+":"+str(size)
	if force_generate:
		mesh_maps[mesh].erase(field_name)
	if not mesh_maps[mesh].has(field_name):
		if MAP_DEFINITIONS[map].has("dependencies"):
			for d in MAP_DEFINITIONS[map].dependencies:
				await get_map(mesh, d, size)
		#print("Creating map ", field_name, " for mesh ", mesh)
		while not mesh_maps[mesh].has(field_name):
			if busy:
				await mm_globals.get_tree().process_frame
			else:
				busy = true
				var texture : MMTexture = MMTexture.new()
				await mm_renderer.thread_run(generate, [mesh, map, size, texture])
				mesh_maps[mesh][field_name] = texture
				busy = false
	return mesh_maps[mesh][field_name] as MMTexture
