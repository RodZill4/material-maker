tool
extends "res://addons/material_maker/node_base.gd"

var resolution = 1
var albedo_color
var metallic
var roughness
var emission_energy
var normal_scale
var ao_light_affect
var depth_scale

var texture_list

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

const ADDON_TEXTURE_LIST = [
	{ port=0, texture="albedo" },
	{ port=3, texture="emission" },
	{ port=4, texture="normal_map" },
	{ ports=[1, 2, 5], default_values=["0.0", "1.0", "1.0"], texture="mrao" },
	{ port=6, texture="depth_map" }
]

func _ready():
	texture_list = TEXTURE_LIST
	if Engine.editor_hint:
		texture_list = ADDON_TEXTURE_LIST
	for t in texture_list:
		generated_textures[t.texture] = { shader=null, source=null, texture=null }
	initialize_properties([ $resolution, $Albedo/albedo_color, $Metallic/metallic, $Roughness/roughness, $Emission/emission_energy, $NormalMap/normal_scale, $AmbientOcclusion/ao_light_affect, $DepthMap/depth_scale ])

func _rerender():
	var size = int(pow(2, 8+resolution))
	var has_textures = false
	for t in texture_list:
		var shader = generated_textures[t.texture].shader
		if shader != null:
			var input_textures = {}
			for s in generated_textures[t.texture].sources:
				var source_textures = s.get_textures()
				for st in source_textures.keys():
					input_textures[st] = source_textures[st]
			get_parent().renderer.precalculate_shader(shader, input_textures, size, generated_textures[t.texture].texture, self, "do_update_materials", [ current_material_list ])
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
	for t in texture_list:
		var shader = null
		var sources = []
		if t.has("port"):
			var source = get_source(t.port)
			if source != null:
				shader = source.generate_shader()
				sources.append(source)
		elif t.has("ports"):
			var source = [ null, null, null ]
			generated_textures[t.texture].mask = 0
			for i in range(3):
				source[i] = get_source(t.ports[i])
				if source[i] != null:
					sources.append(source[i])
					generated_textures[t.texture].mask |= 1 << i
			if !sources.empty():
				for c in get_parent().get_children():
					if c is GraphNode:
						c.reset()
				var source_code = [ null, null, null ]
				for i in range(3):
					if source[i] != null:
						source_code[i] = source[i].get_shader_code("UV")
					else:
						source_code[i] = { defs="", code="", f=t.default_values[i] }
				shader = get_parent().renderer.generate_combined_shader(source_code[0], source_code[1], source_code[2])
		generated_textures[t.texture].shader = shader
		generated_textures[t.texture].sources = sources
		if shader == null:
			if generated_textures[t.texture].texture != null:
				generated_textures[t.texture].texture = null
		else:
			if generated_textures[t.texture].texture == null:
				generated_textures[t.texture].texture = ImageTexture.new()
	_rerender()

func get_generated_texture(slot, file_prefix = null):
	if file_prefix != null:
		var file_name = "%s_%s.png" % [ file_prefix, slot ]
		if File.new().file_exists(file_name):
			return load(file_name)
		else:
			return null
	else:
		return generated_textures[slot].texture

func update_spatial_material(m, file_prefix = null):
	var texture
	m.albedo_color = albedo_color
	m.albedo_texture = get_generated_texture("albedo", file_prefix)
	m.metallic = metallic
	m.roughness = roughness
	if Engine.editor_hint:
		texture = get_generated_texture("mrao", file_prefix)
		m.metallic_texture = texture 
		m.metallic_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
		m.roughness_texture = texture
		m.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN
	else:
		m.metallic_texture = get_generated_texture("metallic", file_prefix)
		m.roughness_texture = get_generated_texture("roughness", file_prefix)
	texture = get_generated_texture("emission", file_prefix)
	if texture != null:
		m.emission_enabled = true
		m.emission_energy = emission_energy
		m.emission_texture = texture
	else:
		m.emission_enabled = false
	texture = get_generated_texture("normal_map", file_prefix)
	if texture != null:
		m.normal_enabled = true
		m.normal_texture = texture
	else:
		m.normal_enabled = false
	if Engine.editor_hint:
		if (generated_textures.mrao.mask & (1 << 2)) != 0:
			m.ao_enabled = true
			m.ao_light_affect = ao_light_affect
			m.ao_texture = m.metallic_texture
			m.ao_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_BLUE
		else:
			m.ao_enabled = false
	else:
		texture = get_generated_texture("ambient_occlusion", file_prefix)
		if texture != null:
			m.ao_enabled = true
			m.ao_light_affect = ao_light_affect
			m.ao_texture = texture
		else:
			m.ao_enabled = false
	texture = get_generated_texture("depth_map", file_prefix)
	if texture != null:
		m.depth_enabled = true
		m.depth_scale = depth_scale
		m.depth_texture = texture
	else:
		m.depth_enabled = false

func do_update_materials(material_list):
	for m in material_list:
		if m is SpatialMaterial:
			update_spatial_material(m)

func export_textures(prefix, size = null):
	if size == null:
		size = int(pow(2, 8+resolution))
	for t in texture_list:
		var texture = generated_textures[t.texture].texture
		if texture != null:
			var image = texture.get_data()
			image.save_png("%s_%s.png" % [ prefix, t.texture ])
	if Engine.editor_hint:
		var resource_filesystem = get_parent().editor_interface.get_resource_filesystem()
		resource_filesystem.scan()
		yield(resource_filesystem, "filesystem_changed")
		var new_material = SpatialMaterial.new()
		update_spatial_material(new_material, prefix)
		ResourceSaver.save("%s.tres" % [ prefix ], new_material)
		resource_filesystem.scan()
