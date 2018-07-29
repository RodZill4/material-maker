tool
extends "res://addons/procedural_material/node_base.gd"

var texture_albedo     = null
var texture_metallic   = null
var texture_roughness  = null
var texture_emission   = null
var texture_normal_map = null
var texture_depth_map  = null

var render_queue = []   # render queue for generated textures
var material_list = []  # materials to be updatedwith generated textures

func _ready():
	pass

func _get_shader_code(uv):
	var rv = { defs="", code="", f="0.0" }
	var src = get_source()
	if src != null:
		rv = src.get_shader_code(uv)
		rv.albedo = get_source_rgb(rv)
	src = get_source(1)
	if src != null:
		var src_code = src.get_shader_code(uv)
		rv.defs += src_code.defs
		rv.code += src_code.code
		rv.normal_map = get_source_rgb(src_code)
	return rv

func _get_state_variables():
	return [ ]

func update_materials(ml):
	material_list = ml
	render_queue = [
		{ port= 0, texture= "albedo" },
		{ port= 1, texture= "metallic" },
		{ port= 2, texture= "roughness" },
		{ port= 3, texture= "emission" },
		{ port= 4, texture= "normal_map" },
		{ port= 5, texture= "depth_map" }
	]
	process_render_queue()

func process_render_queue():
	while !render_queue.empty():
		var job = render_queue.pop_front()
		var source = get_source(job.port)
		if source != null:
			get_parent().precalculate_texture(source, 1024, self, "store_texture", [ job.texture ])
			return
		else:
			set("texture_"+job.texture, null)
	do_update_materials()

func store_texture(texture_name, texture):
	set("texture_"+texture_name, texture)
	process_render_queue()

func do_update_materials():
	for m in material_list:
		if m is SpatialMaterial:
			m.albedo_texture = texture_albedo
			m.metallic_texture = texture_metallic
			m.roughness_texture = texture_roughness
			if texture_emission != null:
				m.emission_enabled = true
				m.emission_texture = texture_emission
			else:
				m.emission_enabled = false
			if texture_normal_map != null:
				m.normal_enabled = true
				m.normal_texture = texture_normal_map
			else:
				m.normal_enabled = false
			if texture_depth_map != null:
				m.depth_enabled = true
				m.depth_texture = texture_depth_map
			else:
				m.depth_enabled = false

