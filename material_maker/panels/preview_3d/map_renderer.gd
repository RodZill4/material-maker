extends Viewport

export(ShaderMaterial) var mesh_normal_material
export(ShaderMaterial) var inv_uv_material
export(ShaderMaterial) var dilate_pass1
export(ShaderMaterial) var dilate_pass2

func _ready():
	pass

func gen(mesh: Mesh, map : String, file_name : String, map_size = 512) -> void:
	size = Vector2(map_size, map_size)
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
	var result = mm_renderer.render_material(dilate_pass1, map_size)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	var t : ImageTexture = ImageTexture.new()
	result.copy_to_texture(t)
	result.release()
	dilate_pass2.set_shader_param("tex", t)
	dilate_pass2.set_shader_param("size", map_size)
	result = mm_renderer.render_material(dilate_pass2, map_size)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	result.save_to_file(file_name)
	result.release()
