@tool
extends StandardMaterial3D

@export var ptex : String = "" : set = set_ptex

func set_ptex_no_render(s : String) -> void :
	ptex = s

func set_ptex(s : String) -> void :
	if ptex == s:
		return
	ptex = s
	call_deferred("update_texture")

func update_texture() -> void:
	var test_json_conv = JSON.new()
	test_json_conv.parse(ptex))
	var mm_graph = mm_loader.create_gen(test_json_conv.get_data()
	if mm_graph == null:
		return
	var mm_material : MMGenMaterial = mm_graph.get_node("Material")
	if ! (mm_material is MMGenMaterial):
		return
	mm_renderer.add_child(mm_graph)
	var status = mm_material.render_textures()
	while status is GDScriptFunctionState:
		status = await status.completed
	mm_material.update_material(self)
	mm_graph.queue_free()

