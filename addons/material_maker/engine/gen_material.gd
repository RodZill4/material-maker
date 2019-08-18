tool
extends MMGenBase
class_name MMGenMaterial

var texture_list

var material : SpatialMaterial
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

func get_type():
	return "material"

func _ready():
	texture_list = TEXTURE_LIST
	if Engine.editor_hint:
		texture_list = ADDON_TEXTURE_LIST
	for t in texture_list:
		generated_textures[t.texture] = { shader=null, source=null, texture=null }
	material = SpatialMaterial.new()

func generate_material(renderer : MMGenRenderer):
	var source = get_source(0)
	if source != null:
		var status = source.generator.render(source.output_index, renderer, 512)
		while status is GDScriptFunctionState:
			status = yield(status, "completed")
		print("Render status: "+str(status))
		renderer.get_texture().get_data().save_png("res://test.png")
		material.albedo_texture = load("res://test.png")
	return material

func initialize(data: Dictionary):
	if data.has("name"):
		name = data.name

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
	m.albedo_color = parameters.albedo_color
	m.albedo_texture = get_generated_texture("albedo", file_prefix)
	m.metallic = parameters.metallic
	m.roughness = parameters.roughness
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
		m.emission_energy = parameters.emission_energy
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
			m.ao_light_affect = parameters.ao_light_affect
			m.ao_texture = m.metallic_texture
			m.ao_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_BLUE
		else:
			m.ao_enabled = false
	else:
		texture = get_generated_texture("ambient_occlusion", file_prefix)
		if texture != null:
			m.ao_enabled = true
			m.ao_light_affect = parameters.ao_light_affect
			m.ao_texture = texture
		else:
			m.ao_enabled = false
	texture = get_generated_texture("depth_map", file_prefix)
	if texture != null:
		m.depth_enabled = true
		m.depth_scale = parameters.depth_scale
		m.depth_texture = texture
	else:
		m.depth_enabled = false

func export_textures(prefix, size = null):
	if size == null:
		size = int(pow(2, 8+parameters.resolution))
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
