tool
extends "res://addons/procedural_material/node_base.gd"

var albedo_color
var metallic
var roughness
var emission_energy
var normal_scale
var ao_light_affect
var depth_scale

var current_material_list = []
var generated_textures = {}

const TEXTURE_LIST = [
	{ port=0, texture="albedo" },
	{ port=1, texture="metallic" },
	{ port=2, texture="roughness" },
	{ port=3, texture="emission" },
	{ port=4, texture="normal_map" },
	{ port=5, texture="ambient_occlusion" },
	{ port=6, texture="depth_map" }
]

func _ready():
	for t in TEXTURE_LIST:
		generated_textures[t.texture] = { shader=null, source=null, texture=null}
	initialize_properties([ $Albedo/albedo_color, $Metallic/metallic, $Roughness/roughness, $Emission/emission_energy, $NormalMap/normal_scale, $AmbientOcclusion/ao_light_affect, $DepthMap/depth_scale ])

func _rerender():
	var has_textures = false
	for t in TEXTURE_LIST:
		var shader = generated_textures[t.texture].shader
		if shader != null:
			var input_textures = null
			if generated_textures[t.texture].source != null:
				input_textures = generated_textures[t.texture].source.get_textures()
			get_parent().precalculate_shader(shader, input_textures, 1024, generated_textures[t.texture].texture, self, "do_update_materials", [ current_material_list ])
			has_textures = true
	if !has_textures:
		do_update_materials(current_material_list)

func _get_shader_code(uv):
	var rv = { defs="", code="", f="0.0" }
	var src = get_source()
	if src != null:
		rv = src.get_shader_code(uv)
	return rv

func update_materials(material_list):
	current_material_list = material_list
	var has_textures = false
	for t in TEXTURE_LIST:
		var source = get_source(t.port)
		if source == null:
			generated_textures[t.texture].shader = null
			generated_textures[t.texture].source = null
			if generated_textures[t.texture].texture != null:
				generated_textures[t.texture].texture = null
		else:
			generated_textures[t.texture].shader = source.generate_shader()
			generated_textures[t.texture].source = source
			if generated_textures[t.texture].texture == null:
				generated_textures[t.texture].texture = ImageTexture.new()
	_rerender()

func do_update_materials(material_list):
	for m in material_list:
		if m is SpatialMaterial:
			m.albedo_color = albedo_color
			m.albedo_texture = generated_textures.albedo.texture
			m.metallic = metallic
			m.metallic_texture = generated_textures.metallic.texture
			m.roughness = roughness
			m.roughness_texture = generated_textures.roughness.texture
			if generated_textures.emission.texture != null:
				m.emission_enabled = true
				m.emission_energy = emission_energy
				m.emission_texture = generated_textures.emission.texture
			else:
				m.emission_enabled = false
			if generated_textures.normal_map.texture != null:
				m.normal_enabled = true
				m.normal_texture = generated_textures.normal_map.texture
			else:
				m.normal_enabled = false
			if generated_textures.ambient_occlusion.texture != null:
				m.ao_enabled = true
				m.ao_light_affect = ao_light_affect
				m.ao_texture = generated_textures.ambient_occlusion.texture
			else:
				m.ao_enabled = false
			if generated_textures.depth_map.texture != null:
				m.depth_enabled = true
				m.depth_scale = depth_scale
				m.depth_texture = generated_textures.depth_map.texture
			else:
				m.depth_enabled = false

func export_textures(prefix):
	for t in TEXTURE_LIST:
		get_parent().export_texture(get_source(t.port), prefix+"_"+t.texture+".png", 1024)
