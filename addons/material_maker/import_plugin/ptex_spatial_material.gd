tool
extends SpatialMaterial

export var ptex : String = "" setget set_ptex

func set_ptex_no_render(s : String) -> void :
	ptex = s

func set_ptex(s : String) -> void :
	if ptex == s:
		return
	ptex = s
	call_deferred("update_texture")

func update_texture() -> void:
	var mm_graph = mm_loader.create_gen(parse_json(ptex))
	if not mm_graph:
		return
	var mm_material : MMGenMaterial = mm_graph.get_node("Material")
	if ! (mm_material is MMGenMaterial):
		return
	mm_renderer.add_child(mm_graph)
	var status = mm_material.render_textures()
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	mm_material.update_material(self)
	mm_graph.queue_free()
