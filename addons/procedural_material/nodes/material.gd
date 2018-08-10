tool
extends "res://addons/procedural_material/node_base.gd"

var albedo_color
var metallic
var roughness
var emission_energy
var normal_scale
var ao_light_affect
var depth_scale 

var texture_albedo            = null
var texture_metallic          = null
var texture_roughness         = null
var texture_emission          = null
var texture_normal_map        = null
var texture_ambient_occlusion = null
var texture_depth_map         = null

const TEXTURE_LIST = [
		{ port= 0, texture= "albedo" },
		{ port= 1, texture= "metallic" },
		{ port= 2, texture= "roughness" },
		{ port= 3, texture= "emission" },
		{ port= 4, texture= "normal_map" },
		{ port= 5, texture= "ambient_occlusion" },
		{ port= 6, texture= "depth_map" }
]

func _ready():
	initialize_properties([ $Albedo/albedo_color, $Metallic/metallic, $Roughness/roughness, $Emission/emission_energy, $NormalMap/normal_scale, $AmbientOcclusion/ao_light_affect, $DepthMap/depth_scale ])

func _get_shader_code(uv):
	var rv = { defs="", code="", f="0.0" }
	var src = get_source()
	if src != null:
		rv = src.get_shader_code(uv)
	return rv

func _get_state_variables():
	return [ ]

func update_materials(material_list):
	var has_textures = false
	for t in TEXTURE_LIST:
		var source = get_source(t.port)
		if source == null:
			set("texture_"+t.texture, null)
		else:
			get_parent().precalculate_texture(source, 1024, self, "store_texture", [ t.texture, material_list ])
			has_textures = true
	if !has_textures:
		do_update_materials(material_list)

func store_texture(texture_name, material_list, texture):
	set("texture_"+texture_name, texture)
	do_update_materials(material_list)

func do_update_materials(material_list):
	for m in material_list:
		if m is SpatialMaterial:
			m.albedo_color = albedo_color
			m.albedo_texture = texture_albedo
			m.metallic = metallic
			m.metallic_texture = texture_metallic
			m.roughness = roughness
			m.roughness_texture = texture_roughness
			if texture_emission != null:
				m.emission_enabled = true
				m.emission_energy = emission_energy
				m.emission_texture = texture_emission
			else:
				m.emission_enabled = false
			if texture_normal_map != null:
				m.normal_enabled = true
				m.normal_texture = texture_normal_map
			else:
				m.normal_enabled = false
			if texture_ambient_occlusion != null:
				m.ao_enabled = true
				m.ao_light_affect = ao_light_affect
				m.ao_texture = texture_ambient_occlusion
			else:
				m.ao_enabled = false
			if texture_depth_map != null:
				m.depth_enabled = true
				m.depth_scale = depth_scale
				m.depth_texture = texture_depth_map
			else:
				m.depth_enabled = false

func export_textures(prefix):
	for t in TEXTURE_LIST:
		get_parent().export_texture(get_source(t.port), prefix+"_"+t.texture+".png", 1024)
