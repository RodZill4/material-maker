extends Viewport

export(ShaderMaterial) var mesh_normal_material
export(ShaderMaterial) var curvature_material
export(ShaderMaterial) var inv_uv_material
export(ShaderMaterial) var dilate_pass1
export(ShaderMaterial) var dilate_pass2

func _ready():
	pass

func gen(mesh: Mesh, map : String, file_name : String, map_size = 512) -> void:
	size = Vector2(map_size, map_size)
	if map == "curvature":
		$MeshInstance.mesh = $CurvatureGenerator.generate(mesh)
	else:
		$MeshInstance.mesh = mesh
	$MeshInstance.set_surface_material(0, get(map+"_material"))
	var aabb = $MeshInstance.get_aabb()
	inv_uv_material.set_shader_param("position", aabb.position)
	inv_uv_material.set_shader_param("size", aabb.size)
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	dilate_pass1.set_shader_param("tex", get_texture())
	dilate_pass1.set_shader_param("size", map_size)
	var renderer = mm_renderer.request(self)
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	renderer = renderer.render_material(self, dilate_pass1, map_size)
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	var t : ImageTexture = ImageTexture.new()
	renderer.copy_to_texture(t)
	dilate_pass2.set_shader_param("tex", t)
	dilate_pass2.set_shader_param("size", map_size)
	renderer = renderer.render_material(self, dilate_pass2, map_size)
	while renderer is GDScriptFunctionState:
		renderer = yield(renderer, "completed")
	renderer.save_to_file(file_name)
	renderer.release(self)
