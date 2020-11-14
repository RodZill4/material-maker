extends Viewport

export(ShaderMaterial) var mesh_normal_material
export(ShaderMaterial) var inv_uv_material
export(ShaderMaterial) var white_material
export(ShaderMaterial) var dilate_pass1
export(ShaderMaterial) var dilate_pass2
export(ShaderMaterial) var seams_pass1
export(ShaderMaterial) var seams_pass2

var passes = {
	mesh_normal = { first=mesh_normal_material, second=dilate_pass1, third=dilate_pass2 },
	inv_uv =      { first=inv_uv_material, second=dilate_pass1, third=dilate_pass2 },
	seams =       { first=white_material, second=seams_pass1, third=seams_pass2 }
}

func _ready():
	pass

func gen(mesh: Mesh, map : String, renderer_method : String, arguments : Array, map_size = 512) -> void:
	var passes = {
		mesh_normal = { first=mesh_normal_material, second=dilate_pass1, third=dilate_pass2 },
		inv_uv =      { first=inv_uv_material, second=dilate_pass1, third=dilate_pass2 },
		seams =       { first=white_material, second=seams_pass1, third=seams_pass2 }
	}[map]
	size = Vector2(map_size, map_size)
	$MeshInstance.mesh = mesh
	$MeshInstance.set_surface_material(0, passes.first)
	var aabb = $MeshInstance.get_aabb()
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
